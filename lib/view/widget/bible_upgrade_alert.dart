import 'dart:async';
import 'dart:io';

import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:upgrader/upgrader.dart';
import 'package:url_launcher/url_launcher.dart';

class BibleUpgradeAlert extends UpgradeAlert {
  BibleUpgradeAlert({
    super.key,
    super.upgrader,
    super.barrierDismissible,
    super.dialogStyle,
    super.onIgnore,
    super.onLater,
    super.onUpdate,
    super.shouldPopScope,
    super.showIgnore,
    super.showLater,
    super.showReleaseNotes,
    super.cupertinoButtonTextStyle,
    super.dialogKey,
    super.navigatorKey,
    super.child,
  });

  @override
  BibleUpgradeAlertState createState() => BibleUpgradeAlertState();
}

class BibleUpgradeAlertState extends UpgradeAlertState {
  static const Color _dialogCream = Color(0xFFFFF9F3);
  static const Color _ink = Color(0xFF4B3423);
  static const Color _muted = Color(0xFF6B4E3D);
  static const Color _notesBg = Color(0xFFF3E6D6);
  static const Color _secondaryBtnBg = Color(0xFFF7EDE2);
  static const Color _accent = Color(0xFFE8874A);
  static const Duration _kIntroRemindLaterDelay = Duration(days: 3);
  static const Duration _kPresentationRecheckDelay =
      Duration(milliseconds: 200);

  Timer? _presentationRecheckTimer;

  @override
  void dispose() {
    _presentationRecheckTimer?.cancel();
    super.dispose();
  }

  @override
  void checkVersion({required BuildContext context}) {
    unawaited(_checkVersionPhased(context));
  }

  Future<bool> _shouldHoldUpgradePresentation(BuildContext context) async {
    final defer =
        await SharPreferences.getBoolean(SharPreferences.deferUpgradeAlert) ??
            false;
    if (defer) return true;

    final navContext = widget.navigatorKey?.currentContext ?? context;
    final navigator = Navigator.of(navContext, rootNavigator: true);
    return navigator.canPop();
  }

  void _scheduleUpgradePresentationRecheck(BuildContext context) {
    _presentationRecheckTimer?.cancel();
    _presentationRecheckTimer = Timer(_kPresentationRecheckDelay, () {
      if (!mounted) return;
      displayed = false;
      _checkVersionPhased(context);
    });
  }

  Future<void> _openAppStoreListing() async {
    final uri = Platform.isIOS
        ? Uri.parse('https://itunes.apple.com/app/id${BibleInfo.apple_AppId}')
        : Uri.parse(
            'https://play.google.com/store/apps/details?id=${(await PackageInfo.fromPlatform()).packageName}',
          );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void onUserUpdated(BuildContext context, bool shouldPop) {
    if (widget.upgrader.state.debugLogging) {
      debugPrint('upgrader: button tapped: update now');
    }

    final doProcess = widget.onUpdate?.call() ?? true;
    if (doProcess) {
      unawaited(_openAppStoreListing());
    }

    // Do not show the update alert again after Update is tapped.
    unawaited(SharPreferences.setBoolean(
      SharPreferences.upgradeAlertDismissedPermanently,
      true,
    ));
    unawaited(widget.upgrader.saveLastAlerted());

    if (shouldPop) {
      popNavigator(context);
    }
  }

  Widget _buildStoreFooterNote() {
    final storeLabel = Platform.isIOS ? 'App Store' : 'Play Store';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline,
          size: 18,
          color: _muted.withOpacity(0.85),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: _muted,
                fontWeight: FontWeight.w500,
              ),
              children: [
                const TextSpan(
                  text: 'You can always update from the ',
                ),
                TextSpan(
                  text: storeLabel,
                  style: const TextStyle(
                    color: _accent,
                    fontWeight: FontWeight.w700,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => unawaited(_openAppStoreListing()),
                ),
                const TextSpan(text: ' later.'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _dismissUpgradePermanently(BuildContext context) async {
    await SharPreferences.setBoolean(
      SharPreferences.upgradeAlertDismissedPermanently,
      true,
    );
    await widget.upgrader.saveLastAlerted();
    if (context.mounted) {
      popNavigator(context);
    }
  }

  Future<void> _checkVersionPhased(BuildContext context) async {
    if (!widget.upgrader.shouldDisplayUpgrade()) return;

    final permanentlyDismissed = await SharPreferences.getBoolean(
            SharPreferences.upgradeAlertDismissedPermanently) ??
        false;
    if (permanentlyDismissed) return;

    final checkContext = widget.navigatorKey != null &&
            widget.navigatorKey!.currentContext != null
        ? widget.navigatorKey!.currentContext!
        : context;

    if (await _shouldHoldUpgradePresentation(checkContext)) {
      _scheduleUpgradePresentationRecheck(checkContext);
      return;
    }

    final remindAtStr = await SharPreferences.getString(
        SharPreferences.upgradeIntroRemindLaterAt);

    if (remindAtStr != null) {
      final remindedAt = DateTime.tryParse(remindAtStr);
      if (remindedAt != null) {
        final elapsed = DateTime.now().difference(remindedAt);
        if (elapsed < _kIntroRemindLaterDelay) {
          return;
        }
      }
    }

    if (await _shouldHoldUpgradePresentation(checkContext)) {
      _scheduleUpgradePresentationRecheck(checkContext);
      return;
    }

    if (displayed) return;
    displayed = true;

    final appMessages = widget.upgrader.determineMessages(checkContext);
    final title = appMessages.message(UpgraderMessage.title) ?? '';
    final message = widget.upgrader.body(appMessages);
    final releaseNotes =
        shouldDisplayReleaseNotes ? widget.upgrader.releaseNotes : null;

    if (remindAtStr == null) {
      _showIntroTheDialog(
        key: widget.dialogKey ?? const Key('upgrader_intro_alert_dialog'),
        context: checkContext,
        title: title,
        message: message,
        releaseNotes: releaseNotes,
        messages: appMessages,
      );
      return;
    }

    unawaited(widget.upgrader.saveLastAlerted());
    showGeneralDialog(
      barrierDismissible: widget.barrierDismissible,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 280),
      context: checkContext,
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return PopScope(
          canPop: onCanPop(),
          child: alertDialog(
            widget.dialogKey ?? const Key('upgrader_alert_dialog'),
            title,
            message,
            releaseNotes,
            dialogContext,
            false,
            appMessages,
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  void _showIntroTheDialog({
    Key? key,
    required BuildContext context,
    required String title,
    required String message,
    required String? releaseNotes,
    required UpgraderMessages messages,
  }) {
    unawaited(widget.upgrader.saveLastAlerted());

    showGeneralDialog(
      barrierDismissible: widget.barrierDismissible,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 280),
      context: context,
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return PopScope(
          canPop: onCanPop(),
          child: _buildIntroAlertDialog(
            key,
            title,
            message,
            releaseNotes,
            dialogContext,
            messages,
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildIntroAlertDialog(
    Key? key,
    String title,
    String message,
    String? releaseNotes,
    BuildContext context,
    UpgraderMessages messages,
  ) {
    final notes = shouldDisplayReleaseNotes ? releaseNotes : null;

    return Dialog(
      key: key,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 56),
      child: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.72,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: _dialogCream,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.14),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () =>
                          unawaited(_dismissUpgradePermanently(context)),
                      icon: const Icon(
                        Icons.close,
                        size: 20,
                        color: Color(0xFF7A5A3A),
                      ),
                    ),
                  ),
                  _buildHeaderIcon(),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatUpdateMessageForDisplay(
                      message,
                      messages.message(UpgraderMessage.prompt),
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.35,
                      color: _muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (notes != null && notes.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildReleaseNotesCard(
                      messages.message(UpgraderMessage.releaseNotes) ??
                          'Release Notes',
                      notes,
                    ),
                  ],
                  const SizedBox(height: 12),
                  _buildPrimaryButton(
                    title: messages.message(UpgraderMessage.buttonTitleUpdate) ??
                        'UPDATE NOW',
                    subtitle: 'Get the latest version',
                    onPressed: () =>
                        onUserUpdated(context, !widget.upgrader.blocked()),
                  ),
                  const SizedBox(height: 10),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => unawaited(_onIntroRemindLater(context)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          children: [
                            Text(
                              'Remind Later',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: _accent,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Not now? We\'ll remind you again in 3 days.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.3,
                                color: _muted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: _muted.withOpacity(0.25),
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'or',
                          style: TextStyle(
                            fontSize: 12,
                            color: _muted.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: _muted.withOpacity(0.25),
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildStoreFooterNote(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onIntroRemindLater(BuildContext context) async {
    await SharPreferences.setString(
      SharPreferences.upgradeIntroRemindLaterAt,
      DateTime.now().toIso8601String(),
    );
    await widget.upgrader.saveLastAlerted();
    if (context.mounted) {
      popNavigator(context);
    }
  }

  @override
  Widget alertDialog(
    Key? key,
    String title,
    String message,
    String? releaseNotes,
    BuildContext context,
    bool cupertino,
    UpgraderMessages messages,
  ) {
    // Remind-later follow-up: only Update CTA (no Ignore / Later).
    final notes = shouldDisplayReleaseNotes ? releaseNotes : null;

    return Dialog(
      key: key,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 56),
      child: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.72,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: _dialogCream,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.14),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () =>
                          unawaited(_dismissUpgradePermanently(context)),
                      icon: const Icon(
                        Icons.close,
                        size: 20,
                        color: Color(0xFF7A5A3A),
                      ),
                    ),
                  ),
                  _buildHeaderIcon(),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatUpdateMessageForDisplay(
                      message,
                      messages.message(UpgraderMessage.prompt),
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.35,
                      color: _muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (notes != null && notes.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildReleaseNotesCard(
                      messages.message(UpgraderMessage.releaseNotes) ??
                          'Release Notes',
                      notes,
                    ),
                  ],
                  const SizedBox(height: 12),
                  _buildPrimaryButton(
                    title: messages.message(UpgraderMessage.buttonTitleUpdate) ??
                        'UPDATE NOW',
                    subtitle: 'Get the latest version',
                    onPressed: () =>
                        onUserUpdated(context, !widget.upgrader.blocked()),
                  ),
                  const SizedBox(height: 10),
                  _buildStoreFooterNote(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIcon() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.asset(
        Images.appIcon1024,
        height: 64,
        width: 64,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            'assets/new_logos.jpg',
            height: 64,
            width: 64,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.menu_book_rounded,
              size: 30,
              color: _ink,
            ),
          ),
        ),
      ),
    );
  }

  /// Display-only: one concise update line (no upgrader logic changes).
  String _formatUpdateMessageForDisplay(String message, String? prompt) {
    final body = message.trim();
    final promptText = prompt?.trim() ?? '';

    final versionMatch = RegExp(
      r'Version\s+([\d.]+)\s+is\s+now\s+available[-\s–]*you\s+have\s+([\d.]+)',
      caseSensitive: false,
    ).firstMatch(body);
    if (versionMatch != null) {
      final newVersion = versionMatch.group(1);
      final currentVersion = versionMatch.group(2);
      return 'Version $newVersion of ${BibleInfo.bible_shortName} is available. You\'re on $currentVersion.';
    }

    if (body.isNotEmpty) {
      // Drop redundant follow-up when the primary CTA already asks to update.
      if (promptText.isNotEmpty &&
          RegExp(
            r'would you like|update it now|update now',
            caseSensitive: false,
          ).hasMatch(promptText)) {
        return body;
      }
      if (promptText.isNotEmpty && !body.toLowerCase().contains(promptText.toLowerCase())) {
        return '$body $promptText';
      }
      return body;
    }

    return promptText;
  }

  Widget _buildReleaseNotesCard(String heading, String notes) {
    final items = notes
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map((line) => line.replaceFirst(RegExp(r'^[-*•]\s*'), ''))
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: _notesBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.description_outlined,
                size: 16,
                color: _ink,
              ),
              const SizedBox(width: 6),
              Text(
                heading,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 120),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: items
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 6, right: 8),
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: _accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                item,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.35,
                                  color: _muted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: _secondaryBtnBg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: _ink, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _muted,
                          fontWeight: FontWeight.w500,
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
    );
  }

  Widget _buildPrimaryButton({
    required String title,
    required String subtitle,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFF09A57),
                  Color(0xFFE8874A),
                  Color(0xFFD4692A),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _accent.withOpacity(0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.download_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.92),
                            fontWeight: FontWeight.w500,
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
