import 'dart:io';

import 'package:biblebookapp/controller/dashboard_controller.dart';
import 'package:biblebookapp/core/notifiers/download.notifier.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Additive: home/drawer hook for premium plan labels.
/// Does **not** auto-apply Keychain/last-IAP memory as a live plan.
/// Plans are set only by Buy success or explicit Restore.
/// Clears orphan `silver`/`gold`/`twoyear` when premium expiry is inactive.
class PremiumEntitlementLabelSync {
  PremiumEntitlementLabelSync._();

  static const MethodChannel _iapMemoryChannel =
      MethodChannel('com.biblebookapp/iap_memory');
  static const String _lastIapProductPrefKey = 'last_iap_product_id';

  static const bool _qaModeFlag = bool.fromEnvironment('QA_MODE');
  static bool? _qaBuildCache;

  /// QA/TestFlight/sandbox build (or `--dart-define=QA_MODE=true`).
  /// Always false for App Store builds. Used only to skip the local
  /// "already owned" memory so QA can retest purchase after clearing Apple history.
  static Future<bool> isQaBuild() async {
    if (_qaModeFlag) return true;
    final cached = _qaBuildCache;
    if (cached != null) return cached;
    var qa = false;
    if (Platform.isIOS) {
      try {
        qa = await _iapMemoryChannel.invokeMethod<bool>('isSandboxBuild') ??
            false;
      } catch (_) {
        qa = false;
      }
    }
    _qaBuildCache = qa;
    return qa;
  }

  static Future<String?> readLastProductId() async {
    final local = await SharPreferences.getString(_lastIapProductPrefKey);
    if (local != null && local.trim().isNotEmpty) return local.trim();
    if (!Platform.isIOS) return null;
    try {
      final remote =
          await _iapMemoryChannel.invokeMethod<String>('getLastIapProduct');
      if (remote != null && remote.trim().isNotEmpty) {
        await SharPreferences.setString(
          _lastIapProductPrefKey,
          remote.trim(),
        );
        return remote.trim();
      }
    } catch (e) {
      debugPrint('PremiumEntitlementLabelSync: keychain read failed: $e');
    }
    return null;
  }

  /// QA only: clear local premium / last-buy memory so buy can be retested
  /// after Store purchase history is cleared. Does not change StoreKit.
  static Future<void> clearLocalEntitlementForQa({
    DownloadProvider? download,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('subscription_plan', '');
    await prefs.remove('isRewardAdViewTime');
    await prefs.remove(_lastIapProductPrefKey);
    await prefs.remove('last_iap_expires_at');
    await prefs.setBool(BibleInfo.aiPremiumCreditSkipGrantedKey, false);
    await prefs.setBool('ad_enabled', true);
    await prefs.setString('premiumalrt', '1');
    await SharPreferences.setBoolean(SharPreferences.isAdsEnabled, true);
    await SharPreferences.setString(SharPreferences.isRewardAdViewTime, '');
    await SharPreferences.setBoolean('startpurches', false);
    await SharPreferences.setBoolean('restorepurches', false);

    if (Platform.isIOS) {
      try {
        await _iapMemoryChannel.invokeMethod('clearLastIapProduct');
      } catch (e) {
        debugPrint(
          'PremiumEntitlementLabelSync: keychain clear failed: $e',
        );
      }
    }

    if (download != null) {
      await download.setSubscriptionPlan('');
    }

    if (Get.isRegistered<DashBoardController>()) {
      final c = Get.find<DashBoardController>();
      c.adFree.value = false;
      c.RewardAdExpireDate.value = '';
      c.isGetRewardAd.value = false;
      c.adsDisplayTim.value = true;
    }

    debugPrint('PremiumEntitlementLabelSync: QA local entitlement cleared');
  }

  /// One label for Restore, the active-plan box, and Subscription Info.
  /// `month`, `sixmonth`, `year`, `twoyear`, `lifetime`, or null.
  static String? periodKind({
    String? plan,
    String? productId,
    required int daysRemaining,
  }) {
    final id = (productId ?? '').toLowerCase();
    final planKey = (plan ?? '').toLowerCase();
    final knownOneYear = id.contains('oneyear') ||
        id.contains('1year') ||
        BibleInfo.isArOneYearProductId(productId ?? '');
    final knownSixMonth = id.contains('sixmonth') ||
        id.contains('6month') ||
        BibleInfo.isArSixMonthProductId(productId ?? '');
    final knownOneMonth = BibleInfo.isOneMonthProductId(productId ?? '');
    final twoYearByDays = daysRemaining >= 680 && daysRemaining <= 800;
    final oneYearByDays = daysRemaining >= 330 && daysRemaining <= 400;
    final sixByDays = daysRemaining >= 120 && daysRemaining <= 220;
    final monthByDays = daysRemaining >= 20 && daysRemaining <= 45;

    // Exit yearly (`oneyearautoexit`) is never Lifetime — even if platinum/far expiry leftover.
    if (BibleInfo.isExitOfferYearlyProductId(productId ?? '')) {
      return 'year';
    }
    if (planKey == 'platinum' ||
        id.contains('lifetime') ||
        daysRemaining > 10000) {
      return 'lifetime';
    }
    if (planKey == 'twoyear' ||
        id.contains('twoyear') ||
        ((planKey == 'gold' || planKey.isEmpty) &&
            twoYearByDays &&
            !knownOneYear)) {
      return 'twoyear';
    }
    if (planKey == 'gold' ||
        knownOneYear ||
        (planKey != 'silver' &&
            oneYearByDays &&
            !knownSixMonth &&
            !knownOneMonth)) {
      return 'year';
    }
    if (knownSixMonth ||
        ((planKey == 'silver' || planKey.isEmpty) &&
            sixByDays &&
            !knownOneMonth &&
            !knownOneYear)) {
      return 'sixmonth';
    }
    if (planKey == 'silver' || knownOneMonth || monthByDays) {
      return 'month';
    }
    return null;
  }

  static String? planKeyForProductId(String productId) {
    final id = productId.toLowerCase();
    if (id.contains('lifetime')) return 'platinum';
    if (id.contains('twoyear')) return 'twoyear';
    if (id.contains('oneyear') ||
        id.contains('1year') ||
        BibleInfo.isArOneYearProductId(productId)) {
      return 'gold';
    }
    if (id.contains('sixmonth') ||
        id.contains('6month') ||
        id.contains('onemonth') ||
        BibleInfo.isOneMonthProductId(productId) ||
        BibleInfo.isArSixMonthProductId(productId)) {
      return 'silver';
    }
    return null;
  }

  static int _planTier(String? plan) {
    switch ((plan ?? '').toLowerCase()) {
      case 'platinum':
        return 3;
      case 'gold':
      case 'twoyear':
        return 2;
      case 'silver':
        return 1;
      default:
        return 0;
    }
  }

  /// Additive: when local plan is already 1Y (gold), rewrite stale Keychain/prefs
  /// that still point at an old 2Y product so later sync/restore cannot relabel.
  static Future<void> _alignRememberedProductToOneYear() async {
    final oneYearId = BibleInfo.oneYearPlanid;
    if (oneYearId.isEmpty) return;
    await SharPreferences.setString(_lastIapProductPrefKey, oneYearId);
    if (!Platform.isIOS) return;
    try {
      await _iapMemoryChannel.invokeMethod('setLastIapProduct', {
        'productId': oneYearId,
      });
    } catch (e) {
      debugPrint(
        'PremiumEntitlementLabelSync: align keychain to 1Y failed: $e',
      );
    }
  }

  /// Home/drawer entry: never auto-grant a plan from Keychain/last IAP.
  /// Buy success and explicit Restore still set `subscription_plan` themselves.
  /// Clears orphan AI-Premium labels via [BibleInfo.clearOrphanAiPremiumCreditSkipIfNeeded].
  static Future<bool> syncPlanLabelFromRememberedProduct(
    DownloadProvider download,
  ) async {
    try {
      final before =
          (await download.getSubscriptionPlan())?.toLowerCase().trim();
      await BibleInfo.clearOrphanAiPremiumCreditSkipIfNeeded();
      // Keep DownloadProvider in-memory plan in sync if prefs were cleared.
      final after =
          (await download.getSubscriptionPlan())?.toLowerCase().trim();
      if ((before == 'silver' || before == 'gold' || before == 'twoyear') &&
          (after == null || after.isEmpty)) {
        await download.setSubscriptionPlan('');
        debugPrint(
          'PremiumEntitlementLabelSync: cleared orphan plan=$before '
          '(Buy/Restore only)',
        );
        return true;
      }

      debugPrint(
        'PremiumEntitlementLabelSync: skip auto plan apply from memory '
        '(Buy/Restore only)',
      );
      return false;
    } catch (e) {
      debugPrint('PremiumEntitlementLabelSync error: $e');
      return false;
    }
  }
}
