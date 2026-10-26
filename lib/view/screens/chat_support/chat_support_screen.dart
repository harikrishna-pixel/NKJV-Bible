import 'dart:async';
import 'dart:io';

import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/screens/chat_support/chat_support_api.dart';
import 'package:biblebookapp/view/screens/chat_support/support_content.dart';
import 'package:biblebookapp/view/screens/chat_support/support_topic_screens.dart';
import 'package:biblebookapp/view/screens/chat_support/support_ui.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class ChatSupportScreen extends StatefulWidget {
  const ChatSupportScreen({
    super.key,
    this.initialQuestion,
    this.initialImagePath,
    this.sendToSupport = false,
  });

  /// Sent once after history loads (e.g. typed on Support Home).
  final String? initialQuestion;
  final String? initialImagePath;

  /// Skip the local FAQ match and forward [initialQuestion] straight to
  /// the support team (FAQ "Was this helpful?" → No).
  final bool sendToSupport;

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
  SupportContent? _content;
  final List<_LocalAnswer> _local = [];
  Timer? _poll;
  bool _refreshing = false;
  bool _manualRefreshing = false;
  stt.SpeechToText? _speech;
  bool _speechReady = false;
  bool _listening = false;
  String _textBeforeVoice = '';
  bool _listenersTaken = false;
  stt.SpeechStatusListener? _prevStatusListener;
  stt.SpeechErrorListener? _prevErrorListener;

  @override
  void initState() {
    super.initState();
    _imagePath = widget.initialImagePath;
    final content = SupportContent.load().then((c) {
      if (mounted) setState(() => _content = c);
    });
    Future.wait([content, _load()]).then((_) {
      final initial = widget.initialQuestion?.trim() ?? '';
      if (!mounted || initial.isEmpty) return;
      _text.text = initial;
      if (widget.sendToSupport) {
        _sendToSupport();
      } else {
        _submit();
      }
    });
    _poll =
        Timer.periodic(const Duration(seconds: 10), (_) => _refreshPending());
  }

  /// Silently re-fetch while a question is awaiting a team reply, so the
  /// answer appears without pull-to-refresh.
  Future<void> _refreshPending() async {
    if (!mounted || _loading || _sending || _refreshing) return;
    if (!_items.any((item) => item.waitingForReply)) return;
    _refreshing = true;
    try {
      final userId = await ChatSupportApi.resolveUserId();
      final items =
          (await ChatSupportApi.fetchQuestions(userId)).reversed.toList();
      if (!mounted || _sending) return;
      String sig(List<SupportQuestion> list) => list
          .map((q) => '${q.id}|${q.status}|${q.answeredBy}|${q.answer}')
          .join('\n');
      if (sig(items) == sig(_items)) return;
      setState(() => _items = items);
      _scrollToEnd();
    } catch (_) {
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _manualRefresh() async {
    if (_refreshing) return;
    setState(() => _manualRefreshing = true);
    await _refreshPending();
    if (mounted) setState(() => _manualRefreshing = false);
  }

  /// Attach: pick a screenshot / photo; sent with the next question.
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

  /// Voice: dictate into the input; tap again to stop.
  Future<void> _toggleVoice() async {
    if (_listening) {
      await _stopVoice();
      return;
    }
    _speech ??= stt.SpeechToText();
    final speech = _speech!;
    if (!_speechReady) {
      try {
        _speechReady = await speech.initialize(
          onStatus: _onVoiceStatus,
          onError: _onVoiceError,
        );
      } catch (e) {
        debugPrint('App Support voice init failed: $e');
        _speechReady = false;
      }
      if (!_speechReady) {
        Constants.showToast(
            'Please allow Microphone and Speech Recognition in Settings.');
        return;
      }
    }
    // SpeechToText is an app-wide singleton: if another screen initialised it
    // first, its listeners are still attached — point them at this screen.
    if (!_listenersTaken) {
      _prevStatusListener = speech.statusListener;
      _prevErrorListener = speech.errorListener;
      _listenersTaken = true;
    }
    speech.statusListener = _onVoiceStatus;
    speech.errorListener = _onVoiceError;
    if (speech.isListening) await speech.cancel();

    _textBeforeVoice = _text.text.trim();
    setState(() => _listening = true);
    try {
      await speech.listen(
        onResult: (result) {
          if (!mounted) return;
          final spoken = result.recognizedWords.trim();
          debugPrint('App Support voice result: "$spoken" '
              '(final: ${result.finalResult})');
          if (spoken.isEmpty) return;
          final next =
              _textBeforeVoice.isEmpty ? spoken : '$_textBeforeVoice $spoken';
          _text.value = TextEditingValue(
            text: next,
            selection: TextSelection.collapsed(offset: next.length),
          );
          if (result.finalResult) setState(() => _listening = false);
        },
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 5),
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenMode: stt.ListenMode.dictation,
        ),
      );
    } catch (e) {
      debugPrint('App Support voice listen failed: $e');
      if (!mounted) return;
      setState(() => _listening = false);
      Constants.showToast('Could not start voice input. Please try again.');
    }
  }

  void _onVoiceStatus(String status) {
    debugPrint('App Support voice status: $status');
    if (!mounted) return;
    if (status == 'done' || status == 'notListening') {
      setState(() => _listening = false);
    }
  }

  void _onVoiceError(SpeechRecognitionError error) {
    debugPrint('App Support voice error: ${error.errorMsg} '
        '(permanent: ${error.permanent})');
    if (!mounted) return;
    setState(() => _listening = false);
    final msg = error.errorMsg.toLowerCase();
    if (msg.contains('permission') ||
        msg.contains('denied') ||
        msg.contains('not authorized')) {
      Constants.showToast(
          'Please allow Microphone and Speech Recognition in Settings.');
    } else if (msg.contains('no_match') || msg.contains('timeout')) {
      Constants.showToast("Didn't catch that. Tap the mic and try again.");
    } else {
      Constants.showToast('Voice input stopped. Please try again.');
    }
  }

  Future<void> _stopVoice() async {
    try {
      await _speech?.stop();
    } catch (_) {}
    if (mounted) setState(() => _listening = false);
  }

  /// Answers from support_content JSON when the question matches an FAQ;
  /// otherwise sends to Chat Support as before.
  void _submit() {
    if (_listening) _stopVoice();
    final question = _text.text.trim();
    if (question.isEmpty || _sending) return;
    final content = _content;
    if (content != null && _imagePath == null) {
      final match = content.localMatch(question);
      if (match.best != null || match.suggestions.isNotEmpty) {
        _text.clear();
        setState(() => _local.add(_LocalAnswer(
              question: question,
              faq: match.best,
              suggestions: match.suggestions,
            )));
        _scrollToEnd();
        return;
      }
    }
    _sendToSupport();
  }

  static const _noAnswerText =
      "I don't have an answer right now. Our team will guide you further.";

  /// Sends via [_send] and tells the user when no answer came back.
  Future<void> _sendToSupport() async {
    final before = _items.length;
    final latest = _items.isEmpty ? null : _items.last;
    await _send();
    if (!mounted || _items.isEmpty) return;
    final last = _items.last;
    final isNew = _items.length > before || !identical(last, latest);
    if (isNew && last.waitingForReply) Constants.showToast(_noAnswerText);
  }

  void _showFaq(SupportFaq faq) {
    setState(() => _local.add(_LocalAnswer(question: faq.question, faq: faq)));
    _scrollToEnd();
  }

  void _askSupport(String question) {
    if (_sending) return;
    _text.text = question;
    _sendToSupport();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _speech?.stop();
    // Hand the shared recognizer's listeners back (e.g. to AI Chat).
    if (_listenersTaken && _speech != null) {
      _speech!.statusListener = _prevStatusListener;
      _speech!.errorListener = _prevErrorListener;
    }
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
                question:
                    updated.question.isEmpty ? item.question : updated.question,
                answer: '',
                status: 'open',
                answeredBy: 'human',
                imageUrl:
                    updated.imageUrl.isEmpty ? item.imageUrl : updated.imageUrl,
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

  /// Server messages and JSON answers in time order; welcome first when
  /// there is no server history.
  List<Object> get _timeline {
    final entries = <(DateTime, int, Object)>[];
    var order = 0;
    for (final item in _items) {
      entries.add((item.createdAt ?? DateTime(0), order++, item));
    }
    for (final local in _local) {
      entries.add((local.at, order++, local));
    }
    entries.sort((a, b) {
      final byTime = a.$1.compareTo(b.$1);
      return byTime != 0 ? byTime : a.$2.compareTo(b.$2);
    });
    return [
      if (_items.isEmpty) 'welcome',
      for (final e in entries) e.$3,
    ];
  }

  void _sendPrompt(String prompt) {
    if (_sending) return;
    _text.text = prompt;
    _submit();
  }

  static String _dayLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('MMM d, yyyy').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final p = SupportPalette.of(context);
    final chat = _content?.section('support_chat') ?? const {};
    final title = _content?.resolve(chat['title']?.toString() ?? '') ?? '';
    final subtitle =
        _content?.resolve(chat['subtitle']?.toString() ?? '') ?? '';

    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        children: [
          SupportHeader(
            title: title.isEmpty ? 'App Support' : title,
            subtitle: subtitle,
          ),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: p.accent))
                : RefreshIndicator(
                    color: p.accent,
                    onRefresh: _load,
                    child: _error != null && _items.isEmpty && _local.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: p.ink, fontSize: 15),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            controller: _scroll,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                            itemCount: _timeline.length,
                            itemBuilder: (context, index) {
                              final entry = _timeline[index];
                              if (entry is _LocalAnswer) {
                                return _localBubble(entry, p);
                              }
                              if (entry is! SupportQuestion) {
                                return _welcome(p);
                              }
                              final item = entry;
                              SupportQuestion? previous;
                              for (var i = index - 1; i >= 0; i--) {
                                final e = _timeline[i];
                                if (e is SupportQuestion) {
                                  previous = e;
                                  break;
                                }
                              }
                              final prev = previous?.createdAt;
                              final date = item.createdAt;
                              final showDay = date != null &&
                                  (prev == null ||
                                      _dayLabel(prev) != _dayLabel(date));
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (showDay) _dayChip(_dayLabel(date), p),
                                  _bubble(item: item, p: p),
                                ],
                              );
                            },
                          ),
                  ),
          ),
          _composer(p),
        ],
      ),
    );
  }

  Widget _dayChip(String label, SupportPalette p) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, top: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: p.iconBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 11.5, color: p.muted, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _avatar(SupportPalette p) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: p.iconBg,
        shape: BoxShape.circle,
        border: Border.all(color: p.border),
      ),
      child: Icon(Icons.menu_book_outlined, size: 17, color: p.accent),
    );
  }

  Widget _replyCard({required SupportPalette p, required Widget child}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _avatar(p),
        const SizedBox(width: 8),
        Flexible(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 320),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: p.border),
            ),
            child: child,
          ),
        ),
      ],
    );
  }

  Widget _welcome(SupportPalette p) {
    final welcome = _content?.chatWelcome ?? '';
    final prompts = _content?.suggestedPrompts ?? const <String>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _replyCard(
          p: p,
          child: Text(
            welcome.isEmpty ? 'Ask a question about the app.' : welcome,
            style: TextStyle(color: p.ink, fontSize: 15, height: 1.45),
          ),
        ),
        if (prompts.isNotEmpty) ...[
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final prompt in prompts)
                  InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: _sending ? null : () => _sendPrompt(prompt),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: p.card,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: p.border),
                      ),
                      child: Text(
                        prompt,
                        style: TextStyle(
                          fontSize: 13,
                          color: p.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _userBubble(String text, DateTime at, SupportPalette p) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        decoration: BoxDecoration(
          color: p.isDark ? const Color(0xFF4A382C) : const Color(0xFFEBDDC8),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(text,
                style: TextStyle(color: p.ink, fontSize: 15, height: 1.4)),
            const SizedBox(height: 4),
            Text(DateFormat('h:mm a').format(at),
                style: TextStyle(fontSize: 10.5, color: p.muted)),
          ],
        ),
      ),
    );
  }

  Widget _outlined(SupportPalette p, String label, VoidCallback? onPressed) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.accent,
          side: BorderSide(color: p.border),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: onPressed,
        child: Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  /// A question answered from support_content JSON.
  Widget _localBubble(_LocalAnswer entry, SupportPalette p) {
    final content = _content;
    final faq = entry.faq;
    final text = TextStyle(color: p.ink, fontSize: 15, height: 1.45);
    final Widget reply;
    if (faq == null || content == null) {
      reply = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(content?.ambiguousMessage ?? 'Did you mean one of these?',
              style: text),
          const SizedBox(height: 8),
          for (final s in entry.suggestions)
            InkWell(
              onTap: () => _showFaq(s),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(s.question,
                          style: TextStyle(
                              color: p.accent,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600)),
                    ),
                    Icon(Icons.chevron_right, color: p.muted, size: 20),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 6),
          _outlined(p, 'None of these — ask App Support',
              _sending ? null : () => _askSupport(entry.question)),
        ],
      );
    } else {
      final steps = faq.steps;
      reply = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (faq.answerTitle.isNotEmpty) ...[
            Text(faq.answerTitle,
                style: TextStyle(
                    color: p.ink, fontSize: 15.5, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
          ],
          if (faq.body.isNotEmpty) Text(faq.body, style: text),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${i + 1}. ',
                      style: text.copyWith(
                          fontWeight: FontWeight.w700, color: p.accent)),
                  Expanded(child: Text(steps[i], style: text)),
                ],
              ),
            ),
          for (final para in faq.extraParagraphs)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(para, style: text),
            ),
          for (final action in faq.actions) ...[
            const SizedBox(height: 10),
            _outlined(
              p,
              action.label,
              action.type == 'support_chat'
                  ? (_sending ? null : () => _askSupport(entry.question))
                  : () => runSupportAction(content, action, faq: faq),
            ),
          ],
          const SizedBox(height: 10),
          _outlined(p, "Didn't help? Ask App Support",
              _sending ? null : () => _askSupport(entry.question)),
        ],
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _userBubble(entry.question, entry.at, p),
          const SizedBox(height: 10),
          _replyCard(p: p, child: reply),
        ],
      ),
    );
  }

  Widget _pendingReply(SupportPalette p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: p.iconBg,
                shape: BoxShape.circle,
              ),
              child:
                  Icon(Icons.support_agent_rounded, size: 18, color: p.accent),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Sent to our support team',
                style: TextStyle(
                  color: p.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          _noAnswerText,
          style: TextStyle(color: p.ink, fontSize: 14.5, height: 1.5),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: p.iconBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: p.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule_rounded, size: 14, color: p.accent),
                  const SizedBox(width: 5),
                  Text(
                    'Awaiting reply',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: p.accent,
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _manualRefreshing ? null : _manualRefresh,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: p.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_manualRefreshing)
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 1.8, color: p.accent),
                      )
                    else
                      Icon(Icons.refresh_rounded, size: 15, color: p.accent),
                    const SizedBox(width: 5),
                    Text(
                      'Refresh',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: p.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _bubble({required SupportQuestion item, required SupportPalette p}) {
    final reply =
        item.showAiAnswer || item.showHumanAnswer ? item.answer : _noAnswerText;
    final time = item.createdAt == null
        ? ''
        : DateFormat('h:mm a').format(item.createdAt!);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 300),
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
              decoration: BoxDecoration(
                color: p.isDark
                    ? const Color(0xFF4A382C)
                    : const Color(0xFFEBDDC8),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(4),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item.question,
                    style: TextStyle(color: p.ink, fontSize: 15, height: 1.4),
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
                  if (time.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(time,
                        style: TextStyle(fontSize: 10.5, color: p.muted)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          _replyCard(
            p: p,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.waitingForReply)
                  _pendingReply(p)
                else
                  Text(
                    reply,
                    style: TextStyle(color: p.ink, fontSize: 15, height: 1.45),
                  ),
                if (item.showAiAnswer) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: p.accent,
                        side: BorderSide(color: p.border),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _sending ? null : () => _escalate(item),
                      child: const Text(
                        "Didn't help? Contact support",
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _composer(SupportPalette p) {
    final chat = _content?.section('support_chat') ?? const {};
    final hint = (_items.isEmpty
                ? chat['first_input_placeholder']
                : chat['input_placeholder'])
            ?.toString() ??
        'Ask a question';
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: p.bg,
          border: Border(top: BorderSide(color: p.border)),
        ),
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_asking)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Getting an answer...',
                  style: TextStyle(color: p.accent, fontSize: 13),
                ),
              ),
            if (_imagePath != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 6),
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
            Container(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
              decoration: BoxDecoration(
                color: p.card,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: p.border),
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Attach image',
                    onPressed: _sending ? null : _pickImage,
                    icon: Icon(Icons.attach_file_rounded, color: p.accent),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _text,
                      minLines: 1,
                      maxLines: 4,
                      style: TextStyle(color: p.ink, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: _listening ? 'Listening…' : hint,
                        hintStyle: TextStyle(color: p.muted, fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: _listening ? 'Stop voice' : 'Voice input',
                    onPressed: _sending ? null : _toggleVoice,
                    icon: Icon(
                      _listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                      color: _listening ? Colors.redAccent : p.accent,
                    ),
                  ),
                  GestureDetector(
                    onTap: _sending ? null : _submit,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: p.isDark ? const Color(0xFF8A5530) : p.headerTop,
                        shape: BoxShape.circle,
                      ),
                      child: _sending
                          ? const Padding(
                              padding: EdgeInsets.all(11),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded,
                              color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocalAnswer {
  _LocalAnswer({
    required this.question,
    this.faq,
    this.suggestions = const [],
  }) : at = DateTime.now();

  final String question;
  final SupportFaq? faq;
  final List<SupportFaq> suggestions;
  final DateTime at;
}
