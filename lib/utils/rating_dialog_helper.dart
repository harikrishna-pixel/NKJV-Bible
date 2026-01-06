import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:provider/provider.dart';

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

    final isTablet = MediaQuery.of(context).size.width > 600;
    final dialogWidth = isTablet ? 400.0 : double.infinity;
    final screenWidth = MediaQuery.of(context).size.width;

    // Await showDialog to ensure dialog is shown and wait for user interaction
    // This will pause execution until dialog is dismissed
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
        final isDark = themeProvider.themeMode == ThemeMode.dark;
        return Dialog(
          backgroundColor: isDark
              ? CommanColor.white
              : CommanColor.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: dialogWidth,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                        },
                        child: const Icon(
                          Icons.close,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const Text("😍", style: TextStyle(fontSize: 40)),
                const SizedBox(height: 15),
                Text(
                  "Thanks for Sharing!💛",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isTablet ? 26 : 22, // Increased font size
                    color: CommanColor.black,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Your quick rating helps more people experience God's Word too!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isTablet
                        ? 20
                        : screenWidth < 380
                            ? 17
                            : 18, // Increased font size
                    color: CommanColor.black,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown,
                  ),
                  child: Text(
                    "Rate the app",
                    style: TextStyle(
                      color: CommanColor.white,
                      fontSize: isTablet ? 18 : null,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    "Later",
                    style: TextStyle(
                      color: CommanColor.black,
                      fontSize: isTablet ? 17 : null,
                    ),
                  ),
                ),
              ],
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

