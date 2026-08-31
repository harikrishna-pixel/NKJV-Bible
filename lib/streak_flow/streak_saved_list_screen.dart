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

IconData _streakSavedTypeIconData(String type) {
  switch (type) {
    case 'verse':
      return Icons.menu_book_rounded;
    case 'devotional':
      return Icons.local_fire_department_rounded;
    case 'prayer':
      return Icons.volunteer_activism_rounded;
    default:
      return Icons.bookmark;
  }
}

Widget _buildStreakSavedTypeIcon({
  required IconData icon,
  required Color gold,
  double outer = 44,
  double inner = 34,
  double iconSize = 20,
}) {
  return SizedBox(
    width: outer,
    height: outer,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: outer,
          height: outer,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.12),
            boxShadow: [
              BoxShadow(
                color: gold.withOpacity(0.28),
                blurRadius: 14,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        Container(
          width: inner,
          height: inner,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.9),
            border: Border.all(color: gold.withOpacity(0.5), width: 1),
          ),
          child: Icon(icon, color: gold, size: iconSize),
        ),
      ],
    ),
  );
}

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

class _StreakSavedListScreenState extends State<StreakSavedListScreen>
    with SingleTickerProviderStateMixin {
  static const Color _brown = Color(0xFF3D2914);
  static const Color _gold = Color(0xFFC9A227);
  static const Color _panel = Color(0xFFF8F4EB);

  List<StreakSavedItem> _items = [];
  bool _loading = true;
  late TabController _tabController;
  int _selectedTap = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && mounted) {
        setState(() => _selectedTap = _tabController.index);
      }
    });
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<StreakSavedItem> _itemsForType(String type) =>
      _items.where((e) => e.type == type).toList();

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

  BoxDecoration _tabChipDecoration(BuildContext context, int tabIndex) {
    final isSelected = _selectedTap == tabIndex;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(3),
      boxShadow: const [
        BoxShadow(
          color: Colors.black38,
          blurRadius: 0.5,
          spreadRadius: 1,
          offset: Offset(0, 1),
        ),
      ],
      color: isSelected
          ? CommanColor.lightDarkPrimary(context)
          : CommanColor.whiteBlack45(context),
    );
  }

  Color _tabIconColor(BuildContext context, int tabIndex) {
    if (_selectedTap == tabIndex) return Colors.white;
    return CommanColor.isDarkTheme(context)
        ? CommanColor.lightDarkPrimary(context)
        : Colors.white;
  }

  Widget _buildTabChip({
    required BuildContext context,
    required int tabIndex,
    required double screenWidth,
    required IconData icon,
    required String label,
  }) {
    final chipHeight = screenWidth > 450 ? 50.0 : 42.0;
    final iconSize = screenWidth > 450 ? 22.0 : 18.0;
    final fontSize = screenWidth > 450 ? 15.0 : 13.0;
    final isSelected = _selectedTap == tabIndex;

    return Tab(
      child: Container(
        height: chipHeight,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: _tabChipDecoration(context, tabIndex),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: _tabIconColor(context, tabIndex),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (CommanColor.isDarkTheme(context)
                          ? CommanColor.lightDarkPrimary(context)
                          : Colors.white),
                  fontFamily: 'Georgia',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeEmptyState({
    required String typeLabel,
    required Color textColor,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
        child: Text(
          'No saved $typeLabel yet.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            height: 1.45,
            color: textColor.withOpacity(0.85),
            fontFamily: 'Georgia',
          ),
        ),
      ),
    );
  }

  Widget _buildSavedListForType({
    required List<StreakSavedItem> items,
    required Color textColor,
    required Color panelColor,
  }) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _SavedItemCard(
          item: item,
          textColor: textColor,
          panelColor: panelColor,
          gold: _gold,
          onDelete: (String type) async {
            await StreakSavedStorage.remove(item.type, item.title, item.body);
            await _load();
            if (mounted) _showRemovedToast(context, type);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 450;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isVintage =
        themeProvider.currentCustomTheme == AppCustomTheme.vintage;
    final usesLightCustom = themeProvider.currentCustomTheme ==
            AppCustomTheme.white ||
        themeProvider.currentCustomTheme == AppCustomTheme.lightbrown;
    final isDark =
        themeProvider.themeMode == ThemeMode.dark && !usesLightCustom;
    final bgColor =
        isDark ? CommanColor.darkPrimaryColor : themeProvider.backgroundColor;
    final isWhiteLight =
        !isDark && themeProvider.currentCustomTheme == AppCustomTheme.white;
    final Color accentBrown = isWhiteLight ? const Color(0xFF424242) : _brown;
    final Color textColor = isDark ? Colors.white : accentBrown;
    final Color panelColor = isDark
        ? Colors.white.withOpacity(0.12)
        : (isWhiteLight ? const Color(0xFFF0F0F0) : _panel);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: isVintage
            ? BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(Images.bgImage(context)),
                  fit: BoxFit.cover,
                ),
              )
            : BoxDecoration(color: bgColor),
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
                        'Saved to Faith Journey',
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
                              color: _panel.withOpacity(0.9),
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
                            child: Icon(
                              Icons.menu_book_rounded,
                              size: 64,
                              color: _gold.withOpacity(0.95),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                        child: SizedBox(
                          height: isTablet ? 54 : 46,
                          child: TabBar(
                            controller: _tabController,
                            isScrollable: false,
                            indicatorWeight: 0,
                            dividerColor: Colors.transparent,
                            padding: EdgeInsets.zero,
                            labelPadding: EdgeInsets.zero,
                            indicatorPadding: EdgeInsets.zero,
                            indicatorSize: TabBarIndicatorSize.tab,
                            indicator: const BoxDecoration(),
                            onTap: (value) {
                              setState(() => _selectedTap = value);
                            },
                            tabs: [
                              _buildTabChip(
                                context: context,
                                tabIndex: 0,
                                screenWidth: MediaQuery.of(context).size.width,
                                icon: Icons.menu_book_rounded,
                                label: 'Verses',
                              ),
                              _buildTabChip(
                                context: context,
                                tabIndex: 1,
                                screenWidth: MediaQuery.of(context).size.width,
                                icon: Icons.local_fire_department_rounded,
                                label: 'Devotional',
                              ),
                              _buildTabChip(
                                context: context,
                                tabIndex: 2,
                                screenWidth: MediaQuery.of(context).size.width,
                                icon: Icons.volunteer_activism_rounded,
                                label: 'Prayer',
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _itemsForType('verse').isEmpty
                                ? _buildTypeEmptyState(
                                    typeLabel: 'verses',
                                    textColor: textColor,
                                  )
                                : _buildSavedListForType(
                                    items: _itemsForType('verse'),
                                    textColor: textColor,
                                    panelColor: panelColor,
                                  ),
                            _itemsForType('devotional').isEmpty
                                ? _buildTypeEmptyState(
                                    typeLabel: 'devotionals',
                                    textColor: textColor,
                                  )
                                : _buildSavedListForType(
                                    items: _itemsForType('devotional'),
                                    textColor: textColor,
                                    panelColor: panelColor,
                                  ),
                            _itemsForType('prayer').isEmpty
                                ? _buildTypeEmptyState(
                                    typeLabel: 'prayers',
                                    textColor: textColor,
                                  )
                                : _buildSavedListForType(
                                    items: _itemsForType('prayer'),
                                    textColor: textColor,
                                    panelColor: panelColor,
                                  ),
                          ],
                        ),
                      ),
                    ],
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
                  _buildStreakSavedTypeIcon(
                    icon: _streakSavedTypeIconData(item.type),
                    gold: gold,
                  ),
                  const SizedBox(width: 10),
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
