import 'package:biblebookapp/core/notifiers/download.notifier.dart';
import 'package:biblebookapp/view/screens/milestone/milestone_journey_dialog.dart';
import 'package:biblebookapp/view/screens/milestone/milestone_lifetime_iap_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Counts successful AI replies and shows milestone → Lifetime IAP once each
/// (chat: 50, prayer guidance: 10). Only when user is not subscribed.
/// Triggers only immediately after the Nth success response — not on app resume.
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
    return ['platinum', 'gold', 'silver'].contains(plan.toLowerCase());
  }

  /// Call after a successful scripture chat AI response (not errors).
  static Future<void> onChatAiResponseSuccess(BuildContext context) async {
    if (!context.mounted) return;
    if (await _isSubscribed(context)) return;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kChatFlowDone) == true) return;

    final next = (prefs.getInt(_kChatCount) ?? 0) + 1;
    await prefs.setInt(_kChatCount, next);

    if (next != chatThreshold) return;

    if (!context.mounted) return;
    if (await _isSubscribed(context)) {
      await prefs.setBool(_kChatFlowDone, true);
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!context.mounted) return;
    if (await _isSubscribed(context)) {
      await prefs.setBool(_kChatFlowDone, true);
      return;
    }

    if (!context.mounted) return;
    await MilestoneJourneyDialog.showScriptureMilestone(context);
    if (!context.mounted) return;

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const MilestoneLifetimeIapScreen(
          kind: MilestoneLifetimeKind.scripture,
        ),
      ),
    );

    await prefs.setBool(_kChatFlowDone, true);
  }

  /// Call after a successful prayer guidance AI response (not errors).
  static Future<void> onPrayerGuidanceAiResponseSuccess(BuildContext context) async {
    if (!context.mounted) return;
    if (await _isSubscribed(context)) return;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kPrayerFlowDone) == true) return;

    final next = (prefs.getInt(_kPrayerCount) ?? 0) + 1;
    await prefs.setInt(_kPrayerCount, next);

    if (next != prayerThreshold) return;

    if (!context.mounted) return;
    if (await _isSubscribed(context)) {
      await prefs.setBool(_kPrayerFlowDone, true);
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!context.mounted) return;
    if (await _isSubscribed(context)) {
      await prefs.setBool(_kPrayerFlowDone, true);
      return;
    }

    if (!context.mounted) return;
    await MilestoneJourneyDialog.showPrayerMilestone(context);
    if (!context.mounted) return;

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const MilestoneLifetimeIapScreen(
          kind: MilestoneLifetimeKind.prayer,
        ),
      ),
    );

    await prefs.setBool(_kPrayerFlowDone, true);
  }
}
