import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Wallet Service to manage user credits/coins
class WalletService {
  static const String _creditsKey = 'user_wallet_credits';
  static const String _lastClaimTimeKey = 'last_claim_time';
  static const String _lastAdWatchTimeKey = 'last_ad_watch_time';
  static const String _adWatchCountKey = 'ad_watch_count';
  static const String _adWatchDateKey = 'ad_watch_date';
  static const String _answerLengthKey = 'chat_answer_length'; // 'small', 'medium', 'large'
  static const int _freeCreditsOnStart = 100;
  static const int _claimAmount = 20;
  static const int _claimCooldownMinutes = 15;
  static const int _adWatchAmount = 50; // 50 credits per ad
  static const int _maxAdsPerDay = 2; // Maximum 2 ads per day
  
  // Answer length credit costs
  static const int _smallAnswerCost = 20;
  static const int _mediumAnswerCost = 50;
  static const int _largeAnswerCost = 100;

  /// Initialize wallet for new users (give 100 free credits)
  static Future<void> initializeWallet() async {
    final prefs = await SharedPreferences.getInstance();
    final hasCredits = prefs.containsKey(_creditsKey);
    
    if (!hasCredits) {
      // New user - give 100 free credits
      await prefs.setInt(_creditsKey, _freeCreditsOnStart);
      debugPrint('WalletService: Initialized wallet with $_freeCreditsOnStart credits');
    }
  }

  /// Get current credits balance
  static Future<int> getCredits() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_creditsKey) ?? 0;
  }

  /// Add credits to wallet
  static Future<int> addCredits(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getCredits();
    final newBalance = current + amount;
    await prefs.setInt(_creditsKey, newBalance);
    debugPrint('WalletService: Added $amount credits. New balance: $newBalance');
    return newBalance;
  }

  /// Deduct credits from wallet
  static Future<bool> deductCredits(int amount) async {
    final current = await getCredits();
    if (current >= amount) {
      final prefs = await SharedPreferences.getInstance();
      final newBalance = current - amount;
      await prefs.setInt(_creditsKey, newBalance);
      debugPrint('WalletService: Deducted $amount credits. New balance: $newBalance');
      return true;
    }
    debugPrint('WalletService: Insufficient credits. Required: $amount, Available: $current');
    return false;
  }

  /// Check if user can claim free credits (15 min cooldown)
  static Future<bool> canClaimFreeCredits() async {
    final prefs = await SharedPreferences.getInstance();
    final lastClaimTime = prefs.getString(_lastClaimTimeKey);
    
    if (lastClaimTime == null) {
      return true; // Never claimed before
    }
    
    final lastClaim = DateTime.parse(lastClaimTime);
    final now = DateTime.now();
    final difference = now.difference(lastClaim);
    
    return difference.inMinutes >= _claimCooldownMinutes;
  }

  /// Claim free credits (20 credits every 15 minutes)
  static Future<int?> claimFreeCredits() async {
    if (!await canClaimFreeCredits()) {
      return null; // Still on cooldown
    }

    final prefs = await SharedPreferences.getInstance();
    // Persist cooldown timestamp first so UI polls never briefly show "Claim" again.
    await prefs.setString(_lastClaimTimeKey, DateTime.now().toIso8601String());
    final newBalance = await addCredits(_claimAmount);
    debugPrint('WalletService: Claimed $_claimAmount free credits');
    return newBalance;
  }

  /// Get time remaining until next claim is available
  static Future<int> getClaimCooldownMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    final lastClaimTime = prefs.getString(_lastClaimTimeKey);
    
    if (lastClaimTime == null) {
      return 0; // Can claim now
    }
    
    final lastClaim = DateTime.parse(lastClaimTime);
    final now = DateTime.now();
    final difference = now.difference(lastClaim);
    final remaining = _claimCooldownMinutes - difference.inMinutes;
    
    return remaining > 0 ? remaining : 0;
  }

  /// Get time remaining until next claim is available (seconds)
  static Future<int> getClaimCooldownSeconds() async {
    final prefs = await SharedPreferences.getInstance();
    final lastClaimTime = prefs.getString(_lastClaimTimeKey);
    if (lastClaimTime == null) {
      return 0;
    }

    final lastClaim = DateTime.parse(lastClaimTime);
    final now = DateTime.now();
    final difference = now.difference(lastClaim);
    final remainingSeconds = (_claimCooldownMinutes * 60) - difference.inSeconds;
    return remainingSeconds > 0 ? remainingSeconds : 0;
  }

  /// Check if user can watch ad (max 2 ads per day)
  static Future<bool> canWatchAd() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    final lastWatchDate = prefs.getString(_adWatchDateKey);
    final watchCount = prefs.getInt(_adWatchCountKey) ?? 0;
    
    // Reset count if it's a new day
    if (lastWatchDate != todayKey) {
      await prefs.setString(_adWatchDateKey, todayKey);
      await prefs.setInt(_adWatchCountKey, 0);
      return true; // Can watch ad on new day
    }
    
    // Check if user has watched less than max ads today
    return watchCount < _maxAdsPerDay;
  }

  /// Get remaining ads for today
  static Future<int> getRemainingAdsToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    final lastWatchDate = prefs.getString(_adWatchDateKey);
    final watchCount = prefs.getInt(_adWatchCountKey) ?? 0;
    
    // Reset count if it's a new day
    if (lastWatchDate != todayKey) {
      return _maxAdsPerDay;
    }
    
    return _maxAdsPerDay - watchCount;
  }

  /// Watch ad to get credits (50 credits per ad, max 2 per day)
  static Future<int?> watchAdForCredits() async {
    if (!await canWatchAd()) {
      return null; // Already watched max ads today
    }
    
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    
    // Increment watch count
    final currentCount = prefs.getInt(_adWatchCountKey) ?? 0;
    await prefs.setInt(_adWatchCountKey, currentCount + 1);
    await prefs.setString(_adWatchDateKey, todayKey);
    await prefs.setString(_lastAdWatchTimeKey, DateTime.now().toIso8601String());
    
    final newBalance = await addCredits(_adWatchAmount);
    debugPrint('WalletService: Watched ad, received $_adWatchAmount credits. Remaining ads today: ${_maxAdsPerDay - currentCount - 1}');
    return newBalance;
  }

  /// Get current answer length preference ('small', 'medium', 'large')
  /// Default is 'small'
  static Future<String> getAnswerLength() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_answerLengthKey) ?? 'small';
  }

  /// Set answer length preference ('small', 'medium', 'large')
  static Future<void> setAnswerLength(String length) async {
    if (length != 'small' && length != 'medium' && length != 'large') {
      debugPrint('WalletService: Invalid answer length: $length');
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_answerLengthKey, length);
    debugPrint('WalletService: Answer length set to $length');
  }

  /// Get credit cost for current answer length
  static Future<int> getChatCost() async {
    final length = await getAnswerLength();
    switch (length) {
      case 'small':
        return _smallAnswerCost;
      case 'medium':
        return _mediumAnswerCost;
      case 'large':
        return _largeAnswerCost;
      default:
        return _smallAnswerCost; // Default to small
    }
  }

  /// Get credit cost for specific answer length
  static int getChatCostForLength(String length) {
    switch (length) {
      case 'small':
        return _smallAnswerCost;
      case 'medium':
        return _mediumAnswerCost;
      case 'large':
        return _largeAnswerCost;
      default:
        return _smallAnswerCost; // Default to small
    }
  }

  /// Reset wallet (for testing)
  static Future<void> resetWallet() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_creditsKey);
    await prefs.remove(_lastClaimTimeKey);
    await prefs.remove(_lastAdWatchTimeKey);
    debugPrint('WalletService: Wallet reset');
  }
}

