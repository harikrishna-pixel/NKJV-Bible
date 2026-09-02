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
    if (id.contains('oneyear') || id.contains('1year')) return 'gold';
    if (id.contains('sixmonth') || id.contains('6month')) return 'silver';
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

  static Future<void> _writeRememberedProductId(String productId) async {
    if (productId.isEmpty) return;
    await SharPreferences.setString(_lastIapProductPrefKey, productId);
    if (!Platform.isIOS) return;
    try {
      await _iapMemoryChannel.invokeMethod('setLastIapProduct', {
        'productId': productId,
      });
    } catch (e) {
      debugPrint(
        'PremiumEntitlementLabelSync: write keychain failed: $e',
      );
    }
  }

  /// When local plan is already a non-2Y timed/lifetime plan, do not let a
  /// stale Keychain 2Y relabel Info — realign memory to match local plan.
  static Future<void> _alignRememberedProductToCurrentPlan(
    String currentPlan,
  ) async {
    String? productId;
    switch (currentPlan) {
      case 'silver':
        productId = BibleInfo.sixMonthPlanid;
        break;
      case 'gold':
        productId = BibleInfo.oneYearPlanid;
        break;
      case 'platinum':
        productId = BibleInfo.lifeTimePlanid;
        break;
      default:
        return;
    }
    await _writeRememberedProductId(productId);
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

      // Never downgrade a higher local plan from a lower remembered product
      // (e.g. 1Y still active after a skipped shorter 6M buy attempt).
      if (expectedTier < currentTier) {
        debugPrint(
          'PremiumEntitlementLabelSync: skip downgrade '
          '$current → $expected ($productId)',
        );
        return false;
      }

      // Never let stale remembered 2Y overwrite an active 6M/1Y/lifetime label.
      if (expected == 'twoyear' &&
          (current == 'silver' ||
              current == 'gold' ||
              current == 'platinum')) {
        debugPrint(
          'PremiumEntitlementLabelSync: skip stale twoyear over $current '
          '($productId) — aligning memory',
        );
        await _alignRememberedProductToCurrentPlan(current!);
        return false;
      }

      // Same tier / empty / upgrade: apply remembered label (including
      // correcting stale twoyear → gold when last product is 1Y).
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
