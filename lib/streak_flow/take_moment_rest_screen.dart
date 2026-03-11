import 'dart:async';
import 'package:biblebookapp/streak_flow/take_moment_released_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// "Rest in His presence" - breathing exercise with "Hold" countdown (30 sec).
/// Second screen of Find Peace flow.
class TakeMomentRestScreen extends StatefulWidget {
  const TakeMomentRestScreen({super.key});

  @override
  State<TakeMomentRestScreen> createState() => _TakeMomentRestScreenState();
}

class _TakeMomentRestScreenState extends State<TakeMomentRestScreen> {
  int _count = 30;
  Timer? _timer;

  static const Color _brown = Color(0xFF3D2914);
  static const Color _cream = Color(0xFFF5F0E6);

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_count > 0) {
          _count--;
        } else {
          _timer?.cancel();
          Get.off(() => const TakeMomentReleasedScreen());
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

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
                  _dot(active: true),
                  const SizedBox(width: 12),
                  _dot(active: false),
                ],
              ),
              const SizedBox(height: 48),
              Text(
                'Rest in',
                style: TextStyle(
                  fontSize: isTablet ? 28 : 24,
                  fontWeight: FontWeight.w500,
                  color: _brown,
                  fontFamily: 'Georgia',
                ),
              ),
              Text(
                'His presence',
                style: TextStyle(
                  fontSize: isTablet ? 32 : 28,
                  fontWeight: FontWeight.w700,
                  color: _brown,
                  fontFamily: 'Georgia',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Hold your breath and be still',
                style: TextStyle(
                  fontSize: isTablet ? 17 : 15,
                  color: _brown.withOpacity(0.9),
                  fontFamily: 'Georgia',
                ),
              ),
              const SizedBox(height: 40),
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _cream.withOpacity(0.8), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: _brown.withOpacity(0.1),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$_count',
                        style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.w300,
                          color: _brown,
                          fontFamily: 'Georgia',
                        ),
                      ),
                      Text(
                        'Hold',
                        style: TextStyle(
                          fontSize: 18,
                          color: _brown.withOpacity(0.85),
                          fontFamily: 'Georgia',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
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
}
