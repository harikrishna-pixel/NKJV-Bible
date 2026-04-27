import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_local_store.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Bottom sheet: list comments, add, edit (PATCH), delete — for comments this device created.
class PrayerWallCommentsSheet extends StatefulWidget {
  const PrayerWallCommentsSheet({
    super.key,
    required this.prayerId,
    required this.titlePreview,
  });

  final String prayerId;
  final String titlePreview;

  @override
  State<PrayerWallCommentsSheet> createState() => _PrayerWallCommentsSheetState();
}

class _PrayerWallCommentsSheetState extends State<PrayerWallCommentsSheet> {
  final _input = TextEditingController();
  bool _loading = true;
  bool _posting = false;
  final Set<String> _editBusyIds = {};
  String? _error;
  List<Map<String, dynamic>> _rows = [];
  Set<String> _myIds = {};

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    _myIds = await PrayerWallLocalStore.loadMyCommentIds();
    await _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list =
          await PrayerWallService.fetchCommentsForPrayer(widget.prayerId);
      // Comments fetched successfully
      if (!mounted) return;
      setState(() {
        _rows = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String? _commentId(Map<String, dynamic> row) {
    return row['_id']?.toString();
  }

  String _commentText(Map<String, dynamic> row) {
    return (row['comment_text'] ?? row['text'] ?? '').toString();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    if (text.length > 1000) {
      Constants.showToast('Comment is too long (max 1000).');
      return;
    }
    setState(() => _posting = true);
    try {
      final id = await PrayerWallService.postComment(
        prayerId: widget.prayerId,
        commentText: text,
        isAnonymous: true,
      );
      await PrayerWallLocalStore.addMyCommentId(id);
      _input.clear();
      if (!mounted) return;
      setState(() {
        _myIds = {..._myIds, id};
      });
      await _reload();
      if (mounted) Constants.showToast('Comment posted.');
    } catch (e) {
      if (!mounted) return;
      Constants.showToast('Could not post. Please try again.');
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  Future<void> _edit(Map<String, dynamic> row) async {
    final id = _commentId(row);
    if (id == null) return;
    if (_editBusyIds.contains(id)) return;
    final ctrl = TextEditingController(text: _commentText(row));
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final brown = const Color(0xFF5C4033);
    final dialogBg =
        isDark ? CommanColor.darkPrimaryColor : const Color(0xFFF8F3EA);

    final newText = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: dialogBg,
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: brown.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.edit_outlined, color: brown, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'Edit comment',
              style: TextStyle(
                color: isDark ? Colors.white : brown,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFE7DCCB),
            ),
          ),
          child: TextField(
            controller: ctrl,
            maxLines: 4,
            maxLength: 1000,
            style: TextStyle(color: isDark ? Colors.white : CommanColor.black),
            decoration: InputDecoration(
              hintText: 'Update your comment',
              hintStyle: TextStyle(color: isDark ? Colors.white54 : null),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              counterText: '',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: brown)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(
                backgroundColor: brown, foregroundColor: Colors.white),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newText == null || newText.isEmpty) return;
    if (!mounted) return;
    setState(() => _editBusyIds.add(id));
    try {
      await PrayerWallService.updateComment(
        commentId: id,
        commentText: newText,
      );
      if (!mounted) return;
      // Small delay to allow server-side processing
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      await _reload();
      if (!mounted) return;
      Constants.showToast('Comment updated.');
    } catch (e) {
      if (!mounted) return;
      Constants.showToast('Could not update. Please try again.');
    } finally {
      if (!mounted) return;
      setState(() => _editBusyIds.remove(id));
    }
  }

  Future<void> _delete(Map<String, dynamic> row) async {
    final id = _commentId(row);
    if (id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete comment?'),
        content: const Text('This comment will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await PrayerWallService.deleteComment(id);
      await PrayerWallLocalStore.removeMyCommentId(id);
      if (!mounted) return;
      setState(() => _myIds.remove(id));
      await _reload();
      if (!mounted) return;
      Constants.showToast('Comment deleted.');
    } catch (e) {
      if (!mounted) return;
      Constants.showToast('Could not delete. Please try again.');
    }
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final brown = const Color(0xFF5C4033);
    final iconTileBg = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : brown.withValues(alpha: 0.12);
    final iconTileBorder = isDark
        ? Colors.white.withValues(alpha: 0.22)
        : brown.withValues(alpha: 0.18);
    final surfaceBg = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.0);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.82,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(Images.bgImage(context)),
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: isDark 
                    ? Colors.white.withValues(alpha: 0.1)
                    : const Color(0xFFD4C4B0),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  // Enhanced Header with close button and drag handle
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
                    child: Column(
                      children: [
                        // Drag handle
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark 
                              ? Colors.white.withValues(alpha: 0.3)
                              : brown.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Header row with title and close button
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: iconTileBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: iconTileBorder),
                              ),
                              child: Icon(
                                Icons.comment_outlined,
                                color: isDark ? Colors.white70 : brown,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Comments',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : brown,
                                      fontFamily: 'Georgia',
                                    ),
                                  ),
                                  if (widget.titlePreview.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        widget.titlePreview,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark ? Colors.white60 : Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
              // Enhanced input section
              Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surfaceBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.22)
                        : const Color(0xFFD4C4B0),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        maxLines: 3,
                        minLines: 1,
                        maxLength: 1000,
                        onTapOutside: (_) => FocusScope.of(context).unfocus(),
                        style: TextStyle(
                          color: isDark ? Colors.white : CommanColor.black,
                          fontSize: 15,
                          height: 1.4,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Share your thoughts...',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          counterText: '',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.white60 : Colors.grey.shade500,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _posting
                        ? Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.16)
                                  : Colors.grey.shade400,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          )
                        : Material(
                            color: brown,
                            borderRadius: BorderRadius.circular(12),
                            elevation: 2,
                            child: InkWell(
                              onTap: _send,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : RefreshIndicator(
                        onRefresh: _reload,
                        child: _rows.isEmpty
                            ? ListView(
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                children: [
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.height *
                                            0.15,
                                  ),
                                  Center(
                                    child: Text(
                                      'No comments yet.',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                                itemCount: _rows.length,
                                itemBuilder: (_, i) {
                                  final row = _rows[i];
                                  final id = _commentId(row);
                                  final mine =
                                      id != null && _myIds.contains(id);
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: surfaceBg,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: mine
                                            ? brown.withValues(alpha: 0.3)
                                            : (isDark
                                                ? Colors.white.withValues(alpha: 0.22)
                                                : const Color(0xFFD4C4B0)),
                                        width: mine ? 1.5 : 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: mine
                                                  ? brown.withValues(alpha: 0.15)
                                                  : (isDark 
                                                      ? Colors.white.withValues(alpha: 0.12)
                                                      : Colors.grey.withValues(alpha: 0.15)),
                                              borderRadius: BorderRadius.circular(18),
                                              border: Border.all(
                                                color: mine
                                                    ? brown.withValues(alpha: 0.3)
                                                    : (isDark 
                                                        ? Colors.white.withValues(alpha: 0.22)
                                                        : Colors.grey.withValues(alpha: 0.3)),
                                              ),
                                            ),
                                            child: Icon(
                                              mine ? Icons.account_circle : Icons.person_outline,
                                              size: 20,
                                              color: mine
                                                  ? (isDark ? Colors.white : brown)
                                                  : (isDark ? Colors.white70 : Colors.grey.shade600),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                if (mine)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                        horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: brown.withValues(alpha: 0.1),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      'You',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w600,
                                                        color: isDark ? Colors.white : brown,
                                                      ),
                                                    ),
                                                  ),
                                                if (mine) const SizedBox(height: 6),
                                                Text(
                                                  _commentText(row),
                                                  style: TextStyle(
                                                    color: isDark ? Colors.white : CommanColor.black,
                                                    height: 1.4,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (mine) ...[
                                            const SizedBox(width: 8),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  decoration: BoxDecoration(
                                                    color: isDark 
                                                        ? Colors.white.withValues(alpha: 0.12)
                                                        : brown.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: IconButton(
                                                    icon: Icon(
                                                      Icons.edit_outlined,
                                                      color: isDark ? Colors.white70 : brown,
                                                      size: 18,
                                                    ),
                                                    onPressed: () => _edit(row),
                                                    padding: const EdgeInsets.all(8),
                                                    constraints: const BoxConstraints(
                                                      minWidth: 32,
                                                      minHeight: 32,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Container(
                                                  decoration: BoxDecoration(
                                                    color: isDark
                                                        ? Colors.red.withValues(alpha: 0.14)
                                                        : Colors.red.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: IconButton(
                                                    icon: const Icon(
                                                      Icons.delete_outline,
                                                      color: Colors.redAccent,
                                                      size: 18,
                                                    ),
                                                    onPressed: () => _delete(row),
                                                    padding: const EdgeInsets.all(8),
                                                    constraints: const BoxConstraints(
                                                      minWidth: 32,
                                                      minHeight: 32,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
