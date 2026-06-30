import 'package:biblebookapp/core/notifiers/download.notifier.dart';
import 'package:biblebookapp/Model/mainBookListModel.dart';
import 'package:biblebookapp/controller/dashboard_controller.dart';
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

  @override
  void initState() {
    super.initState();
    _loadRotatingMessage();
    _loadReadingPercentage();
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
        final result = await db.rawQuery(
            "SELECT read_per FROM book WHERE book_num = $currentBookNum LIMIT 1");

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
    } catch (e) {
      debugPrint("Error loading reading percentage: $e");
    }
  }

  void _handleBackToReading() {
    Get.back();
    Provider.of<DownloadProvider>(context, listen: false)
        .incrementBookmarkCount(context);
  }

  Widget _markAsReadSparkle({double size = 12}) {
    return Icon(
      Icons.auto_awesome,
      size: size,
      color: _kMarkAsReadGold.withOpacity(0.9),
    );
  }

  Widget _markAsReadSuccessBadge() {
    const badgeSize = 250.0;

    return SizedBox(
      height: 118,
      width: 170,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned(top: 4, left: 28, child: _markAsReadSparkle(size: 11)),
          Positioned(top: 8, right: 30, child: _markAsReadSparkle(size: 13)),
          Positioned(top: 16, left: 54, child: _markAsReadSparkle(size: 9)),
          Container(
            width: badgeSize,
            height: badgeSize,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/mark-us-complete.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
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
                  left: (fillWidth - knobSize / 2).clamp(0.0, constraints.maxWidth - knobSize),
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

  Widget _markAsReadBottomSection({
    required BuildContext context,
    required double progress,
    required bool hasNextChapter,
    required VoidCallback onNextChapter,
    required VoidCallback onBackToReading,
  }) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset > 0 ? bottomInset + 8 : 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: _kMarkAsReadGold.withOpacity(0.95),
              ),
              const SizedBox(width: 8),
              Text(
                DateFormat('dd/MM/yyyy').format(DateTime.now()),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: _kMarkAsReadBodyBrown,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _markAsReadProgressCard(progress),
          const SizedBox(height: 22),
          InkWell(
            onTap: onNextChapter,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: double.infinity,
              height: 56,
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
          const SizedBox(height: 16),
          Center(
            child: InkWell(
              onTap: onBackToReading,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Text(
                  'Back to Reading',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _kMarkAsReadCardCream,
                    shadows: const [
                      Shadow(
                        color: Color(0x99000000),
                        blurRadius: 8,
                        offset: Offset(0, 1),
                      ),
                    ],
                    decoration: TextDecoration.underline,
                    decorationColor: _kMarkAsReadGold,
                    decorationThickness: 1.5,
                  ),
                ),
              ),
            ),
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

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
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
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    child: Column(
                      children: [
                        _markAsReadSuccessBadge(),
                        const SizedBox(height: 14),
                        const Text(
                          'Successful!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: _kMarkAsReadBrown,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _currentMessage.isEmpty ? 'Loading...' : _currentMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.4,
                            color: _kMarkAsReadBodyBrown,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _markAsReadGoldDivider(),
                        const SizedBox(height: 20),
                        ColorFiltered(
                          colorFilter: const ColorFilter.mode(
                            _kMarkAsReadGold,
                            BlendMode.srcIn,
                          ),
                          child: Image.asset(
                            'assets/reading_book.png',
                            width: 30,
                            height: 30,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.RededBookName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: _kMarkAsReadBrown,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Chapter ${widget.ReadedChapter}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: _kMarkAsReadBodyBrown,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          width: 120,
                          height: 1,
                          color: _kMarkAsReadGold.withOpacity(0.45),
                        ),
                      ],
                    ),
                  ),
                ),
                _markAsReadBottomSection(
                  context: context,
                  progress: progress,
                  hasNextChapter: hasNextChapter,
                  onBackToReading: _handleBackToReading,
                  onNextChapter: () async {
                    debugPrint('ReadedChapter : ${widget.ReadedChapter}');
                    debugPrint(
                        'SelectedBookChapterCount : ${widget.SelectedBookChapterCount}');
                    if (int.parse(widget.ReadedChapter) + 1 <=
                        int.parse(
                            "${int.parse(widget.SelectedBookChapterCount)}")) {
                      // Next Chapter
                      SharPreferences.setString(SharPreferences.selectedChapter,
                          (int.parse(widget.ReadedChapter) + 1).toString());
                      debugPrint('Get off All');
                      await SharPreferences.setString('OpenAd', '1');
                      Get.offAll(
                          () => HomeScreen(
                              From: "Chapter",
                              selectedVerseNumForRead: "",
                              selectedBookForRead: "",
                              selectedChapterForRead: "",
                              selectedBookNameForRead: "",
                              selectedVerseForRead: ""),
                          transition: Transition.fadeIn,
                          duration: Duration(milliseconds: 300));
                      Provider.of<DownloadProvider>(context, listen: false)
                          .incrementBookmarkCount(context);
                    } else {
                      // Next Book - Get the next book and navigate to first chapter
                      try {
                        // Get current book number from SharedPreferences
                        final currentBookNumStr = await SharPreferences.getString(
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
                            final nextBook = MainBookListModel.fromJson(result[0]);
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

                            // Update controller if available
                            try {
                              final controller = Get.find<DashBoardController>();
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

                              // Load content
                              controller.getSelectedChapterAndBook();
                              controller.getBookContentForRead();
                            } catch (e) {
                              debugPrint("DashBoardController not available: $e");
                              // Controller will be initialized when HomeScreen loads
                            }

                            // Navigate to reading screen
                            await SharPreferences.setString('OpenAd', '1');
                            Get.offAll(
                                () => HomeScreen(
                                    From: "Chapter",
                                    selectedVerseNumForRead: "",
                                    selectedBookForRead: "",
                                    selectedChapterForRead: "",
                                    selectedBookNameForRead: "",
                                    selectedVerseForRead: ""),
                                transition: Transition.fadeIn,
                                duration: Duration(milliseconds: 300));
                            Provider.of<DownloadProvider>(context, listen: false)
                                .incrementBookmarkCount(context);
                          } else {
                            // No next book found
                            Constants.showToast(
                                "Selected Book is completed. Please change the book.");
                          }
                        } else {
                          Constants.showToast(
                              "Selected Book is completed. Please change the book.");
                        }
                      } catch (e) {
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
        ],
      ),
    );
  }
}
