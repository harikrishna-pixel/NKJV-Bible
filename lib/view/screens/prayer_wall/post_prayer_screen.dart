import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/core/notifiers/cache.notifier.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_guidelines_dialog.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_join_sheet.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_local_store.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_models.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_screen.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_service.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_verify_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// "Post a Prayer" — POST `/api/prayers`. Duration/credits are UI-only (not sent to API).
class PostPrayerScreen extends StatefulWidget {
  const PostPrayerScreen({
    super.key,
    this.initialTitle,
    this.initialDescription,
    this.initialCategory,
  });

  /// GetX route id so Prayer Wall cannot push this screen twice.
  static const routeName = '/PostPrayerScreen';

  final String? initialTitle;
  final String? initialDescription;
  final String? initialCategory;

  @override
  State<PostPrayerScreen> createState() => _PostPrayerScreenState();
}

class _PostPrayerScreenState extends State<PostPrayerScreen> {
  static const List<String> _categories = [
    'Health',
    'Financial',
    'Job',
    'Family',
    'Gratitude',
    'Others',
  ];

  static const int _creditsPerDay = 100;

  final _titleCtrl = TextEditingController();
  final _detailsCtrl = TextEditingController();
  String _category = 'Others';
  int _durationDays = 30;
  // Anonymous posting UI disabled for now; posts use author name when provided.
  bool _isAnonymous = false;
  bool _submitting = false;
  /// Raw words from the Type Your Prayer step (any language).
  String _rawPrayerWords = '';
  /// Encoded original+AI payload for POST; the details field stays tag-free.
  String _encodedDetails = '';
  bool _openingDetailsComposer = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialTitle != null && widget.initialTitle!.trim().isNotEmpty) {
      _titleCtrl.text = _clip(widget.initialTitle!.trim(), 120);
    }
    if (widget.initialDescription != null &&
        widget.initialDescription!.trim().isNotEmpty) {
      final raw = widget.initialDescription!.trim();
      if (PrayerDualDescription.isDual(raw)) {
        _encodedDetails = raw;
        _detailsCtrl.text = _clip(
          (PrayerDualDescription.aiPrayer(raw) ??
                  PrayerDualDescription.myWords(raw) ??
                  raw)
              .trim(),
          500,
        );
      } else {
        _detailsCtrl.text = _clip(raw, 500);
      }
    }
    if (widget.initialCategory != null &&
        _categories.contains(widget.initialCategory)) {
      _category = widget.initialCategory!;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _onFirstFrame());
  }

  Future<void> _onFirstFrame() async {
    if (!mounted) return;

    final alreadyAccepted =
        await PrayerWallLocalStore.hasAcceptedPrayerWallJoinTerms();
    if (!mounted) return;

    if (!alreadyAccepted) {
      // Brief pause so the post form paints before the sheet slides up.
      await Future<void>.delayed(const Duration(milliseconds: 280));
      if (!mounted) return;
    }

    final accepted = await PrayerWallJoinSheet.ensureAccepted(context);
    if (!mounted) return;
    if (!accepted) {
      Navigator.of(context).pop();
      return;
    }
    if (!alreadyAccepted) {
      PrayerWallJoinSheet.showSuccessBanner(context);
    }
  }

  String _clip(String s, int max) =>
      s.length <= max ? s : s.substring(0, max);

  /// Opens Type Your Prayer → Review & Confirm; stores original + AI in details.
  Future<void> _openDetailsComposer() async {
    if (_submitting || _openingDetailsComposer) return;
    _openingDetailsComposer = true;
    try {
      final existingDesc = _detailsCtrl.text.trim();
      final seedWords = _rawPrayerWords.isNotEmpty
          ? _rawPrayerWords
          : (PrayerDualDescription.myWords(existingDesc) ??
              (PrayerDualDescription.isDual(existingDesc)
                  ? ''
                  : existingDesc));
      final result = await Navigator.of(context).push<_PrayerDetailsComposeResult>(
        MaterialPageRoute(
          builder: (_) => _PrayerDetailsComposeScreen(
            initialWords: seedWords,
          ),
        ),
      );
      if (!mounted || result == null) return;
      setState(() {
        _rawPrayerWords = result.originalWords;
        _encodedDetails = PrayerDualDescription.encode(
          originalWords: result.originalWords,
          englishPrayer: result.englishPrayer,
        );
        _detailsCtrl.text = result.englishPrayer.trim();
      });
    } finally {
      _openingDetailsComposer = false;
    }
  }

  int get _totalCredits => _durationDays * _creditsPerDay;

  DateTime get _startDate => DateTime.now();
  DateTime get _endDate =>
      _startDate.add(Duration(days: _durationDays - 1)); // inclusive display

  String? _extractPrayerId(dynamic value) {
    if (value is! Map) return null;
    final map = Map<String, dynamic>.from(value);

    final direct = (map['_id'] ?? map['id'])?.toString().trim();
    if (direct != null && direct.isNotEmpty) return direct;

    final nestedCandidates = [
      map['data'],
      map['prayer'],
      map['result'],
      map['item'],
      map['payload'],
    ];
    for (final nested in nestedCandidates) {
      final id = _extractPrayerId(nested);
      if (id != null && id.isNotEmpty) return id;
    }
    return null;
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final details = _encodedDetails.trim().isNotEmpty
        ? _encodedDetails.trim()
        : _detailsCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a prayer title.')),
      );
      return;
    }
    if (details.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter prayer details.')),
      );
      return;
    }
    if (title.length > 120 || details.length > 1500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Title or description exceeds allowed length.')),
      );
      return;
    }

    setState(() => _submitting = true);
    final progress = PrayerVerifyProgressController();
    var verifyingOpen = false;
    try {
      // NOTE: Prayer Wall posting should not deduct wallet credits.
      // final currentCredits = await WalletService.getCredits();
      // if (currentCredits < _totalCredits) {
      //   if (!mounted) return;
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //       content: Text(
      //           'Insufficient credits. Need $_totalCredits, you have $currentCredits.'),
      //     ),
      //   );
      //   return;
      // }

      // Show verifying UI while AI reviews (replaces toast-only feedback).
      verifyingOpen = true;
      // ignore: unawaited_futures
      PrayerWallVerifyDialogs.showVerifying(context, controller: progress);

      // Animate early steps while AI runs.
      final validationFuture = PrayerWallService.validatePrayerContent(
        prayerTitle: title,
        prayerDescription: details,
      );
      await progress.advanceTo(2);
      final validation = await validationFuture;

      if (!validation.isValid) {
        if (mounted && verifyingOpen) {
          Navigator.of(context, rootNavigator: true).pop();
          verifyingOpen = false;
        }
        if (!mounted) return;
        final action = await PrayerWallVerifyDialogs.showInappropriate(context);
        if (!mounted) return;
        if (action == 'cancel') {
          Navigator.of(context).pop(false);
        }
        // 'edit' / dismiss → stay on form so user can revise.
        return;
      }

      await progress.advanceTo(3);

      // Author name always from Bible Profile (cache `name`), not a form field.
      final loginName =
          (await CacheNotifier().readCache(key: 'name') ?? '')
              .toString()
              .trim();
      final savedName =
          (await PrayerWallLocalStore.loadLastDisplayName() ?? '').trim();
      final effectiveName =
          loginName.isNotEmpty ? loginName : savedName;

      // Additive: profile photo URL for Prayer Wall post (profile_image).
      final cachedImage =
          (await CacheNotifier().readCache(key: 'profile_image') ?? '')
              .toString()
              .trim();
      final profileImageUrl =
          cachedImage.isNotEmpty ? cachedImage : null;
      print(
          'Post prayer profile_image URL → ${profileImageUrl ?? "none"}');

      // Additive: login email (cached as key `user`).
      final cachedEmail =
          (await CacheNotifier().readCache(key: 'user') ?? '')
              .toString()
              .trim();
      final email =
          cachedEmail.isNotEmpty ? cachedEmail : null;
      print('Post prayer email → ${email ?? "none"}');

      final created = await PrayerWallService.createPrayer(
        prayerTitle: title,
        prayerDescription: details,
        prayerCategory: _category,
        isAnonymous: _isAnonymous,
        prayerDuration: _durationDays,
        userName: effectiveName.isNotEmpty ? effectiveName : null,
        profileImage: profileImageUrl,
        email: email,
      );
      await progress.advanceTo(4);
      // UI only: let step 4 finish visibly before the success confirmation.
      await Future<void>.delayed(const Duration(milliseconds: 2500));
      if (!mounted) return;
      // await WalletService.deductCredits(_totalCredits);
      if (effectiveName.isNotEmpty) {
        await PrayerWallLocalStore.saveLastDisplayName(effectiveName);
      }
      final prayerId = (_extractPrayerId(created) ?? '').trim();
      if (prayerId.isNotEmpty) {
        // Always track prayers created by this device so Edit/Delete works even
        // for anonymous/community posts.
        await PrayerWallLocalStore.addMyPrayerId(prayerId);
        print('posted prayer id: $prayerId');
        print('this prayer id will be used as user_id for block');
        // Exact timestamp for status prompt: postedAt + durationDays.
        final postedAt = DateTime.tryParse(
              (created['createdAt'] ?? created['created_at'] ?? '').toString(),
            ) ??
            DateTime.now();
        await PrayerWallLocalStore.putPrayerDurationMeta(
          prayerId: prayerId,
          durationDays: _durationDays,
          postedAt: postedAt,
        );
        // Keep existing author map behavior for non-anonymous posts.
        if (!_isAnonymous && effectiveName.isNotEmpty) {
          await PrayerWallLocalStore.putPrayerAuthor(
            prayerId: prayerId,
            authorName: effectiveName,
          );
        }
        final posterUserId = PrayerWallItem.extractAuthorUserId(created);
        if (posterUserId != null && posterUserId.trim().isNotEmpty) {
          await PrayerWallLocalStore.putPrayerAuthorUserId(
            prayerId: prayerId,
            authorUserId: posterUserId.trim(),
          );
        }
      }
      if (mounted && verifyingOpen) {
        Navigator.of(context, rootNavigator: true).pop();
        verifyingOpen = false;
      }
      if (!mounted) return;
      setState(() => _submitting = false);
      final result = await PrayerWallVerifyDialogs.showVerified(context);
      if (!mounted) return;
      if (result == true) {
        // UI destination only: "View Prayer Wall" must land on Prayer Wall,
        // not fall through to Reading when the stack was popped too far.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const PrayerWallScreen()),
          (route) => route.isFirst,
        );
      } else {
        Navigator.of(context).pop(false);
      }
    } catch (e) {
      if (mounted && verifyingOpen) {
        Navigator.of(context, rootNavigator: true).pop();
        verifyingOpen = false;
      }
      if (!mounted) return;
      final s = e.toString();
      final isOffline = s.contains('SocketException') ||
          s.contains('Failed host lookup') ||
          s.contains('ClientException') ||
          s.contains('Network is unreachable');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(isOffline
                ? 'No internet connection. Please try again.'
                : 'Could not post. Please try again.')),
      );
    } finally {
      progress.dispose();
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _detailsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isVintage =
        themeProvider.currentCustomTheme == AppCustomTheme.vintage;
    final usesLightCustom = themeProvider.currentCustomTheme ==
            AppCustomTheme.white ||
        themeProvider.currentCustomTheme == AppCustomTheme.lightbrown;
    final isDark =
        themeProvider.themeMode == ThemeMode.dark && !usesLightCustom;
    final brown = const Color(0xFF5C4033);
    final cream = isDark
        ? CommanColor.darkPrimaryColor
        : (isVintage
            ? const Color(0xFFF5F0E6)
            : themeProvider.backgroundColor);
    final dateFmt = DateFormat('MMMM d, yyyy');

    return FocusScope(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: isVintage
              ? BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(Images.bgImage(context)),
                    fit: BoxFit.cover,
                  ),
                )
              : BoxDecoration(color: cream),
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: Colors.transparent,
            body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              decoration: BoxDecoration(
                color: brown,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Post a Prayer',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // Balance the close button so the title stays centered.
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  24 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Share your prayer request with others.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : const Color(0xFF6D6D6D),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _label('Prayer Title', brown, isDark),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _titleCtrl,
                      maxLength: 120,
                      style: TextStyle(color: isDark ? Colors.white : brown),
                      decoration: _fieldDecoration(
                        'Enter your prayer title',
                        isDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _label('Prayer Details', brown, isDark),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _detailsCtrl,
                      maxLines: 5,
                      maxLength: 1500,
                      readOnly: true,
                      showCursor: false,
                      enableInteractiveSelection: false,
                      onTap: _submitting ? null : _openDetailsComposer,
                      style: TextStyle(color: isDark ? Colors.white : brown),
                      decoration: _fieldDecoration(
                        'Tap to write your prayer request...',
                        isDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _label('Category (Optional)', brown, isDark),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((c) {
                        final sel = _category == c;
                        return ChoiceChip(
                          label: Text(c),
                          selected: sel,
                          onSelected: (_) => setState(() => _category = c),
                          selectedColor: brown,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: sel
                                ? Colors.white
                                : (isDark ? Colors.white : brown),
                            fontWeight: FontWeight.w500,
                          ),
                          backgroundColor: isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.white,
                          side: BorderSide(
                            color: sel
                                ? brown
                                : (isDark
                                    ? Colors.white.withOpacity(0.45)
                                    : Colors.grey.shade400),
                            width: sel ? 1.5 : 1,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    _label('Prayer Duration', brown, isDark),
                    const SizedBox(height: 4),
                    Text(
                      'Select the duration for your prayer post',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _durationChip('7 Days', 7, brown, isDark),
                        const SizedBox(width: 8),
                        _durationChip('14 Days', 14, brown, isDark),
                        const SizedBox(width: 8),
                        _durationChip('30 Days', 30, brown, isDark),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Active: ${dateFmt.format(_startDate)} to ${dateFmt.format(_endDate)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : const Color(0xFF6D6D6D),
                      ),
                    ),
                    // const SizedBox(height: 16),
                    // _label('Credit Cost', brown, isDark),
                    // const SizedBox(height: 6),
                    // Text(
                    //   'Total Cost: $_totalCredits Credits',
                    //   style: TextStyle(
                    //     fontSize: 16,
                    //     fontWeight: FontWeight.w600,
                    //     color: isDark ? Colors.white : brown,
                    //   ),
                    // ),
                    const SizedBox(height: 12),
                    // CMD: Post-as-anonymous option disabled for now.
                    // SwitchListTile(
                    //   contentPadding: EdgeInsets.zero,
                    //   title: Text(
                    //     'Post anonymously',
                    //     style: TextStyle(
                    //       color: isDark ? Colors.white : brown,
                    //       fontWeight: FontWeight.w600,
                    //     ),
                    //   ),
                    //   value: _isAnonymous,
                    //   activeThumbColor: Colors.white,
                    //   activeTrackColor:
                    //       isDark ? const Color(0xFFB8956A) : brown,
                    //   inactiveThumbColor:
                    //       isDark ? Colors.white54 : Colors.grey.shade400,
                    //   inactiveTrackColor: isDark
                    //       ? Colors.white.withOpacity(0.18)
                    //       : Colors.grey.shade300,
                    //   trackOutlineColor: WidgetStateProperty.resolveWith(
                    //     (states) => states.contains(WidgetState.selected)
                    //         ? Colors.transparent
                    //         : (isDark
                    //             ? Colors.white.withOpacity(0.35)
                    //             : Colors.grey.shade400),
                    //   ),
                    //   onChanged: (v) => setState(() => _isAnonymous = v),
                    // ),
                    const SizedBox(height: 20),
                    PrayerWallGuidelinesDialog.helpBanner(
                      context,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _submitting
                                ? null
                                : () => Navigator.of(context).pop(false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                                  isDark ? Colors.white70 : brown,
                              side: BorderSide(
                                  color: isDark ? Colors.white24 : brown),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _submitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: brown,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: _submitting
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Done'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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

  Widget _label(String t, Color brown, bool isDark) {
    return Text(
      t,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white : brown,
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint, bool isDark) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: isDark ? Colors.white54 : Colors.grey.shade600,
      ),
      filled: true,
      fillColor: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? Colors.white24 : Colors.grey.shade300,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF5C4033), width: 1.5),
      ),
    );
  }

  Widget _durationChip(String label, int days, Color brown, bool isDark) {
    final sel = _durationDays == days;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _durationDays = days),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: sel
                ? brown
                : (isDark ? Colors.white.withOpacity(0.08) : Colors.white),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: sel ? brown : Colors.grey.shade400,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: sel
                  ? Colors.white
                  : (isDark ? Colors.white : brown),
            ),
          ),
        ),
      ),
        );
  }
}

/// Result returned from Type → Review compose flow into Post a Prayer details.
class _PrayerDetailsComposeResult {
  const _PrayerDetailsComposeResult({
    required this.originalWords,
    required this.englishPrayer,
  });

  final String originalWords;
  final String englishPrayer;
}

/// Type Your Prayer → Review & Confirm (UI only; parent Done still posts).
class _PrayerDetailsComposeScreen extends StatefulWidget {
  const _PrayerDetailsComposeScreen({this.initialWords = ''});

  final String initialWords;

  @override
  State<_PrayerDetailsComposeScreen> createState() =>
      _PrayerDetailsComposeScreenState();
}

class _PrayerDetailsComposeScreenState
    extends State<_PrayerDetailsComposeScreen> {
  static const int _maxChars = 300;
  static const Color _brown = Color(0xFF5C4033);
  static const String _typeBg = 'assets/prayer_wall/prayer_type_bg.png';
  static const String _reviewBg = 'assets/prayer_wall/prayer_review_bg.png';

  final _wordsCtrl = TextEditingController();
  final _englishCtrl = TextEditingController();
  bool _reviewStep = false;
  bool _creating = false;
  String _originalWords = '';

  @override
  void initState() {
    super.initState();
    final initial = widget.initialWords.trim();
    if (initial.isNotEmpty) {
      _wordsCtrl.text = initial.length <= _maxChars
          ? initial
          : initial.substring(0, _maxChars);
    }
  }

  @override
  void dispose() {
    _wordsCtrl.dispose();
    _englishCtrl.dispose();
    super.dispose();
  }

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _onCreatePrayer() async {
    _dismissKeyboard();
    final words = _wordsCtrl.text.trim();
    if (words.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please type your prayer need.')),
      );
      return;
    }
    setState(() => _creating = true);
    final english = await PrayerWallService.formatPrayerInEnglish(
      userWords: words,
    );
    if (!mounted) return;
    setState(() => _creating = false);
    if (english == null || english.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not create prayer. Please try again.'),
        ),
      );
      return;
    }
    setState(() {
      _originalWords = words;
      _englishCtrl.text = english.trim();
      _reviewStep = true;
    });
  }

  void _onEditMyWords() {
    setState(() {
      _reviewStep = false;
      _wordsCtrl.text = _originalWords.length <= _maxChars
          ? _originalWords
          : _originalWords.substring(0, _maxChars);
    });
  }

  void _onConfirmPrayer() {
    _dismissKeyboard();
    final english = _englishCtrl.text.trim();
    if (english.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the prayer text.')),
      );
      return;
    }
    Navigator.of(context).pop(
      _PrayerDetailsComposeResult(
        originalWords: _originalWords,
        englishPrayer: english,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Full-screen type BG (black bars cropped from asset). Quill lives in the
    // image — content sits below it.
    final topTitle = _reviewStep ? 'Review & Confirm' : 'Type Your Prayer';
    final media = MediaQuery.of(context);
    final isTablet = media.size.shortestSide >= 600;
    final bgAsset = _reviewStep ? _reviewBg : _typeBg;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFF5F0E6),
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Material(
        color: const Color(0xFFF5F0E6),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _dismissKeyboard,
          child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Image.asset(
                bgAsset,
                fit: isTablet ? BoxFit.fitWidth : BoxFit.cover,
                alignment: Alignment.topCenter,
                filterQuality: FilterQuality.medium,
                excludeFromSemantics: true,
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.only(
                  top: media.padding.top,
                  bottom: media.padding.bottom,
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 48,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              icon:
                                  const Icon(Icons.arrow_back, color: _brown),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                          Text(
                            topTitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Georgia',
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: _brown,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _reviewStep ? _buildReview() : _buildType(),
                    ),
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

  Widget _buildType() {
    final media = MediaQuery.of(context);
    final isTablet = media.size.shortestSide >= 600;
    final keyboard = media.viewInsets.bottom;
    final isLandscape = media.size.width > media.size.height;
    // iPad only: push title + field below the BG pen/ink (was overlapping).
    final topGap = isTablet
        ? (keyboard > 0
            ? (isLandscape ? 80.0 : 48.0)
            : (isLandscape
                ? (media.size.height * 0.42).clamp(240.0, 360.0)
                : (media.size.height * 0.28).clamp(220.0, 340.0)))
        : 156.0;
    final hPad = isTablet ? 48.0 : 22.0;
    final maxW = isTablet ? 560.0 : double.infinity;
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 0, hPad, isTablet ? 20 : 12),
      child: Column(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxW),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Phone: sit below the BG quill. iPad: below pen/ink; up a little when typing.
                      SizedBox(height: topGap),
                      Text(
                        'Tell us your prayer need',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: isTablet ? 26 : 22,
                          fontWeight: FontWeight.w700,
                          color: _brown,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Type in your own words (any language)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isTablet ? 16 : 14,
                          color: _brown.withOpacity(0.7),
                        ),
                      ),
                      SizedBox(height: isTablet ? 20 : 16),
                      TextField(
                        controller: _wordsCtrl,
                        maxLines: isTablet ? 8 : 6,
                        maxLength: _maxChars,
                        enabled: !_creating,
                        textCapitalization: TextCapitalization.sentences,
                        onTapOutside: (_) => _dismissKeyboard(),
                        style: const TextStyle(color: _brown, height: 1.35),
                        decoration: InputDecoration(
                          hintText: 'Share what is on your heart...',
                          hintStyle: TextStyle(color: Colors.grey.shade600),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.92),
                          counterStyle:
                              TextStyle(color: _brown.withOpacity(0.6)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                const BorderSide(color: _brown, width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // AI note sits just above the Create Prayer CTA.
          Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxW),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _brown.withOpacity(0.12)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.volunteer_activism_outlined,
                          size: 22,
                          color: _brown.withOpacity(0.85),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Our AI will turn this into a meaningful prayer request for the community.',
                            style: TextStyle(
                              fontSize: isTablet ? 15 : 13,
                              height: 1.35,
                              color: _brown.withOpacity(0.85),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _creating ? null : _onCreatePrayer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _brown,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 17 : 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _creating
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.auto_awesome, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Create Prayer',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReview() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      child: Column(
        children: [
          // Your Words — roomier card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.94),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _brown.withOpacity(0.18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Words',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _brown,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '“',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 30,
                        height: 0.9,
                        color: _brown.withOpacity(0.45),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _originalWords,
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontStyle: FontStyle.italic,
                          fontSize: 15,
                          height: 1.5,
                          color: _brown.withOpacity(0.92),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '(You expressed)',
                  style: TextStyle(
                    fontSize: 12,
                    color: _brown.withOpacity(0.55),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Prayer Created — size to content (not a tall empty box)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.94),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _brown.withOpacity(0.18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 18,
                      color: _brown.withOpacity(0.75),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Prayer Created for You',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _brown,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _englishCtrl,
                  maxLines: null,
                  minLines: 3,
                  onTapOutside: (_) => _dismissKeyboard(),
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 15.5,
                    height: 1.5,
                    color: _brown.withOpacity(0.95),
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFF8F3EA),
                    hintText: 'Edit your prayer…',
                    hintStyle: TextStyle(
                      color: _brown.withOpacity(0.4),
                      fontSize: 15,
                    ),
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: _brown.withOpacity(0.15),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: _brown,
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _onConfirmPrayer,
              style: ElevatedButton.styleFrom(
                backgroundColor: _brown,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Done',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ),
          TextButton(
            onPressed: _onEditMyWords,
            child: const Text(
              'Edit My Words',
              style: TextStyle(
                color: _brown,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
