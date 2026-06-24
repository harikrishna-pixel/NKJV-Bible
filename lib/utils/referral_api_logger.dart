import 'dart:convert';

import 'package:flutter/foundation.dart';

void logAuthApiReferralFields(String apiName, dynamic response) {
  const encoder = JsonEncoder.withIndent('  ');
  try {
    debugPrint('══════════ $apiName FULL RESPONSE ══════════');
    if (response is Map || response is List) {
      debugPrint(encoder.convert(response));
    } else {
      debugPrint(response.toString());
    }
  } catch (_) {
    debugPrint('$apiName response: $response');
  }

  Map<String, dynamic>? user;
  if (response is Map<String, dynamic>) {
    final data = response['data'];
    if (data is Map<String, dynamic> && data['user'] is Map<String, dynamic>) {
      user = Map<String, dynamic>.from(data['user'] as Map);
    } else if (response['user'] is Map<String, dynamic>) {
      user = Map<String, dynamic>.from(response['user'] as Map);
    }
  }

  String readField(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      if (map.containsKey(key)) {
        final value = map[key];
        if (value == null) return '(null)';
        return value.toString();
      }
    }
    return '(not in API response)';
  }

  debugPrint('────────── $apiName REFERRAL PROFILE FIELDS ──────────');
  if (user == null) {
    debugPrint('user object: (not found in response)');
    debugPrint('══════════════════════════════════════════════');
    return;
  }

  debugPrint('All user keys: ${user.keys.toList()}');
  debugPrint(
      '1. Referral code            → ${readField(user, ['referral_code', 'referralCode'])}');
  debugPrint(
      '2. referred_by              → ${readField(user, ['referred_by', 'referredBy', 'you_referred_by'])}');
  debugPrint(
      '3. referral_count           → ${readField(user, ['referral_count', 'referralCount', 'refered_count'])}');
  debugPrint(
      '4. referral_reward_claimed  → ${readField(user, ['referral_reward_claimed', 'referralRewardClaimed', 'is_referral_reward_claimed', 'referral_reward'])}');
  debugPrint('══════════════════════════════════════════════');
}
