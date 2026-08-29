class UserModel {
  final String uid;
  final String? displayName;
  final String? photoURL;
  final String? address;
  final String? phoneNumber;
  final String? email;
  final String? appId;
  final String? token;
  final String? referralCode;
  final String? referredBy;
  final int? referralCount;
  final int? referralRewardClaimed;
  /// Additive PDF fields (login/profile) — unused by existing claim logic.
  final int? referralRewardCredits;
  final int? totalReferredCount;
  final int? totalClaimedCount;
  final int? walletBalance;

  UserModel({
    this.address,
    required this.uid,
    this.displayName,
    this.email,
    this.phoneNumber,
    this.appId,
    this.token,
    this.photoURL,
    this.referralCode,
    this.referredBy,
    this.referralCount,
    this.referralRewardClaimed,
    this.referralRewardCredits,
    this.totalReferredCount,
    this.totalClaimedCount,
    this.walletBalance,
  });

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  factory UserModel.fromJson(Map<String, dynamic> json, String token) {
    return UserModel(
      uid: json['user_id'] as String,
      address: json['address'] as String?,
      displayName: json['name'] as String?,
      email: json['email'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      photoURL: json['photoURL'] as String?,
      appId: json['app_id'] as String?,
      token: token,
      referralCode: json['referral_code'] as String?,
      referredBy: json['referred_by'] as String?,
      referralCount: _parseInt(json['referral_count']),
      referralRewardClaimed: _parseInt(json['referral_reward_claimed']),
      referralRewardCredits: _parseInt(json['referral_reward_credits']),
      totalReferredCount: _parseInt(json['total_referred_count']),
      totalClaimedCount: _parseInt(json['total_claimed_count']),
      walletBalance: _parseInt(json['wallet_balance']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': uid,
      'address': address,
      'name': displayName,
      'email': email,
      'phoneNumber': phoneNumber,
      'photoURL': photoURL,
      'app_id': appId,
      'token': token,
      'referral_code': referralCode,
      'referred_by': referredBy,
      'referral_count': referralCount,
      'referral_reward_claimed': referralRewardClaimed,
      'referral_reward_credits': referralRewardCredits,
      'total_referred_count': totalReferredCount,
      'total_claimed_count': totalClaimedCount,
      'wallet_balance': walletBalance,
    };
  }
}
