import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:biblebookapp/services/wallet_service.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:biblebookapp/view/screens/auth/splash.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> _products = [];
  bool _isAvailable = false;
  String? _loadingProductId; // Track which specific product is loading
  String? _selectedProductId; // Track which product is selected/tapped
  int _currentCredits = 0;
  List<Map<String, dynamic>> _coinPacks = [];
  Timer? _creditsTimer;
  String _currentAnswerLength = 'small'; // Track current answer length
  int _claimCooldownMinutes = 0;
  int _claimCooldownSeconds = 0;
  bool _hasWatchedMaxAds =
      false; // Track if user has watched max ads (2 per day)
  Map<String, Timer> _purchaseTimeouts =
      {}; // Track timeout timers for each product

  // Rewarded Ad
  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoaded = false;

  // Cache SharedPreferences instance for instant credits loading (works offline)
  SharedPreferences? _cachedPrefs;

  @override
  void initState() {
    super.initState();
    _checkConnectivityAndShowToast();
    // Initialize and load credits immediately from local storage (works offline)
    _initializeCredits();
    // Initialize coin packs with constants immediately so UI shows data right away
    _loadCoinPacksFromConstants();
    // Then try to load from API/SharedPreferences (will update if available)
    _loadCoinPacks();
    _initStoreInfoIfOnline(); // Only initialize store if online
    _loadRewardedAd(); // Load rewarded ad for watch ad feature
    _loadAnswerLength(); // Load current answer length preference
    // Refresh credits every second to show real-time updates
    _creditsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _loadCredits();
      _refreshClaimCooldown();
      _checkMaxAdsWatched();
    });
    // Initialize max ads check
    _checkMaxAdsWatched();
  }

  Future<void> _checkConnectivityAndShowToast() async {
    // Use InternetConnectionChecker for more accurate connectivity check
    // This checks actual internet access, not just network interface availability
    final hasInternet = await InternetConnection().hasInternetAccess;
    if (!hasInternet) {
      // No internet connection - show toast
      Constants.showToast("No internet connection");
    }
  }

  Future<void> _loadAnswerLength() async {
    final length = await WalletService.getAnswerLength();
    if (mounted) {
      setState(() {
        _currentAnswerLength = length;
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _creditsTimer?.cancel();
    _rewardedAd?.dispose();
    // Cancel all pending purchase timeouts
    for (var timer in _purchaseTimeouts.values) {
      timer.cancel();
    }
    _purchaseTimeouts.clear();
    super.dispose();
  }

  Future<void> _loadRewardedAd() async {
    String? adUnitId =
        await SharPreferences.getString(SharPreferences.rewardedAd);
    if (adUnitId == null || adUnitId.isEmpty) {
      debugPrint('WalletScreen: No rewarded ad unit ID found');
      return;
    }

    // Get ad request with fallback
    AdRequest adRequest;
    try {
      adRequest = await AdConsentManager.getAdRequest();
    } catch (e) {
      debugPrint('WalletScreen: Error getting ad request, using default: $e');
      adRequest = const AdRequest();
    }

    RewardedAd.load(
      adUnitId: adUnitId,
      request: adRequest,
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              debugPrint('WalletScreen: Rewarded ad showed');
            },
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('WalletScreen: Rewarded ad dismissed');
              ad.dispose();
              _rewardedAd = null;
              _isRewardedAdLoaded = false;
              // Reload ad for next time
              _loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('WalletScreen: Rewarded ad failed to show: $error');
              ad.dispose();
              _rewardedAd = null;
              _isRewardedAdLoaded = false;
            },
          );
          _rewardedAd = ad;
          _isRewardedAdLoaded = true;
          debugPrint('WalletScreen: Rewarded ad loaded');
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('WalletScreen: Rewarded ad failed to load: $error');
          _isRewardedAdLoaded = false;
        },
      ),
    );
  }

  /// Initialize and store credits in constant/state variable immediately
  /// This ensures credits are shown instantly even when offline (no internet needed)
  /// Credits are stored locally and displayed immediately
  Future<void> _initializeCredits() async {
    try {
      // Cache SharedPreferences instance for faster subsequent access
      _cachedPrefs = await SharedPreferences.getInstance();

      // Store credits in constant/state variable immediately from local storage
      // This works offline - no API dependency
      final storedCredits = _cachedPrefs?.getInt('user_wallet_credits') ?? 0;

      // Store in state variable immediately (works offline)
      if (mounted) {
        setState(() {
          _currentCredits = storedCredits; // Store credits in constant/state
        });
      }
    } catch (e) {
      debugPrint('Error initializing credits: $e');
      // Fallback: try to load from WalletService
      try {
        final credits = await WalletService.getCredits();
        if (mounted) {
          setState(() {
            _currentCredits = credits; // Store credits in constant/state
          });
        }
      } catch (e2) {
        debugPrint('Error loading credits from WalletService: $e2');
      }
    }
  }

  /// Load credits from local storage and store in constant/state variable
  /// This ensures credits are shown even when offline or when API is slow/delayed
  /// Uses stored local data - no internet connection required
  Future<void> _loadCredits() async {
    try {
      int storedCredits;

      // Use cached SharedPreferences instance if available for instant read (works offline)
      if (_cachedPrefs != null) {
        // Instant synchronous read from cached instance - no async delay, works offline
        storedCredits = _cachedPrefs!.getInt('user_wallet_credits') ?? 0;
      } else {
        // Fallback: get from WalletService and cache the instance
        storedCredits = await WalletService.getCredits();
        _cachedPrefs = await SharedPreferences.getInstance();
      }

      // Update stored credits in constant/state variable (works offline)
      if (mounted && storedCredits != _currentCredits) {
        setState(() {
          _currentCredits = storedCredits; // Store credits in constant/state
        });
      }
    } catch (e) {
      debugPrint('Error loading credits from local storage: $e');
      // If error, keep showing current stored value (works offline)
    }
  }

  Future<void> _refreshClaimCooldown() async {
    final cooldown = await WalletService.getClaimCooldownMinutes();
    final cooldownSeconds = await WalletService.getClaimCooldownSeconds();
    if (mounted &&
        (cooldown != _claimCooldownMinutes ||
            cooldownSeconds != _claimCooldownSeconds)) {
      setState(() {
        _claimCooldownMinutes = cooldown;
        _claimCooldownSeconds = cooldownSeconds;
      });
    }
  }

  Future<void> _checkMaxAdsWatched() async {
    final canWatch = await WalletService.canWatchAd();
    final hasMaxAds = !canWatch;
    if (mounted && hasMaxAds != _hasWatchedMaxAds) {
      setState(() {
        _hasWatchedMaxAds = hasMaxAds;
      });
    }
  }

  Future<void> _loadCoinPacks() async {
    // Check connectivity first - if offline, use constants directly
    final hasInternet = await InternetConnection().hasInternetAccess;

    if (!hasInternet) {
      // Offline - use constants directly (don't check SharedPreferences)
      _loadCoinPacksFromConstants();
      return;
    }

    // Online - Load coin packs data from API response (saved in SharedPreferences by BackgroundApiService)
    // Credits amount comes from API's sub_fields -> item_1 field
    final prefs = await SharedPreferences.getInstance();
    final coinPacksJson = prefs.getString('coin_packs');

    if (coinPacksJson != null && coinPacksJson.isNotEmpty) {
      try {
        final coinPacksMap = jsonDecode(coinPacksJson) as Map<String, dynamic>;
        final packs = <Map<String, dynamic>>[];

        coinPacksMap.forEach((identifier, data) {
          // Determine which price constant to use based on identifier
          String priceFromConstants = '';
          if (identifier == BibleInfo.coinPack1Id) {
            priceFromConstants = BibleInfo.coinPack1Price;
          } else if (identifier == BibleInfo.coinPack2Id) {
            priceFromConstants = BibleInfo.coinPack2Price;
          } else if (identifier == BibleInfo.coinPack3Id) {
            priceFromConstants = BibleInfo.coinPack3Price;
          }

          packs.add({
            'identifier': identifier,
            'credits': data['credits'] ??
                '0', // Credits from API response (sub_fields.item_1)
            'discount': data['discount'] ??
                '0', // Discount from API response (sub_fields.value)
            'price': priceFromConstants, // Price from constants as fallback
          });
        });

        // Sort by credits amount
        packs.sort((a, b) {
          final aCredits = int.tryParse(a['credits']?.toString() ?? '0') ?? 0;
          final bCredits = int.tryParse(b['credits']?.toString() ?? '0') ?? 0;
          return aCredits.compareTo(bCredits);
        });

        if (mounted) {
          setState(() {
            _coinPacks = packs;
          });
        }
      } catch (e) {
        debugPrint('Error loading coin packs: $e');
        // Fallback to constants if JSON parsing fails
        _loadCoinPacksFromConstants();
      }
    } else {
      // No API data available (first time) - use constants as fallback
      _loadCoinPacksFromConstants();
    }
  }

  /// Load coin packs from constants directly (offline mode or fallback)
  void _loadCoinPacksFromConstants() {
    try {
      // Use constants directly (don't check SharedPreferences when offline)
      final coinPack1Id = BibleInfo.coinPack1Id;
      final coinPack2Id = BibleInfo.coinPack2Id;
      final coinPack3Id = BibleInfo.coinPack3Id;

      // Default coin pack data based on constants (matches API structure)
      final packs = <Map<String, dynamic>>[
        {
          'identifier': coinPack1Id,
          'credits': '100', // Default credits for pack 1
          'discount': '20', // Default discount for pack 1
          'price': BibleInfo.coinPack1Price, // Price from constants
        },
        {
          'identifier': coinPack2Id,
          'credits': '500', // Default credits for pack 2
          'discount': '20', // Default discount for pack 2
          'price': BibleInfo.coinPack2Price, // Price from constants
        },
        {
          'identifier': coinPack3Id,
          'credits': '1000', // Default credits for pack 3
          'discount': '20', // Default discount for pack 3
          'price': BibleInfo.coinPack3Price, // Price from constants
        },
      ];

      if (mounted) {
        setState(() {
          _coinPacks = packs;
        });
        debugPrint(
            'WalletScreen: Loaded coin packs from constants (offline mode) - Count: ${packs.length}');
        for (var pack in packs) {
          debugPrint(
              'WalletScreen: Pack - ${pack['identifier']}, Credits: ${pack['credits']}, Price: ${pack['price']}');
        }
      }
    } catch (e) {
      debugPrint('Error loading coin packs from constants: $e');
    }
  }

  Future<void> _initStoreInfoIfOnline() async {
    // Check connectivity first - skip if offline
    final hasInternet = await InternetConnection().hasInternetAccess;
    if (!hasInternet) {
      // Offline - don't try to query products, just show coin packs from constants
      if (mounted) {
        setState(() {
          _isAvailable = false; // Mark as unavailable when offline
          _loadingProductId = null; // Clear any loading state when offline
        });
      }
      return;
    }

    await _initStoreInfo();
  }

  Future<void> _initStoreInfo() async {
    if (_coinPacks.isEmpty) {
      await _loadCoinPacks();
    }

    if (_coinPacks.isEmpty) return;

    final Set<String> productIds = _coinPacks
        .map((pack) => pack['identifier'] as String)
        .where((id) => id.isNotEmpty)
        .toSet();

    if (productIds.isEmpty) return;

    final bool isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) {
      if (mounted) {
        setState(() {
          _isAvailable = false;
        });
      }
      return;
    }

    // Set iOS delegate if needed
    if (Platform.isIOS) {
      try {
        final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
            _inAppPurchase
                .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
        await iosPlatformAddition.setDelegate(_WalletPaymentQueueDelegate());
      } catch (e) {
        debugPrint('Error setting iOS delegate: $e');
      }
    }

    final ProductDetailsResponse response =
        await _inAppPurchase.queryProductDetails(productIds);

    if (mounted) {
      setState(() {
        _isAvailable = isAvailable;
        _products = response.productDetails;
      });
    }

    // Listen to purchase updates
    _subscription = _inAppPurchase.purchaseStream.listen(
      (List<PurchaseDetails> purchaseDetailsList) {
        _listenToPurchaseUpdated(purchaseDetailsList);
      },
    );
  }

  void _listenToPurchaseUpdated(
      List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      // Clear loading state for the product being processed (regardless of status)
      final productId = purchaseDetails.productID;

      if (purchaseDetails.status == PurchaseStatus.purchased) {
        // Find which coin pack was purchased
        try {
          final pack = _coinPacks.firstWhere(
            (p) => p['identifier'] == purchaseDetails.productID,
          );

          final credits = int.tryParse(pack['credits']?.toString() ?? '0') ?? 0;
          await WalletService.addCredits(credits);
          // Update cached instance immediately for instant display
          if (_cachedPrefs != null) {
            final newBalance = await WalletService.getCredits();
            await _cachedPrefs!.setInt('user_wallet_credits', newBalance);
          }
          await _loadCredits();
          Constants.showToast('Successfully added $credits credits!');
        } catch (e) {
          debugPrint('Error processing purchase: $e');
        }

        // Complete the purchase (important for consumables)
        await _inAppPurchase.completePurchase(purchaseDetails);

        if (mounted && _loadingProductId == productId) {
          setState(() {
            _loadingProductId = null; // Clear loading state for this product
            _selectedProductId = null; // Clear selected state
          });
          // Cancel any pending timeout timer
          _purchaseTimeouts[productId]?.cancel();
          _purchaseTimeouts.remove(productId);
        }
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        if (mounted && _loadingProductId == productId) {
          setState(() {
            _loadingProductId = null; // Clear loading state on error
            _selectedProductId = null; // Clear selected state
          });
          // Cancel timeout timer
          _purchaseTimeouts[productId]?.cancel();
          _purchaseTimeouts.remove(productId);
        }
        Constants.showToast('Purchase failed. Please try again.');
      } else if (purchaseDetails.status == PurchaseStatus.pending) {
        // Purchase is pending, keep loading state
        debugPrint('Purchase pending...');
      } else if (purchaseDetails.status == PurchaseStatus.restored) {
        // Handle restored purchases - clear loading state
        if (mounted && _loadingProductId == productId) {
          setState(() {
            _loadingProductId = null;
            _selectedProductId = null; // Clear selected state
          });
          // Cancel timeout timer
          _purchaseTimeouts[productId]?.cancel();
          _purchaseTimeouts.remove(productId);
        }
      } else {
        // Handle any other status or cancellation - clear loading state
        if (mounted && _loadingProductId == productId) {
          setState(() {
            _loadingProductId = null;
            _selectedProductId = null; // Clear selected state
          });
          // Cancel timeout timer
          _purchaseTimeouts[productId]?.cancel();
          _purchaseTimeouts.remove(productId);
        }
      }
    }
  }

  Future<void> _buyCoinPack(ProductDetails product) async {
    if (_loadingProductId != null || !_isAvailable) return;

    // Check connectivity first (using InternetConnectionChecker for more accurate check)
    // This checks actual internet access, not just network interface availability
    final hasInternet = await InternetConnection().hasInternetAccess;
    if (!hasInternet) {
      Constants.showToast("Check your internet connection.");
      return;
    }

    final productId = product.id;
    setState(() {
      _loadingProductId = productId; // Track which product is loading
    });

    // Set a timeout to clear loading state if purchase dialog is canceled
    // This handles the case where user cancels and no purchase update is sent
    _purchaseTimeouts[productId] = Timer(const Duration(seconds: 10), () {
      if (mounted && _loadingProductId == productId) {
        setState(() {
          _loadingProductId = null; // Clear loading state after timeout
          _selectedProductId = null; // Clear selected state
        });
        debugPrint('WalletScreen: Purchase timeout - clearing loading state');
        _purchaseTimeouts.remove(productId);
      }
    });

    try {
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );

      // Use buyNonConsumable (matching existing codebase pattern)
      // For coins, we'll add credits and complete purchase immediately
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      // Purchase stream will handle the success/error cases
      // Cancel timeout if purchase is initiated successfully
      // timeoutTimer?.cancel();
    } catch (e) {
      _purchaseTimeouts[productId]?.cancel();
      _purchaseTimeouts.remove(productId);
      if (mounted) {
        setState(() {
          _loadingProductId = null; // Clear loading state on error
          _selectedProductId = null; // Clear selected state
        });
      }
      Constants.showToast('Error: $e');
    }
  }

  Future<void> _claimFreeCredits() async {
    final result = await WalletService.claimFreeCredits();
    if (result != null) {
      // Update cached instance immediately for instant display
      if (_cachedPrefs != null) {
        await _cachedPrefs!.setInt('user_wallet_credits', result);
      }
      await _loadCredits();
      await _refreshClaimCooldown();
      Constants.showToast('Claimed 20 credits!', 6000);
    } else {
      final cooldown = await WalletService.getClaimCooldownMinutes();
      if (cooldown > 0) {
        Constants.showToast('Please wait $cooldown more minutes');
      }
    }
  }

  Future<void> _watchAdForCredits() async {
    try {
      // Check connectivity first (using InternetConnectionChecker for more accurate check)
      // This checks actual internet access, not just network interface availability
      final hasInternet = await InternetConnection().hasInternetAccess;
      if (!hasInternet) {
        Constants.showToast("Check your Internet connection", 6000);
        return;
      }

      // Check if user can watch ad (max 2 per day)
      final canWatch = await WalletService.canWatchAd();
      if (!canWatch) {
        final remaining = await WalletService.getRemainingAdsToday();
        Constants.showToast(
            'You have already watched 2 ads Today. Come back Tomorrow!', 6000);
        return;
      }

      // Capture remaining before showing ad to avoid off-by-one toast
      final remainingBefore = await WalletService.getRemainingAdsToday();

      // Check if ad is loaded
      if (!_isRewardedAdLoaded || _rewardedAd == null) {
        Constants.showToast(
            'Ad is loading. Please try again in a moment.', 6000);
        _loadRewardedAd(); // Try to load ad
        return;
      }

      // Store the callback before showing ad
      final adToShow = _rewardedAd;
      if (adToShow == null) {
        Constants.showToast('Ad is not ready. Please try again.', 6000);
        _loadRewardedAd();
        return;
      }

      adToShow.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          debugPrint('WalletScreen: Rewarded ad dismissed');
          ad.dispose();
          _rewardedAd = null;
          _isRewardedAdLoaded = false;
          _loadRewardedAd(); // Reload for next time
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('WalletScreen: Failed to show rewarded ad: $error');
          ad.dispose();
          _rewardedAd = null;
          _isRewardedAdLoaded = false;
          Constants.showToast('Failed to show ad. Please try again.', 6000);
          _loadRewardedAd();
        },
      );

      // Prevent app open ad from showing immediately after rewarded watch flow
      await SharPreferences.setString('OpenAd', '1');

      adToShow.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) async {
          try {
            // User earned reward - give credits only when reward is earned
            final newBalance = await WalletService.watchAdForCredits();
            if (newBalance != null) {
              // Update cached instance immediately for instant display
              if (_cachedPrefs != null) {
                await _cachedPrefs!.setInt('user_wallet_credits', newBalance);
              }
              await _loadCredits();
              final remainingAfter = await WalletService.getRemainingAdsToday();
              final safeRemaining = remainingAfter < 0 ? 0 : remainingAfter;
              Constants.showToast(
                  'Watched ad! Received 50 credits. $safeRemaining ads remaining today.',
                  6000);
              // Update max ads status after watching ad
              await _checkMaxAdsWatched();
            } else {
              Constants.showToast('You have already watched 2 ads today', 6000);
            }
          } catch (e) {
            debugPrint('WalletScreen: Error giving credits after ad: $e');
            Constants.showToast(
                'Error processing credits. Please try again.', 6000);
          }
        },
      );
    } catch (e) {
      debugPrint('WalletScreen: Error in _watchAdForCredits: $e');
      Constants.showToast('Error loading ad. Please try again.', 6000);
      _loadRewardedAd(); // Try to reload ad
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final isVintage =
        themeProvider.currentCustomTheme == AppCustomTheme.vintage;

    return Scaffold(
      backgroundColor: isVintage
          ? (isDark ? CommanColor.black : themeProvider.backgroundColor)
          : (isDark
              ? CommanColor.darkPrimaryColor
              : themeProvider.backgroundColor),
      appBar: AppBar(
        backgroundColor: isVintage
            ? (isDark ? CommanColor.black : themeProvider.backgroundColor)
            : (isDark
                ? CommanColor.darkPrimaryColor
                : themeProvider.backgroundColor),
        flexibleSpace: isVintage
            ? Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? CommanColor.black
                      : themeProvider.backgroundColor,
                  image: DecorationImage(
                    image: AssetImage(Images.bgImage(context)),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            : null,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarOpacity: 1.0,
        bottomOpacity: 1.0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: CommanColor.whiteBlack(context),
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Credits',
          style: TextStyle(
            color: CommanColor.whiteBlack(context),
            fontSize: screenWidth > 450 ? 22 : 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Container(
        decoration: isVintage
            ? BoxDecoration(
                color:
                    isDark ? CommanColor.black : themeProvider.backgroundColor,
                image: DecorationImage(
                  image: AssetImage(Images.bgImage(context)),
                  fit: BoxFit.cover,
                ),
              )
            : BoxDecoration(
                color: isDark
                    ? CommanColor.darkPrimaryColor
                    : themeProvider.backgroundColor,
              ),
        // Avoid extra top inset (especially on iPad with visible app bar)
        child: SafeArea(
          top: false,
          bottom: true, // Enable bottom safe area for iPad
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: screenWidth > 450 ? 20 : 16,
                    right: screenWidth > 450 ? 20 : 16,
                    top: screenWidth > 450 ? 20 : 16,
                    bottom: screenWidth > 450 ? 20 : 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Current Credits Display
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(screenWidth > 450 ? 24 : 20),
                        decoration: BoxDecoration(
                          color: isDark
                              ? CommanColor.darkPrimaryColor.withOpacity(0.8)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Your Credits',
                              style: TextStyle(
                                color: CommanColor.whiteBlack(context)
                                    .withOpacity(0.7),
                                fontSize: screenWidth > 450 ? 16 : 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$_currentCredits',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : CommanColor.lightDarkPrimary(context),
                                fontSize: screenWidth > 450 ? 48 : 40,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Answer Length Selection Section
                      Text(
                        'Answer Length',
                        style: TextStyle(
                          color: CommanColor.whiteBlack(context),
                          fontSize: screenWidth > 450 ? 20 : 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildAnswerLengthCard(context, screenWidth, isDark),
                      const SizedBox(height: 24),

                      // Free Credits Section
                      Text(
                        'Free Credits',
                        style: TextStyle(
                          color: CommanColor.whiteBlack(context),
                          fontSize: screenWidth > 450 ? 20 : 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildFreeCreditCard(
                        context,
                        screenWidth,
                        isDark,
                        icon: Icons.monetization_on,
                        title: '20 Credits',
                        subtitle: 'Every 15 min',
                        buttonText: _claimCooldownSeconds > 0
                            ? 'Wait ${_claimCooldownSeconds ~/ 60}m ${(_claimCooldownSeconds % 60).toString().padLeft(2, '0')}s'
                            : 'Claim',
                        onTap: _claimFreeCredits,
                        // isDisabled: _claimCooldownSeconds > 0,
                      ),
                      const SizedBox(height: 12),
                      _buildFreeCreditCard(
                        context,
                        screenWidth,
                        isDark,
                        icon: Icons.card_giftcard,
                        title: 'Gift Credits',
                        subtitle: 'Get 50 credits \n(2 ads per day)',
                        buttonText: 'Watch Ad',
                        onTap: _watchAdForCredits,
                        buttonOpacity: _hasWatchedMaxAds ? 0.5 : 1.0,
                      ),
                      const SizedBox(height: 32),

                      // Buy Credits Section
                      Text(
                        'Buy Credits',
                        style: TextStyle(
                          color: CommanColor.whiteBlack(context),
                          fontSize: screenWidth > 450 ? 20 : 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._buildBuyCreditCards(context, screenWidth, isDark),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFreeCreditCard(
    BuildContext context,
    double screenWidth,
    bool isDark, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onTap,
    bool isDisabled = false,
    double buttonOpacity = 1.0,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return Container(
      padding: EdgeInsets.all(screenWidth > 450 ? 16 : 14),
      decoration: BoxDecoration(
        color: isDark
            ? CommanColor.darkPrimaryColor.withOpacity(0.8)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: screenWidth > 450 ? 50 : 45,
            height: screenWidth > 450 ? 50 : 45,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.15)
                  : CommanColor.lightDarkPrimary(context).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color:
                  isDark ? Colors.white : CommanColor.lightDarkPrimary(context),
              size: screenWidth > 450 ? 28 : 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: CommanColor.whiteBlack(context),
                    fontSize: screenWidth > 450 ? 18 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: CommanColor.whiteBlack(context).withOpacity(0.6),
                      fontSize: screenWidth > 450 ? 14 : 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Opacity(
            opacity: buttonOpacity,
            child: Container(
              decoration: BoxDecoration(
                color: isDisabled
                    ? CommanColor.lightDarkPrimary(context).withOpacity(0.6)
                    : CommanColor.lightDarkPrimary(context),
                borderRadius: BorderRadius.circular(8),
                border: isDark
                    ? Border.all(
                        color: Colors.white,
                        width: 1.5,
                      )
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isDisabled ? null : onTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: screenWidth > 450 ? 150 : 130,
                    height: screenWidth > 450 ? 46 : 42,
                    alignment: Alignment.center,
                    child: Text(
                      buttonText,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth > 450 ? 14 : 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBuyCreditCards(
    BuildContext context,
    double screenWidth,
    bool isDark,
  ) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final widgets = <Widget>[];

    // Match products with coin packs
    debugPrint(
        'WalletScreen: Building credit cards - _coinPacks count: ${_coinPacks.length}');

    // If _coinPacks is empty, use constants directly
    if (_coinPacks.isEmpty) {
      debugPrint('WalletScreen: _coinPacks is empty, loading from constants');
      _loadCoinPacksFromConstants();
      return widgets; // Return empty for now, will rebuild after setState
    }

    for (var pack in _coinPacks) {
      final identifier = pack['identifier'] as String;
      final credits = pack['credits']?.toString() ?? '0';
      final discount = pack['discount']?.toString() ?? '0';
      // Read price directly from pack - this will be the latest value since we're iterating over _coinPacks
      final priceFromConstants = (pack['price']?.toString() ?? '').trim();
      debugPrint(
          'WalletScreen: Building card for $identifier - Credits: $credits, Price: "$priceFromConstants", isEmpty: ${priceFromConstants.isEmpty}, _coinPacks.length: ${_coinPacks.length}');

      ProductDetails? product;
      try {
        product = _products.firstWhere(
          (p) => p.id == identifier,
        );
      } catch (e) {
        // Product not loaded yet, will show loading state
        product = null;
      }

      final isBestValue =
          false; // Remove default selection - only show when actually selected

      final isSelected = _selectedProductId == identifier;

      widgets.add(
        Padding(
          key: ValueKey('credit_card_$identifier'), // Add key to force rebuild
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: (_loadingProductId == product?.id && product != null)
                  ? null
                  : () async {
                      // Check internet connection first before proceeding
                      final hasInternet =
                          await InternetConnection().hasInternetAccess;
                      if (!hasInternet) {
                        // Clear any loading state when offline
                        if (mounted) {
                          setState(() {
                            _loadingProductId = null;
                          });
                        }
                        Constants.showToast("Check your internet connection.");
                        return;
                      }
                      if (product == null) {
                        // Clear any loading state when product is null
                        if (mounted) {
                          setState(() {
                            _loadingProductId = null;
                          });
                        }
                        Constants.showToast("Check your internet connection.");
                        return;
                      }
                      if (!_isAvailable) return;
                      setState(() {
                        _selectedProductId = identifier;
                      });
                      _buyCoinPack(product!);
                    },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.all(screenWidth > 450 ? 16 : 14),
                decoration: BoxDecoration(
                  color: isDark
                      ? CommanColor.darkPrimaryColor.withOpacity(0.8)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.5)
                              : Colors.grey.withOpacity(0.5),
                          width: 2,
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: screenWidth > 450 ? 50 : 45,
                      height: screenWidth > 450 ? 50 : 45,
                      decoration: BoxDecoration(
                        color: isDark
                            ? CommanColor.lightDarkPrimary(context)
                                .withOpacity(0.2)
                            : CommanColor.lightDarkPrimary(context)
                                .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.monetization_on,
                        color: isDark
                            ? Colors.white
                            : CommanColor.lightDarkPrimary(context),
                        size: screenWidth > 450 ? 28 : 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$credits Credits', // Credits amount from API response (sub_fields.item_1)
                            style: TextStyle(
                              color: CommanColor.whiteBlack(context),
                              fontSize: screenWidth > 450 ? 18 : 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IgnorePointer(
                          ignoring:
                              true, // Ignore button taps, parent InkWell handles it
                          child: ElevatedButton(
                            onPressed:
                                () {}, // Empty handler to keep button enabled appearance
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  CommanColor.lightDarkPrimary(context),
                              disabledBackgroundColor:
                                  CommanColor.lightDarkPrimary(context),
                              fixedSize: Size(
                                screenWidth > 450 ? 150 : 130,
                                screenWidth > 450 ? 46 : 42,
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth > 450 ? 20 : 16,
                                vertical: screenWidth > 450 ? 12 : 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: isDark
                                    ? const BorderSide(
                                        color: Colors.white,
                                        width: 1.5,
                                      )
                                    : BorderSide.none,
                              ),
                            ),
                            child: (_loadingProductId == product?.id &&
                                    product != null)
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.monetization_on,
                                        color:
                                            Colors.amber.shade700, // Gold color
                                        size: screenWidth > 450 ? 18 : 16,
                                      ),
                                      const SizedBox(width: 4),
                                      // Use priceFromConstants directly - it's already read from the current pack
                                      Text(
                                        () {
                                          // Determine display price
                                          String displayPrice;
                                          if (product != null &&
                                              product.price.isNotEmpty) {
                                            displayPrice = product.price;
                                          } else if (priceFromConstants
                                              .isNotEmpty) {
                                            displayPrice = priceFromConstants;
                                          } else {
                                            // Fallback: try to get price from constants directly
                                            String fallbackPrice = '';
                                            if (identifier ==
                                                BibleInfo.coinPack1Id) {
                                              fallbackPrice =
                                                  BibleInfo.coinPack1Price;
                                            } else if (identifier ==
                                                BibleInfo.coinPack2Id) {
                                              fallbackPrice =
                                                  BibleInfo.coinPack2Price;
                                            } else if (identifier ==
                                                BibleInfo.coinPack3Id) {
                                              fallbackPrice =
                                                  BibleInfo.coinPack3Price;
                                            }
                                            displayPrice =
                                                fallbackPrice.isNotEmpty
                                                    ? fallbackPrice
                                                    : 'Loading...';
                                          }

                                          debugPrint(
                                              'WalletScreen: Text for $identifier - priceFromConstants: "$priceFromConstants", product: ${product?.id}, displayPrice: "$displayPrice"');
                                          return displayPrice;
                                        }(),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize:
                                              screenWidth > 450 ? 14 : 13.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        if (discount != '0' && discount.isNotEmpty)
                          Positioned(
                            top: -8,
                            right: -8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '$discount%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildAnswerLengthCard(
    BuildContext context,
    double screenWidth,
    bool isDark,
  ) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isVintage =
        themeProvider.currentCustomTheme == AppCustomTheme.vintage;

    String lengthDisplay = '';
    int cost = 0;
    switch (_currentAnswerLength) {
      case 'small':
        lengthDisplay = 'Small Answer';
        cost = 20;
        break;
      case 'medium':
        lengthDisplay = 'Medium Answer';
        cost = 50;
        break;
      case 'large':
        lengthDisplay = 'Full Study Answer';
        cost = 100;
        break;
    }

    return Container(
      padding: EdgeInsets.all(screenWidth > 450 ? 16 : 14),
      decoration: BoxDecoration(
        color: isDark
            ? CommanColor.darkPrimaryColor.withOpacity(0.8)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showAnswerLengthDialog(context, screenWidth, isDark),
        child: Row(
          children: [
            Container(
              width: screenWidth > 450 ? 50 : 45,
              height: screenWidth > 450 ? 50 : 45,
              decoration: BoxDecoration(
                color: isDark
                    ? CommanColor.lightDarkPrimary(context).withOpacity(0.2)
                    : CommanColor.lightDarkPrimary(context).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.text_fields,
                color: isDark
                    ? Colors.white
                    : CommanColor.lightDarkPrimary(context),
                size: screenWidth > 450 ? 28 : 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lengthDisplay,
                    style: TextStyle(
                      color: CommanColor.whiteBlack(context),
                      fontSize: screenWidth > 450 ? 18 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$cost Credits per response',
                    style: TextStyle(
                      color: CommanColor.whiteBlack(context).withOpacity(0.6),
                      fontSize: screenWidth > 450 ? 14 : 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: CommanColor.whiteBlack(context).withOpacity(0.5),
              size: screenWidth > 450 ? 18 : 16,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAnswerLengthDialog(
    BuildContext context,
    double screenWidth,
    bool isDark,
  ) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isVintage =
        themeProvider.currentCustomTheme == AppCustomTheme.vintage;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: isDark ? CommanColor.darkPrimaryColor : Colors.white,
          child: Container(
            padding: EdgeInsets.all(screenWidth > 450 ? 24 : 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  textAlign: TextAlign.center,
                  '    Choose Answer Length',
                  style: TextStyle(
                    color: CommanColor.whiteBlack(context),
                    fontSize: screenWidth > 450 ? 22 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _buildAnswerLengthOption(
                  context,
                  screenWidth,
                  isDark,
                  'small',
                  'Short Answer - 20 Credits',
                  'Simple explanation',
                  20,
                ),
                const SizedBox(height: 12),
                _buildAnswerLengthOption(
                  context,
                  screenWidth,
                  isDark,
                  'medium',
                  'Medium Answer - 50 Credits',
                  'Contextual explanation',
                  50,
                ),
                const SizedBox(height: 12),
                _buildAnswerLengthOption(
                  context,
                  screenWidth,
                  isDark,
                  'large',
                  'Full Study Answer - 100 Credits',
                  'Long, detailed explanation',
                  100,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: CommanColor.whiteBlack(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnswerLengthOption(
    BuildContext context,
    double screenWidth,
    bool isDark,
    String length,
    String title,
    String description,
    int cost,
  ) {
    final isSelected = _currentAnswerLength == length;

    return InkWell(
      onTap: () async {
        await WalletService.setAnswerLength(length);
        await _loadAnswerLength();
        if (mounted) {
          Navigator.pop(context);
          Constants.showToast('Answer length set to ${title.split(' - ')[0]}');
        }
      },
      child: Container(
        padding: EdgeInsets.all(screenWidth > 450 ? 16 : 14),
        decoration: BoxDecoration(
          color: isSelected
              ? CommanColor.lightDarkPrimary(context).withOpacity(0.1)
              : (isDark
                  ? CommanColor.darkPrimaryColor.withOpacity(0.3)
                  : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(
                  color: CommanColor.lightDarkPrimary(context),
                  width: 2,
                )
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? CommanColor.lightDarkPrimary(context)
                      : CommanColor.whiteBlack(context).withOpacity(0.3),
                  width: 2,
                ),
                color: isSelected
                    ? CommanColor.lightDarkPrimary(context)
                    : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: CommanColor.whiteBlack(context),
                      fontSize: screenWidth > 450 ? 16 : 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: CommanColor.whiteBlack(context).withOpacity(0.7),
                      fontSize: screenWidth > 450 ? 13 : 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// iOS Payment Queue Delegate implementation
class _WalletPaymentQueueDelegate implements SKPaymentQueueDelegateWrapper {
  @override
  bool shouldContinueTransaction(
      SKPaymentTransactionWrapper transaction, SKStorefrontWrapper storefront) {
    return true;
  }

  @override
  bool shouldShowPriceConsent() {
    return false;
  }
}
