import 'dart:io';

import 'package:biblebookapp/core/notifiers/download.notifier.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Additive: corrects stale local plan labels from the last remembered IAP
/// product (prefs + iOS Keychain). Does not change buy/charge/ad logic or
/// overwrite a higher-tier local plan with a lower remembered product.
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

  /// Rewrites local plan label when remembered product is more accurate.
  /// Returns true when the stored plan was updated.
  static Future<bool> syncPlanLabelFromRememberedProduct(
    DownloadProvider download,
  ) async {
    try {
      final productId = await readLastProductId();
      if (productId == null || productId.isEmpty) return false;

      final expected = planKeyForProductId(productId);
      if (expected == null) return false;

      final current = (await download.getSubscriptionPlan())?.toLowerCase();
      if (current == expected) return false;

      final currentTier = _planTier(current);
      final expectedTier = _planTier(expected);

      if (expectedTier < currentTier) {
        debugPrint(
          'PremiumEntitlementLabelSync: skip downgrade '
          '$current → $expected ($productId)',
        );
        return false;
      }

      if (current == 'gold' && expected == 'twoyear') {
        debugPrint(
          'PremiumEntitlementLabelSync: skip stale twoyear over gold '
          '($productId) — aligning memory to 1Y',
        );
        await _alignRememberedProductToOneYear();
        return false;
      }

      await download.setSubscriptionPlan(expected);
      debugPrint(
        'PremiumEntitlementLabelSync: plan $current → $expected '
        'from $productId',
      );
      return true;
    } catch (e) {
      debugPrint('PremiumEntitlementLabelSync error: $e');
      return false;
    }
  }
}
