import 'package:biblebookapp/core/notifiers/download.notifier.dart';
import 'package:biblebookapp/view/screens/intro_subcribtion_screen.dart';
import 'package:biblebookapp/view/screens/milestone/milestone_journey_dialog.dart';
import 'package:biblebookapp/view/screens/milestone/milestone_lifetime_iap_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Counts successful AI replies and shows milestone → 1-year IAP once each
/// (chat: 50, prayer guidance: 10). Only when user is not subscribed.
/// Triggers only immediately after a success response — not on app resume.
class MilestoneLifetimePaywallCoordinator {
  MilestoneLifetimePaywallCoordinator._();

  static const _kChatCount = 'milestone_chat_ai_success_count_v1';
  static const _kPrayerCount = 'milestone_prayer_ai_success_count_v1';
  static const _kChatFlowDone = 'milestone_chat_50_flow_done_v1';
  static const _kPrayerFlowDone = 'milestone_prayer_10_flow_done_v1';

  static const int chatThreshold = 50;
  static const int prayerThreshold = 10;

  static Future<bool> _isSubscribed(BuildContext context) async {
    final download = Provider.of<DownloadProvider>(context, listen: false);
    final plan = await download.getSubscriptionPlan();
    if (plan == null || plan.isEmpty) return false;
    return ['platinum', 'gold', 'silver', 'twoyear'].contains(plan.toLowerCase());
  }

  /// Bump success count up to [threshold]. Returns current count after update.
  /// Caps at threshold so a missed show (unmount / IAP flicker) can still
  /// open the offer on a later success — does not change once-done behavior.
  static Future<int> _bumpCountTowardThreshold(
    SharedPreferences prefs, {
    required String countKey,
    required int threshold,
  }) async {
    final current = prefs.getInt(countKey) ?? 0;
    if (current >= threshold) return current;
    final next = current + 1;
    await prefs.setInt(countKey, next);
    return next;
  }

  /// Shared gates after threshold: IAP on, not subscribed, then [showFlow].
  /// [showFlow] must set [flowDoneKey] only after the offer was presented.
  static Future<void> _runMilestoneOfferIfEligible(
    BuildContext context, {
    required SharedPreferences prefs,
    required String flowDoneKey,
    required Future<void> Function(BuildContext context) showFlow,
  }) async {
    if (!context.mounted) return;
    if (!await SubscriptionScreen.isDashboardIapEnabled()) return;
    if (await _isSubscribed(context)) {
      await prefs.setBool(flowDoneKey, true);
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!context.mounted) return;
    if (!await SubscriptionScreen.isDashboardIapEnabled()) return;
    if (await _isSubscribed(context)) {
      await prefs.setBool(flowDoneKey, true);
      return;
    }

    if (!context.mounted) return;
    await showFlow(context);
  }

  /// Call after a successful scripture chat AI response (not errors).
  static Future<void> onChatAiResponseSuccess(BuildContext context) async {
    if (!context.mounted) return;
    // Same dashboard IAP gate as Home paywall — skip milestone when IAP is off.
    if (!await SubscriptionScreen.isDashboardIapEnabled()) return;
    if (await _isSubscribed(context)) return;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kChatFlowDone) == true) return;

    final count = await _bumpCountTowardThreshold(
      prefs,
      countKey: _kChatCount,
      threshold: chatThreshold,
    );
    if (count < chatThreshold) return;

    await _runMilestoneOfferIfEligible(
      context,
      prefs: prefs,
      flowDoneKey: _kChatFlowDone,
      showFlow: (ctx) async {
        await MilestoneJourneyDialog.showScriptureMilestone(ctx);
        if (!ctx.mounted) return;
        await Navigator.of(ctx).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => const MilestoneLifetimeIapScreen(
              kind: MilestoneLifetimeKind.scripture,
            ),
          ),
        );
        await prefs.setBool(_kChatFlowDone, true);
      },
    );
  }

  /// Call after a successful prayer guidance AI response (not errors).
  static Future<void> onPrayerGuidanceAiResponseSuccess(BuildContext context) async {
    if (!context.mounted) return;
    // Same dashboard IAP gate as Home paywall — skip milestone when IAP is off.
    if (!await SubscriptionScreen.isDashboardIapEnabled()) return;
    if (await _isSubscribed(context)) return;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kPrayerFlowDone) == true) return;

    final count = await _bumpCountTowardThreshold(
      prefs,
      countKey: _kPrayerCount,
      threshold: prayerThreshold,
    );
    if (count < prayerThreshold) return;

    await _runMilestoneOfferIfEligible(
      context,
      prefs: prefs,
      flowDoneKey: _kPrayerFlowDone,
      showFlow: (ctx) async {
        await MilestoneJourneyDialog.showPrayerMilestone(ctx);
        if (!ctx.mounted) return;
        await Navigator.of(ctx).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => const MilestoneLifetimeIapScreen(
              kind: MilestoneLifetimeKind.prayer,
            ),
          ),
        );
        await prefs.setBool(_kPrayerFlowDone, true);
      },
    );
  }
}
