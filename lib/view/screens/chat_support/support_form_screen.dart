import 'dart:io';

import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/screens/chat_support/chat_support_api.dart';
import 'package:biblebookapp/view/screens/chat_support/chat_support_screen.dart';
import 'package:biblebookapp/view/screens/chat_support/support_content.dart';
import 'package:biblebookapp/view/screens/chat_support/support_topic_screens.dart';
import 'package:biblebookapp/view/screens/chat_support/support_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';

enum SupportFormKind { report, feature }

/// Screens 10 & 11: Report a Problem / Suggest a Feature forms.
/// Submissions go to Chat Support and then open the support chat.
class SupportFormScreen extends StatefulWidget {
  const SupportFormScreen({
    super.key,
    required this.content,
    required this.kind,
    this.prefillType,
  });

  final SupportContent content;
  final SupportFormKind kind;
  final String? prefillType;

  @override
  State<SupportFormScreen> createState() => _SupportFormScreenState();
}

class _SupportFormScreenState extends State<SupportFormScreen> {
  late SupportPalette _palette;
  final _details = TextEditingController();
  final _email = TextEditingController();
  String? _type;
  String? _imagePath;
  bool _sending = false;
  String? _error;

  bool get _isReport => widget.kind == SupportFormKind.report;
  String get _sectionKey => _isReport ? 'report_problem' : 'feature_request';
  Map<String, dynamic> get _section => widget.content.section(_sectionKey);
  List<Map<String, dynamic>> get _fields =>
      widget.content.formFields(_sectionKey);

  List<SupportOption> get _options => _isReport
      ? widget.content.reportIssueTypes()
      : widget.content.featureTypes();

  SupportOption? get _selected {
    for (final o in _options) {
      if (o.id == _type) return o;
    }
    return null;
  }

  Map<String, dynamic> _field(String type) => _fields.firstWhere(
        (f) => f['type'] == type,
        orElse: () => <String, dynamic>{},
      );

  @override
  void initState() {
    super.initState();
    final prefill = widget.prefillType;
    if (prefill != null && _options.any((o) => o.id == prefill)) {
      _type = prefill;
    }
  }

  @override
  void dispose() {
    _details.dispose();
    _email.dispose();
    super.dispose();
  }

  String _r(dynamic v, [String fallback = '']) =>
      widget.content.resolve(v?.toString() ?? fallback);

  bool _detailsRequired(Map<String, dynamic> field) {
    if (field['required'] == true) return true;
    final when = field['required_when'];
    if (when is Map) {
      for (final entry in when.entries) {
        final values = entry.value;
        if (values is List && values.map((e) => '$e').contains(_type)) {
          return true;
        }
      }
    }
    return false;
  }

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image == null) return;
    final ext = image.path.split('.').last.toLowerCase();
    if (!{'jpg', 'jpeg', 'png', 'webp', 'gif'}.contains(ext)) {
      Constants.showToast('Only jpeg, png, webp, and gif images are allowed');
      return;
    }
    if (await image.length() > 5 * 1024 * 1024) {
      Constants.showToast('File must be 5MB or smaller');
      return;
    }
    if (!mounted) return;
    setState(() => _imagePath = image.path);
  }

  Future<void> _pickType() async {
    final p = _palette;
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: p.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          children: [
            for (final o in _options)
              SupportTile(
                icon: supportIcon(o.icon),
                title: o.label,
                subtitle: o.subtitle,
                trailing: o.id == _type
                    ? Icon(Icons.check_circle_rounded, color: p.accent)
                    : null,
                onTap: () => Navigator.of(context).pop(o.id),
              ),
          ],
        ),
      ),
    );
    if (picked != null && mounted) setState(() => _type = picked);
  }

  String? _validate() {
    final select = _field('select');
    if (select['required'] == true && _type == null) {
      return _r(select['placeholder'], 'Please choose an option');
    }
    final area = _field('textarea');
    final text = _details.text.trim();
    final min = (area['min_length'] as num?)?.toInt() ?? 0;
    if (_detailsRequired(area) && text.length < (min > 0 ? min : 1)) {
      return min > 0
          ? 'Please enter at least $min characters.'
          : 'Please add some details.';
    }
    if (text.isNotEmpty && min > 0 && text.length < min) {
      return 'Please enter at least $min characters.';
    }
    final email = _email.text.trim();
    if (email.isNotEmpty &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  Future<String> _composeQuestion() async {
    final info = await PackageInfo.fromPlatform();
    final heading = _isReport ? 'Report a Problem' : 'Feature Suggestion';
    final buffer = StringBuffer('$heading: ${_selected?.label ?? ''}');
    final text = _details.text.trim();
    if (text.isNotEmpty) buffer.write('\n\n$text');
    final email = _email.text.trim();
    if (email.isNotEmpty) buffer.write('\n\nEmail: $email');
    buffer.write(
        '\n\nApp: ${info.version} (${info.buildNumber}) · ${Platform.operatingSystem} ${Platform.operatingSystemVersion}');
    return buffer.toString();
  }

  Future<void> _submit() async {
    final error = _validate();
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() {
      _error = null;
      _sending = true;
    });
    try {
      final userId = await ChatSupportApi.resolveUserId();
      var imageUrl = '';
      final path = _imagePath;
      if (path != null && path.isNotEmpty) {
        imageUrl = await ChatSupportApi.uploadImage(path);
      }
      await ChatSupportApi.ask(
        userId: userId,
        question: await _composeQuestion(),
        imageUrl: imageUrl,
      );
      if (!mounted) return;
      setState(() => _sending = false);
      await _showSuccess();
      Get.off(
        () => const ChatSupportScreen(),
        transition: Transition.cupertino,
        duration: const Duration(milliseconds: 250),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      Constants.showToast(e.toString());
    }
  }

  Future<void> _showSuccess() {
    final p = _palette;
    final success =
        Map<String, dynamic>.from((_section['success'] as Map?) ?? const {});
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: p.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: p.iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_rounded, color: p.accent, size: 32),
              ),
              const SizedBox(height: 14),
              Text(_r(success['title']),
                  textAlign: TextAlign.center, style: p.serif(20)),
              const SizedBox(height: 8),
              Text(
                _r(success['message']),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: p.muted, height: 1.45),
              ),
              const SizedBox(height: 18),
              SupportPrimaryButton(
                label: _r(success['button'], 'Done'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(SupportPalette p, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: TextStyle(
              fontSize: 14.5, fontWeight: FontWeight.w700, color: p.ink),
        ),
      );

  InputDecoration _input(SupportPalette p, String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: p.muted, fontSize: 14),
        filled: true,
        fillColor: p.card,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.accent),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final p = _palette = SupportPalette.of(context);
    final c = widget.content;
    final select = _field('select');
    final area = _field('textarea');
    final image = _field('image');
    final email = _field('email');
    final overrides = area['placeholder_overrides'];
    final areaHint =
        overrides is Map && _type != null && overrides[_type] != null
            ? _r(overrides[_type])
            : _r(area['placeholder']);
    final quickFixes =
        _isReport ? (_selected?.quickFixes ?? const []) : const [];

    return SupportScaffold(
      title: _r(_section['title']),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        children: [
          Text(
            _r(_section['subtitle']),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: p.muted, height: 1.45),
          ),
          const SizedBox(height: 20),
          if (select.isNotEmpty) ...[
            _label(p, _r(select['label'])),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _sending ? null : _pickType,
              child: InputDecorator(
                decoration: _input(p, ''),
                child: Row(
                  children: [
                    if (_selected != null) ...[
                      Icon(supportIcon(_selected!.icon),
                          size: 18, color: p.accent),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        _selected?.label ?? _r(select['placeholder']),
                        style: TextStyle(
                          fontSize: 14.5,
                          color: _selected == null ? p.muted : p.ink,
                        ),
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down_rounded, color: p.muted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
          ],
          if (quickFixes.isNotEmpty) ...[
            SupportCard(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _r(_section['quick_fix_title'], 'Try these quick fixes'),
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: p.accent),
                  ),
                  for (final f in quickFixes)
                    InkWell(
                      onTap: () => openSupportFaq(c, f),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Icon(Icons.lightbulb_outline_rounded,
                                size: 18, color: p.accent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(f.question,
                                  style: TextStyle(fontSize: 14, color: p.ink)),
                            ),
                            Icon(Icons.chevron_right_rounded,
                                size: 20, color: p.muted),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],
          if (area.isNotEmpty) ...[
            _label(p, _r(area['label'])),
            TextField(
              controller: _details,
              minLines: 4,
              maxLines: 7,
              maxLength: (area['max_length'] as num?)?.toInt(),
              style: TextStyle(color: p.ink, fontSize: 14.5),
              decoration: _input(p, areaHint),
            ),
            if (_isReport && _section['privacy_message'] != null)
              Text(
                _r(_section['privacy_message']),
                style: TextStyle(fontSize: 12, color: p.muted, height: 1.4),
              ),
            const SizedBox(height: 18),
          ],
          if (image.isNotEmpty) ...[
            _label(p, _r(image['label'])),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _sending ? null : _pickImage,
              child: Container(
                height: _imagePath == null ? 92 : 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: p.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: p.border),
                ),
                child: _imagePath == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.photo_camera_outlined,
                              color: p.accent, size: 26),
                          const SizedBox(height: 6),
                          Text(
                            _r(image['button_label']),
                            style: TextStyle(
                                color: p.ink,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(File(_imagePath!),
                                fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: GestureDetector(
                              onTap: () => setState(() => _imagePath = null),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close,
                                    size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 18),
          ],
          if (email.isNotEmpty) ...[
            _label(p, _r(email['label'])),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: p.ink, fontSize: 14.5),
              decoration: _input(p, _r(email['placeholder'])),
            ),
            if (email['helper_text'] != null) ...[
              const SizedBox(height: 6),
              Text(
                _r(email['helper_text']),
                style: TextStyle(fontSize: 12, color: p.muted, height: 1.4),
              ),
            ],
            const SizedBox(height: 18),
          ],
          if (_error != null) ...[
            Text(
              _error!,
              style: const TextStyle(
                  color: Color(0xFFB3261E), fontSize: 13.5, height: 1.4),
            ),
            const SizedBox(height: 12),
          ],
          SupportPrimaryButton(
            label: _r(_section['submit_label'], 'Send'),
            busy: _sending,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
