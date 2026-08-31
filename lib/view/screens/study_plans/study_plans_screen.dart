// Using local study plan images from assets/study_plan_images
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/study_plans/data/study_plans_data.dart';
import 'package:biblebookapp/view/screens/study_plans/study_plan_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class StudyPlansScreen extends StatefulWidget {
  const StudyPlansScreen({super.key});

  @override
  State<StudyPlansScreen> createState() => _StudyPlansScreenState();
}

class _StudyPlansScreenState extends State<StudyPlansScreen> {
  final Map<String, String> _categoryImages = {};
  bool _isLoadingImages = false;

  @override
  void initState() {
    super.initState();
    _loadCategoryImages();
  }

  Future<void> _loadCategoryImages() async {
    // Replace network Unsplash images with bundled local assets.
    setState(() {
      _isLoadingImages = true;
    });

    final categories = StudyPlansData.getAllCategories();

    for (var category in categories) {
      try {
        final assetPath = _assetForCategory(category);
        if (mounted) {
          setState(() {
            _categoryImages[category] = assetPath;
          });
        }
      } catch (e) {
        debugPrint('Error assigning asset for $category: $e');
      }
    }

    setState(() {
      _isLoadingImages = false;
    });
  }

  String _assetForCategory(String category) {
    switch (category) {
      case 'Love':
        return 'assets/study_plan_images/Gemini_Generated_Image_uwge7ruwge7ruwge.png';
      case 'Joy':
        return 'assets/study_plan_images/Joy Scene.png';
      case 'Faith':
        return 'assets/study_plan_images/Faith Scene.png';
      case 'Peace':
        return 'assets/study_plan_images/Peace Symbol Integration.png';
      case 'Hope':
        return 'assets/study_plan_images/Hope and Love Scene.png';
      case 'Wisdom':
        return 'assets/study_plan_images/Peace and Wisdom Scene.png';
      case 'Courage':
        return 'assets/study_plan_images/Courage Scene.png';
      case 'Forgiveness':
        return 'assets/study_plan_images/Gemini_Generated_Image_5weyjf5weyjf5wey.png';
      case 'Healing':
        return 'assets/study_plan_images/Healing Scene.png';
      default:
        return 'assets/study_plan_images/Gemini_Generated_Image_5weyjf5weyjf5wey.png';
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Love':
        return Colors.pink.shade300;
      case 'Joy':
        return Colors.amber.shade300;
      case 'Faith':
        return Colors.blue.shade300;
      case 'Peace':
        return Colors.teal.shade300;
      case 'Hope':
        return Colors.purple.shade300;
      case 'Wisdom':
        return Colors.indigo.shade300;
      case 'Courage':
        return Colors.orange.shade300;
      case 'Forgiveness':
        return Colors.green.shade300;
      case 'Healing':
        return Colors.lightBlue.shade300;
      default:
        return Colors.grey.shade300;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Love':
        return Icons.favorite;
      case 'Joy':
        return Icons.celebration;
      case 'Faith':
        return Icons.church;
      case 'Peace':
        return Icons.spa;
      case 'Hope':
        return Icons.wb_sunny;
      case 'Wisdom':
        return Icons.psychology;
      case 'Courage':
        return Icons.shield;
      case 'Forgiveness':
        return Icons.handshake;
      case 'Healing':
        return Icons.healing;
      default:
        return Icons.book;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark;
    final categoriesWithCount = StudyPlansData.getCategoriesWithCount();
    final categories = categoriesWithCount.keys.toList()..sort();
    // Responsive adjustments: on wider screens (iPad) use a more relaxed
    // childAspectRatio so the card banner images have more vertical space
    // and are less likely to be visually cropped. This is a presentation
    // change only and doesn't modify any business logic or data.
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isTabletLayout = screenWidth >= 700;

    return Scaffold(
      backgroundColor: CommanColor.Blackwhite(context),
      appBar: AppBar(
        backgroundColor: CommanColor.lightDarkPrimary(context),
        title: Text(
          'Study Plans',
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Container(
            // ensure full-width on large screens (iPad) so no right-side gap appears
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  CommanColor.lightDarkPrimary(context),
                  CommanColor.lightDarkPrimary(context).withOpacity(0.8),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Grow Your Faith',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Choose a topic that speaks to your heart and begin your journey.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Categories Grid
          Expanded(
            child: _isLoadingImages && _categoryImages.isEmpty
                ? Center(
                    child: CircularProgressIndicator(
                      color: CommanColor.lightDarkPrimary(context),
                    ),
                  )
                : GridView.builder(
                    padding: EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      // Use a taller card on tablets so banner images show more
                      // of the image instead of aggressively cropping.
                      childAspectRatio: isTabletLayout ? 1.25 : 0.85,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final count = categoriesWithCount[category] ?? 0;
                      final imageUrl = _categoryImages[category] ?? '';

                      return _buildCategoryCard(
                        context,
                        category,
                        count,
                        imageUrl,
                        isDark,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    String category,
    int count,
    String imageUrl,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () {
        Get.to(
          () => StudyPlanDetailScreen(category: category),
          transition: Transition.cupertino,
          duration: Duration(milliseconds: 300),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Background Image
              Positioned.fill(
                child: imageUrl.isNotEmpty
                    ? (imageUrl.startsWith('assets/')
                        ? Image.asset(
                            imageUrl,
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: _getCategoryColor(category),
                              );
                            },
                          )
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: _getCategoryColor(category),
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
                                color: _getCategoryColor(category),
                              );
                            },
                          ))
                    : Container(
                        color: _getCategoryColor(category),
                      ),
              ),

              // Gradient Overlay
              Positioned.fill(
                child: Container(
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
              ),

              // Content
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getCategoryIcon(category),
                        color: _getCategoryColor(category),
                        size: 28,
                      ),
                    ),

                    Spacer(),

                    // Category Name
                    Text(
                      category,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),

                    // Plan Count
                    Text(
                      '$count ${count == 1 ? 'Plan' : 'Plans'}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
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
