import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/screens/intro_subcribtion_screen.dart';
import 'package:biblebookapp/view/screens/multi_select_paywall.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Routes to the visible paywall UI based on [BibleInfo.paywallShows].
/// IAP / restore always run through [SubscriptionScreen] (invisible host when multi).
class PaywallNavigation {
  PaywallNavigation._();

  static bool get _useMultiPaywall => BibleInfo.isAutoRenewablePaywallMode;

  /// Paywall 2 uses AR 6M/1Y IDs; Paywall 1 keeps the IDs passed in.
  static String _sixMonthIdForVisiblePaywall(String sixMonthPlan) =>
      _useMultiPaywall ? BibleInfo.arSixMonthPlanid : sixMonthPlan;

  static String _oneYearIdForVisiblePaywall(String oneYearPlan) =>
      _useMultiPaywall ? BibleInfo.arOneYearPlanid : oneYearPlan;

  static Widget buildVisiblePaywall({
    required String sixMonthPlan,
    required String oneYearPlan,
    required String lifeTimePlan,
    required String checkad,
    bool fromHomeExitOffer = false,
  }) {
    final six = _sixMonthIdForVisiblePaywall(sixMonthPlan);
    final year = _oneYearIdForVisiblePaywall(oneYearPlan);
    if (_useMultiPaywall) {
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
