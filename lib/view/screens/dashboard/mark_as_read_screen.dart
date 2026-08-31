import 'package:biblebookapp/core/notifiers/download.notifier.dart';
import 'package:biblebookapp/Model/mainBookListModel.dart';
import 'package:biblebookapp/controller/dashboard_controller.dart';
import 'package:biblebookapp/home_widget/widget_prompt_cards.dart';
import 'package:biblebookapp/home_widget/widget_prompt_service.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/screens/dashboard/home_screen.dart';
import 'package:biblebookapp/controller/dpProvider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MarkAsReadScreen extends StatefulWidget {
  String RededBookName;
  String ReadedChapter;
  String SelectedBookChapterCount;
  MarkAsReadScreen(
      {super.key,
      required this.ReadedChapter,
      required this.RededBookName,
      required this.SelectedBookChapterCount});

  /// Presentation-only: always push as an opaque route so the reader never
  /// shows through during Mark as Read / Next Chapter transitions (real devices).
  static Future<T?>? open<T>({
    required String ReadedChapter,
    required String RededBookName,
    required String SelectedBookChapterCount,
  }) {
    return Get.to<T>(
      () => MarkAsReadScreen(
        ReadedChapter: ReadedChapter,
        RededBookName: RededBookName,
        SelectedBookChapterCount: SelectedBookChapterCount,
      ),
      opaque: true,
      transition: Transition.cupertino,
      duration: const Duration(milliseconds: 350),
    );
  }

  @override
  State<MarkAsReadScreen> createState() => _MarkAsReadScreenState();
}

class _MarkAsReadScreenState extends State<MarkAsReadScreen> {
  static const String _kMarkAsReadBg = 'assets/marks_as_read.png';
  static const Color _kMarkAsReadGold = Color(0xFFBF9B5A);
  static const Color _kMarkAsReadBrown = Color(0xFF5C4033);
  static const Color _kMarkAsReadBodyBrown = Color(0xFF6D5047);
  static const Color _kMarkAsReadCardCream = Color(0xFFF5F0E8);
  static const Color _kMarkAsReadTan = Color(0xFFEAD6BC);
  static const Color _kMarkAsReadTrack = Color(0xFFE8DFD4);

  String _currentMessage = "";
  String _readingPercentage = "0";

  /// Prevents rapid Next Chapter taps from stacking overlapping Home routes.
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _loadRotatingMessage();
    _loadReadingPercentage();
    _syncBookMetaFromDb();
    WidgetPromptService.noteChapterCompleted();
  }

  /// Additive: after a book switch, MarkAsRead may still hold the previous
  /// book's chapter_count — refresh from the active book row in prefs.
  Future<void> _syncBookMetaFromDb() async {
    try {
      final bookNumStr =
          await SharPreferences.getString(SharPreferences.selectedBookNum) ??
              '0';
      final bookNum = int.tryParse(bookNumStr) ?? 0;
      final db = await DBHelper().db;
      if (db == null) return;
      final rows = await db.rawQuery(
        'SELECT title, chapter_count FROM book WHERE book_num = ? LIMIT 1',
        [bookNum],
      );
      if (rows.isEmpty || !mounted) return;
      final count = rows[0]['chapter_count']?.toString();
      final title = rows[0]['title']?.toString().trim() ?? '';
      setState(() {
        if (count != null && count.isNotEmpty) {
          widget.SelectedBookChapterCount = count;
        }
        if (title.isNotEmpty) {
          widget.RededBookName = title;
        }
      });
      if (Get.isRegistered<DashBoardController>()) {
        final c = Get.find<DashBoardController>();
        c.selectedBookNum.value = bookNum.toString();
        if (count != null && count.isNotEmpty) {
          c.selectedBookChapterCount.value = count;
        }
        if (title.isNotEmpty) {
          c.selectedBook.value = title;
        }
      }
    } catch (e) {
      debugPrint('MarkAsRead sync book meta: $e');
    }
  }

  Future<void> _loadRotatingMessage() async {
    final List<String> markAsReadMessages = [
      "Well done. Keep walking in His Word!",
      "You're growing closer through Scripture!",
      "God's Word is shaping your life!",
      "A faithful step today. Go ahead!",
    ];
    final prefs = await SharedPreferences.getInstance();
    int messageIndex =
        prefs.getInt(SharPreferences.markAsReadMessageIndex) ?? 0;
    if (messageIndex >= markAsReadMessages.length) {
      messageIndex = 0;
    }
    if (mounted) {
      setState(() {
        _currentMessage = markAsReadMessages[messageIndex];
      });
    }
    final nextIndex = (messageIndex + 1) % markAsReadMessages.length;
    await SharPreferences.setInt(
        SharPreferences.markAsReadMessageIndex, nextIndex);
  }

  Future<void> _loadReadingPercentage() async {
    try {
      // Get current book number from SharedPreferences
      final currentBookNumStr =
          await SharPreferences.getString(SharPreferences.selectedBookNum) ??
              "0";
      final currentBookNum = int.parse(currentBookNumStr);

      // Get reading percentage from database
      final db = await DBHelper().db;
      if (db != null) {
        Future<void> applyFromDb() async {
          final result = await db.rawQuery(
              "SELECT read_per FROM book WHERE book_num = ? LIMIT 1",
              [currentBookNum]);

          if (result.isNotEmpty && result[0]["read_per"] != null) {
            final readPer =
                double.tryParse(result[0]["read_per"].toString()) ?? 0.0;
            if (mounted) {
              setState(() {
                _readingPercentage =
                    readPer >= 99.9 ? "100" : readPer.toStringAsFixed(1);
              });
            }
          }
        }

        await applyFromDb();
        // One short refresh in case the write finished a moment later.
        await Future<void>.delayed(const Duration(milliseconds: 120));
        if (mounted) await applyFromDb();
      }
    } catch (e) {
      debugPrint("Error loading reading percentage: $e");
    }
  }

  void _handleBackToReading() {
    final downloadProvider =
        Provider.of<DownloadProvider>(context, listen: false);
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Get.back(closeOverlays: false);
    }
    Future.microtask(() async {
      await WidgetsBinding.instance.endOfFrame;
      DashBoardController? controller;
      try {
        controller = Get.find<DashBoardController>();
      } catch (_) {}
      if (controller != null) {
        final scrollCtrl = controller.autoScrollController.value;
        if (scrollCtrl.hasClients) {
          scrollCtrl.jumpTo(0);
        }
      }
    });
    Future.microtask(() {
      final navContext = Get.context;
      if (navContext != null) {
        downloadProvider.incrementBookmarkCount(navContext);
      }
    });
  }

  Future<void> _popToReaderAfterChapterChange(
    DashBoardController? controller,
  ) async {
    if (!mounted) return;
    if (Navigator.of(context).canPop()) {
      await Navigator.of(context).maybePop();
    } else {
      Get.back(closeOverlays: false);
    }
    await WidgetsBinding.instance.endOfFrame;
    if (controller != null) {
      final scrollCtrl = controller.autoScrollController.value;
      if (scrollCtrl.hasClients) {
        scrollCtrl.jumpTo(0);
      }
    }
    Future.microtask(() {
      final navContext = Get.context;
      if (navContext != null) {
        Provider.of<DownloadProvider>(navContext, listen: false)
            .incrementBookmarkCount(navContext);
      }
    });
  }

  Future<void> _loadNextChapterOnReader(DashBoardController controller) async {
    // Prefer prefs book_num (source of truth after BookList) over possibly stale
    // controller.selectedBookNum from a previous book.
    try {
      final db = await DBHelper().db;
      if (db != null) {
        final bookNumStr =
            await SharPreferences.getString(SharPreferences.selectedBookNum) ??
                controller.selectedBookNum.value;
        final bookNum = int.tryParse(bookNumStr) ?? 0;
        controller.selectedBookNum.value = bookNum.toString();
        final rows = await db.rawQuery(
          'SELECT id, title, chapter_count, read_per FROM book WHERE book_num = ? LIMIT 1',
          [bookNum],
        );
        if (rows.isNotEmpty) {
          final title = rows[0]['title']?.toString().trim() ?? '';
          if (title.isNotEmpty) {
            controller.selectedBook.value = title;
            await SharPreferences.setString(
                SharPreferences.selectedBook, title);
          }
          if (rows[0]['id'] != null) {
            controller.selectedBookId.value = rows[0]['id'].toString();
          }
          if (rows[0]['chapter_count'] != null) {
            controller.selectedBookChapterCount.value =
                rows[0]['chapter_count'].toString();
          }
          if (rows[0]['read_per'] != null) {
            controller.bookReadPer.value = rows[0]['read_per'].toString();
          }
        }
      }
    } catch (e) {
      debugPrint('sync book before next chapter: $e');
    }
    await controller.forceReloadSelectedChapter();
    controller.isFetchContent.value = false;
    controller.loadTextToSpeech.value = false;
  }

  /// Additive: same path as chapter picker — open reader on current prefs chapter.
  Future<void> _openReaderOnCurrentChapter({
    required String bookNameHint,
  }) async {
    await SharPreferences.setString('OpenAd', '1');
    // Additive: load the target chapter on the shared controller before replacing
    // routes so Home cannot briefly keep / skip-reload the previous chapter.
    if (Get.isRegistered<DashBoardController>()) {
      try {
        final c = Get.find<DashBoardController>();
        await c.forceReloadSelectedChapter();
        c.isFetchContent.value = false;
        c.loadTextToSpeech.value = false;
      } catch (e) {
        debugPrint('open reader forceReload: $e');
      }
    }
    // Opaque cupertino (not fadeIn): fadeIn stacked this screen over the new
    // reader on real devices when switching OT→NT / Next Book.
    Get.offAll(
      () => HomeScreen(
        From: "Chapter",
        selectedVerseNumForRead: "",
        selectedBookForRead: "",
        selectedChapterForRead: "",
        selectedBookNameForRead: bookNameHint,
        selectedVerseForRead: "",
      ),
      transition: Transition.cupertino,
      duration: const Duration(milliseconds: 280),
      opaque: true,
    );
  }

  Widget _markAsReadSparkle({double size = 12}) {
    return Icon(
      Icons.auto_awesome,
      size: size,
      color: _kMarkAsReadGold.withOpacity(0.9),
    );
  }

  Widget _markAsReadSuccessBadge({required bool isCompact}) {
    final badgeWidth = isCompact ? 136.0 : 160.0;
    // Asset is 2:3; clip lower transparent area so title sits closer.
    final frameHeight = isCompact ? 98.0 : 114.0;

    return SizedBox(
      width: badgeWidth,
      height: frameHeight,
      child: ClipRect(
        child: Align(
          alignment: Alignment.topCenter,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: isCompact ? 0 : 2,
                left: isCompact ? 6 : 10,
                child: _markAsReadSparkle(size: isCompact ? 10 : 11),
              ),
              Positioned(
                top: isCompact ? 2 : 6,
                right: isCompact ? 6 : 10,
                child: _markAsReadSparkle(size: isCompact ? 11 : 13),
              ),
              Positioned(
                top: isCompact ? 8 : 12,
                left: isCompact ? 24 : 30,
                child: _markAsReadSparkle(size: isCompact ? 8 : 9),
              ),
              Image.asset(
                'assets/mark-us-complete.png',
                width: badgeWidth,
                fit: BoxFit.fitWidth,
                filterQuality: FilterQuality.high,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _markAsReadGoldDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: _kMarkAsReadGold.withOpacity(0.75),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Icon(
              Icons.favorite_border,
              size: 13,
              color: _kMarkAsReadGold,
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: _kMarkAsReadGold.withOpacity(0.75),
            ),
          ),
        ],
      ),
    );
  }

  Widget _markAsReadBookBadge() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: _kMarkAsReadTan,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Image.asset(
              'assets/reading_book.png',
              width: 24,
              height: 24,
              fit: BoxFit.contain,
            ),
          ),
        ),
        Positioned(
          top: -3,
          right: -1,
          child: Icon(
            Icons.auto_awesome,
            size: 14,
            color: _kMarkAsReadGold.withOpacity(0.95),
          ),
        ),
      ],
    );
  }

  Widget _markAsReadProgressBar(double progress) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final normalized = (progress / 100).clamp(0.0, 1.0);
        final fillWidth = constraints.maxWidth * normalized;
        final knobSize = 12.0;

        return SizedBox(
          height: 12,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 5,
                decoration: BoxDecoration(
                  color: _kMarkAsReadTrack,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              if (normalized > 0)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: fillWidth,
                  height: 5,
                  decoration: BoxDecoration(
                    color: _kMarkAsReadGold,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              if (normalized > 0)
                Positioned(
                  left: (fillWidth - knobSize / 2)
                      .clamp(0.0, constraints.maxWidth - knobSize),
                  top: 0,
                  child: Container(
                    width: knobSize,
                    height: knobSize,
                    decoration: BoxDecoration(
                      color: _kMarkAsReadGold,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: _kMarkAsReadGold.withOpacity(0.35),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _markAsReadProgressCard(double progress) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: _kMarkAsReadCardCream.withOpacity(0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.65)),
        boxShadow: [
          BoxShadow(
            color: _kMarkAsReadBrown.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _markAsReadBookBadge(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reading Progress',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _kMarkAsReadBrown,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Keep going, you\'re doing great!',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: _kMarkAsReadBodyBrown,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$_readingPercentage%',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: _kMarkAsReadGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _markAsReadProgressBar(progress),
        ],
      ),
    );
  }

  Widget _markAsReadDateRow({required bool isCompact}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.calendar_today_outlined,
          size: isCompact ? 16 : 18,
          color: _kMarkAsReadGold.withOpacity(0.95),
        ),
        const SizedBox(width: 8),
        Text(
          DateFormat('dd/MM/yyyy').format(DateTime.now()),
          style: TextStyle(
            fontSize: isCompact ? 15 : 17,
            fontWeight: FontWeight.w500,
            color: _kMarkAsReadBodyBrown,
          ),
        ),
      ],
    );
  }

  Widget _markAsReadBottomSection({
    required BuildContext context,
    required double progress,
    required bool hasNextChapter,
    required VoidCallback onNextChapter,
  }) {
    final media = MediaQuery.of(context);
    final bottomInset = media.padding.bottom;
    final isCompact = media.size.width < 375 || media.size.height < 700;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isCompact ? 16 : 20,
        isCompact ? 10 : 12,
        isCompact ? 16 : 20,
        bottomInset > 0
            ? bottomInset + (isCompact ? 4 : 8)
            : (isCompact ? 12 : 20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _markAsReadProgressCard(progress),
          SizedBox(height: isCompact ? 12 : 16),
          // UI-only press blink — onNextChapter logic unchanged.
          _PressBlinkButton(
            onTap: onNextChapter,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: double.infinity,
              height: isCompact ? 50 : 56,
              decoration: BoxDecoration(
                color: _kMarkAsReadBrown,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: _kMarkAsReadBrown.withOpacity(0.22),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    hasNextChapter ? 'Next Chapter' : 'Next Book',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: isCompact ? 10 : 12),
          FutureBuilder<bool>(
            future: WidgetPromptService.a1TriggerMet(),
            builder: (context, triggerSnap) {
              final nextChapter = (int.tryParse(widget.ReadedChapter) ?? 0) + 1;
              final nextLabel = hasNextChapter
                  ? '${widget.RededBookName} $nextChapter'
                  : 'Next book';
              return WidgetPromptGate(
                id: WidgetPromptId.a1,
                triggerMet: triggerSnap.data == true,
                builder: (context, onDismiss) => WidgetPromptA1Row(
                  nextLabel: nextLabel,
                  onDismiss: onDismiss,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress =
        (double.tryParse(_readingPercentage) ?? 0).clamp(0.0, 100.0);
    final hasNextChapter = int.parse(widget.ReadedChapter) + 1 <=
        int.parse("${int.parse(widget.SelectedBookChapterCount)}");
    final media = MediaQuery.of(context);
    // iPhone SE and other compact screens.
    final isCompact = media.size.width < 375 || media.size.height < 700;
    final titleSize = isCompact ? 24.0 : 28.0;
    final messageSize = isCompact ? 14.0 : 15.0;
    final bookNameSize = isCompact ? 20.0 : 24.0;
    final badgeTitleGap = isCompact ? 0.0 : 2.0;
    final messageGap = isCompact ? 4.0 : 6.0;
    final dividerGap = isCompact ? 8.0 : 10.0;
    final bookBlockGap = isCompact ? 10.0 : 12.0;

    return Scaffold(
      // Match bg asset so route transition has no yellow flash.
      backgroundColor: _kMarkAsReadCardCream,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: _kMarkAsReadCardCream),
          Image.asset(
            _kMarkAsReadBg,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            width: double.infinity,
            height: double.infinity,
            filterQuality: FilterQuality.high,
            gaplessPlayback: true,
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      isCompact ? 20 : 24,
                      isCompact ? 22 : 30,
                      isCompact ? 20 : 24,
                      isCompact ? 8 : 12,
                    ),
                    child: Column(
                      children: [
                        _markAsReadSuccessBadge(isCompact: isCompact),
                        SizedBox(height: badgeTitleGap),
                        Text(
                          'Successful!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: titleSize,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                            letterSpacing: 0,
                            color: _kMarkAsReadBrown,
                          ),
                        ),
                        SizedBox(height: messageGap),
                        Text(
                          _currentMessage.isEmpty
                              ? 'Loading...'
                              : _currentMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: messageSize,
                            height: 1.3,
                            color: _kMarkAsReadBodyBrown,
                          ),
                        ),
                        SizedBox(height: dividerGap),
                        _markAsReadGoldDivider(),
                        SizedBox(height: bookBlockGap),
                        ColorFiltered(
                          colorFilter: const ColorFilter.mode(
                            _kMarkAsReadGold,
                            BlendMode.srcIn,
                          ),
                          child: Image.asset(
                            'assets/reading_book.png',
                            width: isCompact ? 26 : 30,
                            height: isCompact ? 26 : 30,
                            fit: BoxFit.contain,
                          ),
                        ),
                        SizedBox(height: isCompact ? 6 : 8),
                        Text(
                          widget.RededBookName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: bookNameSize,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                            color: _kMarkAsReadBrown,
                          ),
                        ),
                        SizedBox(height: isCompact ? 2 : 4),
                        Text(
                          'Chapter ${widget.ReadedChapter}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isCompact ? 15 : 16,
                            fontWeight: FontWeight.w500,
                            height: 1.2,
                            color: _kMarkAsReadBodyBrown,
                          ),
                        ),
                        SizedBox(height: isCompact ? 8 : 10),
                        Container(
                          width: 120,
                          height: 1,
                          color: _kMarkAsReadGold.withOpacity(0.45),
                        ),
                        SizedBox(height: isCompact ? 10 : 12),
                        _markAsReadDateRow(isCompact: isCompact),
                      ],
                    ),
                  ),
                ),
                _markAsReadBottomSection(
                  context: context,
                  progress: progress,
                  hasNextChapter: hasNextChapter,
                  onNextChapter: () async {
                    if (_isNavigating) return;
                    _isNavigating = true;
                    debugPrint('ReadedChapter : ${widget.ReadedChapter}');
                    debugPrint(
                        'SelectedBookChapterCount : ${widget.SelectedBookChapterCount}');
                    if (int.parse(widget.ReadedChapter) + 1 <=
                        int.parse(
                            "${int.parse(widget.SelectedBookChapterCount)}")) {
                      // Next Chapter — write next chapter, then open reader the same
                      // way ChapterList does (From: "Chapter") so a prior book cannot
                      // keep the old chapter on screen.
                      final nextChapter = int.parse(widget.ReadedChapter) + 1;
                      final nextChapterStr = nextChapter.toString();
                      await SharPreferences.setString(
                          SharPreferences.selectedChapter, nextChapterStr);
                      await SharPreferences.setString('OpenAd', '1');
                      DashBoardController? controller;
                      try {
                        controller = Get.find<DashBoardController>();
                      } catch (e) {
                        debugPrint(
                            'DashBoardController not available for next chapter: $e');
                      }
                      if (controller != null) {
                        controller.selectedChapter.value = nextChapterStr;
                        controller.selectChapterChange.value = nextChapter;
                        controller.selectedChapterForRead.value =
                            nextChapterStr;
                        // Refresh chapter count from the active book (widget may
                        // still hold the previous book's count after a book switch).
                        try {
                          final bookNumStr = await SharPreferences.getString(
                                  SharPreferences.selectedBookNum) ??
                              controller.selectedBookNum.value;
                          final bookNum = int.tryParse(bookNumStr) ?? 0;
                          controller.selectedBookNum.value = bookNum.toString();
                          final db = await DBHelper().db;
                          if (db != null) {
                            final rows = await db.rawQuery(
                              'SELECT title, chapter_count FROM book WHERE book_num = ? LIMIT 1',
                              [bookNum],
                            );
                            if (rows.isNotEmpty) {
                              final title =
                                  rows[0]['title']?.toString().trim() ?? '';
                              if (title.isNotEmpty) {
                                controller.selectedBook.value = title;
                                await SharPreferences.setString(
                                    SharPreferences.selectedBook, title);
                              }
                              if (rows[0]['chapter_count'] != null) {
                                controller.selectedBookChapterCount.value =
                                    rows[0]['chapter_count'].toString();
                              }
                            }
                          }
                        } catch (e) {
                          debugPrint('next chapter book sync: $e');
                        }
                        controller.selectedBookContent.clear();
                        controller.selectedVersesContent.clear();
                      }
                      if (!context.mounted) {
                        _isNavigating = false;
                        return;
                      }
                      await _openReaderOnCurrentChapter(
                        bookNameHint: controller?.selectedBook.value ??
                            widget.RededBookName,
                      );
                      _isNavigating = false;
                    } else {
                      // Next Book - Get the next book and navigate to first chapter
                      try {
                        // Get current book number from SharedPreferences
                        final currentBookNumStr =
                            await SharPreferences.getString(
                                    SharPreferences.selectedBookNum) ??
                                "0";
                        final currentBookNum = int.parse(currentBookNumStr);

                        // Get next book from database
                        final db = await DBHelper().db;
                        if (db != null) {
                          final nextBookNum = currentBookNum + 1;
                          final result = await db.rawQuery(
                              "SELECT * FROM book WHERE book_num = $nextBookNum LIMIT 1");

                          if (result.isNotEmpty) {
                            final nextBook =
                                MainBookListModel.fromJson(result[0]);
                            final nextBookNumValue = nextBook.bookNum!.toInt();
                            final nextBookName = nextBook.title ?? "";
                            final nextBookChapterCount =
                                nextBook.chapterCount!.toInt();

                            // Update SharedPreferences for next book and first chapter
                            await SharPreferences.setString(
                                SharPreferences.selectedBook, nextBookName);
                            await SharPreferences.setString(
                                SharPreferences.selectedChapter, "1");
                            await SharPreferences.setString(
                                SharPreferences.selectedBookNum,
                                nextBookNumValue.toString());

                            // Navigate to reading screen
                            await SharPreferences.setString('OpenAd', '1');
                            if (!context.mounted) return;
                            DashBoardController? controller;
                            try {
                              controller = Get.find<DashBoardController>();
                            } catch (e) {
                              debugPrint(
                                  "DashBoardController not available: $e");
                            }
                            if (controller != null) {
                              controller.selectedBook.value = nextBookName;
                              controller.selectedBookNum.value =
                                  nextBookNumValue.toString();
                              controller.selectedChapter.value = "1";
                              controller.selectChapterChange.value = 1;
                              controller.selectedBookChapterCount.value =
                                  nextBookChapterCount.toString();
                              controller.selectedBookNameForRead.value =
                                  nextBookName;
                              controller.selectedBookNumForRead.value =
                                  nextBookNumValue.toString();
                              controller.selectedChapterForRead.value = "1";
                              controller.selectedBookContent.clear();
                              controller.selectedVersesContent.clear();
                            }
                            if (!context.mounted) {
                              _isNavigating = false;
                              return;
                            }
                            await _openReaderOnCurrentChapter(
                              bookNameHint: nextBookName,
                            );
                            _isNavigating = false;
                          } else {
                            // No next book found
                            _isNavigating = false;
                            Constants.showToast(
                                "Selected Book is completed. Please change the book.");
                          }
                        } else {
                          _isNavigating = false;
                          Constants.showToast(
                              "Selected Book is completed. Please change the book.");
                        }
                      } catch (e) {
                        _isNavigating = false;
                        debugPrint("Error getting next book: $e");
                        Constants.showToast(
                            "Selected Book is completed. Please change the book.");
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                onPressed: _handleBackToReading,
                padding: const EdgeInsets.only(left: 8, top: 2),
                constraints: const BoxConstraints(minWidth: 40, minHeight: 32),
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: _kMarkAsReadBrown,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Display-only tap feedback. Calls [onTap] immediately (no logic delay).
class _PressBlinkButton extends StatefulWidget {
  const _PressBlinkButton({
    required this.onTap,
    required this.child,
    this.borderRadius,
  });

  final VoidCallback onTap;
  final Widget child;
  final BorderRadius? borderRadius;

  @override
  State<_PressBlinkButton> createState() => _PressBlinkButtonState();
}

class _PressBlinkButtonState extends State<_PressBlinkButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value || !mounted) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(999);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: _pressed ? 0.72 : 1.0,
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeOut,
          child: ClipRRect(
            borderRadius: radius,
            child: Stack(
              alignment: Alignment.center,
              children: [
                widget.child,
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: _pressed ? 1 : 0,
                      duration: const Duration(milliseconds: 80),
                      child: ColoredBox(
                        color: Colors.white.withOpacity(0.28),
                      ),
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
}
