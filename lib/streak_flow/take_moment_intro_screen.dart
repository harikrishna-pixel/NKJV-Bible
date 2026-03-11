import 'package:biblebookapp/streak_flow/take_moment_rest_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// "Take a Moment With God" intro - "Let's slow down and release your worries", Start button.
/// First screen of Find Peace flow.
class TakeMomentIntroScreen extends StatelessWidget {
  const TakeMomentIntroScreen({super.key});

  static const Color _brown = Color(0xFF3D2914);
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
                  _dot(active: true),
                  const SizedBox(width: 12),
                  _dot(active: false),
                  const SizedBox(width: 12),
                  _dot(active: false),
                ],
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Text(
                  'Take a Moment With God',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isTablet ? 28 : 24,
                    fontWeight: FontWeight.w600,
                    color: _brown,
                    fontFamily: 'Georgia',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Let\'s slow down and release your worries',
                style: TextStyle(
                  fontSize: isTablet ? 17 : 15,
                  color: _brown.withOpacity(0.9),
                  fontFamily: 'Georgia',
                ),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bullet('Breathe in God\'s peace'),
                    _bullet('Rest in His presence'),
                    _bullet('Release your worries to Him'),
                  ],
                ),
              ),
              const Spacer(),
              _parchmentButton(
                context,
                label: 'Start',
                onPressed: () => Get.to(() => const TakeMomentRestScreen()),
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
        color: active ? const Color(0xFFC9A227) : Colors.transparent,
        border: Border.all(
          color: active ? const Color(0xFFC9A227) : _brown.withOpacity(0.3),
          width: active ? 2 : 1.5,
        ),
        boxShadow: active ? [BoxShadow(color: const Color(0xFFC9A227).withOpacity(0.5), blurRadius: 8)] : null,
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _brown,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                height: 1.4,
                color: _brown,
                fontFamily: 'Georgia',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _parchmentButton(BuildContext context, {required String label, required VoidCallback onPressed}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF3D2914),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: _cream.withOpacity(0.6), width: 2),
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
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _cream,
                  fontFamily: 'Georgia',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
