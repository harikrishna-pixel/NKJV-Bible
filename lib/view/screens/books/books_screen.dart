import 'package:biblebookapp/services/analytics/analytics_service.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/books/bloc/book_bloc.dart';
import 'package:biblebookapp/view/screens/books/digital_product_detail_screen.dart';
import 'package:biblebookapp/view/screens/books/digital_products_library_store.dart';
import 'package:biblebookapp/view/screens/books/model/book_model.dart';
import 'package:biblebookapp/view/screens/books/my_digital_library_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:provider/provider.dart' as p;

/// Digital Products storefront — BookAds API via getAppInfo `book_ads_app_id`.
class BooksScreen extends HookConsumerWidget {
  final int bookAdId;
  const BooksScreen({super.key, required this.bookAdId});

  static const _brown = Color(0xFF6D4C41);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookState = ref.watch(bookBloc);
    final selectedCatId = useState<String>('all');
    // bookId → 'Unlocked' | 'Downloaded' for products the user has unlocked.
    final ownedStatus = useState<Map<String, String>>({});

    Future<void> loadOwnedStatus() async {
      final owned = await DigitalProductsLibraryStore.load();
      final status = <String, String>{};
      for (final o in owned) {
        final file =
            await DigitalProductsLibraryStore.downloadedFile(o.book.bookId);
        status[o.book.bookId] = file != null ? 'Downloaded' : 'Unlocked';
      }
      if (context.mounted) ownedStatus.value = status;
    }

    useEffect(() {
      loadOwnedStatus();
      return null;
    }, const []);

    useMemoized(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(bookBloc).getBooks(bookAdId);
        AnalyticsService.trackBooks();
      });
    });

    useEffect(() {
      if (!bookState.isLoading || bookState.books.isNotEmpty) {
        return null;
      }
      var cancelled = false;
      Future.delayed(const Duration(seconds: 12), () async {
        if (cancelled) return;
        final bloc = ref.read(bookBloc);
        if (!bloc.isLoading || bloc.books.isNotEmpty) return;
        final hasInternet = await InternetConnection().hasInternetAccess;
        final message = hasInternet
            ? 'Unable to load products right now. Please try again later.'
            : 'No internet connection. Please check your network and try again.';
        bloc.cancelLoading(message: message);
        Constants.showToast(message);
      });
      return () {
        cancelled = true;
      };
    }, [bookState.isLoading]);

    final theme = p.Provider.of<ThemeProvider>(context);
    final isDark = theme.themeMode == ThemeMode.dark;
    final ink = CommanColor.whiteBlack(context);
    final muted = isDark ? Colors.white70 : const Color(0xFF7A6455);
    final card = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white;
    final border = isDark ? Colors.white24 : const Color(0xFFE6D8C8);

    final filtered = selectedCatId.value == 'all'
        ? bookState.books
        : bookState.books
            .where((b) => b.categoryId == selectedCatId.value)
            .toList();

    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
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
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: Icon(Icons.arrow_back_ios_new, size: 18, color: ink),
                    ),
                    Expanded(
                      child: Text(
                        'Digital Products',
                        textAlign: TextAlign.center,
                        style: CommanStyle.appBarStyle(context),
                      ),
                    ),
                    IconButton(
                      tooltip: 'My Digital Library',
                      onPressed: () async {
                        await Get.to(() => const MyDigitalLibraryScreen());
                        await loadOwnedStatus();
                      },
                      icon: Icon(Icons.layers_outlined, color: ink),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 2, 20, 10),
                child: Text(
                  'Faith resources available to all users.',
                  style: TextStyle(fontSize: 14, height: 1.35, color: muted),
                ),
              ),
              if (bookState.categories.isNotEmpty)
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _catChip(
                        label: 'All',
                        selected: selectedCatId.value == 'all',
                        isDark: isDark,
                        onTap: () => selectedCatId.value = 'all',
                      ),
                      ...bookState.categories.map(
                        (c) => _catChip(
                          label: c.categoryTitle,
                          selected: selectedCatId.value == c.categoryId,
                          isDark: isDark,
                          onTap: () => selectedCatId.value = c.categoryId,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Expanded(
                child: bookState.isLoading && bookState.books.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator.adaptive(),
                      )
                    : bookState.loadTimedOut && bookState.books.isEmpty
                        ? Center(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 28),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.cloud_off_outlined,
                                    size: 48,
                                    color: CommanColor.lightDarkPrimary(context),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    bookState.loadStatusMessage ??
                                        'Unable to load products. Please try again.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: muted),
                                  ),
                                  const SizedBox(height: 20),
                                  TextButton(
                                    onPressed: () => ref
                                        .read(bookBloc)
                                        .retryLoad(bookAdId),
                                    child: Text(
                                      'Try Again',
                                      style: TextStyle(
                                        color: CommanColor.lightDarkPrimary(
                                            context),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : filtered.isEmpty
                            ? Center(
                                child: Text(
                                  'No products in this category.',
                                  style: TextStyle(color: muted),
                                ),
                              )
                            : ListView.separated(
                                physics: const BouncingScrollPhysics(),
                                padding:
                                    const EdgeInsets.fromLTRB(16, 4, 16, 24),
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final book = filtered[index];
                                  return _productRow(
                                    context: context,
                                    book: book,
                                    ink: ink,
                                    muted: muted,
                                    card: card,
                                    border: border,
                                    isDark: isDark,
                                    ownedLabel: ownedStatus.value[book.bookId],
                                    onReturn: loadOwnedStatus,
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

  /// "500 credits" before unlocking; "Unlocked" / "Downloaded" after.
  Widget _creditBadge({required bool isDark, required String? ownedLabel}) {
    final fg = isDark ? const Color(0xFFE8C989) : _brown;
    final IconData icon;
    final String label;
    if (ownedLabel == 'Downloaded') {
      icon = Icons.download_done_rounded;
      label = 'Downloaded';
    } else if (ownedLabel == 'Unlocked') {
      icon = Icons.lock_open_rounded;
      label = 'Unlocked';
    } else {
      icon = Icons.monetization_on_rounded;
      label = '${DigitalProductDetailScreen.unlockCost} credits';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : const Color(0xFFF6EBD7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.28)
              : const Color(0xFFDFCAA3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _catChip({
    required String label,
    required bool selected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: _brown,
        labelStyle: TextStyle(
          color: selected
              ? Colors.white
              : (isDark ? Colors.white70 : const Color(0xFF3D2914)),
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        backgroundColor:
            isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
        side: BorderSide(
          color: selected
              ? _brown
              : (isDark ? Colors.white24 : const Color(0xFFE6D8C8)),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        showCheckmark: false,
      ),
    );
  }

  Widget _productRow({
    required BuildContext context,
    required BookModel book,
    required Color ink,
    required Color muted,
    required Color card,
    required Color border,
    required bool isDark,
    required String? ownedLabel,
    required Future<void> Function() onReturn,
  }) {
    final paid =
        DigitalProductDetailScreen.driveFileIdOf(book.bookUrl) != null;
    return Material(
      color: card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          await Get.to(() => DigitalProductDetailScreen(book: book));
          await onReturn();
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
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 56,
                  height: 68,
                  child: book.bookThumbURL.isEmpty
                      ? ColoredBox(
                          color: isDark
                              ? Colors.white12
                              : const Color(0xFFE8DCC8),
                          child: Icon(Icons.menu_book, color: muted, size: 24),
                        )
                      : CachedNetworkImage(
                          imageUrl: book.bookThumbURL,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => ColoredBox(
                            color: isDark
                                ? Colors.white12
                                : const Color(0xFFE8DCC8),
                            child:
                                Icon(Icons.menu_book, color: muted, size: 24),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                      book.bookDescription.isEmpty
                          ? (book.categoryTitle.isEmpty
                              ? 'Digital faith resource'
                              : book.categoryTitle)
                          : book.bookDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.3,
                        color: muted,
                      ),
                    ),
                    if (paid) ...[
                      const SizedBox(height: 8),
                      _creditBadge(isDark: isDark, ownedLabel: ownedLabel),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right,
                color: muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
