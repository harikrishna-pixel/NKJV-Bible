import 'package:flutter/material.dart';

/// Temporary Prayer Wall holding screen shown from every Prayer Wall entry point.
class PrayerWallMaintenanceScreen extends StatelessWidget {
  const PrayerWallMaintenanceScreen({super.key});

  static const Color _cream = Color(0xFFF8F4EE);
  static const Color _ink = Color(0xFF3D2914);
  static const Color _body = Color(0xFF5C4A3A);
  static const Color _muted = Color(0xFF7A6554);
  static const Color _gold = Color(0xFFB0894A);
  static const Color _divider = Color(0xFFD4C4A8);
  static const Color _button = Color(0xFF6B3E26);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final headlineSize = width < 360 ? 36.0 : 42.0;

    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 18, 28, 20),
          child: Column(
            children: [
              const Text(
                'Prayer Wall',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 72),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Text(
                        'Under\nMaintenance',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: headlineSize,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                          height: 1.12,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Container(
                        width: 72,
                        height: 1.5,
                        color: _divider,
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        "We're updating the Prayer Wall\nto bring you a better and more\nmeaningful experience.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          color: _body,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'It will be available again\nin about 2 days with our next update.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: _muted,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 36),
                      const Text(
                        'Thank you for your patience\nand continued support.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: _gold,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _button,
                    foregroundColor: _cream,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Got It',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
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
