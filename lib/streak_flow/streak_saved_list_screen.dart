import 'package:biblebookapp/streak_flow/streak_saved_storage.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// App-style dialog colors (match streak celebration dialog)
const Color _dialogCream = Color(0xFFF8F4EB);
const Color _dialogBrown = Color(0xFF3D2914);

String _removedMessageForType(String type) {
  switch (type) {
    case 'verse':
      return 'Verse removed';
    case 'devotional':
      return 'Devotional removed';
    case 'prayer':
      return 'Prayer removed';
    default:
      return 'Removed';
  }
}

void _showRemovedToast(BuildContext context, String type) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  messenger?.hideCurrentSnackBar();
  messenger?.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      duration: const Duration(milliseconds: 1400),
      backgroundColor: _dialogCream,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _dialogBrown.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      content: Row(
        children: [
          Icon(
            Icons.bookmark_remove_rounded,
            color: _dialogBrown,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _removedMessageForType(type),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _dialogBrown,
                fontFamily: 'Georgia',
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

void _showRemoveDialog(BuildContext context, VoidCallback onConfirmRemove) {
  final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
  final isDark = themeProvider.themeMode == ThemeMode.dark;

  // Match the app-wide delete confirmation style shown in reference:
  // white dialog on dark background with two filled buttons.
  final bgColor = Colors.white;
  final titleColor = Colors.black;
  final msgColor = Colors.black.withOpacity(0.72);
  final cancelBg = const Color(0xFFE6E6E6);
  final cancelColor = Colors.black.withOpacity(0.75);
  final destructiveBg = _dialogBrown;
  final destructiveColor = Colors.white;

  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(isDark ? 0.55 : 0.35),
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Remove',
              style: TextStyle(
                color: titleColor,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                fontFamily: 'Georgia',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Remove this item from your saved list?',
              style: TextStyle(
                color: msgColor,
                fontSize: 13.5,
                height: 1.35,
                fontFamily: 'Georgia',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: TextButton.styleFrom(
                        backgroundColor: cancelBg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: cancelColor,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Georgia',
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        onConfirmRemove();
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: destructiveBg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Remove',
                        style: TextStyle(
                          color: destructiveColor,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Georgia',
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
}

/// Screen that shows all saved verses, devotionals, and prayers from Streak Flow.
/// Opened from Daily Journey (Saved button) or Settings (Saved from Daily Journey).
class StreakSavedListScreen extends StatefulWidget {
  const StreakSavedListScreen({super.key});

  @override
  State<StreakSavedListScreen> createState() => _StreakSavedListScreenState();
}

class _StreakSavedListScreenState extends State<StreakSavedListScreen> {
  static const Color _brown = Color(0xFF3D2914);
  static const Color _gold = Color(0xFFC9A227);
  static const Color _panel = Color(0xFFF8F4EB);

  List<StreakSavedItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await StreakSavedStorage.getAll();
    list.sort((a, b) {
      try {
        final da = DateTime.parse(a.savedAt);
        final db = DateTime.parse(b.savedAt);
        return db.compareTo(da); // newest first
      } catch (_) {
        return 0;
      }
    });
    if (mounted) {
      setState(() {
        _items = list;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 450;
    Color bgColor;
    try {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      bgColor = themeProvider.themeMode == ThemeMode.dark
          ? CommanColor.darkPrimaryColor
          : themeProvider.backgroundColor;
    } catch (_) {
      bgColor = const Color(0xFFF5F0E6);
    }
    final isDark = bgColor == CommanColor.darkPrimaryColor;
    final Color textColor = isDark ? Colors.white : _brown;
    final Color panelColor = isDark ? Colors.white.withOpacity(0.12) : _panel;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(Images.bgImage(context)),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios, color: textColor),
                      onPressed: () => Get.back(),
                    ),
                    Expanded(
                      child: Text(
                        'Saved',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isTablet ? 24 : 20,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                          fontFamily: 'Georgia',
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              if (_loading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_items.isEmpty)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: panelColor.withOpacity(isDark ? 0.35 : 0.9),
                              border: Border.all(
                                color: _gold.withOpacity(0.65),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _gold.withOpacity(0.25),
                                  blurRadius: 22,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(Icons.auto_stories,
                                    size: 64, color: _gold.withOpacity(0.95)),
                                // Positioned(
                                //   right: 28,
                                //   bottom: 28,
                                //   child: Icon(Icons.bookmark,
                                //       size: 24,
                                //       color:
                                //           textColor.withOpacity(isDark ? 0.85 : 0.75)),
                                // ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          Text(
                            'Nothing saved yet',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                              fontFamily: 'Georgia',
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'No saved verses, devotionals or prayers yet.\nStart your Daily Journey to save what inspires you.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.45,
                              color: textColor.withOpacity(0.85),
                              fontFamily: 'Georgia',
                            ),
                          ),
                          const SizedBox(height: 22),
                          SizedBox(
                            width: 240,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => Get.back(),
                                borderRadius: BorderRadius.circular(28),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: CommanColor.lightDarkPrimary(context),
                                    borderRadius: BorderRadius.circular(28),
                                    border: Border.all(
                                      color: _gold.withOpacity(0.65),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.18),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Text(
                                        'Start Your Journey',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          fontFamily: 'Georgia',
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Icon(Icons.arrow_forward,
                                          size: 18, color: Colors.white),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return _SavedItemCard(
                        item: item,
                        textColor: textColor,
                        panelColor: panelColor,
                        gold: _gold,
                        onDelete: (String type) async {
                          await StreakSavedStorage.removeAt(index);
                          await _load();
                          if (mounted) _showRemovedToast(context, type);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedItemCard extends StatefulWidget {
  const _SavedItemCard({
    required this.item,
    required this.textColor,
    required this.panelColor,
    required this.gold,
    required this.onDelete,
  });

  final StreakSavedItem item;
  final Color textColor;
  final Color panelColor;
  final Color gold;
  final void Function(String type) onDelete;

  @override
  State<_SavedItemCard> createState() => _SavedItemCardState();
}

class _SavedItemCardState extends State<_SavedItemCard> {
  bool _expanded = false;

  static String _typeLabel(String type) {
    switch (type) {
      case 'verse':
        return 'Verse';
      case 'devotional':
        return 'Devotional';
      case 'prayer':
        return 'Prayer';
      default:
        return type;
    }
  }

  static IconData _typeIcon(String type) {
    switch (type) {
      case 'verse':
        return Icons.menu_book;
      case 'devotional':
        return Icons.auto_stories;
      case 'prayer':
        return Icons.favorite;
      default:
        return Icons.bookmark;
    }
  }

  static String _formatSavedDate(String savedAt) {
    try {
      final dt = DateTime.parse(savedAt);
      return DateFormat('MMM d, yyyy').format(dt);
    } catch (_) {
      return savedAt.isNotEmpty ? savedAt : '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final textColor = widget.textColor;
    final panelColor = widget.panelColor;
    final gold = widget.gold;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: panelColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(_typeIcon(item.type), size: 20, color: gold),
                  const SizedBox(width: 8),
                  Text(
                    _typeLabel(item.type),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: gold,
                      fontFamily: 'Georgia',
                    ),
                  ),
                  if (item.savedAt.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Text(
                      _formatSavedDate(item.savedAt),
                      style: TextStyle(
                        fontSize: 13,
                        color: textColor.withOpacity(0.65),
                        fontFamily: 'Georgia',
                      ),
                    ),
                  ],
                  const Spacer(),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 24,
                    color: textColor.withOpacity(0.7),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 22, color: textColor.withOpacity(0.7)),
                    onPressed: () {
                      _showRemoveDialog(context, () => widget.onDelete(item.type));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (item.title.isNotEmpty && item.type != 'devotional' && item.type != 'prayer')
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    fontFamily: 'Georgia',
                  ),
                ),
              if (item.title.isNotEmpty && item.type != 'devotional' && item.type != 'prayer') const SizedBox(height: 4),
              Text(
                item.body,
                maxLines: _expanded ? null : 2,
                overflow: _expanded ? null : TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 17,
                  height: 1.45,
                  color: textColor,
                  fontFamily: 'Georgia',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
