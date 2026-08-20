import 'package:biblebookapp/home_widget/bible_home_widget.dart';
import 'package:biblebookapp/home_widget/widget_prompt_service.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

/// Walkthrough for adding home-screen widgets.
/// Opened from Mark as Read (Add widget) and Home drawer -> Add Widget.
class AddWidgetIntroScreen extends StatefulWidget {
  const AddWidgetIntroScreen({
    super.key,
    this.iosWidgetKind,
    this.widgetTitle,
    this.previewImages,
    this.initialShowGallery = false,
  });

  final String? iosWidgetKind;
  final String? widgetTitle;
  final List<String>? previewImages;
  /// Drawer hub only: open straight to the swipe gallery (UI routing).
  final bool initialShowGallery;

  @override
  State<AddWidgetIntroScreen> createState() => _AddWidgetIntroScreenState();
}

class _DrawerWidgetCatalogItem {
  const _DrawerWidgetCatalogItem({
    required this.title,
    required this.subtitle,
    required this.iosWidgetKind,
    required this.previewImages,
    required this.icon,
    this.listThumbnailImage,
    this.listThumbnailWidth = 64,
    this.listThumbnailHeight = 64,
    this.countsDrawerGeneric = false,
  });

  final String title;
  final String subtitle;
  final String iosWidgetKind;
  final List<String> previewImages;
  final IconData icon;
  final String? listThumbnailImage;
  final double listThumbnailWidth;
  final double listThumbnailHeight;
  final bool countsDrawerGeneric;

  bool isExplored(Set<String> previewedKinds) {
    if (previewedKinds.contains(iosWidgetKind)) return true;
    if (countsDrawerGeneric && previewedKinds.contains('widgets')) {
      return true;
    }
    return false;
  }

  bool isAdded(Set<String> installedKinds) =>
      installedKinds.contains(iosWidgetKind);
}

class _AddWidgetIntroScreenState extends State<AddWidgetIntroScreen>
    with WidgetsBindingObserver {
  static const Color _brown = Color(0xFF5C4033);
  static const Color _bodyBrown = Color(0xFF6D5047);
  static const Color _cream = Color(0xFFF5F0E6);
  static const Color _goldInk = Color(0xFFC47A3A);
  static const Color _addedGreen = Color(0xFF2E7D32);
  static const Color _addedGreenChip = Color(0xFFDCEFD9);
  static const Color _addedGreenCard = Color(0xFFF1F8F1);
  static const Color _availableOrangeCard = Color(0xFFFFF6EB);
  static const Color _exploredChip = Color(0xFFFCE4CC);
  static const Color _darkTitleInk = Color(0xFFF5EDE3);
  static const Color _darkBodyInk = Color(0xFFE4D4C4);

  bool get _isDarkPage =>
      Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark;

  Color get _titleInk => _isDarkPage ? _darkTitleInk : _brown;

  Color get _bodyInk => _isDarkPage ? _darkBodyInk : _bodyBrown;

  static const List<_DrawerWidgetCatalogItem> _drawerCatalog = [
    _DrawerWidgetCatalogItem(
      title: 'Daily Verse',
      subtitle: 'A fresh verse on your Home Screen each day.',
      iosWidgetKind: kVerseOfTheDayWidgetKind,
      previewImages: [
        'assets/bible_widget/Daily_Verse_1.png',
        'assets/bible_widget/Daily_Verse_2.png',
        'assets/bible_widget/Daily_Verse_3.png',
      ],
      icon: Icons.wb_sunny_outlined,
      countsDrawerGeneric: true,
    ),
    _DrawerWidgetCatalogItem(
      title: 'Random Verse',
      subtitle: 'Tap to get a new verse on your Home Screen.',
      iosWidgetKind: kRandomVerseWidgetKind,
      previewImages: [
        'assets/bible_widget/Random_Verse_1.png',
        'assets/bible_widget/Random_Verse_2.png',
        'assets/bible_widget/Random_Verse_3.png',
      ],
      icon: Icons.shuffle_rounded,
    ),
    _DrawerWidgetCatalogItem(
      title: 'Hourly Verse',
      subtitle: 'A new verse every hour on your Home Screen.',
      iosWidgetKind: kHourlyVerseWidgetKind,
      previewImages: [
        'assets/bible_widget/Hourly_Verse_1.png',
        'assets/bible_widget/Hourly_Verse_2.png',
        'assets/bible_widget/Hourly_Verse_3.png',
      ],
      icon: Icons.schedule_rounded,
    ),
    _DrawerWidgetCatalogItem(
      title: 'Verse Image',
      subtitle: 'Scenic verse art on your Home Screen.',
      iosWidgetKind: kVerseImageWidgetKind,
      previewImages: [
        'assets/bible_widget/Verse_Image_1.png',
        'assets/bible_widget/Verse_Image_2.png',
        'assets/bible_widget/Verse_Image_3.png',
      ],
      icon: Icons.image_outlined,
    ),
    _DrawerWidgetCatalogItem(
      title: 'Continue Reading',
      subtitle: 'Pick up your Bible right where you left off.',
      iosWidgetKind: kContinueReadingWidgetKind,
      previewImages: [
        'assets/bible_widget/Continue_Reading_1.png',
        'assets/bible_widget/Continue_Reading_2.png',
        'assets/bible_widget/Continue_Reading_3.png',
      ],
      listThumbnailImage: 'assets/bible_widget/Continue_Reading_1.png',
      icon: Icons.menu_book_outlined,
    ),
    _DrawerWidgetCatalogItem(
      title: 'Weekly Reading Streak',
      subtitle: 'Keep your reading flame visible every day.',
      iosWidgetKind: kWeeklyStreakWidgetKind,
      previewImages: [
        'assets/bible_widget/Reading_Streak_1.png',
        'assets/bible_widget/Reading_Streak_2.png',
        'assets/bible_widget/Reading_Streak_3.png',
      ],
      icon: Icons.local_fire_department_outlined,
    ),
    _DrawerWidgetCatalogItem(
      title: 'Favorite Verse',
      subtitle: 'Rotate through the verses you have saved.',
      iosWidgetKind: kFavoriteVerseWidgetKind,
      previewImages: [
        'assets/bible_widget/Favorite_Verse.png',
        'assets/bible_widget/Favorite_Verse_2.png',
        'assets/bible_widget/Favorite_Verse_3.png',
      ],
      listThumbnailImage: 'assets/bible_widget/Favorite_Verse.png',
      icon: Icons.bookmark_outline_rounded,
    ),
    _DrawerWidgetCatalogItem(
      title: 'Bible Prayer',
      subtitle: 'Prayer prompts and guidance at a glance.',
      iosWidgetKind: kBiblePrayerWidgetKind,
      previewImages: [
        'assets/bible_widget/Bible_Prayer_1.png',
        'assets/bible_widget/Bible_Prayer_2.png',
        'assets/bible_widget/Bible_Prayer_3.png',
      ],
      icon: Icons.favorite_outline_rounded,
    ),
    _DrawerWidgetCatalogItem(
      title: 'Bible Chat',
      subtitle: 'A Bible Q&A on your Home Screen.',
      iosWidgetKind: kBibleChatWidgetKind,
      previewImages: [
        'assets/bible_widget/Bible_Chat_1.png',
        'assets/bible_widget/Bible_Chat_2.png',
        'assets/bible_widget/Bible_Chat_3.png',
      ],
      icon: Icons.chat_bubble_outline_rounded,
    ),
  ];

  static const List<String> _defaultPreviewImages = [
    'assets/bible_widget/Daily_Verse_1.png',
    'assets/bible_widget/Daily_Verse_2.png',
    'assets/bible_widget/Daily_Verse_3.png',
  ];

  List<String> get _previewImages {
    if (_hubPreviewActive &&
        _drawerGalleryImages != null &&
        _drawerGalleryImages!.isNotEmpty) {
      return _drawerGalleryImages!;
    }
    if (widget.previewImages != null && widget.previewImages!.isNotEmpty) {
      return widget.previewImages!;
    }
    return _defaultPreviewImages;
  }

  String? get _activeWidgetKind {
    if (_hubPreviewActive && _drawerGalleryTitle != null) {
      for (final item in _drawerCatalog) {
        if (item.title == _drawerGalleryTitle) {
          return item.iosWidgetKind;
        }
      }
    }
    return widget.iosWidgetKind;
  }

  String? get _activeWidgetTitle {
    if (_hubPreviewActive &&
        _drawerGalleryTitle != null &&
        _drawerGalleryTitle!.trim().isNotEmpty) {
      return _drawerGalleryTitle;
    }
    return widget.widgetTitle;
  }

  bool get _isDrawerEntry =>
      (widget.iosWidgetKind == null || widget.iosWidgetKind!.trim().isEmpty) &&
      (widget.widgetTitle == null || widget.widgetTitle!.trim().isEmpty);

  bool _showAvailableWidgets = false;
  bool _showHowToGuide = false;
  bool _hubPreviewActive = false;
  String? _drawerGalleryTitle;
  List<String>? _drawerGalleryImages;
  int _hubRefreshToken = 0;
  late final PageController _galleryPageController;
  int _galleryDotIndex = 0;

  Future<Map<String, Set<String>>> _loadDrawerHubKinds() async {
    final results = await Future.wait([
      WidgetPromptService.previewedWidgetKinds(),
      WidgetPromptService.installedDrawerWidgetKinds(),
    ]);
    return {
      'previewed': results[0],
      'installed': results[1],
    };
  }

  List<String> get _galleryPreviewImages {
    if (_hubPreviewActive &&
        _drawerGalleryImages != null &&
        _drawerGalleryImages!.isNotEmpty) {
      return _drawerGalleryImages!;
    }
    return _previewImages;
  }

  String get _galleryTitle {
    if (_hubPreviewActive &&
        _drawerGalleryTitle != null &&
        _drawerGalleryTitle!.trim().isNotEmpty) {
      return _drawerGalleryTitle!.trim();
    }
    return widget.widgetTitle ?? 'Available Widgets';
  }

  void _openDrawerWidgetPreview(_DrawerWidgetCatalogItem item) {
    setState(() {
      _hubPreviewActive = true;
      _drawerGalleryTitle = item.title;
      _drawerGalleryImages = item.previewImages;
      _showAvailableWidgets = false;
      _showHowToGuide = false;
    });
  }

  void _closeDrawerWidgetPreview() {
    setState(() {
      _hubPreviewActive = false;
      _drawerGalleryTitle = null;
      _drawerGalleryImages = null;
      _showAvailableWidgets = false;
    });
  }

  void _handleAppBarBack() {
    if (_showAvailableWidgets) {
      setState(() => _showAvailableWidgets = false);
      return;
    }
    if (_hubPreviewActive) {
      _closeDrawerWidgetPreview();
      return;
    }
    if (_showHowToGuide && _isDrawerEntry) {
      setState(() => _showHowToGuide = false);
      return;
    }
    Get.back();
  }
  Widget _galleryPageDots({required int count}) {
    if (count <= 1) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final active = index == _galleryDotIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 8 : 7,
          height: active ? 8 : 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? _goldInk : _titleInk.withOpacity(0.28),
          ),
        );
      }),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _galleryPageController = PageController();
    _showAvailableWidgets = widget.initialShowGallery &&
        widget.previewImages != null &&
        widget.previewImages!.isNotEmpty;
  }

  @override
  void dispose() {
    _galleryPageController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() => _hubRefreshToken++);
    }
  }

  Widget _dividerWithLeaf() {
    return Row(
      children: [
        Expanded(child: Divider(color: _titleInk.withOpacity(0.22), thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child:
              Icon(Icons.spa_outlined, size: 16, color: _titleInk.withOpacity(0.55)),
        ),
        Expanded(child: Divider(color: _titleInk.withOpacity(0.22), thickness: 1)),
      ],
    );
  }

  Widget _howToStep({
    required String number,
    required String title,
    required String body,
    required bool isLast,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _titleInk.withOpacity(0.7), width: 1.2),
            ),
            child: Text(
              number,
              style: TextStyle(
                fontFamily: 'Georgia',
                fontWeight: FontWeight.w700,
                color: _titleInk,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: _titleInk,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.35,
                    color: _bodyInk.withOpacity(0.95),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _widgetListThumbnail(
    String path, {
    double width = 64,
    double height = 64,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _brown.withOpacity(0.28),
          width: 1.2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.8),
        child: Image.asset(
          path,
          width: width,
          height: height,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) {
            final fallback = path.contains('assets/bible_widget/')
                ? path.replaceFirst(
                    'assets/bible_widget/', 'assets/bible_widegt/')
                : path;
            if (fallback == path) {
              return const Center(
                child: Icon(Icons.widgets_outlined, size: 28, color: _brown),
              );
            }
            return Image.asset(
              fallback,
              width: width,
              height: height,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (_, __, ___) => const Center(
                child: Icon(Icons.widgets_outlined, size: 28, color: _brown),
              ),
            );
          },
        ),
      ),
    );
  }

  bool _isWidePreviewAsset(String path) {
    return path.contains('Continue_Reading_1') ||
        path.contains('Favorite_Verse_2');
  }

  double _galleryPreviewHeight(String path) {
    return _isWidePreviewAsset(path) ? 120 : 420;
  }

  Widget _previewImage(String path, {double? height, double? width}) {
    return Image.asset(
      path,
      height: height,
      width: width,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) {
        final fallback = path.contains('assets/bible_widget/')
            ? path.replaceFirst('assets/bible_widget/', 'assets/bible_widegt/')
            : path;
        if (fallback == path) {
          return SizedBox(
            height: height ?? 120,
            width: width,
            child: const Center(
              child: Icon(Icons.widgets_outlined, size: 40, color: _brown),
            ),
          );
        }
        return Image.asset(
          fallback,
          height: height,
          width: width,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => SizedBox(
            height: height ?? 120,
            width: width,
            child: const Center(
              child: Icon(Icons.widgets_outlined, size: 40, color: _brown),
            ),
          ),
        );
      },
    );
  }

  Widget _hubSectionHeader({
    required Widget leading,
    required String title,
    String? subtitle,
    required Color titleColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            leading,
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 1.1,
                  color: titleColor,
                ),
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: _bodyInk.withOpacity(0.92),
            ),
          ),
        ],
      ],
    );
  }

  Widget _statusChip({
    required String label,
    required Color background,
    required Color foreground,
    Color? borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor ?? foreground.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }

  Widget _installedWidgetTile(_DrawerWidgetCatalogItem item) {
    final cardBg = _isDarkPage ? _addedGreen.withOpacity(0.12) : _addedGreenCard;
    final borderColor =
        _isDarkPage ? _addedGreen.withOpacity(0.45) : _addedGreen.withOpacity(0.35);

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openDrawerWidgetPreview(item),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Row(
              children: [
                _widgetListThumbnail(
                  item.listThumbnailImage ?? item.previewImages.first,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(item.icon, size: 16, color: _goldInk),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                fontFamily: 'Georgia',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _titleInk,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.3,
                          color: _bodyInk.withOpacity(0.88),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _statusChip(
                        label: 'Added',
                        background: _isDarkPage
                            ? _addedGreen.withOpacity(0.22)
                            : _addedGreenChip,
                        foreground: _addedGreen,
                        borderColor: _addedGreen.withOpacity(0.35),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.check_circle_rounded, color: _addedGreen, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _availableWidgetTile(
    _DrawerWidgetCatalogItem item, {
    required bool explored,
  }) {
    final cardBg =
        _isDarkPage ? _goldInk.withOpacity(0.08) : _availableOrangeCard;
    final borderColor =
        _isDarkPage ? _goldInk.withOpacity(0.35) : _goldInk.withOpacity(0.28);

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openDrawerWidgetPreview(item),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
            child: Row(
              children: [
                _widgetListThumbnail(
                  item.listThumbnailImage ?? item.previewImages.first,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(item.icon, size: 16, color: _goldInk),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                fontFamily: 'Georgia',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _titleInk,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.3,
                          color: _bodyInk.withOpacity(0.88),
                        ),
                      ),
                      if (explored) ...[
                        const SizedBox(height: 8),
                        _statusChip(
                          label: 'Explored',
                          background:
                              _isDarkPage ? _goldInk.withOpacity(0.18) : _exploredChip,
                          foreground: _goldInk,
                          borderColor: _goldInk.withOpacity(0.28),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _openDrawerWidgetPreview(item),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _goldInk,
                    backgroundColor:
                        _isDarkPage ? Colors.black.withOpacity(0.12) : Colors.white,
                    side: BorderSide(color: _goldInk.withOpacity(0.75)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: const Size(0, 34),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: const Text(
                    '+ Add',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _hubFooterTip() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline_rounded, size: 18, color: _goldInk),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Add a widget by long pressing it on your Home Screen or via the + Add button.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.35,
                color: _bodyInk.withOpacity(0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerWidgetsHub() {
    return FutureBuilder<Map<String, Set<String>>>(
      key: ValueKey(_hubRefreshToken),
      future: _loadDrawerHubKinds(),
      builder: (context, snap) {
        final previewed = snap.data?['previewed'] ?? const {};
        final installed = snap.data?['installed'] ?? const {};
        final installedItems = _drawerCatalog
            .where((item) => item.isAdded(installed))
            .toList();
        final availableItems = _drawerCatalog
            .where((item) => !item.isAdded(installed))
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.75),
                border: Border.all(color: _brown.withOpacity(0.14)),
              ),
              child: Image.asset(
                'assets/home icons/Widgets.png',
                width: 34,
                height: 34,
                color: _brown,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.widgets_outlined,
                  size: 34,
                  color: _brown,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Personalize Your Home Screen',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: _titleInk,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add beautiful, faith-filled widgets that keep ${BibleInfo.bible_shortName} with you throughout your day.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.5,
                height: 1.4,
                color: _bodyInk.withOpacity(0.95),
              ),
            ),
            if (installedItems.isNotEmpty) ...[
              const SizedBox(height: 24),
              _hubSectionHeader(
                leading: Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: _addedGreen,
                ),
                title: 'ON YOUR HOME SCREEN (${installedItems.length})',
                titleColor: _addedGreen,
              ),
              const SizedBox(height: 12),
              ...List.generate(installedItems.length, (index) {
                final item = installedItems[index];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == installedItems.length - 1 ? 0 : 12,
                  ),
                  child: _installedWidgetTile(item),
                );
              }),
            ],
            if (availableItems.isNotEmpty) ...[
              const SizedBox(height: 24),
              _hubSectionHeader(
                leading: Icon(
                  Icons.widgets_outlined,
                  size: 18,
                  color: _titleInk,
                ),
                title: 'AVAILABLE WIDGETS (${availableItems.length})',
                subtitle:
                    'Explore more widgets and add them to your Home Screen.',
                titleColor: _titleInk,
              ),
              const SizedBox(height: 12),
              ...List.generate(availableItems.length, (index) {
                final item = availableItems[index];
                final exploredItem = item.isExplored(previewed);
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == availableItems.length - 1 ? 0 : 12,
                  ),
                  child: _availableWidgetTile(
                    item,
                    explored: exploredItem,
                  ),
                );
              }),
            ],
            const SizedBox(height: 20),
            _hubFooterTip(),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _howToContent() {
    final appName = BibleInfo.bible_shortName;
    return Column(
      children: [
        if (_isDrawerEntry && _showHowToGuide) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _showHowToGuide = false),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
              label: const Text(
                'Back to widget list',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(foregroundColor: _titleInk),
            ),
          ),
          const SizedBox(height: 4),
        ],
        const SizedBox(height: 8),
        Icon(Icons.menu_book_rounded, size: 48, color: _titleInk),
        const SizedBox(height: 16),
        Text(
          'Keep God’s Word Close',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: _titleInk,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Add a Bible widget to your Home Screen for daily inspiration at a glance.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14.5,
            height: 1.4,
            color: _bodyInk,
          ),
        ),
        const SizedBox(height: 22),
        _dividerWithLeaf(),
        const SizedBox(height: 18),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'HOW TO ADD',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: 1.2,
              color: _titleInk,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _howToStep(
          number: '1',
          title: 'Go to Home Screen',
          body: 'Touch and hold an empty area on your Home Screen.',
          isLast: false,
        ),
        _howToStep(
          number: '2',
          title: 'Tap Edit',
          body: 'Tap Edit at the top left, then choose ‘Add Widget’.',
          isLast: false,
        ),
        _howToStep(
          number: '3',
          title: 'Find $appName',
          body: 'Search for ‘$appName’ in the widget list.',
          isLast: false,
        ),
        _howToStep(
          number: '4',
          title: 'Choose Your Widget',
          body: 'Select your preferred widget and tap ‘Add Widget’.',
          isLast: true,
        ),
        const SizedBox(height: 22),
        _dividerWithLeaf(),
        const SizedBox(height: 18),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'WIDGET PREVIEW',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: 1.2,
              color: _titleInk,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEFE4D4).withOpacity(0.9),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _brown.withOpacity(0.18)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _previewImage(
              _previewImages.first,
              height: _isWidePreviewAsset(_previewImages.first) ? 96 : 140,
              width: double.infinity,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'God’s Word, right on your Home Screen.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: _bodyInk,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () async {
              await WidgetPromptService.noteWidgetPreviewed(
                iosWidgetKind: _activeWidgetKind,
                widgetTitle: _activeWidgetTitle,
              );
              if (!mounted) return;
              setState(() {
                _showAvailableWidgets = true;
                _galleryDotIndex = 0;
              });
              if (_galleryPageController.hasClients) {
                _galleryPageController.jumpToPage(0);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _brown,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: const Text(
              'View Available Widgets  >',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextButton(
          onPressed: () => Get.back(),
          child: Text(
            'Got It',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _titleInk,
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _availableWidgetsGallery() {
    final pageWidth = MediaQuery.of(context).size.width - 40;
    final images = _galleryPreviewImages;
    final maxHeight = images
        .map(_galleryPreviewHeight)
        .fold<double>(0, (a, b) => a > b ? a : b);
    return Column(
      children: [
        const SizedBox(height: 8),
        Text(
          _galleryTitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: _titleInk,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Swipe to preview each widget style.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: _bodyInk),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: maxHeight,
          child: PageView.builder(
            controller: _galleryPageController,
            onPageChanged: (index) {
              if (mounted) setState(() => _galleryDotIndex = index);
            },
            itemCount: images.length,
            itemBuilder: (context, index) {
              final imagePath = images[index];
              final pageHeight = _galleryPreviewHeight(imagePath);
              return Align(
                alignment: Alignment.center,
                child: Container(
                  width: pageWidth,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFE4D4).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _brown.withOpacity(0.18)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: pageWidth - 24,
                      height: pageHeight,
                      child: _previewImage(
                        imagePath,
                        width: pageWidth - 24,
                        height: pageHeight,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        _galleryPageDots(count: images.length),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _bodyContent() {
    if (_showAvailableWidgets) return _availableWidgetsGallery();
    if (_isDrawerEntry && !_showHowToGuide && !_hubPreviewActive) {
      return _drawerWidgetsHub();
    }
    return _howToContent();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isVintage =
        themeProvider.currentCustomTheme == AppCustomTheme.vintage;
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final bg = isDark
        ? CommanColor.darkPrimaryColor
        : (isVintage ? _cream : themeProvider.backgroundColor);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: CommanColor.lightDarkPrimary(context),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: _handleAppBarBack,
        ),
        title: const Text(
          'Widgets',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      ),
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
            : BoxDecoration(color: bg),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 20),
            child: _bodyContent(),
          ),
        ),
      ),
    );
  }
}
