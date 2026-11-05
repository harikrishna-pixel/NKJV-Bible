import 'package:biblebookapp/controller/dashboard_controller.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/books/books_screen.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/screens/books/digital_product_detail_screen.dart';
import 'package:biblebookapp/view/screens/books/digital_products_library_store.dart';
import 'package:biblebookapp/view/screens/dashboard/eproducts_screen.dart'
    show PdfViewScreen;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyDigitalLibraryScreen extends StatefulWidget {
  const MyDigitalLibraryScreen({super.key, this.openedFromProducts = false});

  final bool openedFromProducts;

  @override
  State<MyDigitalLibraryScreen> createState() => _MyDigitalLibraryScreenState();
}

class _MyDigitalLibraryScreenState extends State<MyDigitalLibraryScreen> {
  static const _brown = Color(0xFF6D4C41);
  List<OwnedDigitalProduct> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final items = await DigitalProductsLibraryStore.load();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final isDark = theme.themeMode == ThemeMode.dark;
    final ink = CommanColor.whiteBlack(context);
    final muted = isDark ? Colors.white70 : const Color(0xFF7A6455);
    final card = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white;
    final border = isDark ? Colors.white24 : const Color(0xFFE6D8C8);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: theme.currentCustomTheme == AppCustomTheme.vintage
            ? BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(Images.bgImage(context)),
                  fit: BoxFit.fill,
                ),
              )
            : BoxDecoration(
                color: isDark ? Colors.black : const Color(0xFFF7F1E8),
              ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Get.back(),
                      icon:
                          Icon(Icons.arrow_back_ios_new, size: 18, color: ink),
                    ),
                    Expanded(
                      child: Text(
                        'My Digital Library',
                        textAlign: TextAlign.center,
                        style: CommanStyle.appBarStyle(context),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              if (_loading || _items.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Text(
                    'Your unlocked products. Downloaded books are saved on this device.',
                    style: TextStyle(fontSize: 14, height: 1.35, color: muted),
                  ),
                ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator.adaptive())
                    : _items.isEmpty
                        ? _buildEmptyState(context, isDark, ink, muted)
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: _items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              final book = item.book;
                              final date = DateFormat('d MMM yyyy')
                                  .format(item.purchasedAt);
                              return Material(
                                color: card,
                                borderRadius: BorderRadius.circular(14),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () async {
                                    final file =
                                        await DigitalProductsLibraryStore
                                            .downloadedFile(book.bookId);
                                    if (file != null) {
                                      await Get.to(() =>
                                          PdfViewScreen(filePath: file.path));
                                      return;
                                    }
                                    await Get.to(() =>
                                        DigitalProductDetailScreen(book: book));
                                    _reload();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: border),
                                    ),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: SizedBox(
                                            width: 52,
                                            height: 64,
                                            child: book.bookThumbURL.isEmpty
                                                ? ColoredBox(
                                                    color: isDark
                                                        ? Colors.white12
                                                        : const Color(
                                                            0xFFE8DCC8),
                                                    child: Icon(Icons.menu_book,
                                                        color: muted, size: 22),
                                                  )
                                                : CachedNetworkImage(
                                                    imageUrl: book.bookThumbURL,
                                                    fit: BoxFit.cover,
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                book.bookName,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 15,
                                                  color: ink,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Saved on $date',
                                                style: TextStyle(
                                                  fontSize: 12.5,
                                                  color: muted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? Colors.white
                                                    .withValues(alpha: 0.12)
                                                : const Color(0xFFF3E4C8),
                                            borderRadius:
                                                BorderRadius.circular(18),
                                          ),
                                          child: Text(
                                            'View',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                              color: isDark
                                                  ? const Color(0xFFE8C989)
                                                  : _brown,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
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

  Future<void> _exploreProducts() async {
    if (widget.openedFromProducts) {
      Get.back();
      return;
    }
    var bookAdsAppId = 0;
    try {
      if (Get.isRegistered<DashBoardController>()) {
        bookAdsAppId = Get.find<DashBoardController>().bookAdsAppId.value;
      }
    } catch (_) {}
    if (bookAdsAppId <= 0) {
      final prefs = await SharedPreferences.getInstance();
      bookAdsAppId = prefs.getInt('bookAdsAppId') ?? 0;
    }
    if (bookAdsAppId <= 0) {
      Constants.showToast('Digital products are unavailable right now.');
      return;
    }
    await Get.off(() => BooksScreen(bookAdId: bookAdsAppId));
  }

  Widget _buildEmptyState(
    BuildContext context,
    bool isDark,
    Color ink,
    Color muted,
  ) {
    final accent = isDark ? const Color(0xFFE8C989) : const Color(0xFF8B5A35);
    final line = isDark ? Colors.white24 : const Color(0xFFDCCDB8);
    final buttonBg = isDark ? const Color(0xFFCFA03A) : const Color(0xFF8B5A35);
    final buttonInk = isDark ? const Color(0xFF3A2923) : Colors.white;

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.menu_book_rounded, size: 72, color: accent),
                    const SizedBox(height: 18),
                    Text(
                      'No Digital Products Yet',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(child: Divider(color: line, thickness: 1)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Icon(Icons.favorite, size: 8, color: line),
                        ),
                        Expanded(child: Divider(color: line, thickness: 1)),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Unlock faith resources to access them\nhere anytime.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 16,
                        height: 1.5,
                        color: muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _exploreProducts,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonBg,
                foregroundColor: buttonInk,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.shopping_bag_outlined, size: 22),
              label: const Text(
                'Explore Digital Products',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
