import 'dart:io';

import 'package:biblebookapp/services/wallet_service.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/books/digital_products_library_store.dart';
import 'package:biblebookapp/view/screens/books/model/book_model.dart';
import 'package:biblebookapp/view/screens/dashboard/eproducts_screen.dart'
    show PdfViewScreen;
import 'package:biblebookapp/view/widget/wallet_entry.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

class DigitalProductDetailScreen extends StatefulWidget {
  const DigitalProductDetailScreen({super.key, required this.book});

  final BookModel book;

  static const unlockCost = 500;

  /// Google Drive file id when the product is a downloadable file.
  static String? driveFileIdOf(String url) {
    final m = RegExp(r'drive\.google\.com/(?:file/d/|open\?id=|uc\?(?:export=download&)?id=)([\w-]+)')
        .firstMatch(url);
    return m?.group(1);
  }

  @override
  State<DigitalProductDetailScreen> createState() =>
      _DigitalProductDetailScreenState();
}

class _DigitalProductDetailScreenState
    extends State<DigitalProductDetailScreen> {
  static const _brown = Color(0xFF6D4C41);
  static const _brownDark = Color(0xFF4E342E);
  static const _unlockCost = DigitalProductDetailScreen.unlockCost;
  bool _owned = false;
  bool _opening = false;
  File? _downloaded;
  double? _progress;

  @override
  void initState() {
    super.initState();
    _loadOwned();
  }

  Future<void> _loadOwned() async {
    final owned = await DigitalProductsLibraryStore.isOwned(widget.book.bookId);
    final file =
        await DigitalProductsLibraryStore.downloadedFile(widget.book.bookId);
    if (mounted) {
      setState(() {
        _owned = owned;
        _downloaded = file;
      });
    }
  }

  String? get _driveFileId =>
      DigitalProductDetailScreen.driveFileIdOf(widget.book.bookUrl);

  String get _ctaLabel {
    if (_driveFileId == null) return _owned ? 'Open again' : 'Open product';
    if (!_owned) return 'Unlock · $_unlockCost credits';
    if (_progress != null) {
      return 'Downloading… ${(_progress! * 100).round()}%';
    }
    return _downloaded == null ? 'Download' : 'Open';
  }

  Future<void> _onCtaTap() async {
    if (_opening) return;
    if (_driveFileId == null) return _openProduct();
    if (!_owned) return _unlock();
    if (_downloaded == null) return _download();
    return _openDownloaded();
  }

  Future<void> _unlock() async {
    setState(() => _opening = true);
    try {
      final credits = await WalletService.getCredits();
      if (!mounted) return;
      if (credits < _unlockCost) {
        await _showNotEnoughCredits(credits);
        return;
      }
      final ok = await _confirmUnlock(credits);
      if (ok != true || !mounted) return;
      final debited = await WalletService.deductCredits(_unlockCost);
      if (!debited) {
        if (mounted) {
          await _showNotEnoughCredits(await WalletService.getCredits());
        }
        return;
      }
      await DigitalProductsLibraryStore.add(widget.book);
      if (mounted) setState(() => _owned = true);
      Constants.showToast('Unlocked. Tap Download to save it.');
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _download() async {
    final id = _driveFileId;
    if (id == null) return;
    final isConnected = await InternetConnection().hasInternetAccess;
    if (!isConnected) {
      Constants.showToast('No Internet Connection');
      return;
    }
    setState(() {
      _opening = true;
      _progress = 0;
    });
    final file = await DigitalProductsLibraryStore.fileFor(widget.book);
    final tmp = File('${file.path}.part');
    try {
      await file.parent.create(recursive: true);
      await Dio().download(
        'https://drive.google.com/uc?export=download&id=$id',
        tmp.path,
        onReceiveProgress: (received, total) {
          if (!mounted || total <= 0) return;
          setState(() => _progress = received / total);
        },
      );
      final head = await tmp.openRead(0, 4).first;
      if (String.fromCharCodes(head) != '%PDF') {
        throw 'Not a PDF';
      }
      await tmp.rename(file.path);
      if (!mounted) return;
      setState(() => _downloaded = file);
      Constants.showToast('Saved to Digital Products.');
      await _openDownloaded();
    } catch (e) {
      debugPrint('Digital product download failed: $e');
      if (await tmp.exists()) await tmp.delete();
      Constants.showToast('Download failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _opening = false;
          _progress = null;
        });
      }
    }
  }

  Future<void> _openDownloaded() async {
    final file = _downloaded;
    if (file == null) return;
    await Get.to(() => PdfViewScreen(filePath: file.path));
  }

  Color get _dialogBg {
    final isDark = Provider.of<ThemeProvider>(context, listen: false)
            .themeMode ==
        ThemeMode.dark;
    return isDark ? const Color(0xFF2C2118) : const Color(0xFFFFF9F3);
  }

  Future<bool?> _confirmUnlock(int credits) {
    final ink = CommanColor.whiteBlack(context);
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _dialogBg,
        title: Text(
          'Unlock this product?',
          style: TextStyle(
              fontFamily: 'Georgia', fontWeight: FontWeight.w700, color: ink),
        ),
        content: Text(
          '$_unlockCost credits will be used. Your balance after unlocking: ${credits - _unlockCost} credits.',
          style: TextStyle(color: ink.withValues(alpha: 0.8), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: ink)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Unlock',
              style: TextStyle(color: ink, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showNotEnoughCredits(int credits) async {
    final ink = CommanColor.whiteBlack(context);
    final getCredits = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _dialogBg,
        title: Text(
          'Not enough credits',
          style: TextStyle(
              fontFamily: 'Georgia', fontWeight: FontWeight.w700, color: ink),
        ),
        content: Text(
          'You need $_unlockCost credits to unlock this product. You have $credits credits.',
          style: TextStyle(color: ink.withValues(alpha: 0.8), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: ink)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Get Credits',
              style: TextStyle(color: ink, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (getCredits == true) await WalletEntry.openWallet();
  }

  Future<void> _openProduct() async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      await SharPreferences.setString('OpenAd', '1');
      await DigitalProductsLibraryStore.add(widget.book);
      if (mounted) setState(() => _owned = true);
      final url = _productUrl(widget.book.bookUrl);
      if (url.isNotEmpty && await canLaunchUrlString(url)) {
        await launchUrlString(url, mode: LaunchMode.externalApplication);
      } else {
        Constants.showToast('Unable to open this product right now.');
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  /// BookAds sends Amazon links HTML-escaped many times over (`&amp;amp;…`)
  /// and cut off, which the Amazon app / Safari can't open as the product.
  /// Open the clean `/dp/<ASIN>` product page instead.
  static String _productUrl(String raw) {
    var url = raw.trim();
    while (url.contains('&amp;')) {
      url = url.replaceAll('&amp;', '&');
    }
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.host.contains('amazon.')) return url;
    final segments = uri.pathSegments;
    final dp = segments.indexOf('dp');
    if (dp < 0 || dp + 1 >= segments.length) return url;
    return 'https://${uri.host}/dp/${segments[dp + 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final isDark = theme.themeMode == ThemeMode.dark;
    final ink = CommanColor.whiteBlack(context);
    final muted = isDark ? Colors.white70 : const Color(0xFF7A6455);
    final heroUrl = widget.book.bookPromoImg.isNotEmpty
        ? widget.book.bookPromoImg
        : widget.book.bookThumbURL;

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
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: Icon(Icons.arrow_back_ios_new, size: 18, color: ink),
                    ),
                    Expanded(
                      child: Text(
                        'Product Detail',
                        textAlign: TextAlign.center,
                        style: CommanStyle.appBarStyle(context),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: 16 / 10,
                        child: heroUrl.isEmpty
                            ? Container(
                                color: isDark
                                    ? Colors.white12
                                    : const Color(0xFFE8DCC8),
                                child: Icon(Icons.menu_book, color: muted),
                              )
                            : CachedNetworkImage(
                                imageUrl: heroUrl,
                                fit: BoxFit.contain,
                                placeholder: (_, __) => Container(
                                  color: isDark
                                      ? Colors.white12
                                      : const Color(0xFFE8DCC8),
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  color: isDark
                                      ? Colors.white12
                                      : const Color(0xFFE8DCC8),
                                  child: Icon(Icons.menu_book, color: muted),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      widget.book.bookName,
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: ink,
                      ),
                    ),
                    if (widget.book.categoryTitle.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : const Color(0xFFF3E4C8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.book.categoryTitle,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFFE8C989) : _brown,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Text(
                      widget.book.bookDescription.isEmpty
                          ? 'A faith resource from ${widget.book.bookPublishedBy.isEmpty ? 'BibleOffice' : widget.book.bookPublishedBy}.'
                          : widget.book.bookDescription,
                      style: TextStyle(
                        fontSize: 17,
                        height: 1.5,
                        color: muted,
                      ),
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _opening ? null : _onCtaTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _brownDark,
                        disabledBackgroundColor:
                            _brownDark.withValues(alpha: 0.75),
                        disabledForegroundColor: Colors.white,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      child: Text(
                        _ctaLabel,
                        style: const TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
