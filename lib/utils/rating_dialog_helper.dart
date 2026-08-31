import 'package:biblebookapp/view/widget/thanks_for_love_rating_dialog_content.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';

class RatingDialogHelper {
  /// Shows rating dialog on first share action
  /// Returns true if dialog was shown, false if it was already shown before
  static Future<bool> showRatingDialogOnFirstShare(BuildContext context) async {
    // Check if rating dialog has been shown before
    final hasShown = await SharPreferences.getBoolean(
      SharPreferences.hasShownFirstShareRating,
    );

    debugPrint('RatingDialogHelper: hasShownFirstShareRating = $hasShown');

    if (hasShown == true) {
      // Already shown, don't show again
      debugPrint('RatingDialogHelper: Dialog already shown, skipping');
      return false;
    }

    // Show the rating dialog and wait for it to be dismissed
    // This ensures the dialog is visible before share action continues
    await _showRatingDialog(context);

    // Mark as shown after dialog is dismissed
    await SharPreferences.setBoolean(
      SharPreferences.hasShownFirstShareRating,
      true,
    );

    debugPrint('RatingDialogHelper: Dialog shown and marked as shown');
    return true;
  }

  /// Shows the rating dialog
  static Future<void> _showRatingDialog(BuildContext context) async {
    if (!context.mounted) {
      debugPrint('RatingDialogHelper: Context not mounted');
      return;
    }

    debugPrint('RatingDialogHelper: Showing rating dialog');

    // Await showDialog to ensure dialog is shown and wait for user interaction
    // This will pause execution until dialog is dismissed
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final isTablet = MediaQuery.of(dialogContext).size.width > 600;
        final dialogWidth = isTablet ? 400.0 : double.infinity;

        return Dialog(
          backgroundColor: CommanColor.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            width: dialogWidth,
            child: ThanksForLoveRatingDialogContent(
              onClose: () => Navigator.of(dialogContext).pop(),
              onRate: () async {
                Navigator.pop(dialogContext);
                // Check internet connection with retry mechanism for reliability
                bool hasConnection = false;
                for (int i = 0; i < 3; i++) {
                  try {
                    final connectivityResult =
                        await Connectivity().checkConnectivity();
                    // If result is empty (occasionally on first call), retry after delay
                    if (connectivityResult.isEmpty) {
                      if (i < 2) {
                        await Future.delayed(const Duration(milliseconds: 300));
                      }
                      continue;
                    }
                    hasConnection =
                        connectivityResult.contains(ConnectivityResult.mobile) ||
                        connectivityResult.contains(ConnectivityResult.wifi) ||
                        connectivityResult.contains(ConnectivityResult.ethernet);
                    // Empty result (e.g. on some 5G/configs) — assume connected for rate us
                    if (connectivityResult.isEmpty) hasConnection = true;
                    if (hasConnection) {
                      break; // Connection found, exit retry loop
                    }
                    // Wait a bit before retrying (only if not last attempt)
                    if (i < 2) {
                      await Future.delayed(const Duration(milliseconds: 300));
                    }
                  } catch (e) {
                    debugPrint('Connectivity check error: $e');
                    // Continue to next retry
                  }
                }

                if (!hasConnection) {
                  Constants.showToast("Check your Internet connection");
                  return;
                }
                await SharPreferences.setString('OpenAd', '1');
                await _requestReview();
              },
              onMaybeLater: () => Navigator.pop(dialogContext),
            ),
          ),
        );
      },
    );
  }

  /// Requests in-app review
  static Future<void> _requestReview() async {
    final InAppReview inAppReview = InAppReview.instance;

    final isAvailable = await inAppReview.isAvailable();
    debugPrint('Is Available: $isAvailable');
    if (isAvailable) {
      try {
        await inAppReview.requestReview();
      } catch (e, st) {
        Constants.showToast("review request failed");
        debugPrint('Error: $e,$st');
      }
    } else {
      Constants.showToast("review request not available, try again later");
    }
  }
}

