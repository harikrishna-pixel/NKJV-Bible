import 'package:biblebookapp/view/widget/thanks_for_love_rating_dialog_content.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
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
                // Same as Settings Rate Us: do not block on Connectivity().
                // That check often false-fails after Share and shows
                // "Check your Internet connection" with no App Store action.
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

  /// Requests in-app review; if unavailable, opens the App Store listing
  /// (matches "Rate Us on the App Store" button).
  static Future<void> _requestReview() async {
    final InAppReview inAppReview = InAppReview.instance;

    final isAvailable = await inAppReview.isAvailable();
    debugPrint('Is Available: $isAvailable');
    if (isAvailable) {
      try {
        await inAppReview.requestReview();
        return;
      } catch (e, st) {
        debugPrint('Error: $e,$st');
      }
    }
    try {
      await inAppReview.openStoreListing(appStoreId: BibleInfo.apple_AppId);
    } catch (e, st) {
      Constants.showToast("Could not open the App Store. Please try again.");
      debugPrint('openStoreListing error: $e,$st');
    }
  }
}

