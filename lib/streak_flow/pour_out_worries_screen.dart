import 'package:biblebookapp/streak_flow/take_moment_intro_screen.dart';
import 'package:biblebookapp/streak_flow/take_moment_rest_screen.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

/// "Pour Out Your Worries and Struggles to Find Peace" - text input, then "Give It To God" → Take a Moment flow.
/// Shown first when user taps Find Peace.
class PourOutWorriesScreen extends StatefulWidget {
  const PourOutWorriesScreen({super.key});

  @override
  State<PourOutWorriesScreen> createState() => _PourOutWorriesScreenState();
}

class _PourOutWorriesScreenState extends State<PourOutWorriesScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _hasText = false;

  static const Color _brown = Color(0xFF3D2914);
  static const Color _cream = Color(0xFFF5F0E6);
  static const Color _gold = Color(0xFFC9A227);

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() => _hasText = _controller.text.trim().isNotEmpty);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 450;
    final isDark = Provider.of<ThemeProvider>(context, listen: false).themeMode == ThemeMode.dark;
    final Color textColor = isDark ? Colors.white : _brown;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: TakeMomentRestScreen.peaceBackgroundStack(
          isDark: isDark,
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back_ios,
                          color: textColor, size: 24),
                      onPressed: () => Get.back(),
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final content = _buildMainContent(
                          context,
                          isTablet: isTablet,
                          isDark: isDark,
                          textColor: textColor,
                        );
                        if (!isTablet) {
                          return SingleChildScrollView(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 16),
                                content,
                                const SizedBox(height: 24),
                              ],
                            ),
                          );
                        }
                        return SingleChildScrollView(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 24),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                                minHeight: constraints.maxHeight),
                            child: Center(
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 520),
                                child: content,
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
        ),
      ),
    );
  }

  Widget _buildMainContent(
    BuildContext context, {
    required bool isTablet,
    required bool isDark,
    required Color textColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Give Your Worries to God',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isTablet ? 22 : 18,
            fontWeight: FontWeight.w600,
            color: textColor,
            fontFamily: 'Georgia',
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your words will be kept private',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isTablet ? 15 : 14,
            color: textColor.withOpacity(0.85),
            fontFamily: 'Georgia',
          ),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _controller,
          maxLines: 6,
          decoration: InputDecoration(
            hintText: 'Share what\'s burdening your heart...',
            hintStyle: TextStyle(
              color: textColor.withOpacity(0.5),
              fontFamily: 'Georgia',
              fontSize: 15,
            ),
            filled: true,
            fillColor: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.white.withOpacity(0.6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: textColor.withOpacity(0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: textColor.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: textColor.withOpacity(0.4), width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          style: TextStyle(
            fontSize: 15,
            color: textColor,
            fontFamily: 'Georgia',
          ),
        ),
        const SizedBox(height: 28),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isTablet ? 8 : 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _hasText
                  ? () {
                      Get.to(
                        () => TakeMomentIntroScreen(
                          worryText: _controller.text.trim(),
                        ),
                      );
                    }
                  : null,
              borderRadius: BorderRadius.circular(28),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _hasText
                      ? CommanColor.lightDarkPrimary(context).withOpacity(0.92)
                      : (isDark
                          ? Colors.white.withOpacity(0.12)
                          : _cream.withOpacity(0.9)),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: _hasText
                        ? _gold.withOpacity(0.6)
                        : textColor.withOpacity(0.2),
                    width: 2,
                  ),
                  boxShadow: [
                    const BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                    if (_hasText)
                      BoxShadow(
                        color: _gold.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 1,
                        offset: const Offset(0, 1),
                      ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Give It To God',
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.w600,
                      color: _hasText
                          ? Colors.white
                          : textColor.withOpacity(0.45),
                      fontFamily: 'Georgia',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}


