import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/screens/intro_subcribtion_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum MilestoneLifetimeKind { scripture, prayer }

/// Themed Lifetime offer screen after milestone (chat vs prayer copy).
/// Unlock runs IAP via a transparent [SubscriptionScreen] host (store sheet only).
class MilestoneLifetimeIapScreen extends StatefulWidget {
  const MilestoneLifetimeIapScreen({super.key, required this.kind});

  final MilestoneLifetimeKind kind;

  @override
  State<MilestoneLifetimeIapScreen> createState() =>
      _MilestoneLifetimeIapScreenState();
}

class _MilestoneLifetimeIapScreenState extends State<MilestoneLifetimeIapScreen> {
  Future<void> _openInvisibleLifetimePurchase(BuildContext context) async {
    final sixMonth = await SharPreferences.getString('sixMonthPlan') ??
        BibleInfo.sixMonthPlanid;
    final oneYear =
        await SharPreferences.getString('oneYearPlan') ?? BibleInfo.oneYearPlanid;
    final lifeTime =
        await SharPreferences.getString('lifeTimePlan') ?? BibleInfo.lifeTimePlanid;

    if (!context.mounted) return;

    final checkad = widget.kind == MilestoneLifetimeKind.scripture
        ? 'milestone_scripture_lifetime'
        : 'milestone_prayer_lifetime';

    final ok = await Navigator.of(context).push<bool>(
      PageRouteBuilder<bool>(
        opaque: false,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        pageBuilder: (ctx, _, __) => SubscriptionScreen(
          sixMonthPlan: sixMonth,
          oneYearPlan: oneYear,
          lifeTimePlan: lifeTime,
          checkad: checkad,
          initialSelectedPlanIndex: 2,
          autoStartSelectedPlanPurchase: true,
          invisiblePurchaseHost: true,
        ),
      ),
    );

    // If purchase succeeded, close this offer screen and return to previous screen.
    if (ok == true && context.mounted) {
      Navigator.of(context).maybePop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final brown = const Color(0xFF5C4033);
    final cream = isDark ? CommanColor.darkPrimaryColor : const Color(0xFFF5F0E6);

    final isScripture = widget.kind == MilestoneLifetimeKind.scripture;
    final title = isScripture
        ? 'Deepen Your Journey in Scripture'
        : 'Strengthen Your Prayer Life';
    final bonus = isScripture
        ? '🎁 Special Offer: 1000 Bonus Chat Credits'
        : '🎁 Special Offer: 1000 Bonus Prayer Credits';
    final features = isScripture
        ? const [
            'Ask Questions About Any Scripture',
            'Instant Verse Explanations',
            'AI-Assisted Bible Study',
            'Deeper Spiritual Understanding',
          ]
        : const [
            'Generate Personalized Prayers',
            'Pray for Any Situation',
            'AI-Assisted Prayer Guidance',
            'Strengthen Your Faith Daily',
          ];

    final subtitleStyle = TextStyle(
      fontSize: 14,
      color: isDark ? Colors.white70 : Colors.black87,
      overflow: TextOverflow.ellipsis,
    );

    final bonusColor = isDark ? const Color(0xFFB7F3C2) : const Color(0xFF2E7D32);
    final offColor = isDark ? const Color(0xFFFFB4AB) : Colors.red.shade700;

    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        top: true,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : brown,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                      children: [
                        TextSpan(
                            text: isScripture
                                ? 'Continue exploring '
                                : 'Continue seeking '),
                        TextSpan(
                          text: isScripture ? 'God\'s Word' : 'God\'s',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(
                          text: isScripture
                              ? ' with deeper understanding and spiritual insight with AI-assisted study.'
                              : ' guidance through heartfelt prayers with AI-assisted support.',
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    bonus,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: bonusColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.topCenter,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 14),
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 18),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: brown.withValues(alpha: 0.35),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'LIFETIME ACCESS',
                              style: TextStyle(
                                fontFamily: 'Georgia',
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : brown,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'One Time Payment',
                              textAlign: TextAlign.center,
                              style: subtitleStyle,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '\$99.99',
                                  style: TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    fontSize: 14,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '\$19.99',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white : brown,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '- 80% OFF',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: offColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            ...features.map(
                              (f) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.check_circle,
                                        size: 20, color: brown),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        f,
                                        style: TextStyle(
                                          fontSize: 13,
                                          height: 1.35,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100
                                  .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.amber.shade700
                                      .withValues(alpha: 0.5)),
                            ),
                            child: Text(
                              'Limited-Time Blessing',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: brown,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  ElevatedButton(
                    onPressed: () => _openInvisibleLifetimePurchase(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brown,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text(
                      'Unlock Lifetime Access',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Bonus credits are added to wallet after purchase',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: Icon(
                  Icons.close,
                  color: isDark ? Colors.white70 : brown,
                ),
                style: IconButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  padding: const EdgeInsets.all(10),
                ),
                onPressed: () => Navigator.of(context).maybePop(),
                tooltip: 'Close',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
