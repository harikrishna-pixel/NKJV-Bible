import 'dart:async';
import 'package:biblebookapp/utils/internet_speed_checker.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:flutter/material.dart';

enum NetworkStatus { good, slow, none }

class ConnectionSpeedBanner extends StatefulWidget {
  final int thresholdMs;
  final Widget? child;
  final VoidCallback? onNoInternet;

  const ConnectionSpeedBanner({
    super.key,
    this.thresholdMs = 6500,
    this.child,
    this.onNoInternet,
  });

  @override
  State<ConnectionSpeedBanner> createState() => _ConnectionSpeedBannerState();
}

class _ConnectionSpeedBannerState extends State<ConnectionSpeedBanner>
    with WidgetsBindingObserver {
  NetworkStatus _lastStatus = NetworkStatus.good;
  bool _isAppActive = true;
  bool _hasShownNoInternetToast = false;
  DateTime? _lastToastTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startMonitoring();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _isAppActive = state == AppLifecycleState.resumed;
  }

  void _startMonitoring() {
    _checkContinuously();
  }

  Future<void> _checkContinuously() async {
    while (mounted) {
      if (_isAppActive) {
        final speed = await InternetSpeedChecker.checkSpeed();
        if (!mounted) return;

        NetworkStatus currentStatus;
        if (speed == null) {
          currentStatus = NetworkStatus.none;
        } else if (speed > widget.thresholdMs) {
          currentStatus = NetworkStatus.slow;
        } else {
          currentStatus = NetworkStatus.good;
        }

        if (currentStatus != _lastStatus) {
          _lastStatus = currentStatus;

          if (currentStatus == NetworkStatus.none) {
            if (!_hasShownNoInternetToast) {
              _showToast("❌ No Internet Connection");
              _hasShownNoInternetToast = true;
            }
            // widget.onNoInternet?.call();
          } else if (currentStatus == NetworkStatus.slow) {
            _showToast("⚠️ Slow Internet Connection");
          } else {
            debugPrint("✅ Back online");
            _hasShownNoInternetToast =
                false; // Reset so it can show again if offline later
          }
        }
      }

      await Future.delayed(const Duration(seconds: 5));
    }
  }

  void _showToast(String message) {
    final now = DateTime.now();
    if (_lastToastTime == null ||
        now.difference(_lastToastTime!).inSeconds >= 200) {
      _lastToastTime = now;
      Constants.showToast(message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child ?? const SizedBox.shrink();
  }
}
