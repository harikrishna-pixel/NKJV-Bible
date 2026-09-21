import 'dart:io';

import 'package:biblebookapp/core/notifiers/download.notifier.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Additive: home/drawer hook for premium plan labels.
/// Does **not** auto-apply Keychain/last-IAP memory as a live plan.
/// Plans are set only by Buy success or explicit Restore.
/// Clears orphan `silver`/`gold`/`twoyear` when premium expiry is inactive.
class PremiumEntitlementLabelSync {
  PremiumEntitlementLabelSync._();

  static const MethodChannel _iapMemoryChannel =
      MethodChannel('com.biblebookapp/iap_memory');
  static const String _lastIapProductPrefKey = 'last_iap_product_id';

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
