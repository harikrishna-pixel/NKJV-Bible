import 'package:biblebookapp/home_widget/widget_prompt_service.dart';
import 'package:flutter/material.dart';

/// Swipe gallery of widget mockups from `assets/bible_widget_comopressed`.
/// Marks the drawer "added" count when this screen is closed after viewing.
class WidgetPreviewGalleryScreen extends StatefulWidget {
  const WidgetPreviewGalleryScreen({super.key, this.promptId});

  final WidgetPromptId? promptId;

  @override
  State<WidgetPreviewGalleryScreen> createState() =>
      _WidgetPreviewGalleryScreenState();
}

class _WidgetPreviewGalleryScreenState extends State<WidgetPreviewGalleryScreen> {
  static const _bar = Color(0xFF4A3424);
  static const _paper = Color(0xFFF5F0E6);

  late final List<String> _assets;
  late final PageController _pageController;
  int _index = 0;
  bool _counted = false;

  @override
  void initState() {
    super.initState();
    _assets = WidgetPromptService.previewAssetsFor(widget.promptId);
    _pageController = PageController();
  }

  Future<void> _countAndClose() async {
    if (!_counted) {
      _counted = true;
      await WidgetPromptService.markGalleryViewed(widget.promptId);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _paper,
      appBar: AppBar(
        backgroundColor: _bar,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Available Widgets',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _countAndClose,
        ),
      ),
      body: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, _) {
          if (!_counted) {
            _counted = true;
            WidgetPromptService.markGalleryViewed(widget.promptId);
          }
        },
        child: _assets.isEmpty
          ? const Center(child: Text('No widget previews'))
          : Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemCount: _assets.length,
                    itemBuilder: (context, i) {
                      return Padding(
                        padding: const EdgeInsets.all(20),
                        child: Image.asset(
                          _assets[i],
                          fit: BoxFit.contain,
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 28),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_assets.length, (i) {
                      final on = i == _index;
                      return Container(
                        width: on ? 18 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: on ? _bar : const Color(0xFFD4C0A0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
      ),
    );
  }
}
