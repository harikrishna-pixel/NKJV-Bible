import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment is too long (max 1000).')),
      );
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment posted.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not post: $e')),
      );
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  Future<void> _edit(Map<String, dynamic> row) async {
    final id = _commentId(row);
    if (id == null) return;
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
    try {
      await PrayerWallService.updateComment(
        commentId: id,
        commentText: newText,
      );
      if (!mounted) return;
      await _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment updated.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update: $e')),
      );
    }
  }

  Future<void> _delete(Map<String, dynamic> row) async {
    final id = _commentId(row);
    if (id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete comment?'),
        content: const Text('This cannot be undone.'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment deleted.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete: $e')),
      );
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
    final cream =
        isDark ? CommanColor.darkPrimaryColor : const Color(0xFFF5F0E6);
    final cardBg = isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (_, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: cream,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFE7DCCB),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Comments',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : brown,
                        ),
                      ),
                      if (widget.titlePreview.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            widget.titlePreview,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white70 : Colors.grey.shade700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : const Color(0xFFE7DCCB),
                          ),
                        ),
                        child: TextField(
                          controller: _input,
                          maxLines: 3,
                          maxLength: 1000,
                          style: TextStyle(
                              color: isDark ? Colors.white : CommanColor.black),
                          decoration: InputDecoration(
                            hintText: 'Write a comment...',
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.fromLTRB(12, 12, 12, 12),
                            counterText: '',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _posting
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : Material(
                            color: brown,
                            borderRadius: BorderRadius.circular(12),
                            child: IconButton(
                              onPressed: _send,
                              icon: const Icon(Icons.send, color: Colors.white),
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
                                controller: scrollCtrl,
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
                                controller: scrollCtrl,
                                padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                                itemCount: _rows.length,
                                itemBuilder: (_, i) {
                                  final row = _rows[i];
                                  final id = _commentId(row);
                                  final mine =
                                      id != null && _myIds.contains(id);
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    decoration: BoxDecoration(
                                      color: cardBg,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.white.withValues(alpha: 0.08)
                                            : const Color(0xFFE7DCCB),
                                      ),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.fromLTRB(
                                          12, 6, 8, 6),
                                      leading: CircleAvatar(
                                        radius: 16,
                                        backgroundColor: mine
                                            ? brown.withValues(alpha: 0.18)
                                            : Colors.grey.withValues(alpha: 0.18),
                                        child: Icon(
                                          Icons.person_outline,
                                          size: 16,
                                          color: mine
                                              ? brown
                                              : (isDark ? Colors.white70 : Colors.black54),
                                        ),
                                      ),
                                      title: Text(
                                        _commentText(row),
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white
                                              : CommanColor.black,
                                          height: 1.3,
                                        ),
                                      ),
                                      trailing: mine
                                          ? Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: Icon(Icons.edit_outlined,
                                                      color: brown, size: 20),
                                                  onPressed: () => _edit(row),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                      Icons.delete_outline,
                                                      color: Colors.redAccent,
                                                      size: 20),
                                                  onPressed: () => _delete(row),
                                                ),
                                              ],
                                            )
                                          : null,
                                    ),
                                  );
                                },
                              ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
