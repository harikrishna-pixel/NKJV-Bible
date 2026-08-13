import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/core/notifiers/cache.notifier.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_guidelines_dialog.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_local_store.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_service.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_verify_dialogs.dart';
import 'package:flutter/material.dart';
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
  final _nameCtrl = TextEditingController();
  String _category = 'Others';
  int _durationDays = 7;
  // Anonymous posting UI disabled for now; posts use author name when provided.
  bool _isAnonymous = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialTitle != null && widget.initialTitle!.trim().isNotEmpty) {
      _titleCtrl.text = _clip(widget.initialTitle!.trim(), 120);
    }
    if (widget.initialDescription != null &&
        widget.initialDescription!.trim().isNotEmpty) {
      _detailsCtrl.text = _clip(widget.initialDescription!.trim(), 500);
    }
    if (widget.initialCategory != null &&
        _categories.contains(widget.initialCategory)) {
      _category = widget.initialCategory!;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _prefillDisplayName());
  }

  Future<void> _prefillDisplayName() async {
    final login =
        (await CacheNotifier().readCache(key: 'name') ?? '').toString().trim();
    final saved = (await PrayerWallLocalStore.loadLastDisplayName() ?? '')
        .trim();
    final prefill = login.isNotEmpty ? login : saved;
    if (!mounted || prefill.isEmpty) return;
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _nameCtrl.text = _clip(prefill, 80));
    }
  }

  String _clip(String s, int max) =>
      s.length <= max ? s : s.substring(0, max);

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
    final details = _detailsCtrl.text.trim();
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
    if (title.length > 120 || details.length > 500) {
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

      final enteredName = _nameCtrl.text.trim();
      final loginName =
          (await CacheNotifier().readCache(key: 'name') ?? '')
              .toString()
              .trim();
      final effectiveName =
          enteredName.isNotEmpty ? enteredName : loginName;

      // Additive: profile photo URL for Prayer Wall post (profile_image).
      final cachedImage =
          (await CacheNotifier().readCache(key: 'profile_image') ?? '')
              .toString()
              .trim();
      final profileImageUrl =
          cachedImage.isNotEmpty ? cachedImage : null;
      print(
          'Post prayer profile_image URL → ${profileImageUrl ?? "none"}');

      final created = await PrayerWallService.createPrayer(
        prayerTitle: title,
        prayerDescription: details,
        prayerCategory: _category,
        isAnonymous: _isAnonymous,
        prayerDuration: _durationDays,
        userName: effectiveName.isNotEmpty ? effectiveName : null,
        profileImage: profileImageUrl,
      );
      await progress.advanceTo(4);
      // await WalletService.deductCredits(_totalCredits);
      if (effectiveName.isNotEmpty) {
        await PrayerWallLocalStore.saveLastDisplayName(effectiveName);
      }
      final prayerId = (_extractPrayerId(created) ?? '').trim();
      if (prayerId.isNotEmpty) {
        // Always track prayers created by this device so Edit/Delete works even
        // for anonymous/community posts.
        await PrayerWallLocalStore.addMyPrayerId(prayerId);
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
      }
      if (mounted && verifyingOpen) {
        Navigator.of(context, rootNavigator: true).pop();
        verifyingOpen = false;
      }
      if (!mounted) return;
      final result = await PrayerWallVerifyDialogs.showVerified(context);
      if (!mounted) return;
      Navigator.of(context).pop(result == true);
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
    _nameCtrl.dispose();
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

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
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
                    _label('Enter Name', brown, isDark),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameCtrl,
                      maxLength: 80,
                      textCapitalization: TextCapitalization.words,
                      style: TextStyle(color: isDark ? Colors.white : brown),
                      decoration: _fieldDecoration(
                        'How you want your name to appear',
                        isDark,
                      ),
                    ),
                    const SizedBox(height: 16),
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
                      maxLength: 500,
                      style: TextStyle(color: isDark ? Colors.white : brown),
                      decoration: _fieldDecoration(
                        'Write your prayer request here...',
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
                        _durationChip('1 Day', 1, brown, isDark),
                        const SizedBox(width: 8),
                        _durationChip('3 Days', 3, brown, isDark),
                        const SizedBox(width: 8),
                        _durationChip('1 Week', 7, brown, isDark),
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
                                : const Text('Post Prayer'),
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
