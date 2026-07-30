import 'package:biblebookapp/controller/api_service.dart';
import 'package:biblebookapp/services/wallet_service.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/authenitcation/widgets/text_form_field.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:flutter/material.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';

class ReferralCodeBottomSheet extends StatefulWidget {
  const ReferralCodeBottomSheet({
    super.key,
    this.email = '',
    this.password = '',
    this.ownReferralCode,
    this.initialReferredBy,
    this.initialReferralRewardClaimed,
    this.useLoggedInSession = false,
  });

  final String email;
  final String password;
  final String? ownReferralCode;
  final String? initialReferredBy;
  final int? initialReferralRewardClaimed;
  /// When true, apply via profile API (Account section) — no password needed.
  final bool useLoggedInSession;

  static Future<void> show({
    required BuildContext context,
    required String email,
    required String password,
    String? ownReferralCode,
    String? initialReferredBy,
    int? initialReferralRewardClaimed,
  }) {
    // Do not open the sheet when this account already used a referral.
    final alreadyReferred =
        (initialReferredBy != null && initialReferredBy.trim().isNotEmpty) ||
            ((initialReferralRewardClaimed ?? 0) > 0);
    if (alreadyReferred) {
      return Future.value();
    }

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final mediaQuery = MediaQuery.of(context);
        final keyboardHeight = mediaQuery.viewInsets.bottom;
        final availableHeight =
            mediaQuery.size.height - mediaQuery.padding.top - 8;

        return AnimatedPadding(
          padding: EdgeInsets.only(bottom: keyboardHeight),
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: availableHeight - keyboardHeight,
            ),
            child: ReferralCodeBottomSheet(
              email: email,
              password: password,
              ownReferralCode: ownReferralCode,
              initialReferredBy: initialReferredBy,
              initialReferralRewardClaimed: initialReferralRewardClaimed,
            ),
          ),
        );
      },
    ).whenComplete(() {
      FocusManager.instance.primaryFocus?.unfocus();
    });
  }

  /// Account section: enter a referral code while already signed in.
  static Future<void> showForLoggedInUser({
    required BuildContext context,
    String? ownReferralCode,
    String? initialReferredBy,
    int? initialReferralRewardClaimed,
  }) {
    final alreadyReferred =
        (initialReferredBy != null && initialReferredBy.trim().isNotEmpty) ||
            ((initialReferralRewardClaimed ?? 0) > 0);
    if (alreadyReferred) {
      Constants.showToast('Referral code already applied');
      return Future.value();
    }

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final mediaQuery = MediaQuery.of(context);
        final keyboardHeight = mediaQuery.viewInsets.bottom;
        final availableHeight =
            mediaQuery.size.height - mediaQuery.padding.top - 8;

        return AnimatedPadding(
          padding: EdgeInsets.only(bottom: keyboardHeight),
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: availableHeight - keyboardHeight,
            ),
            child: ReferralCodeBottomSheet(
              ownReferralCode: ownReferralCode,
              initialReferredBy: initialReferredBy,
              initialReferralRewardClaimed: initialReferralRewardClaimed,
              useLoggedInSession: true,
            ),
          ),
        );
      },
    ).whenComplete(() {
      FocusManager.instance.primaryFocus?.unfocus();
    });
  }

  @override
  State<ReferralCodeBottomSheet> createState() =>
      _ReferralCodeBottomSheetState();
}

class _ReferralCodeBottomSheetState extends State<ReferralCodeBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _referralController = TextEditingController();
  final _referralFocusNode = FocusNode();
  final _referralFieldKey = GlobalKey();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _referralFocusNode.addListener(_scrollReferralFieldIntoView);
  }

  void _scrollReferralFieldIntoView() {
    if (!_referralFocusNode.hasFocus) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 280), () {
        if (!mounted || !_referralFocusNode.hasFocus) return;
        final fieldContext = _referralFieldKey.currentContext;
        if (fieldContext == null) return;
        Scrollable.ensureVisible(
          fieldContext,
          alignment: 0.35,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      });
    });
  }

  @override
  void dispose() {
    _referralFocusNode.removeListener(_scrollReferralFieldIntoView);
    _referralFocusNode.dispose();
    _referralController.dispose();
    super.dispose();
  }

  void _dismissKeyboard() {
    _referralFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _submitReferral() async {
    _dismissKeyboard();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    try {
      if (widget.useLoggedInSession) {
        await applyReferralWhileLoggedIn(
          referralCode: _referralController.text.trim(),
          ownReferralCode: widget.ownReferralCode,
          initialReferredBy: widget.initialReferredBy,
          initialReferralRewardClaimed: widget.initialReferralRewardClaimed,
        );
      } else {
        await applyReferralViaLogin(
          email: widget.email,
          password: widget.password,
          referralCode: _referralController.text.trim(),
          ownReferralCode: widget.ownReferralCode,
          initialReferredBy: widget.initialReferredBy,
        );
      }
      const rewardCredits = 100;
      final appliedReferralCode = _referralController.text.trim();
      await WalletService.addCredits(rewardCredits);
      // Notify backend that the referee reward was claimed (also credits referrer).
      await updateReferralRewardClaimed(
        value: rewardCredits,
        referredBy: appliedReferralCode,
      );
      if (!mounted) return;
      _dismissKeyboard();
      Navigator.of(context).pop();
      Constants.showToast('You received 100 free coins!');
    } catch (e) {
      final message = e is String ? e : e.toString();
      final lower = message.toLowerCase();
      final loggedInFallback =
          'Unable to apply referral code. Please check the code and try again.';
      // Always show a referral-specific message for apply failures.
      if (lower.contains('invalid referral') ||
          lower.contains('own referral') ||
          lower.contains('already applied') ||
          lower.contains('please enter') ||
          lower.contains('unable to apply') ||
          lower.contains('sign out and sign in') ||
          lower.contains('no internet') ||
          lower.contains('something went wrong') ||
          (!widget.useLoggedInSession && lower.contains('sign up'))) {
        Constants.showToast(message);
      } else if (widget.useLoggedInSession) {
        Constants.showToast(loggedInFallback);
      } else {
        Constants.showToast('Enter this referral code on the Sign Up screen');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDark = Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark;
    final primary = CommanColor.lightDarkPrimary(context);
    final sheetBg = isDark ? CommanColor.darkPrimaryColor : Colors.white;
    final subtitleColor = isDark
        ? Colors.white.withOpacity(0.75)
        : CommanColor.weekendColor(context);

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 40),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.only(bottom: 8),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primary,
                        primary.withOpacity(0.82),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    screenWidth > 450 ? 24 : 20,
                    12,
                    screenWidth > 450 ? 24 : 20,
                    screenWidth > 450 ? 28 : 24,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: screenWidth > 450 ? 64 : 56,
                        height: screenWidth > 450 ? 64 : 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.35),
                          ),
                        ),
                        child: Icon(
                          Icons.card_giftcard_rounded,
                          color: Colors.white,
                          size: screenWidth > 450 ? 32 : 28,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Have a Referral Code?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth > 450
                              ? BibleInfo.fontSizeScale * 24
                              : BibleInfo.fontSizeScale * 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: BibleInfo.letterSpacing,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter a friend\'s referral code and unlock a welcome reward.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.92),
                          fontSize: screenWidth > 450
                              ? BibleInfo.fontSizeScale * 16
                              : BibleInfo.fontSizeScale * 14,
                          height: 1.35,
                          letterSpacing: BibleInfo.letterSpacing,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      if (!widget.useLoggedInSession)
                        Text(
                          'New accounts: enter the code on Sign Up for best results.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: screenWidth > 450
                                ? BibleInfo.fontSizeScale * 14
                                : BibleInfo.fontSizeScale * 12,
                            height: 1.3,
                            letterSpacing: BibleInfo.letterSpacing,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: 18),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth > 450 ? 18 : 14,
                          vertical: screenWidth > 450 ? 12 : 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.28),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.monetization_on_rounded,
                              color: const Color(0xFFFFD54F),
                              size: screenWidth > 450 ? 24 : 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '+100 Free Coins',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth > 450
                                    ? BibleInfo.fontSizeScale * 17
                                    : BibleInfo.fontSizeScale * 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: BibleInfo.letterSpacing,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    screenWidth > 450 ? 24 : 20,
                    screenWidth > 450 ? 24 : 20,
                    screenWidth > 450 ? 24 : 20,
                    screenWidth > 450 ? 20 : 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.06)
                              : primary.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.1)
                                : primary.withOpacity(0.12),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.people_outline_rounded,
                                color: primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Use the referral code shared by someone who invited you to the app.',
                                style: TextStyle(
                                  fontSize: screenWidth > 450
                                      ? BibleInfo.fontSizeScale * 15
                                      : BibleInfo.fontSizeScale * 13,
                                  color: subtitleColor,
                                  height: 1.4,
                                  letterSpacing: BibleInfo.letterSpacing,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Referral Code',
                        style: TextStyle(
                          fontSize: screenWidth > 450
                              ? BibleInfo.fontSizeScale * 16
                              : BibleInfo.fontSizeScale * 14,
                          fontWeight: FontWeight.w600,
                          color: CommanColor.whiteBlack(context),
                          letterSpacing: BibleInfo.letterSpacing,
                        ),
                      ),
                      const SizedBox(height: 10),
                      KeyedSubtree(
                        key: _referralFieldKey,
                        child: CustomTextFormField(
                          controller: _referralController,
                          focusNode: _referralFocusNode,
                          hintText: 'Enter referral code',
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.required(
                                errorText: 'Please enter a referral code'),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: _isSubmitting ? null : _submitReferral,
                        child: Container(
                          height: screenWidth > 450 ? 56 : 48,
                          decoration: BoxDecoration(
                            color: CommanColor.whiteLightModePrimary(context),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: primary.withOpacity(0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Center(
                            child: _isSubmitting
                                ? SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      color: CommanColor.darkModePrimaryWhite(
                                          context),
                                      strokeWidth: 2.2,
                                    ),
                                  )
                                : Text(
                                    'APPLY REFERRAL',
                                    style: TextStyle(
                                      letterSpacing: BibleInfo.letterSpacing,
                                      fontSize: screenWidth > 450
                                          ? BibleInfo.fontSizeScale * 18
                                          : BibleInfo.fontSizeScale * 14,
                                      fontWeight: FontWeight.w600,
                                      color: CommanColor.darkModePrimaryWhite(
                                          context),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: _isSubmitting
                            ? null
                            : () {
                                _dismissKeyboard();
                                Navigator.of(context).pop();
                              },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          foregroundColor: CommanColor.weekendColor(context),
                        ),
                        child: Text(
                          'Skip for now',
                          style: TextStyle(
                            fontSize: screenWidth > 450 ? 18 : 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: BibleInfo.letterSpacing,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
