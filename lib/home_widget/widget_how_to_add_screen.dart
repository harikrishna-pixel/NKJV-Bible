import 'package:biblebookapp/home_widget/widget_preview_gallery_screen.dart';
import 'package:biblebookapp/home_widget/widget_prompt_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// How-to add a Home Screen widget. Display-only; does not change
/// when prompts appear or any reading / streak / IAP logic.
class WidgetHowToAddScreen extends StatelessWidget {
  const WidgetHowToAddScreen({super.key, this.promptId});

  final WidgetPromptId? promptId;

  static const _ink = Color(0xFF3D2914);
  static const _muted = Color(0xFF6D5A45);
  static const _paper = Color(0xFFF5F0E6);
  static const _bar = Color(0xFF4A3424);

  static const _steps = [
    (
      'Go to Home Screen',
      'Touch and hold an empty area on your Home Screen.'
    ),
    (
      'Tap Edit',
      'Tap Edit at the top left, then choose "Add Widget".'
    ),
    (
      'Find Old Paper Bible',
      'Search for "Old Paper Bible" in the widget list.'
    ),
    (
      'Choose Your Widget',
      'Select your preferred widget and tap "Add Widget".'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _paper,
      appBar: AppBar(
        backgroundColor: _bar,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Widgets',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  'assets/reading_book.png',
                  width: 56,
                  height: 56,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.menu_book_rounded,
                    size: 48,
                    color: _bar,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Keep God's Word Close",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: _ink,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add a Bible widget to your Home Screen for daily inspiration at a glance.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.5,
                height: 1.4,
                color: _muted,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'HOW TO ADD',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: _ink,
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(_steps.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8D5B5),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFD4C0A0)),
                      ),
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: _ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _steps[i].$1,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _steps[i].$2,
                            style: const TextStyle(
                              fontSize: 13.5,
                              height: 1.35,
                              color: _muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            const Text(
              'WIDGET PREVIEW',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: _ink,
              ),
            ),
            const SizedBox(height: 12),
            _PreviewCard(promptId: promptId),
            const SizedBox(height: 10),
            const Text(
              "God's Word, right on your Home Screen.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: _muted,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Get.to(
                    () => WidgetPreviewGalleryScreen(promptId: promptId),
                    transition: Transition.cupertino,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _bar,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'View Available Widgets  >',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Get.back(),
              child: const Text(
                'Got It',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: _ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({this.promptId});

  final WidgetPromptId? promptId;

  @override
  Widget build(BuildContext context) {
    final assets = WidgetPromptService.previewAssetsFor(promptId);
    final hero = assets.isNotEmpty ? assets.first : null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFE6D6),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: hero == null
          ? const SizedBox(height: 80)
          : ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                hero,
                height: 120,
                width: double.infinity,
                fit: BoxFit.contain,
              ),
            ),
    );
  }
}
