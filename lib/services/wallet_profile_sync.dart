import 'dart:convert';

import 'package:biblebookapp/core/api/auth/profile_update.api.dart';
import 'package:biblebookapp/core/notifiers/cache.notifier.dart';
import 'package:biblebookapp/services/wallet_service.dart';
import 'package:biblebookapp/view/screens/profile/model/user_model.dart';
import 'package:flutter/foundation.dart';

/// Additive: sync local wallet credits with profile `wallet_balance` (cloud).
/// Does not change credit amounts, IAP, or subscription logic.
class WalletProfileSync {
  WalletProfileSync._();

  static final CacheNotifier _cache = CacheNotifier();
  static final ProfileUpdateApi _profileApi = ProfileUpdateApi();

  static Future<bool> _isSignedIn() async {
    final token = await _cache.readCache(key: 'authtoken');
    return token != null && token.toString().trim().isNotEmpty;
  }

  static bool _profileUpdateSucceeded(String? body) {
    if (body == null || body.isEmpty) return false;
    try {
      final parsed = jsonDecode(body);
      if (parsed is! Map) return false;
      final status = parsed['status'];
      return status == true ||
          status == 1 ||
          status == '1' ||
          status == 'true';
    } catch (_) {
      return false;
    }
  }

  /// Apply profile balance to local wallet (signed-in users only).
  ///
  /// Server value > 0 restores cloud balance. Server 0 does not wipe local
  /// credits (stale/missing backup); local is pushed to the server instead.
  static Future<void> applyProfileBalanceToLocal(int profileBalance) async {
    if (!await _isSignedIn()) return;
    if (profileBalance < 0) return;

    final localBalance = await WalletService.getCredits();
    debugPrint(
      'WalletProfileSync: reconcile local=$localBalance profile=$profileBalance',
    );

    if (profileBalance > 0) {
      if (profileBalance != localBalance) {
        await WalletService.setCreditsBalance(profileBalance);
        debugPrint(
          'WalletProfileSync: restored profile wallet_balance=$profileBalance '
          '(was local=$localBalance)',
        );
      } else {
        debugPrint(
          'WalletProfileSync: profile wallet_balance=$profileBalance matches local',
        );
      }
      await _cache.writeCache(
          key: 'wallet_balance', value: '$profileBalance');
      return;
    }

    // profileBalance == 0 — never overwrite a positive local balance.
    if (localBalance > 0) {
      debugPrint(
        'WalletProfileSync: profile wallet_balance=0 — keeping local=$localBalance, '
        'pushing to server',
      );
      schedulePushToProfile(localBalance);
      return;
    }

    await _cache.writeCache(key: 'wallet_balance', value: '0');
    debugPrint('WalletProfileSync: profile and local wallet_balance are 0');
  }

  /// Pull from [UserModel] after login/profile cache (additive hook).
  static Future<void> pullFromUser(UserModel user) async {
    final balance = user.walletBalance;
    if (balance == null) return;
    await applyProfileBalanceToLocal(balance);
  }

  /// Pull from cached `wallet_balance` when profile object is unavailable.
  static Future<void> pullFromCachedProfile() async {
    if (!await _isSignedIn()) return;
    final raw = await _cache.readCache(key: 'wallet_balance');
    if (raw == null || raw.toString().trim().isEmpty) return;
    final balance = int.tryParse(raw.toString().trim());
    if (balance == null) return;
    await applyProfileBalanceToLocal(balance);
  }

  /// Push local balance to profile API (signed-in users only).
  static Future<void> pushBalanceToProfile([int? balance]) async {
    if (!await _isSignedIn()) return;
    try {
      final resolved = balance ?? await WalletService.getCredits();
      if (resolved < 0) return;
      final response = await _profileApi.updateWalletBalance(resolved);
      if (_profileUpdateSucceeded(response)) {
        await _cache.writeCache(key: 'wallet_balance', value: '$resolved');
        debugPrint(
          'WalletProfileSync: pushed wallet_balance=$resolved (server saved)',
        );
      } else {
        debugPrint(
          'WalletProfileSync: push failed wallet_balance=$resolved '
          'response=${response ?? 'empty'}',
        );
      }
    } catch (e) {
      debugPrint('WalletProfileSync push: $e');
    }
  }

  /// Fire-and-forget push after local credit change.
  static void schedulePushToProfile([int? balance]) {
    pushBalanceToProfile(balance);
  }
}
