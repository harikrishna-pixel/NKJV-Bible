import 'package:biblebookapp/Model/verseBookContentModel.dart';
import 'package:biblebookapp/services/study_plan_progress_service.dart';
import 'package:biblebookapp/services/study_plan_verse_service.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/chat/chat_screen.dart';
import 'package:biblebookapp/view/screens/study_plans/models/study_plan_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/controller/dpProvider.dart';
import 'package:biblebookapp/view/screens/dashboard/home_screen.dart';
import 'package:html/parser.dart' show parse;

class StudyPlanContentScreen extends StatefulWidget {
  final StudyPlan plan;
  final String imageUrl;

  const StudyPlanContentScreen({
    super.key,
    required this.plan,
    required this.imageUrl,
  });

  @override
  State<StudyPlanContentScreen> createState() => _StudyPlanContentScreenState();
}

class _StudyPlanContentScreenState extends State<StudyPlanContentScreen> {
  Map<String, List<VerseBookContentModel>> _versesContent = {};
  bool _isLoading = true;
  String? _errorMessage;
  bool _isCompleted = false;
  Map<String, bool> _completedVerses = {};
  double? _selectedFontSize;
  String? _selectedFontFamily;

  @override
  void initState() {
    super.initState();
    _loadFontPrefs();
    _loadVerseContent();
    _loadProgressStatus();
  }

  Future<void> _loadFontPrefs() async {
    try {
      final sizeStr =
          await SharPreferences.getString(SharPreferences.selectedFontSize);
      final family =
          await SharPreferences.getString(SharPreferences.selectedFontFamily);

      if (mounted) {
        setState(() {
          if (sizeStr != null) {
            _selectedFontSize = double.tryParse(sizeStr);
          }
          _selectedFontFamily = family;
        });
      }
    } catch (e) {
      debugPrint('Error loading font prefs: $e');
    }
  }

  double _fontSizeOr(double defaultSize) {
    return _selectedFontSize ?? defaultSize;
  }

  Future<void> _loadVerseContent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final versesMap = await StudyPlanVerseService.fetchAllPlanVerses(
        widget.plan.verses,
      );

      if (mounted) {
        setState(() {
          _versesContent = versesMap;
          _isLoading = false;
        });
        // Load per-verse completed flags after verses have been loaded
        _loadPerVerseCompletion();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading verses: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadPerVerseCompletion() async {
    try {
      final Map<String, bool> map = {};
      for (final verseRef in widget.plan.verses) {
        final completed = await StudyPlanProgressService.isVerseCompleted(
            widget.plan.id, verseRef);
        map[verseRef] = completed;
      }
      if (mounted) {
        setState(() {
          _completedVerses = map;
        });
      }
    } catch (e) {
      debugPrint('Error loading per-verse completion: $e');
    }
  }

  Future<void> _toggleVerseCompleted(String verseRef) async {
    final current = _completedVerses[verseRef] ?? false;
    final newVal = !current;
    await StudyPlanProgressService.setVerseCompleted(
        widget.plan.id, verseRef, newVal);
    if (mounted) {
      setState(() {
        _completedVerses[verseRef] = newVal;
      });
    }
  }

  Future<void> _openFullChapterForVerse(String verseRef) async {
    try {
      // Parse book name and chapter from verseRef like "Jeremiah 29:11"
      final lastSpace = verseRef.lastIndexOf(' ');
      if (lastSpace == -1) return;
      final bookName = verseRef.substring(0, lastSpace).trim();
      final chapterPart = verseRef.substring(lastSpace + 1).trim();
      final chapterStr = chapterPart.split(':').first;
      final chapterNum = int.tryParse(chapterStr) ?? 1;

      // Save into shared preferences used by the reading screen
      await SharPreferences.setString(SharPreferences.selectedBook, bookName);
      await SharPreferences.setString(
          SharPreferences.selectedChapter, chapterNum.toString());

      // Try to resolve and set book number if available in DB
      try {
        final db = await DBHelper().db;
        if (db != null) {
          final res = await db.rawQuery(
              "SELECT * FROM book WHERE title = ? LIMIT 1", [bookName]);
          if (res.isNotEmpty) {
            final bookNum = res[0]["book_num"]?.toString();
            if (bookNum != null) {
              await SharPreferences.setString(
                  SharPreferences.selectedBookNum, bookNum);
            }
          }
        }
      } catch (e) {
        debugPrint('Could not resolve book number: $e');
      }

      // Navigate to HomeScreen reading view for the chapter (keeps existing logic)
      Get.offAll(
        () => HomeScreen(
          selectedBookForRead: "",
          selectedChapterForRead: "",
          selectedVerseNumForRead: "",
          From: "Chapter",
          selectedBookNameForRead: "",
          selectedVerseForRead: "",
        ),
        transition: Transition.fadeIn,
        duration: Duration(milliseconds: 300),
      );
    } catch (e) {
      debugPrint('Error opening full chapter: $e');
    }
  }

  Future<void> _loadProgressStatus() async {
    try {
      final isCompleted =
          await StudyPlanProgressService.isCompleted(widget.plan.id);

      if (mounted) {
        setState(() {
          _isCompleted = isCompleted;
        });
      }
    } catch (e) {
      debugPrint('Error loading progress status: $e');
    }
  }

  void _handleAskQuestion() {
    // Open ChatScreen with context related to this Study Plan so the chat
    // session is prefilled with the plan details (keeps ChatScreen logic unchanged)
    final Map<String, String> verseContext = {
      'verseText': widget.plan.description,
      'book': widget.plan.title,
      'chapter': '',
      'verse': '',
    };

    Get.to(
      () => ChatScreen(verseContext: verseContext),
      transition: Transition.cupertino,
      duration: Duration(milliseconds: 300),
    );
  }

  Future<void> _markAsCompleted() async {
    await StudyPlanProgressService.markAsCompleted(widget.plan.id);
    await _loadProgressStatus(); // Refresh status
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Study plan completed! Well done!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _resetProgress() async {
    // Show confirmation dialog
    final bool? shouldReset = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Reset Progress'),
          content: Text(
            'Are you sure you want to reset your progress for this study plan? This will mark it as not started and you can begin again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text('Reset'),
            ),
          ],
        );
      },
    );

    if (shouldReset == true) {
      await StudyPlanProgressService.resetProgress(widget.plan.id);
      await _loadProgressStatus(); // Refresh status
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📝 Study plan progress reset. You can start fresh!'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _handleShare() {
    final String shareText = '''
📖 ${widget.plan.title}

${widget.plan.description}

🙏 Study Plan (${widget.plan.durationDays} days):
${widget.plan.verses.map((v) => '• $v').join('\n')}

Start your spiritual journey today!

Get the app:
https://play.google.com/store/apps/details?id=${BibleInfo.android_Package_Name}
https://itunes.apple.com/app/id${BibleInfo.apple_AppId}
''';

    // Get the RenderBox for positioning the share dialog on iOS
    final box = context.findRenderObject() as RenderBox?;
    final sharePositionOrigin =
        box != null ? box.localToGlobal(Offset.zero) & box.size : null;

    Share.share(
      shareText,
      subject: '${widget.plan.title} - Bible Study Plan',
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  Color _getCategoryColor() {
    switch (widget.plan.category) {
      case 'Love':
        return Colors.pink.shade400;
      case 'Joy':
        return Colors.amber.shade600;
      case 'Faith':
        return Colors.blue.shade400;
      case 'Peace':
        return Colors.teal.shade400;
      case 'Hope':
        return Colors.purple.shade400;
      case 'Wisdom':
        return Colors.indigo.shade400;
      case 'Courage':
        return Colors.orange.shade400;
      case 'Forgiveness':
        return Colors.green.shade400;
      case 'Healing':
        return Colors.lightBlue.shade400;
      default:
        return Colors.grey.shade400;
    }
  }

  /// Remove HTML tags from verse content
  String _cleanHtmlContent(String html) {
    try {
      // Parse HTML and get text content
      final document = parse(html);
      String text = document.body?.text ?? html;

      // Also handle cases where parse might not catch everything
      text = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
      text = text.replaceAll(RegExp(r'<[^>]*>'), '');

      return text.trim();
    } catch (e) {
      // If parsing fails, do basic cleanup
      return html
          .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .trim();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark;
    final primaryColor = _getCategoryColor();

    return Scaffold(
      backgroundColor: CommanColor.Blackwhite(context),
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: CommanColor.lightDarkPrimary(context),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Get.back(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.plan.title,
                // Use shared CommanStyle so font family/size settings apply
                style: CommanStyle.bwWithChangeFont(
                        context, _fontSizeOr(16), _selectedFontFamily)
                    .copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(
                      blurRadius: 4,
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  widget.imageUrl.isNotEmpty
                      ? Image.network(
                          widget.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(color: primaryColor);
                          },
                        )
                      : Container(color: primaryColor),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description Card
                Container(
                  margin: EdgeInsets.all(16),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade900 : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                  color: primaryColor,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '${widget.plan.durationDays} Day Plan',
                                  style: CommanStyle.bwWithChangeFont(
                                          context, 12, null)
                                      .copyWith(
                                    color: primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              widget.plan.category,
                              style: CommanStyle.bwWithChangeFont(
                                      context, 12, null)
                                  .copyWith(
                                color: primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Text(
                        widget.plan.description,
                        // Respect user font settings via CommanStyle helper
                        style: CommanStyle.bwWithChangeFont(
                                context, _fontSizeOr(15), _selectedFontFamily)
                            .copyWith(
                          color: CommanColor.whiteBlack(context),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),

                // Action Buttons
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _handleAskQuestion,
                          icon: Icon(Icons.chat, size: 18),
                          label: Text('Ask Question'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                CommanColor.lightDarkPrimary(context),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _handleShare,
                          icon: Icon(Icons.share, size: 18),
                          label: Text('Share'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark
                                ? Colors.white // Better visibility in dark mode
                                : CommanColor.lightDarkPrimary(context),
                            side: BorderSide(
                              color: isDark
                                  ? Colors
                                      .white // Better border visibility in dark mode
                                  : CommanColor.lightDarkPrimary(context),
                              width: 1.5,
                            ),
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),

                // Progress Action Button (Mark as Complete or Reset Progress)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: _isCompleted
                        ? ElevatedButton.icon(
                            onPressed: _resetProgress,
                            icon: Icon(Icons.refresh, size: 18),
                            label: Text('Reset Progress'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: _markAsCompleted,
                            icon: Icon(Icons.check_circle, size: 18),
                            label: Text('Mark as Completed'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 24),

                // Verses Section Header
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Bible Verses',
                    style: CommanStyle.bwWithChangeFont(
                            context, _fontSizeOr(20), _selectedFontFamily)
                        .copyWith(
                      color: CommanColor.whiteBlack(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 12),

                // Loading, Error, or Verses Content
                if (_isLoading)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Column(
                        children: [
                          CircularProgressIndicator(
                            color: primaryColor,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Loading verses...',
                            style: CommanStyle.bwWithChangeFont(context,
                                    _fontSizeOr(14), _selectedFontFamily)
                                .copyWith(
                              color: CommanColor.whiteBlack(context)
                                  .withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_errorMessage != null)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red,
                          ),
                          SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            style: CommanStyle.bwWithChangeFont(context,
                                    _fontSizeOr(14), _selectedFontFamily)
                                .copyWith(
                              color: Colors.red,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadVerseContent,
                            child: Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ..._buildVersesList(isDark, primaryColor),

                SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildVersesList(bool isDark, Color primaryColor) {
    final List<Widget> widgets = [];
    final int totalDays = widget.plan.durationDays;

    for (int i = 0; i < totalDays; i++) {
      final bool hasVerse = i < widget.plan.verses.length;
      final String? verseRef = hasVerse ? widget.plan.verses[i] : null;
      final verseContents =
          verseRef != null ? _versesContent[verseRef] ?? [] : [];

      widgets.add(
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade900 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Verse Reference Header
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.bookmark,
                      size: 18,
                      color: primaryColor,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        verseRef ?? 'No verse assigned',
                        style: CommanStyle.bwWithChangeFont(
                                context, _fontSizeOr(16), _selectedFontFamily)
                            .copyWith(
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Per-verse COMPLETE badge or toggle (only for real verses)
                    if (hasVerse && _completedVerses[verseRef] == true)
                      GestureDetector(
                        onTap: () => _toggleVerseCompleted(verseRef!),
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'COMPLETE',
                                style: CommanStyle.bwWithChangeFont(context,
                                        _fontSizeOr(11), _selectedFontFamily)
                                    .copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (hasVerse)
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints:
                            BoxConstraints(minWidth: 36, minHeight: 36),
                        onPressed: () => _toggleVerseCompleted(verseRef!),
                        icon: Icon(
                          Icons.check_circle_outline,
                          color: primaryColor.withOpacity(0.9),
                          size: 20,
                        ),
                      ),
                    SizedBox(width: 8),
                    Text(
                      'Day ${i + 1}',
                      style: CommanStyle.bwWithChangeFont(
                              context, _fontSizeOr(12), _selectedFontFamily)
                          .copyWith(color: primaryColor.withOpacity(0.7)),
                    ),
                  ],
                ),
              ),

              // Verse Content
              if (!hasVerse)
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No verse assigned for this day. This plan declares ${widget.plan.durationDays} days but no verse was provided for Day ${i + 1}.',
                    style: CommanStyle.bwWithChangeFont(
                            context, _fontSizeOr(14), _selectedFontFamily)
                        .copyWith(
                      color: CommanColor.whiteBlack(context).withOpacity(0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              else if (verseContents.isEmpty)
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Verse content not available. Please ensure the Bible is downloaded.',
                    style: CommanStyle.bwWithChangeFont(
                            context, _fontSizeOr(14), _selectedFontFamily)
                        .copyWith(
                      color: CommanColor.whiteBlack(context).withOpacity(0.6),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              else
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Read Full Chapter button (aligned right)
                      Row(
                        children: [
                          Spacer(),
                          ElevatedButton(
                            onPressed: () =>
                                _openFullChapterForVerse(verseRef!),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFD5C6A6),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Read Full Chapter',
                              style: CommanStyle.bwWithChangeFont(context,
                                      _fontSizeOr(14), _selectedFontFamily)
                                  .copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      ...verseContents.map((verse) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: _cleanHtmlContent(
                                      verse.content.toString()),
                                  style: CommanStyle.bwWithChangeFont(context,
                                          _fontSizeOr(15), _selectedFontFamily)
                                      .copyWith(
                                    height: 1.6,
                                    color: CommanColor.whiteBlack(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return widgets;
  }
}
