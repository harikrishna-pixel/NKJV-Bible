import 'package:flutter/material.dart';

class DebugConsole {
  static final List<String> _logs = [];
  static final ValueNotifier<int> _logNotifier = ValueNotifier(0);
  static OverlayEntry? _overlayEntry;
  static bool _isExpanded = false;
  static bool _showClearButton = false; // <- NEW

  static void log(String message) {
    _logs.add(message);
    _logNotifier.value++;
  }

  static void show(BuildContext context) {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          bottom: 100,
          left: 16,
          right: 16,
          child: GestureDetector(
            onTap: () {
              _isExpanded = !_isExpanded;
              _showClearButton = false; // hide before expanding
              _overlayEntry?.markNeedsBuild();
            },
            child: Material(
              color: Colors.transparent,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: _isExpanded ? 220 : 40,
                padding: const EdgeInsets.all(8),
                onEnd: () {
                  if (_isExpanded) {
                    _showClearButton = true;
                    _overlayEntry?.markNeedsBuild();
                  }
                },
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ValueListenableBuilder<int>(
                  valueListenable: _logNotifier,
                  builder: (_, __, ___) {
                    return _isExpanded
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Flexible(
                                child: ListView(
                                  padding: EdgeInsets.zero,
                                  children: _logs.reversed
                                      .map((e) => Text(
                                            e,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12),
                                          ))
                                      .toList(),
                                ),
                              ),
                              if (_showClearButton) // ✅ show only after animation
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                    onPressed: () {
                                      _logs.clear();
                                      _logNotifier.value++;
                                    },
                                    icon: const Icon(Icons.clear),
                                    label: const Text("Clear Logs"),
                                  ),
                                ),
                            ],
                          )
                        : const Row(
                            children: [
                              Icon(Icons.bug_report, color: Colors.white),
                              SizedBox(width: 8),
                              Text("Tap to expand debug log",
                                  style: TextStyle(color: Colors.white)),
                            ],
                          );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
