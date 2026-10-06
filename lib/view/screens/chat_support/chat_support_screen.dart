import 'dart:io';

import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/chat_support/chat_support_api.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class ChatSupportScreen extends StatefulWidget {
  const ChatSupportScreen({super.key});

  @override
  State<ChatSupportScreen> createState() => _ChatSupportScreenState();
}

class _ChatSupportScreenState extends State<ChatSupportScreen> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  List<SupportQuestion> _items = const [];
  String? _imagePath;
  bool _loading = true;
  bool _sending = false;
  bool _asking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _items.isEmpty;
      _error = null;
    });
    try {
      final userId = await ChatSupportApi.resolveUserId();
      final items = await ChatSupportApi.fetchQuestions(userId);
      if (!mounted) return;
      setState(() {
        _items = items.reversed.toList();
        _loading = false;
      });
      _scrollToEnd();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image == null) return;
    final ext = image.path.split('.').last.toLowerCase();
    if (ext != 'jpg' &&
        ext != 'jpeg' &&
        ext != 'png' &&
        ext != 'webp' &&
        ext != 'gif') {
      Constants.showToast('Only jpeg, png, webp, and gif images are allowed');
      return;
    }
    final length = await image.length();
    if (length > 5 * 1024 * 1024) {
      Constants.showToast('File must be 5MB or smaller');
      return;
    }
    if (!mounted) return;
    setState(() => _imagePath = image.path);
  }

  Future<void> _send() async {
    final question = _text.text.trim();
    if (question.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _asking = true;
    });
    try {
      final userId = await ChatSupportApi.resolveUserId();
      var imageUrl = '';
      final path = _imagePath;
      if (path != null && path.isNotEmpty) {
        imageUrl = await ChatSupportApi.uploadImage(path);
      }
      final created = await ChatSupportApi.ask(
        userId: userId,
        question: question,
        imageUrl: imageUrl,
      );
      if (!mounted) return;
      _text.clear();
      setState(() {
        _imagePath = null;
        _error = null;
        final next = [..._items];
        final index = created.id.isEmpty
            ? -1
            : next.indexWhere((item) => item.id == created.id);
        if (index >= 0) {
          next[index] = created;
        } else {
          next.add(created);
        }
        _items = next;
      });
      _scrollToEnd();
    } catch (e) {
      Constants.showToast(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
          _asking = false;
        });
      }
    }
  }

  Future<void> _escalate(SupportQuestion item) async {
    if (item.id.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final userId = await ChatSupportApi.resolveUserId();
      final updated = await ChatSupportApi.escalate(
        userId: userId,
        questionId: item.id,
      );
      if (!mounted) return;
      setState(() {
        _items = [
          for (final current in _items)
            if (current.id == item.id)
              SupportQuestion(
                id: item.id,
                question: updated.question.isEmpty ? item.question : updated.question,
                answer: '',
                status: 'open',
                answeredBy: 'human',
                imageUrl: updated.imageUrl.isEmpty ? item.imageUrl : updated.imageUrl,
                resolvedBy: 'human',
              )
            else
              current,
        ];
      });
    } catch (e) {
      final message = e.toString();
      if (message.contains('Only questions answered by AI can be escalated')) {
        if (!mounted) return;
        setState(() {
          _items = [
            for (final current in _items)
              if (current.id == item.id)
                SupportQuestion(
                  id: current.id,
                  question: current.question,
                  answer: current.answer,
                  status: 'open',
                  answeredBy: 'human',
                  imageUrl: current.imageUrl,
                )
              else
                current,
          ];
        });
      }
      Constants.showToast(message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final isDark = CommanColor.isDarkTheme(context);
    final isVintage = theme.currentCustomTheme == AppCustomTheme.vintage;
    final ink = CommanColor.whiteBlack(context);
    final brown = const Color(0xFF5C4033);
    final bar = isDark ? CommanColor.darkPrimaryColor : brown;
    final card = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.9);
    final muted = isDark ? const Color(0xFFD8C8B4) : const Color(0xFF6B4E3D);

    return Scaffold(
      backgroundColor: isDark
          ? CommanColor.darkPrimaryColor
          : (isVintage ? const Color(0xFFF5F0E6) : theme.backgroundColor),
      appBar: AppBar(
        backgroundColor: bar,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Chat Support',
          style: TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.w700),
        ),
      ),
      body: Container(
        decoration: isVintage
            ? BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(Images.bgImage(context)),
                  fit: BoxFit.cover,
                ),
              )
            : null,
        child: Column(
          children: [
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: brown))
                  : RefreshIndicator(
                      color: brown,
                      onRefresh: _load,
                      child: _error != null && _items.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    _error!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: ink, fontSize: 15),
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              controller: _scroll,
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                              itemCount: _items.isEmpty ? 1 : _items.length,
                              itemBuilder: (context, index) {
                                if (_items.isEmpty) {
                                  return Text(
                                    'Ask a question about the app.',
                                    style: TextStyle(
                                      color: muted,
                                      fontSize: 15,
                                      height: 1.4,
                                    ),
                                  );
                                }
                                return _bubble(
                                  item: _items[index],
                                  ink: ink,
                                  muted: muted,
                                  brown: brown,
                                  card: card,
                                  isDark: isDark,
                                );
                              },
                            ),
                    ),
            ),
            _composer(ink: ink, brown: brown, card: card, isDark: isDark),
          ],
        ),
      ),
    );
  }

  Widget _bubble({
    required SupportQuestion item,
    required Color ink,
    required Color muted,
    required Color brown,
    required Color card,
    required bool isDark,
  }) {
    final reply = item.showAiAnswer || item.showHumanAnswer
        ? item.answer
        : 'Waiting for a reply...';
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 320),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF4A382C) : brown,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.question,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  if (item.imageUrl.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.imageUrl,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 320),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: brown.withValues(alpha: isDark ? 0.45 : 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reply,
                    style: TextStyle(
                      color: item.waitingForReply ? muted : ink,
                      fontSize: 15,
                      height: 1.45,
                      fontStyle: item.waitingForReply
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                  if (item.showAiAnswer) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor:
                            isDark ? const Color(0xFFF5EFE4) : brown,
                      ),
                      onPressed: _sending ? null : () => _escalate(item),
                      child: const Text(
                        "Didn't help? Contact support",
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _composer({
    required Color ink,
    required Color brown,
    required Color card,
    required bool isDark,
  }) {
    return SafeArea(
      top: false,
      child: Container(
        color: isDark
            ? const Color(0xFF2C2118)
            : Colors.white.withValues(alpha: 0.92),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_asking)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Getting an answer...',
                  style: TextStyle(
                    color: isDark ? const Color(0xFFD8C8B4) : brown,
                    fontSize: 13,
                  ),
                ),
              ),
            if (_imagePath != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_imagePath!),
                          height: 72,
                          width: 72,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: GestureDetector(
                          onTap: () => setState(() => _imagePath = null),
                          child: const Icon(Icons.close, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Row(
              children: [
                IconButton(
                  onPressed: _sending ? null : _pickImage,
                  icon: Icon(
                    Icons.image_outlined,
                    color: isDark ? Colors.white : brown,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _text,
                    minLines: 1,
                    maxLines: 4,
                    style: TextStyle(color: ink, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Ask a question',
                      hintStyle: TextStyle(
                        color: isDark
                            ? const Color(0xFFD8C8B4)
                            : const Color(0xFF8A7568),
                      ),
                      filled: true,
                      fillColor: card,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            BorderSide(color: brown.withValues(alpha: 0.25)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            BorderSide(color: brown.withValues(alpha: 0.25)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isDark ? Colors.white : brown,
                          ),
                        )
                      : Icon(Icons.send, color: isDark ? Colors.white : brown),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
