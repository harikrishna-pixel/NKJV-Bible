import 'package:biblebookapp/streak_flow/take_moment_intro_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// "Pour Out Your Worries and Struggles to Find Peace" - text input, then "Give It To God" → Take a Moment flow.
/// Shown first when user taps Find Peace.
class PourOutWorriesScreen extends StatefulWidget {
  const PourOutWorriesScreen({super.key});

  @override
  State<PourOutWorriesScreen> createState() => _PourOutWorriesScreenState();
}

class _PourOutWorriesScreenState extends State<PourOutWorriesScreen> {
  final TextEditingController _controller = TextEditingController();

  static const Color _brown = Color(0xFF3D2914);
  static const Color _cream = Color(0xFFF5F0E6);
  static const Color _gold = Color(0xFFC9A227);

  @override
  void dispose() {
    _controller.dispose();
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
              Color(0xFFEDE6D8),
              Color(0xFFE5DCC8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: _brown, size: 24),
                  onPressed: () => Get.back(),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Pour Out Your Worries and Struggles to Find Peace',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isTablet ? 22 : 18,
                    fontWeight: FontWeight.w600,
                    color: _brown,
                    fontFamily: 'Georgia',
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your words will be kept private',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isTablet ? 15 : 14,
                  color: _brown.withOpacity(0.85),
                  fontFamily: 'Georgia',
                ),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TextField(
                  controller: _controller,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText: 'Share what\'s burdening your heart...',
                    hintStyle: TextStyle(
                      color: _brown.withOpacity(0.5),
                      fontFamily: 'Georgia',
                      fontSize: 15,
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _brown.withOpacity(0.2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _brown.withOpacity(0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _brown.withOpacity(0.4), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  style: TextStyle(
                    fontSize: 15,
                    color: _brown,
                    fontFamily: 'Georgia',
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Get.to(() => const TakeMomentIntroScreen());
                    },
                    borderRadius: BorderRadius.circular(28),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3D2914),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: _gold.withOpacity(0.6), width: 2),
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
                          'Give It To God',
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
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
