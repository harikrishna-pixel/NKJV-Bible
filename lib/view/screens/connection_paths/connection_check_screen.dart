import 'package:biblebookapp/view/screens/connection_paths/connection_path_progress.dart';
import 'package:biblebookapp/view/screens/connection_paths/daily_connection_screen.dart';
import 'package:biblebookapp/view/screens/connection_paths/data/connection_paths_data.dart';
import 'package:biblebookapp/view/screens/connection_paths/models/connection_path.dart';
import 'package:biblebookapp/view/screens/connection_paths/widgets/parchment_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Mockup screen 4 — Connection Check (before first day only).
class ConnectionCheckScreen extends StatefulWidget {
  const ConnectionCheckScreen({super.key, required this.path});

  final ConnectionPath path;

  @override
  State<ConnectionCheckScreen> createState() => _ConnectionCheckScreenState();
}

class _ConnectionCheckScreenState extends State<ConnectionCheckScreen> {
  double _value = 0.5;

  String get _label {
    if (_value < 0.2) return 'Very Far';
    if (_value < 0.4) return 'Far';
    if (_value < 0.6) return 'Growing';
    if (_value < 0.8) return 'Close';
    return 'Very Close';
  }

  Future<void> _continue() async {
    await ConnectionPathProgress.saveConnectionCheck(widget.path.id, _value);
    await Get.off(
      () => DailyConnectionScreen(path: widget.path, dayIndex: 0),
      transition: Transition.cupertino,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ParchmentScaffold(
      title: 'Before we begin',
      backgroundAsset: ConnectionPathsData.checkBgAsset,
      scrimColor: Colors.white.withValues(alpha: 0.25),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Image.asset(
              ConnectionPathsData.sproutGlowAsset,
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 12),
            const Text(
              'How is your connection\nwith God today?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: Pc.serif,
                fontSize: 24,
                height: 1.25,
                fontWeight: FontWeight.w700,
                color: Pc.ink,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose what feels closest\nto your heart.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: Pc.serif,
                fontSize: 15,
                height: 1.35,
                color: Pc.ink,
              ),
            ),
            const SizedBox(height: 28),
            // Separate box (mockup) so the level + slider read over the photo.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              decoration: BoxDecoration(
                color: Pc.card.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Pc.border),
                boxShadow: [
                  BoxShadow(
                    color: Pc.brownDark.withValues(alpha: 0.12),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    _label,
                    style: const TextStyle(
                      fontFamily: Pc.serif,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Pc.brown,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Pc.brown,
                      inactiveTrackColor: Pc.track,
                      thumbColor: Pc.brownDark,
                      overlayColor: Pc.brown.withValues(alpha: 0.15),
                    ),
                    child: Slider(
                      value: _value,
                      onChanged: (v) => setState(() => _value = v),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Very Far',
                            style: TextStyle(
                                fontFamily: Pc.serif,
                                fontSize: 12.5,
                                color: Pc.muted)),
                        Text('Very Close',
                            style: TextStyle(
                                fontFamily: Pc.serif,
                                fontSize: 12.5,
                                color: Pc.muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ParchmentButton(
            label: 'Continue to Verse',
            onPressed: _continue,
            gold: true,
            showArrow: true,
          ),
        ],
      ),
    );
  }
}
