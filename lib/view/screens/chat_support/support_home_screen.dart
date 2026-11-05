import 'package:biblebookapp/view/screens/chat_support/chat_support_api.dart';
import 'package:biblebookapp/view/screens/chat_support/chat_support_screen.dart';
import 'package:biblebookapp/view/screens/chat_support/support_content.dart';
import 'package:biblebookapp/view/screens/chat_support/support_topic_screens.dart';
import 'package:biblebookapp/view/screens/chat_support/support_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Screen 1: App Support home.
class SupportHomeScreen extends StatefulWidget {
  const SupportHomeScreen({super.key});

  @override
  State<SupportHomeScreen> createState() => _SupportHomeScreenState();
}

class _SupportHomeScreenState extends State<SupportHomeScreen> {
  SupportContent? _content;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    final c = await SupportContent.load(forceRefresh: true);
    if (mounted) setState(() => _content = c);
  }

  @override
  Widget build(BuildContext context) {
    final p = SupportPalette.of(context);
    final c = _content;
    if (c == null) {
      return Scaffold(
        backgroundColor: p.bg,
        body: Column(
          children: [
            const SupportHeader(title: 'App Support'),
            Expanded(
                child:
                    Center(child: CircularProgressIndicator(color: p.accent))),
          ],
        ),
      );
    }
    final home = c.section('support_home');
    String h(String key, [String fallback = '']) =>
        c.resolve(home[key]?.toString() ?? fallback);
    final popular = c.popularFaqs.take(c.popularLimit).toList();

    return SupportScaffold(
      title: h('header_title', 'App Support'),
      subtitle: h('header_subtitle'),
      trailing: IconButton(
        tooltip: h('history_icon_label', 'Support History'),
        onPressed: () => Get.to(() => SupportHistoryScreen(content: c),
            transition: Transition.cupertino),
        icon: Icon(Icons.history_rounded,
            color: p.isDark ? Colors.white : p.ink),
      ),
      body: RefreshIndicator(
        color: p.accent,
        onRefresh: _loadContent,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
          children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(h('title', 'How can we help you?'), style: p.serif(30)),
              const SizedBox(height: 8),
              Text(
                h('subtitle'),
                style: TextStyle(fontSize: 13.5, color: p.muted, height: 1.4),
              ),
            ],
          ),
          const SizedBox(height: 18),
          for (final cat in c.categories)
            SupportTile(
              large: true,
              icon: supportIcon(cat.icon),
              title: cat.title,
              subtitle: cat.homeSubtitle,
              onTap: () => openSupportCategory(c, cat),
            ),
          if (popular.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.local_fire_department_outlined,
                    color: p.accent, size: 22),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(h('popular_title', 'Popular Questions'),
                        style: p.serif(19))),
                TextButton(
                  onPressed: () => Get.to(
                      () => SupportPopularScreen(content: c),
                      transition: Transition.cupertino),
                  style: TextButton.styleFrom(foregroundColor: p.accent),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(h('view_all_label', 'View All'),
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      const Icon(Icons.chevron_right_rounded, size: 20),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SupportCard(
              child: Column(
                children: [
                  for (var i = 0; i < popular.length; i++)
                    SupportQuestionRow(
                      text: popular[i].question,
                      showDivider: i < popular.length - 1,
                      onTap: () => openSupportFaq(c, popular[i]),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Material(
            color: p.iconBg,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => openSupportChatIfOnline(),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: p.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: p.isDark ? const Color(0xFF8A5530) : p.headerTop,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chat_bubble_outline_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(h('cant_find_title'), style: p.serif(16.5)),
                          const SizedBox(height: 4),
                          Text(
                            h('cant_find_subtitle'),
                            style: TextStyle(
                                fontSize: 12.5, color: p.muted, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: p.muted),
                  ],
                ),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

/// Screen 2: previous support conversations from Chat Support.
class SupportHistoryScreen extends StatefulWidget {
  const SupportHistoryScreen({super.key, required this.content});

  final SupportContent content;

  @override
  State<SupportHistoryScreen> createState() => _SupportHistoryScreenState();
}

class _SupportHistoryScreenState extends State<SupportHistoryScreen> {
  List<_HistoryRow> _rows = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _rows.isEmpty;
      _error = null;
    });
    try {
      final userId = await ChatSupportApi.resolveUserId();
      final tickets = await ChatSupportApi.fetchQuestions(userId);
      final faqs = await SupportFaqHistory.load();
      if (!mounted) return;
      setState(() {
        _rows = _mergeHistory(tickets, faqs);
        _loading = false;
      });
    } catch (e) {
      final faqs = await SupportFaqHistory.load();
      if (!mounted) return;
      if (faqs.isNotEmpty) {
        setState(() {
          _rows = _mergeHistory(const [], faqs);
          _loading = false;
          _error = null;
        });
      } else {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  List<_HistoryRow> _mergeHistory(
      List<SupportQuestion> tickets, List<SupportFaqHistoryEntry> faqs) {
    final rows = <_HistoryRow>[
      for (final t in tickets) _HistoryRow.ticket(t),
      for (final f in faqs) _HistoryRow.faq(f),
    ];
    rows.sort((a, b) {
      final at = a.at ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bt = b.at ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bt.compareTo(at);
    });
    return rows;
  }

  Future<void> _openChat() async {
    await Get.to(() => const ChatSupportScreen(),
        transition: Transition.cupertino);
    if (mounted) _load();
  }

  static IconData _iconFor(String question) {
    if (question.startsWith('Report a Problem')) {
      return Icons.warning_amber_rounded;
    }
    if (question.startsWith('Feature Suggestion')) {
      return Icons.lightbulb_outline_rounded;
    }
    return Icons.chat_bubble_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final p = SupportPalette.of(context);
    final c = widget.content;
    final history = c.section('support_history');
    final statuses =
        Map<String, dynamic>.from((history['statuses'] as Map?) ?? const {});
    final styles = Map<String, dynamic>.from(
        (history['status_styles'] as Map?) ?? const {});
    String t(String key, [String fallback = '']) =>
        c.resolve(history[key]?.toString() ?? fallback);

    Widget body;
    if (_loading) {
      body = Center(child: CircularProgressIndicator(color: p.accent));
    } else if (_error != null && _rows.isEmpty) {
      body = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Text(_error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: p.ink, fontSize: 15)),
        ],
      );
    } else if (_rows.isEmpty) {
      body = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
        children: [
          Icon(Icons.forum_outlined, size: 54, color: p.accent),
          const SizedBox(height: 14),
          Text(t('empty_title'),
              textAlign: TextAlign.center, style: p.serif(18)),
          const SizedBox(height: 6),
          Text(t('empty_message'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: p.muted, height: 1.4)),
        ],
      );
    } else {
      body = ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        itemCount: _rows.length,
        itemBuilder: (context, i) {
          final row = _rows[i];
          if (row.faq != null) {
            final saved = row.faq!;
            final title = saved.question.split('\n').first.trim();
            final date = saved.at == null
                ? ''
                : DateFormat('MMM d, yyyy · h:mm a').format(saved.at!);
            return SupportTile(
              icon: Icons.menu_book_outlined,
              title: title.isEmpty ? 'Support article' : title,
              subtitle: date,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SupportStatusChip(
                    label: statuses['resolved']?.toString() ?? 'Resolved',
                    style: styles['resolved']?.toString() ?? 'neutral',
                  ),
                  Icon(Icons.chevron_right_rounded, color: p.muted, size: 20),
                ],
              ),
              onTap: () {
                final faq = widget.content.faq(saved.id);
                if (faq == null) return;
                Get.to(
                  () => _FaqHistoryDetailScreen(
                    faq: faq,
                    askedQuestion: saved.question,
                    askedAt: saved.at,
                  ),
                  transition: Transition.cupertino,
                );
              },
            );
          }
          final item = row.ticket!;
          final resolved = item.showAiAnswer || item.showHumanAnswer;
          final key = resolved ? 'resolved' : 'in_progress';
          final title = item.question.split('\n').first.trim();
          final date = item.createdAt == null
              ? ''
              : DateFormat('MMM d, yyyy · h:mm a').format(item.createdAt!);
          return SupportTile(
            icon: _iconFor(item.question),
            title: title.isEmpty ? 'Support conversation' : title,
            subtitle: date,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SupportStatusChip(
                  label: statuses[key]?.toString() ??
                      (resolved ? 'Resolved' : 'In Progress'),
                  style: styles[key]?.toString() ?? 'neutral',
                ),
                Icon(Icons.chevron_right_rounded, color: p.muted, size: 20),
              ],
            ),
            onTap: _openChat,
          );
        },
      );
    }

    return SupportScaffold(
      title: t('title', 'Support History'),
      body: RefreshIndicator(color: p.accent, onRefresh: _load, child: body),
      bottom: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: SupportCard(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: p.iconBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.support_agent_rounded,
                          color: p.accent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t('new_chat_title'), style: p.serif(16)),
                          const SizedBox(height: 2),
                          Text(t('new_chat_subtitle'),
                              style: TextStyle(fontSize: 12.5, color: p.muted)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SupportPrimaryButton(
                  label: t('new_chat_label', 'New Support Conversation'),
                  onPressed: _openChat,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryRow {
  _HistoryRow.ticket(SupportQuestion ticket)
      : ticket = ticket,
        faq = null,
        at = ticket.createdAt;

  _HistoryRow.faq(SupportFaqHistoryEntry faq)
      : faq = faq,
        ticket = null,
        at = faq.at;

  final SupportQuestion? ticket;
  final SupportFaqHistoryEntry? faq;
  final DateTime? at;
}

/// Chat-style Q&A for a saved predefined FAQ (not a support-team thread).
class _FaqHistoryDetailScreen extends StatelessWidget {
  const _FaqHistoryDetailScreen({
    required this.faq,
    required this.askedQuestion,
    this.askedAt,
  });

  final SupportFaq faq;
  final String askedQuestion;
  final DateTime? askedAt;

  @override
  Widget build(BuildContext context) {
    final p = SupportPalette.of(context);
    final text = TextStyle(color: p.ink, fontSize: 15, height: 1.45);
    final steps = faq.steps;
    final question =
        askedQuestion.trim().isEmpty ? faq.question : askedQuestion.trim();
    final at = askedAt ?? DateTime.now();

    return SupportScaffold(
      title: 'Support History',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
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
                  Text(question,
                      style:
                          TextStyle(color: p.ink, fontSize: 15, height: 1.4)),
                  const SizedBox(height: 4),
                  Text(DateFormat('h:mm a').format(at),
                      style: TextStyle(fontSize: 10.5, color: p.muted)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: p.iconBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: p.border),
                ),
                child: Icon(Icons.menu_book_outlined,
                    size: 17, color: p.accent),
              ),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (faq.answerTitle.isNotEmpty) ...[
                        Text(faq.answerTitle,
                            style: TextStyle(
                                color: p.ink,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700)),
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
                                      fontWeight: FontWeight.w700,
                                      color: p.accent)),
                              Expanded(child: Text(steps[i], style: text)),
                            ],
                          ),
                        ),
                      for (final para in faq.extraParagraphs)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(para, style: text),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
