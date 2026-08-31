import 'package:biblebookapp/services/study_plan_progress_service.dart';
import 'package:biblebookapp/services/unsplash_service.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/chat/chat_screen.dart';
import 'package:biblebookapp/view/screens/study_plans/data/study_plans_data.dart';
import 'package:biblebookapp/view/screens/study_plans/models/study_plan_model.dart';
import 'package:biblebookapp/view/screens/study_plans/study_plan_content_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';

class StudyPlanDetailScreen extends StatefulWidget {
  final String category;

  const StudyPlanDetailScreen({super.key, required this.category});

  @override
  State<StudyPlanDetailScreen> createState() => _StudyPlanDetailScreenState();
}

class _StudyPlanDetailScreenState extends State<StudyPlanDetailScreen> {
  final UnsplashService _unsplashService = UnsplashService();
  final Map<String, String> _planImages = {};
  List<StudyPlan> _studyPlans = [];
  final Map<String, bool> _expandedPlans = {}; // Track which plans are expanded
  final Map<String, double> _planProgress = {}; // Track progress for each plan
  final Map<String, bool> _planCompleted = {}; // Track completion status
  final Map<String, bool> _planStarted = {}; // Track started status

  @override
  void initState() {
    super.initState();
    _studyPlans = StudyPlansData.getStudyPlansByCategory(widget.category);
    _loadPlanImages();
    _loadPlanProgress();
  }

  Future<void> _loadPlanImages() async {
    for (var plan in _studyPlans) {
      try {
        final imageUrl = await _unsplashService.getImageUrl(
          plan.id,
          plan.category,
          plan.title,
        );
        if (mounted) {
          setState(() {
            _planImages[plan.id] = imageUrl;
          });
        }
      } catch (e) {
        debugPrint('Error loading image for ${plan.id}: $e');
      }
    }
  }

  Future<void> _loadPlanProgress() async {
    for (var plan in _studyPlans) {
      try {
        final progress = await StudyPlanProgressService.getProgress(plan.id);
        final isCompleted = await StudyPlanProgressService.isCompleted(plan.id);
        final isStarted = await StudyPlanProgressService.isStarted(plan.id);

        if (mounted) {
          setState(() {
            _planProgress[plan.id] = progress;
            _planCompleted[plan.id] = isCompleted;
            _planStarted[plan.id] = isStarted;
          });
        }
      } catch (e) {
        debugPrint('Error loading progress for ${plan.id}: $e');
      }
    }
  }

  void _handleAskQuestion(StudyPlan plan) {
    // Navigate to Chat Screen
    Get.to(
      () => ChatScreen(),
      transition: Transition.cupertino,
      duration: Duration(milliseconds: 300),
    );
  }

  Future<void> _handleStartPlan(StudyPlan plan) async {
    // Mark plan as started and update progress
    await StudyPlanProgressService.markAsStarted(plan.id);

    // Refresh progress data
    final progress = await StudyPlanProgressService.getProgress(plan.id);
    final isStarted = await StudyPlanProgressService.isStarted(plan.id);

    if (mounted) {
      setState(() {
        _planProgress[plan.id] = progress;
        _planStarted[plan.id] = isStarted;
      });
    }

    // Navigate to content screen
    Get.to(
      () => StudyPlanContentScreen(
        plan: plan,
        imageUrl: _planImages[plan.id] ?? '',
      ),
      transition: Transition.cupertino,
      duration: Duration(milliseconds: 300),
    );
  }

  Future<void> _handleResetPlan(StudyPlan plan) async {
    // Show confirmation dialog
    final bool? shouldReset = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Reset Progress'),
          content: Text(
            'Are you sure you want to reset your progress for "${plan.title}"? This will mark it as not started and you can begin again.',
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
      await StudyPlanProgressService.resetProgress(plan.id);

      // Refresh progress data
      await _loadPlanProgress();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('📝 "${plan.title}" progress reset. You can start fresh!'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showResetOptions(StudyPlan plan) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.refresh, color: Colors.orange),
                title: Text('Reset Progress'),
                subtitle: Text('Start this study plan from the beginning'),
                onTap: () {
                  Navigator.pop(context);
                  _handleResetPlan(plan);
                },
              ),
              ListTile(
                leading: Icon(Icons.cancel, color: Colors.grey),
                title: Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleShare(StudyPlan plan) {
    // Prepare share text (append app store links)
    final String shareText = '''
📖 ${plan.title}

${plan.description}

🙏 Study Plan:
${plan.verses.map((v) => '• $v').join('\n')}

⏱ Duration: ${plan.durationDays} days

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
      subject: '${plan.title} - Bible Study Plan',
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
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

  @override
  Widget build(BuildContext context) {
    final isDark =
        Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: CommanColor.Blackwhite(context),
      appBar: AppBar(
        backgroundColor: CommanColor.lightDarkPrimary(context),
        title: Text(
          widget.category,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: _studyPlans.isEmpty
          ? Center(
              child: Text(
                'No study plans available',
                style: TextStyle(
                  color: CommanColor.whiteBlack(context),
                  fontSize: 16,
                ),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _studyPlans.length,
              itemBuilder: (context, index) {
                final plan = _studyPlans[index];
                final imageUrl = _planImages[plan.id] ?? '';

                return _buildPlanCard(
                  context,
                  plan,
                  imageUrl,
                  isDark,
                );
              },
            ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context,
    StudyPlan plan,
    String imageUrl,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () {
        // Navigate to Study Plan Content Screen with verse text
        Get.to(
          () => StudyPlanContentScreen(
            plan: plan,
            imageUrl: imageUrl,
          ),
          transition: Transition.cupertino,
          duration: Duration(milliseconds: 300),
        );
      },
      onLongPress: _planCompleted[plan.id] == true
          ? () => _showResetOptions(plan)
          : null,
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade900 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Header
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  Container(
                    height: 180,
                    width: double.infinity,
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: _getCategoryColor(widget.category),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: _getCategoryColor(widget.category),
                              );
                            },
                          )
                        : Container(
                            color: _getCategoryColor(widget.category),
                          ),
                  ),
                  // Gradient overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.5),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Duration Badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: _getCategoryColor(widget.category),
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${plan.durationDays} days',
                            style: TextStyle(
                              color: _getCategoryColor(widget.category),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Progress Badge
                  if (_planCompleted[plan.id] == true ||
                      _planStarted[plan.id] == true)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _planCompleted[plan.id] == true
                              ? Colors.green.withOpacity(0.9)
                              : Colors.orange.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _planCompleted[plan.id] == true
                                  ? Icons.check_circle
                                  : Icons.play_circle_filled,
                              size: 12,
                              color: Colors.white,
                            ),
                            SizedBox(width: 4),
                            Text(
                              _planCompleted[plan.id] == true
                                  ? 'Completed'
                                  : '${StudyPlanProgressService.getProgressPercentage(_planProgress[plan.id] ?? 0.0)}%',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            // Add reset hint for completed plans
                            if (_planCompleted[plan.id] == true) ...[
                              SizedBox(width: 4),
                              Icon(
                                Icons.more_vert,
                                size: 10,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    plan.title,
                    style: TextStyle(
                      color: CommanColor.whiteBlack(context),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),

                  // Description
                  Text(
                    plan.description,
                    style: TextStyle(
                      color: CommanColor.whiteBlack(context).withOpacity(0.8),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 12),

                  // Progress Bar (only show if started or completed)
                  if (_planStarted[plan.id] == true ||
                      _planCompleted[plan.id] == true)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              StudyPlanProgressService.getProgressStatusText(
                                _planProgress[plan.id] ?? 0.0,
                                _planCompleted[plan.id] ?? false,
                                _planStarted[plan.id] ?? false,
                              ),
                              style: TextStyle(
                                color: _planCompleted[plan.id] == true
                                    ? Colors.green
                                    : Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${StudyPlanProgressService.getProgressPercentage(_planProgress[plan.id] ?? 0.0)}%',
                              style: TextStyle(
                                color: CommanColor.whiteBlack(context)
                                    .withOpacity(0.7),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: _planProgress[plan.id] ?? 0.0,
                          backgroundColor: isDark
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _planCompleted[plan.id] == true
                                ? Colors.green
                                : _getCategoryColor(widget.category),
                          ),
                          minHeight: 6,
                        ),
                        SizedBox(height: 16),
                      ],
                    )
                  else
                    SizedBox(height: 16),

                  // Verses Section
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.book,
                              size: 16,
                              color: _getCategoryColor(widget.category),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Key Verses',
                              style: TextStyle(
                                color: CommanColor.whiteBlack(context),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        // Show verses based on expansion state
                        ...(_expandedPlans[plan.id] == true
                                ? plan.verses
                                : plan.verses.take(3))
                            .map((verse) => Padding(
                                  padding: EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    '• $verse',
                                    style: TextStyle(
                                      color: CommanColor.whiteBlack(context)
                                          .withOpacity(0.7),
                                      fontSize: 13,
                                    ),
                                  ),
                                )),
                        // Show More/Less button if there are more than 3 verses
                        if (plan.verses.length > 3)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _expandedPlans[plan.id] =
                                    !(_expandedPlans[plan.id] ?? false);
                              });
                            },
                            child: Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                _expandedPlans[plan.id] == true
                                    ? '  Less'
                                    : '  More',
                                style: TextStyle(
                                  color: _getCategoryColor(widget.category),
                                  fontSize:
                                      15, // Slightly bigger text as requested
                                  fontWeight: FontWeight.w600,
                                  // decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    children: [
                      // Ask Question Button (or Start Button if not started)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            // If not started, start the plan first
                            if (_planStarted[plan.id] != true) {
                              await _handleStartPlan(plan);
                            } else {
                              _handleAskQuestion(plan);
                            }
                          },
                          icon: Icon(
                            _planStarted[plan.id] == true
                                ? Icons.chat
                                : Icons.play_arrow,
                            size: 18,
                          ),
                          label: Text(_planStarted[plan.id] == true
                              ? 'Ask Question'
                              : 'Start Plan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _planCompleted[plan.id] == true
                                ? Colors.green
                                : CommanColor.lightDarkPrimary(context),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),

                      // Share Button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _handleShare(plan),
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
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
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
    );
  }
}
