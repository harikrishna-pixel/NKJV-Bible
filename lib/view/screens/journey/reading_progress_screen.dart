import 'dart:convert';

import 'package:biblebookapp/Model/mainBookListModel.dart';
import 'package:biblebookapp/controller/dashboard_controller.dart';
import 'package:biblebookapp/controller/dpProvider.dart';
import 'package:biblebookapp/core/notifiers/download.notifier.dart';
import 'package:biblebookapp/services/reading_activity_service.dart';
import 'package:biblebookapp/streak/streak_service.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/screens/dashboard/book_list_screen.dart';
import 'package:biblebookapp/view/screens/dashboard/chapterListScreen.dart';
import 'package:biblebookapp/view/screens/dashboard/home_screen.dart';
import 'package:biblebookapp/streak_flow/daily_journey_screen.dart';
import 'package:biblebookapp/view/screens/journey/journey_parchment.dart';
import 'package:biblebookapp/view/screens/journey/reading_activity_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReadingProgressScreen extends StatefulWidget {
  const ReadingProgressScreen({super.key});

  @override
  State<ReadingProgressScreen> createState() => _ReadingProgressScreenState();
}

class _ReadingProgressScreenState extends State<ReadingProgressScreen> {
  static const _ink = Color(0xFF3D2E24);
  static const _muted = Color(0xFF8A7A6C);
  static const _green = Color(0xFF5B8C51);

  int _biblePct = 0;
  double _biblePctRaw = 0;
  int _chaptersRead = 0;
  int _booksCompleted = 0;
  int _streakDays = 0;
  String _currentBook = '';
  int _currentChapter = 1;
  int _currentBookTotal = 1;
  int _currentBookPct = 0;
  List<ReadingActivity> _recent = [];
  List<MainBookListModel> _books = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Same chapter-done math as Book list capsules (`read_per` × chapter count).
  int _bookListDoneChapters(List<MainBookListModel> books) {
    var done = 0;
    for (final book in books) {
      done += _completedInBook(book);
    }
    return done;
  }

  int _bookListTotalChapters(List<MainBookListModel> books) {
    var total = 0;
    for (final book in books) {
      total += (book.chapterCount ?? 0).round().clamp(0, 9999);
    }
    return total;
  }

  /// Display-only: Bible Completed % from Book list `read_per` + latest marked
  /// chapters. Same sources as Book list; does not change save/streak.
  double _bibleCompletedPercentFromBookList(
    List<MainBookListModel> books, {
    int markedChapters = 0,
  }) {
    final total = _bookListTotalChapters(books);
    var done = _bookListDoneChapters(books);
    if (markedChapters > done) done = markedChapters;
    if (total <= 0 || done <= 0) return 0;
    return ((done * 100.0) / total).clamp(0.0, 100.0);
  }

  int _completedInBook(MainBookListModel book) {
    final total = (book.chapterCount ?? 0).round();
    if (total <= 0) return 0;
    final raw = double.tryParse((book.readPer ?? '0').trim()) ?? 0.0;
    if (raw <= 0) return 0;
    return (raw * total / 100.0).round().clamp(0, total);
  }

  Future<List<MainBookListModel>> _loadBooks() async {
    final books = <MainBookListModel>[];
    try {
      final db = await DBHelper().db;
      if (db != null) {
        final rows = await db.rawQuery('SELECT * FROM book ORDER BY book_num');
        books.addAll(rows.map((e) => MainBookListModel.fromJson(e)));
      }
    } catch (_) {}
    if (books.isNotEmpty) return books;
    try {
      final downloadProvider =
          Provider.of<DownloadProvider>(context, listen: false);
      if (downloadProvider.bookList.isNotEmpty) {
        return List<MainBookListModel>.from(downloadProvider.bookList);
      }
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      final allBookJson = prefs.getString('bookList');
      if (allBookJson != null && allBookJson.isNotEmpty) {
        return (jsonDecode(allBookJson) as List)
            .map((e) => MainBookListModel.fromJson(e))
            .toList();
      }
    } catch (_) {}
    return books;
  }

  Future<List<({int bookNum, int chapter, String bookName})>>
      _loadCompletedChapters(List<MainBookListModel> books) async {
    final out = <({int bookNum, int chapter, String bookName})>[];
    try {
      final db = await DBHelper().db;
      if (db == null) return out;
      final rows = await db.rawQuery(
        "SELECT book_num, chapter_num FROM verse WHERE LOWER(TRIM(is_read)) = 'yes' GROUP BY book_num, chapter_num",
      );
      final zeroBasedBooks = <int>{};
      for (final row in rows) {
        final bookNum = (row['book_num'] as num?)?.toInt() ?? 0;
        final chapterNum = (row['chapter_num'] as num?)?.toInt() ?? 0;
        if (chapterNum == 0) zeroBasedBooks.add(bookNum);
      }
      final byNum = <int, MainBookListModel>{};
      for (final book in books) {
        byNum[(book.bookNum ?? -1).toInt()] = book;
      }
      for (final row in rows) {
        final bookNum = (row['book_num'] as num?)?.toInt() ?? 0;
        final stored = (row['chapter_num'] as num?)?.toInt() ?? 0;
        final chapter =
            zeroBasedBooks.contains(bookNum) ? stored + 1 : stored;
        if (chapter <= 0) continue;
        final book = byNum[bookNum];
        final name = (book?.title ?? '').toString();
        if (name.isEmpty) continue;
        out.add((bookNum: bookNum, chapter: chapter, bookName: name));
      }
    } catch (_) {}
    return out;
  }

  Future<void> _load() async {
    var books = await _loadBooks();
    try {
      final downloadProvider =
          Provider.of<DownloadProvider>(context, listen: false);
      if (downloadProvider.bookList.isNotEmpty) {
        final live = <int, MainBookListModel>{};
        for (final b in downloadProvider.bookList) {
          live[(b.bookNum ?? -1).toInt()] = b;
        }
        books = books
            .map((b) {
              final src = live[(b.bookNum ?? -1).toInt()];
              if (src == null) return b;
              return b.copyWith(readPer: src.readPer ?? b.readPer);
            })
            .toList();
      }
    } catch (_) {}

    var chaptersRead = 0;
    var chaptersTotal = 0;
    var booksDone = 0;
    for (final book in books) {
      final total = (book.chapterCount ?? 0).round().clamp(0, 9999);
      chaptersTotal += total;
      final done = _completedInBook(book);
      chaptersRead += done;
      if (total > 0 && done >= total) booksDone++;
    }

    final verseReads = await _loadCompletedChapters(books);
    if (verseReads.isNotEmpty) {
      chaptersRead = verseReads.length;
      final byBook = <int, int>{};
      for (final read in verseReads) {
        byBook[read.bookNum] = (byBook[read.bookNum] ?? 0) + 1;
      }
      booksDone = 0;
      for (final book in books) {
        final total = (book.chapterCount ?? 0).round();
        final done = byBook[(book.bookNum ?? -1).toInt()] ?? 0;
        if (total > 0 && done >= total) booksDone++;
      }
    }

    if (chaptersRead == 0) {
      for (final book in books) {
        chaptersRead += _completedInBook(book);
      }
    }

    // Bible Completed follows latest Book list `read_per` (and marked chapters).
    final biblePctRaw = _bibleCompletedPercentFromBookList(
      books,
      markedChapters: chaptersRead,
    );
    final biblePct = biblePctRaw <= 0
        ? 0
        : DashBoardController.displayBookReadPercent(biblePctRaw.toString());

    String currentBook = '';
    int currentChapter = 1;
    int currentTotal = 1;
    int currentPct = 0;
    try {
      final controller = Get.find<DashBoardController>();
      currentBook = controller.selectedBook.value.trim();
      currentChapter =
          int.tryParse(controller.selectedChapter.value.trim()) ?? 1;
      currentTotal =
          int.tryParse(controller.selectedBookChapterCount.value.trim()) ?? 1;
      currentPct = DashBoardController.displayBookReadPercent(
          controller.bookReadPer.value);
      if (currentPct <= 0) {
        for (final book in books) {
          if ((book.title ?? '') == currentBook) {
            currentPct = DashBoardController.displayBookReadPercent(book.readPer);
            currentTotal = (book.chapterCount ?? currentTotal).round();
            break;
          }
        }
      }
    } catch (_) {
      currentBook =
          await SharPreferences.getString(SharPreferences.selectedBook) ?? '';
      currentChapter = int.tryParse(
              await SharPreferences.getString(SharPreferences.selectedChapter) ??
                  '1') ??
          1;
    }
    if (currentBook.isEmpty && books.isNotEmpty) {
      currentBook = books.first.title ?? '';
      currentTotal = (books.first.chapterCount ?? 1).round();
    }

    final streak = await StreakService.getCurrentStreak();
    final recent = await ReadingActivityService.mergeExistingReads(
      reads: verseReads,
    );

    if (!mounted) return;
    final recentOrdered = List<ReadingActivity>.from(recent)
      ..sort(ReadingActivity.compareNewestCompletedFirst);
    setState(() {
      _books = books;
      _biblePct = biblePct.clamp(0, 100);
      _biblePctRaw = biblePctRaw;
      _chaptersRead = chaptersRead;
      _booksCompleted = booksDone;
      _streakDays = streak;
      _currentBook = currentBook.isEmpty ? 'Bible' : currentBook;
      _currentChapter = currentChapter <= 0 ? 1 : currentChapter;
      _currentBookTotal = currentTotal <= 0 ? 1 : currentTotal;
      _currentBookPct = currentPct;
      _recent = recentOrdered;
    });
  }

  Future<void> _openBooks() async {
    await Get.to(
      () => const BookListScreen(showCompletedChapters: true),
      transition: Transition.cupertino,
      duration: const Duration(milliseconds: 300),
    );
    if (mounted) await _load();
  }

  void _openFaithJourney() {
    Get.to(
      () => const DailyJourneyScreen(),
      transition: Transition.cupertino,
      duration: const Duration(milliseconds: 300),
    );
  }

  /// Display-only label for Recent Activity / View All.
  String _activityWhenLabel(ReadingActivity item) {
    var bookFullyRead = false;
    for (final book in _books) {
      if ((item.bookNum > 0 && (book.bookNum ?? -1) == item.bookNum) ||
          (book.title ?? '') == item.bookName) {
        final total = (book.chapterCount ?? 0).round();
        bookFullyRead = total > 0 && _completedInBook(book) >= total;
        break;
      }
    }
    return item.whenLabelFor(bookFullyRead: bookFullyRead);
  }

  Future<void> _openActivity(ReadingActivity item) async {
    MainBookListModel? match;
    for (final book in _books) {
      if ((item.bookNum > 0 && (book.bookNum ?? -1) == item.bookNum) ||
          (book.title ?? '') == item.bookName) {
        match = book;
        break;
      }
    }
    await SharPreferences.setString(
        SharPreferences.selectedBook, item.bookName);
    if (item.bookNum > 0) {
      await SharPreferences.setString(
          SharPreferences.selectedBookNum, item.bookNum.toString());
    }
    Get.to(
      () => ChapterListScreen(
        chapterCount: match?.chapterCount ?? item.chapter,
        book_num: item.bookNum > 0 ? item.bookNum : (match?.bookNum ?? 1),
        selectedChapter: item.chapter,
      ),
      transition: Transition.cupertino,
      duration: const Duration(milliseconds: 300),
    );
  }

  /// Open the reader on the Currently Reading book + chapter (same ChapterList path).
  Future<void> _openCurrentlyReading() async {
    if (_currentBook.isEmpty) return;
    MainBookListModel? match;
    for (final book in _books) {
      if ((book.title ?? '') == _currentBook) {
        match = book;
        break;
      }
    }
    final chapterNum = _currentChapter <= 0 ? 1 : _currentChapter;
    final bookNumStr = (match?.bookNum ?? 0).toString();
    final chapterCountStr =
        (match?.chapterCount ?? _currentBookTotal).toString();

    await SharPreferences.setString(
        SharPreferences.selectedBook, _currentBook);
    await SharPreferences.setString(
        SharPreferences.selectedChapter, '$chapterNum');
    await SharPreferences.setString(
        SharPreferences.selectedBookNum, bookNumStr);

    if (Get.isRegistered<DashBoardController>()) {
      final c = Get.find<DashBoardController>();
      c.selectedChapter.value = '$chapterNum';
      c.selectChapterChange.value = chapterNum;
      c.selectedBookNum.value = bookNumStr;
      c.selectedBookChapterCount.value = chapterCountStr;
      c.selectedBook.value = _currentBook;
      c.selectedBookContent.clear();
      c.selectedVersesContent.clear();
    }

    Get.offAll(
      () => HomeScreen(
        From: 'Chapter',
        selectedVerseNumForRead: '',
        selectedBookForRead: '',
        selectedChapterForRead: '',
        selectedBookNameForRead: _currentBook,
        selectedVerseForRead: '',
      ),
      transition: Transition.cupertino,
      duration: const Duration(milliseconds: 280),
      opaque: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final screenH = MediaQuery.of(context).size.height;
    // Match reference: hero sits in mountain band; cards start in cream area.
    final heroHeight = (screenH * 0.30).clamp(210.0, 268.0);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EC),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/journey/reading_progress_bg.png',
              fit: BoxFit.fill,
              alignment: Alignment.topCenter,
              errorBuilder: (_, __, ___) => Container(
                decoration: journeyParchmentDecoration(context),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: heroHeight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: top + 4),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Get.back(),
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: _ink,
                            size: 20,
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'Reading Progress',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _ink,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Georgia',
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _openBooks,
                          icon: const Icon(
                            Icons.info_outline,
                            color: _ink,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(24, 0, 24, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Keep Going',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                              fontFamily: 'Georgia',
                              shadows: [
                                Shadow(
                                  color: Color(0x66000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Every chapter takes you closer to God\'s heart.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 1.3,
                              shadows: [
                                Shadow(
                                  color: Color(0x66000000),
                                  blurRadius: 6,
                                  offset: Offset(0, 1),
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
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                  children: [
                    _statsCard(),
                    const SizedBox(height: 14),
                    if (_streakDays > 0) ...[
                      _streakCard(),
                      const SizedBox(height: 22),
                    ],
                    _sectionTitle('Currently Reading'),
                    const SizedBox(height: 10),
                    _currentlyReadingCard(),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(child: _sectionTitle('Recent Activity')),
                        if (_recent.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              Get.to(
                                () => ReadingActivityListScreen(
                                  items: _recent,
                                  onOpen: _openActivity,
                                  whenLabelFor: _activityWhenLabel,
                                ),
                                transition: Transition.cupertino,
                                duration: const Duration(milliseconds: 300),
                              );
                            },
                            child: const Text(
                              'View All',
                              style: TextStyle(
                                color: Color(0xFFC4A574),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_recent.isEmpty)
                      _emptyActivity()
                    else
                      ..._recent.take(3).map(_activityTile),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _statCell(
              child: SizedBox(
                width: 54,
                height: 54,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: (_biblePctRaw <= 0 ? 0.0 : _biblePctRaw / 100)
                          .clamp(0.0, 1.0),
                      strokeWidth: 6,
                      backgroundColor: const Color(0xFFE8E2D8),
                      color: _green,
                    ),
                    Text(
                      _biblePctRaw <= 0
                          ? '0%'
                          : _biblePctRaw < 1
                              ? '${_biblePctRaw.toStringAsFixed(1)}%'
                              : '$_biblePct%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                  ],
                ),
              ),
              label: 'Bible Completed',
            ),
          ),
          Container(width: 1, height: 64, color: const Color(0xFFE8E2D8)),
          Expanded(
            child: _statCell(
              child: Column(
                children: [
                  const Icon(Icons.menu_book_rounded, color: Color(0xFF6B8FBF), size: 26),
                  const SizedBox(height: 4),
                  Text(
                    '$_chaptersRead',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                ],
              ),
              label: 'Chapters Read',
            ),
          ),
          Container(width: 1, height: 64, color: const Color(0xFFE8E2D8)),
          Expanded(
            child: _statCell(
              child: Column(
                children: [
                  const Icon(Icons.emoji_events_rounded, color: Color(0xFFD4A017), size: 26),
                  const SizedBox(height: 4),
                  Text(
                    '$_booksCompleted',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                ],
              ),
              label: 'Books Completed',
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCell({required Widget child, required String label}) {
    return Column(
      children: [
        child,
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: _muted, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _streakCard() {
    return Material(
      color: const Color(0xFFFAF0E1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: _openFaithJourney,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reading Streak',
                      style: TextStyle(
                        fontSize: 12,
                        color: _ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '$_streakDays days',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Great consistency!',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFFC45C26),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: _ink),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: _ink,
        fontFamily: 'Georgia',
      ),
    );
  }

  Widget _currentlyReadingCard() {
    final frac = (_currentBookPct / 100).clamp(0.0, 1.0);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: _openCurrentlyReading,
        borderRadius: BorderRadius.circular(16),
        child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/bible_widget/Continue_Reading_2.png',
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 56,
                height: 56,
                color: const Color(0xFFE8F0DC),
                child: const Icon(Icons.menu_book, color: _green),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentBook,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                    fontFamily: 'Georgia',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Chapter $_currentChapter of $_currentBookTotal',
                  style: const TextStyle(fontSize: 13, color: _muted),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: frac,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFE8E2D8),
                          color: _green,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$_currentBookPct%',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _muted,
                      ),
                    ),
                  ],
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

  Widget _emptyActivity() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Text(
        'Complete a chapter with Mark as Read to see it here.',
        textAlign: TextAlign.center,
        style: TextStyle(color: _muted, fontSize: 13),
      ),
    );
  }

  Widget _activityTile(ReadingActivity item) {
    final icons = [
      Icons.auto_stories_outlined,
      Icons.park_outlined,
      Icons.menu_book_outlined,
    ];
    final colors = [
      const Color(0xFFE8C36A),
      const Color(0xFF7CB342),
      const Color(0xFF5B8C51),
    ];
    final i = item.bookName.hashCode.abs() % 3;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => _openActivity(item),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors[i].withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icons[i], color: colors[i], size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _activityWhenLabel(item),
                        style: const TextStyle(fontSize: 12, color: _muted),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: _muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
