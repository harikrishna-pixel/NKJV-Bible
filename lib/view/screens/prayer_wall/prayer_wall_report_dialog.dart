import 'package:flutter/material.dart';

/// Report Prayer popup — returns selected reason title on submit, else null.
class PrayerWallReportDialog {
  PrayerWallReportDialog._();

  static const Color _cream = Color(0xFFFFF9F3);
  static const Color _ink = Color(0xFF4B3423);
  static const Color _muted = Color(0xFF6B4E3D);
  static const Color _brown = Color(0xFF5C4033);
  static const Color _peach = Color(0xFFF3E4D8);
  static const Color _flagRed = Color(0xFFC45C3A);
  static const Color _heart = Color(0xFFE8A0A0);

  static const List<_ReportReason> _reasons = [
    _ReportReason(
      id: 'inappropriate',
      title: 'Inappropriate Content',
      subtitle: 'Contains offensive, abusive or inappropriate content.',
      icon: Icons.error_outline_rounded,
    ),
    _ReportReason(
      id: 'spam',
      title: 'Spam or Advertising',
      subtitle: 'Promotes products, services or unrelated links.',
      icon: Icons.chat_bubble_outline_rounded,
    ),
    _ReportReason(
      id: 'misleading',
      title: 'False or Misleading',
      subtitle: 'Contains false information or misleading claims.',
      icon: Icons.person_outline_rounded,
    ),
    _ReportReason(
      id: 'other',
      title: 'Other',
      subtitle: 'Something else.',
      icon: Icons.more_horiz_rounded,
    ),
  ];

  /// Returns the selected reason title (for `report_reason`) on submit.
  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const _PrayerWallReportDialogBody(),
    );
  }
}

class _ReportReason {
  const _ReportReason({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
}

class _PrayerWallReportDialogBody extends StatefulWidget {
  const _PrayerWallReportDialogBody();

  @override
  State<_PrayerWallReportDialogBody> createState() =>
      _PrayerWallReportDialogBodyState();
}

class _PrayerWallReportDialogBodyState
    extends State<_PrayerWallReportDialogBody> {
  String _selectedId = PrayerWallReportDialog._reasons.first.id;
  final _detailsCtrl = TextEditingController();

  @override
  void dispose() {
    _detailsCtrl.dispose();
    super.dispose();
  }

  String get _selectedTitle => PrayerWallReportDialog._reasons
      .firstWhere((r) => r.id == _selectedId)
      .title;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
      child: Material(
        color: PrayerWallReportDialog._cream,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.86,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 26, 18, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _FlagHero(),
                    const SizedBox(height: 12),
                    const Text(
                      'Report Prayer',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: PrayerWallReportDialog._ink,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Help us keep the Prayer Wall a safe and respectful space for everyone.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: PrayerWallReportDialog._muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const _HeartDivider(),
                    const SizedBox(height: 14),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Why are you reporting this prayer?',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: PrayerWallReportDialog._ink,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...PrayerWallReportDialog._reasons.map((r) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _ReasonCard(
                          reason: r,
                          selected: _selectedId == r.id,
                          onTap: () => setState(() => _selectedId = r.id),
                        ),
                      );
                    }),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _detailsCtrl,
                      maxLength: 200,
                      maxLines: 3,
                      minLines: 3,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(
                        fontSize: 14,
                        color: PrayerWallReportDialog._ink,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Additional details (optional)',
                        hintStyle: TextStyle(
                          color: PrayerWallReportDialog._muted
                              .withValues(alpha: 0.65),
                          fontSize: 13.5,
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.9),
                        counterText: '${_detailsCtrl.text.length}/200',
                        counterStyle: TextStyle(
                          fontSize: 11,
                          color: PrayerWallReportDialog._muted
                              .withValues(alpha: 0.8),
                        ),
                        contentPadding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: PrayerWallReportDialog._brown
                                .withValues(alpha: 0.22),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: PrayerWallReportDialog._brown
                                .withValues(alpha: 0.22),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: PrayerWallReportDialog._brown,
                            width: 1.4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 46,
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: PrayerWallReportDialog._brown,
                                side: BorderSide(
                                  color: PrayerWallReportDialog._brown
                                      .withValues(alpha: 0.55),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                maxLines: 1,
                                softWrap: false,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 3,
                          child: SizedBox(
                            height: 46,
                            child: ElevatedButton(
                              onPressed: () =>
                                  Navigator.of(context).pop(_selectedTitle),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: PrayerWallReportDialog._brown,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Submit Report',
                                  maxLines: 1,
                                  softWrap: false,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 14,
                          color: PrayerWallReportDialog._muted
                              .withValues(alpha: 0.85),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Your report is anonymous and confidential.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: PrayerWallReportDialog._muted
                                  .withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.close,
                  color: PrayerWallReportDialog._muted.withValues(alpha: 0.85),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlagHero extends StatelessWidget {
  const _FlagHero();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      height: 84,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              color: PrayerWallReportDialog._peach,
              shape: BoxShape.circle,
            ),
          ),
          const Icon(
            Icons.flag_outlined,
            size: 32,
            color: PrayerWallReportDialog._flagRed,
          ),
          const Positioned(
            top: 6,
            left: 10,
            child: Icon(Icons.auto_awesome, size: 12, color: Color(0xFFE0A84E)),
          ),
          const Positioned(
            top: 10,
            right: 8,
            child: Icon(Icons.auto_awesome, size: 10, color: Color(0xFFE0A84E)),
          ),
          const Positioned(
            bottom: 10,
            left: 8,
            child: Icon(Icons.auto_awesome, size: 9, color: Color(0xFFE0A84E)),
          ),
          const Positioned(
            bottom: 12,
            right: 6,
            child: Icon(Icons.auto_awesome, size: 11, color: Color(0xFFE0A84E)),
          ),
        ],
      ),
    );
  }
}

class _HeartDivider extends StatelessWidget {
  const _HeartDivider();

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Container(
        height: 1,
        color: PrayerWallReportDialog._brown.withValues(alpha: 0.16),
      ),
    );
    return Row(
      children: [
        line,
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Icon(
            Icons.favorite,
            size: 12,
            color: PrayerWallReportDialog._heart,
          ),
        ),
        line,
      ],
    );
  }
}

class _ReasonCard extends StatelessWidget {
  const _ReasonCard({
    required this.reason,
    required this.selected,
    required this.onTap,
  });

  final _ReportReason reason;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final border = selected
        ? PrayerWallReportDialog._brown
        : PrayerWallReportDialog._brown.withValues(alpha: 0.2);
    return Material(
      color: Colors.white.withValues(alpha: 0.78),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: selected ? 1.6 : 1),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: PrayerWallReportDialog._flagRed.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  reason.icon,
                  size: 18,
                  color: PrayerWallReportDialog._flagRed,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reason.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: PrayerWallReportDialog._ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      reason.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.3,
                        color: PrayerWallReportDialog._muted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: selected
                    ? PrayerWallReportDialog._brown
                    : PrayerWallReportDialog._brown.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
