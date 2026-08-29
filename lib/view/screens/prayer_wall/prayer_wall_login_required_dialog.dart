import 'package:flutter/material.dart';

/// Login prompt shown when a guest tries Like, Comment, or Post on Prayer Wall.
class PrayerWallLoginRequiredDialog {
  PrayerWallLoginRequiredDialog._();

  static const Color _cream = Color(0xFFFFF9F3);
  static const Color _ink = Color(0xFF4B3423);
  static const Color _muted = Color(0xFF6B4E3D);
  static const Color _brown = Color(0xFF5C4033);
  static const Color _peach = Color(0xFFF3E4D8);

  /// Returns `true` if the user tapped Log In; otherwise `false`/`null`.
  static Future<bool?> show(
    BuildContext context, {
    String message =
        'Please log in to support this prayer request and leave a comment.',
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Material(
          color: _cream,
          borderRadius: BorderRadius.circular(22),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _LockHero(),
                    const SizedBox(height: 18),
                    const Text(
                      'Login Required',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                        color: _muted,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      height: 1,
                      color: _brown.withValues(alpha: 0.18),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _brown,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.eco_rounded, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Log In',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _brown,
                          side: BorderSide(
                            color: _brown.withValues(alpha: 0.55),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => Navigator.of(ctx).pop(false),
                  icon: Icon(
                    Icons.close,
                    color: _muted.withValues(alpha: 0.85),
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

class _LockHero extends StatelessWidget {
  const _LockHero();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: PrayerWallLoginRequiredDialog._peach,
              shape: BoxShape.circle,
            ),
          ),
          const Icon(
            Icons.lock_rounded,
            size: 34,
            color: PrayerWallLoginRequiredDialog._brown,
          ),
          const Positioned(
            top: 6,
            left: 10,
            child: Icon(Icons.auto_awesome, size: 12, color: Color(0xFFE0A84E)),
          ),
          const Positioned(
            top: 10,
            right: 8,
            child: Icon(Icons.auto_awesome, size: 10, color: Color(0xFFE0A84E)),
          ),
          const Positioned(
            bottom: 10,
            left: 8,
            child: Icon(Icons.auto_awesome, size: 9, color: Color(0xFFE0A84E)),
          ),
          const Positioned(
            bottom: 14,
            right: 6,
            child: Icon(Icons.auto_awesome, size: 11, color: Color(0xFFE0A84E)),
          ),
        ],
      ),
    );
  }
}
