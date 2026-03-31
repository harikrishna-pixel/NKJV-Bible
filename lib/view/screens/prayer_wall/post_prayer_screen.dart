import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/core/notifiers/cache.notifier.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_local_store.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_added_success_screen.dart';
import 'package:biblebookapp/view/screens/prayer_wall/prayer_wall_service.dart';
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
  String _category = 'Others';
  int _durationDays = 7;
  bool _isAnonymous = true;
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
      final created = await PrayerWallService.createPrayer(
        prayerTitle: title,
        prayerDescription: details,
        prayerCategory: _category,
        isAnonymous: _isAnonymous,
        prayerDuration: _durationDays,
      );
      // await WalletService.deductCredits(_totalCredits);
      if (!_isAnonymous) {
        final prayerId = (_extractPrayerId(created) ?? '').trim();
        final cachedName =
            (await CacheNotifier().readCache(key: 'name') ?? '').toString().trim();
        if (prayerId.isNotEmpty && cachedName.isNotEmpty) {
          await PrayerWallLocalStore.putPrayerAuthor(
            prayerId: prayerId,
            authorName: cachedName,
          );
        }
      }
      if (!mounted) return;
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PrayerAddedSuccessScreen(durationDays: _durationDays),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (e) {
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
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final brown = const Color(0xFF5C4033);
    final dateFmt = DateFormat('MMMM d, yyyy');

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(Images.bgImage(context)),
              fit: BoxFit.cover,
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                color: brown,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
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
                    child: Text(
                      'Post a Prayer',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                            color: sel ? brown : Colors.grey.shade400,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    _label('Prayer Duration', brown, isDark),
                    const SizedBox(height: 4),
                    Text(
                      'Select the duration for your prayer post ($_creditsPerDay credits per day)',
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
                    const SizedBox(height: 16),
                    _label('Credit Cost', brown, isDark),
                    const SizedBox(height: 6),
                    Text(
                      'Total Cost: $_totalCredits Credits',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : brown,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Post anonymously',
                        style: TextStyle(
                          color: isDark ? Colors.white : brown,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      value: _isAnonymous,
                      activeColor: brown,
                      onChanged: (v) => setState(() => _isAnonymous = v),
                    ),
                    const SizedBox(height: 24),
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
