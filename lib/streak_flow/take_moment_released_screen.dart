import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// "You have released your worries to God." + verse 1 Peter 5:7, "Continue Your Journey".
/// Final screen of Find Peace flow; pops back to Daily Journey.
class TakeMomentReleasedScreen extends StatelessWidget {
  const TakeMomentReleasedScreen({super.key});

  static const Color _brown = Color(0xFF3D2914);
  static const Color _gold = Color(0xFFC9A227);
  static const Color _cream = Color(0xFFF5F0E6);

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 450;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF5F0E6),
              Color(0xFFE8DED0),
              Color(0xFFDDD0C0),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _dot(active: false),
                  const SizedBox(width: 12),
                  _dot(active: false),
                  const SizedBox(width: 12),
                  _dot(active: true),
                ],
              ),
              const SizedBox(height: 48),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Text(
                  'You have released your worries to God.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isTablet ? 24 : 20,
                    fontWeight: FontWeight.w600,
                    color: _brown,
                    fontFamily: 'Georgia',
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  '"Cast all your anxiety on Him because He cares for you."',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontStyle: FontStyle.italic,
                    color: _brown,
                    fontFamily: 'Georgia',
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '— 1 Peter 5:7',
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  color: _brown.withOpacity(0.85),
                  fontFamily: 'Georgia',
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Get.back();
                        Get.back();
                        Get.back(); // pop Released, Intro, PourOut -> back to Daily Journey
                      },
                      borderRadius: BorderRadius.circular(28),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B7355),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: _gold, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Continue Your Journey',
                            style: TextStyle(
                              fontSize: isTablet ? 18 : 16,
                              fontWeight: FontWeight.w600,
                              color: _cream,
                              fontFamily: 'Georgia',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot({required bool active}) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? _gold : Colors.transparent,
        border: Border.all(
          color: active ? _gold : _brown.withOpacity(0.3),
          width: active ? 2 : 1.5,
        ),
        boxShadow: active ? [BoxShadow(color: _gold.withOpacity(0.5), blurRadius: 8)] : null,
      ),
    );
  }
}
