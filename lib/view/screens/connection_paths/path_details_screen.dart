import 'package:biblebookapp/view/screens/connection_paths/connection_check_screen.dart';
import 'package:biblebookapp/view/screens/connection_paths/connection_path_progress.dart';
import 'package:biblebookapp/view/screens/connection_paths/connection_path_verse_service.dart';
import 'package:biblebookapp/view/screens/connection_paths/data/connection_paths_data.dart';
import 'package:biblebookapp/view/screens/connection_paths/models/connection_path.dart';
import 'package:biblebookapp/view/screens/connection_paths/path_overview_screen.dart';
import 'package:biblebookapp/view/screens/connection_paths/widgets/parchment_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Mockup screen 3 — Path Details.
class PathDetailsScreen extends StatefulWidget {
  const PathDetailsScreen({super.key, required this.path});

  final ConnectionPath path;

  @override
  State<PathDetailsScreen> createState() => _PathDetailsScreenState();
}

class _PathDetailsScreenState extends State<PathDetailsScreen> {
  bool _started = false;
  bool _completed = false;
  String _keyVerse = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await ConnectionPathProgress.isStarted(widget.path.id);
    final c = await ConnectionPathProgress.isCompleted(widget.path.id);
    final verse =
        await ConnectionPathVerseService.textForRefs(widget.path.summaryVerses);
    if (!mounted) return;
    setState(() {
      _started = s;
      _completed = c;
      _keyVerse = verse;
    });
  }

  Future<void> _start() async {
    final path = widget.path;
    if (_completed || _started) {
      await Get.off(
        () => PathOverviewScreen(path: path),
        transition: Transition.cupertino,
      );
      return;
    }
    await ConnectionPathProgress.start(path.id);
    final checked = await ConnectionPathProgress.hasConnectionCheck(path.id);
    if (!checked) {
      await Get.off(
        () => ConnectionCheckScreen(path: path),
        transition: Transition.cupertino,
      );
      return;
    }
    await Get.off(
      () => PathOverviewScreen(path: path),
      transition: Transition.cupertino,
    );
  }

  @override
  Widget build(BuildContext context) {
    final path = widget.path;
    return ParchmentScaffold(
      title: '',
      backgroundAsset: ConnectionPathsData.pageBgAsset,
      scrim: true,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.asset(
                ConnectionPathsData.coverFor(path),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            path.title,
            style: const TextStyle(
              fontFamily: Pc.serif,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Pc.ink,
            ),
          ),
          if (path.subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              path.subtitle,
              style: const TextStyle(
                fontFamily: Pc.serif,
                fontSize: 15,
                color: Pc.ink,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MetaItem(
                icon: Icons.calendar_month_outlined,
                value: '${path.durationDays}',
                caption: 'days',
              ),
              const SizedBox(width: 14),
              _MetaItem(
                icon: Icons.schedule_outlined,
                value: _timeValue(path.dailyTime),
                caption: 'mins daily',
              ),
              if (path.includes.isNotEmpty) ...[
                const SizedBox(width: 14),
                Expanded(
                  child: _MetaItem(
                    icon: Icons.menu_book_outlined,
                    caption: path.includes.join(', '),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: Pc.border, height: 1),
          if (path.description.isNotEmpty) ...[
            const SizedBox(height: 14),
            const _SectionHeading('About This Path'),
            const SizedBox(height: 4),
            _BodyText(path.description),
          ],
          if (path.bestFor.isNotEmpty) ...[
            const SizedBox(height: 14),
            const _SectionHeading('Best For'),
            const SizedBox(height: 4),
            _BodyText(path.bestFor),
          ],
          if (path.summaryReference.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              decoration: BoxDecoration(
                color: Pc.card.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Pc.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionHeading('Key Verse'),
                  if (_keyVerse.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      '\u201C$_keyVerse\u201D',
                      style: const TextStyle(
                        fontFamily: Pc.serif,
                        fontSize: 15,
                        height: 1.4,
                        color: Pc.ink,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    path.summaryReference,
                    style: const TextStyle(
                      fontFamily: Pc.serif,
                      fontSize: 14,
                      color: Pc.ink,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      bottom: ParchmentButton(
        label: _completed
            ? 'View This Path'
            : _started
                ? 'Continue Path'
                : 'Start This Path',
        onPressed: _start,
        gold: true,
        showArrow: true,
      ),
    );
  }
}

/// "5–10 mins" → "5–10" (caption "mins daily" is shown separately).
String _timeValue(String dailyTime) =>
    dailyTime.replaceAll(RegExp(r'\s*mins?\b.*$', caseSensitive: false), '');

/// Mockup meta item: outlined icon + bold value over a small caption.
class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.caption, this.value});
  final IconData icon;
  final String? value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: Pc.brown),
        const SizedBox(width: 6),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (value != null && value!.isNotEmpty)
                Text(
                  value!,
                  style: const TextStyle(
                    fontFamily: Pc.serif,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Pc.ink,
                  ),
                ),
              Text(
                caption,
                style: const TextStyle(
                  fontFamily: Pc.serif,
                  fontSize: 11.5,
                  height: 1.25,
                  color: Pc.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: Pc.serif,
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: Pc.ink,
      ),
    );
  }
}

class _BodyText extends StatelessWidget {
  const _BodyText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: Pc.serif,
        fontSize: 14.5,
        height: 1.4,
        color: Pc.ink,
      ),
    );
  }
}
