import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_guidelines_dialog.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_local_store.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

/// One-time "Before You Join the Prayer Wall" bottom sheet — UI only.
class PrayerWallJoinSheet {
  PrayerWallJoinSheet._();

  static const Color _cream = Color(0xFFFFFBF5);
  static const Color _ink = Color(0xFF1A1A1A);
  static const Color _muted = Color(0xFF3D3D3D);
  static const Color _brown = Color(0xFF5C4033);
  static const Color _link = Color(0xFF5C4033);
  static const Color _bannerBg = Color(0xFFFDF9F3);
  static const Color _successGreen = Color(0xFF2E7D32);

  static const _iconAsset = 'assets/prayer_wall/prayer_wall_join_icon.png';
  static const _successAsset = 'assets/prayer_wall/prayer_wall_join_success.png';

  /// Returns `true` when the user may use the post form (already accepted or
  /// just agreed). Returns `false` when the user cancelled.
  static Future<bool> ensureAccepted(BuildContext context) async {
    if (await PrayerWallLocalStore.hasAcceptedPrayerWallJoinTerms()) {
      return true;
    }
    final agreed = await _showJoinSheet(context);
    if (agreed != true) return false;
    await PrayerWallLocalStore.markPrayerWallJoinTermsAccepted();
    return true;
  }

  static Future<bool?> _showJoinSheet(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _JoinSheetBody(),
    );
  }

  /// Top confirmation banner after first-time agreement.
  static void showSuccessBanner(BuildContext context) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) {
        final top = MediaQuery.paddingOf(ctx).top + 10;
        return Positioned(
          top: top,
          left: 14,
          right: 14,
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              builder: (_, t, child) => Transform.translate(
                offset: Offset(0, -18 * (1 - t)),
                child: Opacity(opacity: t, child: child),
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                decoration: BoxDecoration(
                  color: _bannerBg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: _successGreen,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Thanks! You're all set.",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _ink,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'You can now post your prayers anytime.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.3,
                              color: _muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.asset(
                        _successAsset,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox(
                          width: 56,
                          height: 56,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(entry);
    Future.delayed(const Duration(milliseconds: 3200), () {
      if (entry.mounted) entry.remove();
    });
  }
}

class _JoinSheetBody extends StatefulWidget {
  const _JoinSheetBody();

  @override
  State<_JoinSheetBody> createState() => _JoinSheetBodyState();
}

class _JoinSheetBodyState extends State<_JoinSheetBody> {
  bool _agreed = false;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      decoration: const BoxDecoration(
        color: PrayerWallJoinSheet._cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: EdgeInsets.fromLTRB(26, 14, 26, 22 + bottom),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 22),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(
              width: 88,
              height: 88,
              child: Image.asset(
                PrayerWallJoinSheet._iconAsset,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.article_outlined,
                  size: 64,
                  color: PrayerWallJoinSheet._brown,
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Before You Join the Prayer Wall',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: PrayerWallJoinSheet._ink,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 18),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Prayer Wall is a supportive faith community where people pray for one another.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: PrayerWallJoinSheet._muted,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Please keep prayer requests respectful, appropriate, and free from abusive or harmful content.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: PrayerWallJoinSheet._muted,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 26,
                  height: 26,
                  child: Checkbox(
                    value: _agreed,
                    activeColor: PrayerWallJoinSheet._brown,
                    side: const BorderSide(
                      color: PrayerWallJoinSheet._brown,
                      width: 1.5,
                    ),
                    onChanged: (v) => setState(() => _agreed = v ?? false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: _agreementText(context)),
              ],
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _agreed
                    ? () => Navigator.of(context).pop(true)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: PrayerWallJoinSheet._brown,
                  disabledBackgroundColor:
                      PrayerWallJoinSheet._brown.withValues(alpha: 0.45),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white70,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Agree & Continue',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: PrayerWallJoinSheet._ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _agreementText(BuildContext context) {
    const base = TextStyle(
      fontSize: 14.5,
      height: 1.4,
      color: PrayerWallJoinSheet._muted,
    );
    const link = TextStyle(
      fontSize: 14.5,
      height: 1.4,
      color: PrayerWallJoinSheet._link,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: PrayerWallJoinSheet._link,
    );

    return Text.rich(
      TextSpan(
        style: base,
        children: [
          const TextSpan(text: 'I agree to the '),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: () => PrayerWallGuidelinesDialog.show(context),
              child: const Text('Community Guidelines', style: link),
            ),
          ),
          const TextSpan(text: ' and '),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: () => launchUrlString(BibleInfo.termsandConditionURL),
              child: const Text('Terms of Use', style: link),
            ),
          ),
          const TextSpan(text: '.'),
        ],
      ),
    );
  }
}
