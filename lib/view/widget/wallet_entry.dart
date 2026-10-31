import 'package:biblebookapp/services/wallet_service.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/screens/intro_subcribtion_screen.dart';
import 'package:biblebookapp/view/screens/paywall_navigation.dart';
import 'package:biblebookapp/view/screens/wallet/wallet_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Read-only wallet summary for the Wallet entry points (Menu, Settings,
/// My Account). Same sources as the Wallet screen.
class WalletSummary {
  const WalletSummary({
    required this.credits,
    required this.unlimited,
    required this.shortCost,
    required this.planLabel,
  });

  final int credits;

  /// AI Premium: chat / prayer don't use credits.
  final bool unlimited;
  final int shortCost;

  /// 'Free' | 'Premium' | 'Lifetime'
  final String planLabel;

  int get shortAnswers => shortCost > 0 ? credits ~/ shortCost : 0;

  /// e.g. "100 credits · ≈ 5 AI answers" or "Unlimited AI".
  String get menuSubtitle => unlimited
      ? 'Unlimited AI'
      : '$credits credits · ≈ $shortAnswers AI answers';

  static Future<WalletSummary> load() async {
    final credits = await WalletService.getCredits();
    final unlimited = await BibleInfo.shouldSkipChatPrayerCredits();
    final prefs = await SharedPreferences.getInstance();
    final plan =
        (prefs.getString('subscription_plan') ?? '').toLowerCase().trim();
    final active = await BibleInfo.hasActivePremiumPlan();
    final label = !active
        ? 'Free'
        : (plan == 'platinum' ? 'Lifetime' : 'Premium');
    return WalletSummary(
      credits: credits,
      unlimited: unlimited,
      shortCost: WalletService.getChatCostForLength('small'),
      planLabel: label,
    );
  }
}

/// Actions shared by the Wallet entry points. All open existing screens/flows.
class WalletEntry {
  WalletEntry._();

  static const String checkadId = 'wallet_entry';

  static Future<void> openWallet() async {
    await Get.to(() => const WalletScreen());
  }

  static Future<void> openPremium() async {
    final six = await SharPreferences.getString('sixMonthPlan') ??
        BibleInfo.sixMonthPlanid;
    final year = await SharPreferences.getString('oneYearPlan') ??
        BibleInfo.oneYearPlanid;
    final life = await SharPreferences.getString('lifeTimePlan') ??
        BibleInfo.lifeTimePlanid;
    await PaywallNavigation.openStacked(
      sixMonthPlan: six,
      oneYearPlan: year,
      lifeTimePlan: life,
      checkad: checkadId,
    );
  }

  /// Existing Restore flow (same invisible purchase screen the paywall uses).
  static Future<void> restore(BuildContext context) async {
    if (!await SubscriptionScreen.isDashboardIapEnabled()) return;
    final ar = BibleInfo.isAutoRenewablePaywallMode;
    final six = ar
        ? BibleInfo.arOneMonthPlanid
        : (await SharPreferences.getString('sixMonthPlan') ??
            BibleInfo.sixMonthPlanid);
    final year = ar
        ? BibleInfo.arOneYearPlanid
        : (await SharPreferences.getString('oneYearPlan') ??
            BibleInfo.oneYearPlanid);
    final life = await SharPreferences.getString('lifeTimePlan') ??
        BibleInfo.lifeTimePlanid;
    if (!context.mounted) return;
    await Navigator.of(context).push<bool>(
      PageRouteBuilder<bool>(
        opaque: false,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        pageBuilder: (ctx, _, __) => SubscriptionScreen(
          sixMonthPlan: six,
          oneYearPlan: year,
          lifeTimePlan: life,
          checkad: checkadId,
          invisiblePurchaseHost: true,
          autoStartRestore: true,
        ),
      ),
    );
  }
}
