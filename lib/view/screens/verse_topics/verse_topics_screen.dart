import 'dart:async';

import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/verse_topics/verse_topic_detail_screen.dart';
import 'package:biblebookapp/view/screens/verse_topics/verse_topics_data.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class VerseTopicsScreen extends StatefulWidget {
  const VerseTopicsScreen({super.key});

  @override
  State<VerseTopicsScreen> createState() => _VerseTopicsScreenState();
}

class _VerseTopicsScreenState extends State<VerseTopicsScreen> {
  static const Color _ink = Color(0xFF3D2914);

  List<String> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final cached = VerseTopicsData.cachedCategories;
    if (cached != null) {
      _categories = cached;
      _loading = false;
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await VerseTopicsData.loadCategories();
    if (!mounted) return;
    setState(() {
      _categories = categories;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 450;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final usesLightCustom =
        themeProvider.currentCustomTheme == AppCustomTheme.white ||
            themeProvider.currentCustomTheme == AppCustomTheme.lightbrown;
    final isDark =
        themeProvider.themeMode == ThemeMode.dark && !usesLightCustom;
    // Match dark theme during Read→Home pops so cream scaffold never flashes.
    final scaffoldBg =
        isDark ? CommanColor.darkPrimaryColor : const Color(0xFFF5F0E6);
    final titleColor = isDark ? Colors.white : _ink;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (!isDark)
            Image.asset(
              VerseTopicsData.backgroundAsset,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              gaplessPlayback: true,
            )
          else
            ColoredBox(color: scaffoldBg),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: Icon(Icons.arrow_back_ios, color: titleColor),
                      ),
                      Expanded(
                        child: Text(
                          'Topics',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: isWide ? 24 : 20,
                            fontWeight: FontWeight.w700,
                            color: titleColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _loading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: titleColor,
                          ),
                        )
                      : _categories.isEmpty
                          ? Center(
                              child: Text(
                                'No topics available yet.',
                                style: TextStyle(
                                  fontFamily: 'Georgia',
                                  fontSize: isWide ? 18 : 16,
                                  color: titleColor.withValues(alpha: 0.8),
                                ),
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: isWide ? 2.6 : 2.35,
                              ),
                              itemCount: _categories.length,
                              itemBuilder: (context, index) {
                                final category = _categories[index];
                                return _TopicCard(
                                  category: category,
                                  onTap: () {
                                    Get.to(
                                      () => VerseTopicDetailScreen(
                                        categoryName: category,
                                      ),
                                      transition: Transition.cupertino,
                                    );
                                  },
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({
    required this.category,
    required this.onTap,
  });

  final String category;
  final VoidCallback onTap;

  static const Color _ink = Color(0xFF3D2914);
  static const Color _card = Color(0xFFF8F4EB);
  static const Color _iconCircle = Color(0xFFE8DCC8);

  @override
  Widget build(BuildContext context) {
    final iconPath = VerseTopicsData.iconPathForCategory(category);
    final isDark =
        Provider.of<ThemeProvider>(context, listen: false).themeMode ==
            ThemeMode.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? _ink.withValues(alpha: 0.45)
                  : _ink.withValues(alpha: 0.12),
              width: isDark ? 1.3 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _ink.withValues(alpha: isDark ? 0.1 : 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: _iconCircle,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(7),
                    child: Image.asset(
                      iconPath,
                      fit: BoxFit.contain,
                      color: _ink,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.auto_stories_outlined,
                        size: 18,
                        color: _ink.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    category,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _ink,
                      height: 1.2,
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
