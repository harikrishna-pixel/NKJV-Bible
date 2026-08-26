import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_local_store.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Comments UI for a prayer — sheet/dialog or embedded inline in a card.
/// Fetch / post / edit / delete logic is unchanged.
class PrayerWallCommentsSheet extends StatefulWidget {
  const PrayerWallCommentsSheet({
    super.key,
    required this.prayerId,
    required this.titlePreview,
    this.embedded = false,
    this.onChanged,
    this.onEnsureCanPost,
  });

  final String prayerId;
  final String titlePreview;
  /// When true, render compact inline UI (no dialog chrome).
  final bool embedded;
  /// Called after comments list changes (post/edit/delete).
  final VoidCallback? onChanged;
  /// UI gate only: login check before posting. Viewing remains open.
  final Future<bool> Function()? onEnsureCanPost;

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
      widget.onChanged?.call();
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
    // UI gate: guests may view comments; posting requires login.
    if (widget.onEnsureCanPost != null) {
      final allowed = await widget.onEnsureCanPost!();
      if (!allowed || !mounted) return;
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
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) {
        final fieldBg =
            isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white;
        final fieldBorder = isDark
            ? Colors.white.withValues(alpha: 0.14)
            : const Color(0xFFE2D5C4);
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          backgroundColor: dialogBg,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.black26,
          elevation: 8,
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          title: Row(
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: Image.asset(
                  'assets/edit_post_quill_icon.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: brown.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.edit_outlined, color: brown, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Edit comment',
                style: TextStyle(
                  color: isDark ? Colors.white : brown,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Material(
            color: fieldBg,
            elevation: 0,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: fieldBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: TextField(
              controller: ctrl,
              maxLines: 4,
              maxLength: 1000,
              cursorColor: brown,
              style: TextStyle(
                color: isDark ? Colors.white : CommanColor.black,
                fontSize: 15,
                height: 1.35,
              ),
              decoration: InputDecoration(
                hintText: 'Update your comment',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                ),
                filled: true,
                fillColor: fieldBg,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                counterText: '',
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? const Color(0xFFF5EDE3) : brown,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: brown,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
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
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    const cream = Color(0xFFFFFBF7);
    const ink = Color(0xFF4B3423);
    const muted = Color(0xFF6B4E3D);
    const brown = Color(0xFF5C4033);
    const gold = Color(0xFFC9A227);
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) {
        final bg = isDark ? CommanColor.darkPrimaryColor : cream;
        final titleColor = isDark ? Colors.white : ink;
        final bodyColor = isDark ? Colors.white70 : muted;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Material(
            color: bg,
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/delete_comment_icon.png',
                    width: 140,
                    height: 140,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.delete_outline_rounded,
                      size: 56,
                      color: brown.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Delete comment?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'This comment will be permanently deleted and can’t be undone.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: bodyColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: gold.withValues(alpha: 0.45),
                          thickness: 1,
                          height: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(
                          Icons.eco_rounded,
                          size: 16,
                          color: gold.withValues(alpha: 0.9),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: gold.withValues(alpha: 0.45),
                          thickness: 1,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: titleColor,
                              side: BorderSide(
                                color: brown.withValues(
                                  alpha: isDark ? 0.55 : 0.7,
                                ),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: brown,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: const Text(
                              'Delete',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isVintage =
        themeProvider.currentCustomTheme == AppCustomTheme.vintage;
    final usesLightCustom = themeProvider.currentCustomTheme ==
            AppCustomTheme.white ||
        themeProvider.currentCustomTheme == AppCustomTheme.lightbrown;
    final isDark =
        themeProvider.themeMode == ThemeMode.dark && !usesLightCustom;
    final brown = const Color(0xFF5C4033);

    if (widget.embedded) {
      return _buildEmbedded(context, isDark: isDark, brown: brown);
    }

    final cream = isDark
        ? CommanColor.darkPrimaryColor
        : (isVintage
            ? const Color(0xFFF8F3EA)
            : themeProvider.backgroundColor);
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
                color: isVintage ? null : cream,
                image: isVintage
                    ? DecorationImage(
                        image: AssetImage(Images.bgImage(context)),
                        fit: BoxFit.cover,
                      )
                    : null,
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

  Widget _buildEmbedded(
    BuildContext context, {
    required bool isDark,
    required Color brown,
  }) {
    final ink = isDark ? Colors.white : const Color(0xFF3D2914);
    final muted = isDark ? Colors.white70 : const Color(0xFF6B5344);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Divider(
          height: 1,
          color: isDark ? Colors.white24 : const Color(0xFFE0D2C2),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              'Comments',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: ink,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: brown.withValues(alpha: isDark ? 0.35 : 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_rows.length}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : brown,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (_rows.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 36,
                  color: muted.withValues(alpha: isDark ? 0.45 : 0.35),
                ),
                const SizedBox(height: 8),
                Text(
                  'Be the first to encourage this person.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.3,
                    fontWeight: FontWeight.w400,
                    color: muted.withValues(alpha: isDark ? 0.55 : 0.42),
                  ),
                ),
              ],
            ),
          )
        else
          ..._rows.map((row) {
            final id = _commentId(row);
            final mine = id != null && _myIds.contains(id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: brown.withValues(alpha: 0.15),
                    child: Icon(
                      mine ? Icons.person : Icons.person_outline,
                      size: 16,
                      color: brown,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _commentText(row),
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.35,
                            color: ink,
                          ),
                        ),
                        if (mine)
                          Row(
                            children: [
                              TextButton(
                                onPressed: () => _edit(row),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.only(
                                    top: 4,
                                    bottom: 4,
                                    right: 10,
                                  ),
                                  minimumSize: const Size(0, 28),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ),
                                child: Text(
                                  'Edit',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: brown,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () => _delete(row),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                    horizontal: 4,
                                  ),
                                  minimumSize: const Size(0, 28),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ),
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: 6),
        Row(
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
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Write an encouraging comment...',
                  counterText: '',
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : const Color(0xFFF8F1E6),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white24 : const Color(0xFFD4C4B0),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white24 : const Color(0xFFD4C4B0),
                    ),
                  ),
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _posting
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Material(
                    color: brown,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _send,
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ],
    );
  }
}
