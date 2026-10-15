import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/screens/intro_subcribtion_screen.dart';
import 'package:biblebookapp/view/screens/multi_select_paywall.dart';
import 'package:biblebookapp/view/screens/yearly_trial_paywall.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Routes to the visible paywall UI based on [BibleInfo.paywallShows].
/// IAP / restore always run through [SubscriptionScreen] (invisible host when multi).
class PaywallNavigation {
  PaywallNavigation._();

  static bool get _useArProductIds => BibleInfo.isAutoRenewablePaywallMode;

  /// Paywall 1 and 2 use the auto-renewable plan IDs.
  /// AR 6M / classic 6M stay in constants for fallback/restore only.
  static String _sixMonthIdForVisiblePaywall(String sixMonthPlan) =>
      _useArProductIds
          ? BibleInfo.arOneMonthPlanid
          : BibleInfo.oneMonthPlanid;

  static String _oneYearIdForVisiblePaywall(String oneYearPlan) =>
      _useArProductIds ? BibleInfo.arOneYearPlanid : oneYearPlan;

  static Widget buildVisiblePaywall({
    required String sixMonthPlan,
    required String oneYearPlan,
    required String lifeTimePlan,
    required String checkad,
    bool fromHomeExitOffer = false,
  }) {
    final six = _sixMonthIdForVisiblePaywall(sixMonthPlan);
    final year = _oneYearIdForVisiblePaywall(oneYearPlan);
    if (BibleInfo.isProPaywall) {
      return YearlyTrialPaywall(
        sixMonthPlan: six,
        oneYearPlan: year,
        lifeTimePlan: lifeTimePlan,
        checkad: checkad,
      );
    }
    if (BibleInfo.paywallShows == 1) {
      return MultiSelectPaywall(
        sixMonthPlan: six,
        oneYearPlan: year,
        lifeTimePlan: lifeTimePlan,
        checkad: checkad,
      );
    }
    return SubscriptionScreen(
      sixMonthPlan: six,
      oneYearPlan: year,
      lifeTimePlan: lifeTimePlan,
      checkad: checkad,
      fromHomeExitOffer: fromHomeExitOffer,
    );
  }

  static Future<T?> openStacked<T>({
    required String sixMonthPlan,
    required String oneYearPlan,
    required String lifeTimePlan,
    required String checkad,
    bool fromHomeExitOffer = false,
  }) {
    return Get.to<T>(
      () => buildVisiblePaywall(
        sixMonthPlan: sixMonthPlan,
        oneYearPlan: oneYearPlan,
        lifeTimePlan: lifeTimePlan,
        checkad: checkad,
        fromHomeExitOffer: fromHomeExitOffer,
      ),
      transition: SubscriptionScreen.paywallRouteTransition,
      duration: SubscriptionScreen.paywallRouteDuration,
    ) ??
        Future<T?>.value(null);
  }
}
