import 'package:biblebookapp/view/screens/chat_support/chat_support_screen.dart';
import 'package:biblebookapp/view/screens/chat_support/support_content.dart';
import 'package:biblebookapp/view/screens/chat_support/support_form_screen.dart';
import 'package:biblebookapp/view/screens/chat_support/support_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

// GetX derives the route name from the builder type, which is the same for
// every page pushed here, so duplicate prevention would block nested screens.
void _push(Widget page) => Get.to(
      () => page,
      transition: Transition.cupertino,
      duration: const Duration(milliseconds: 250),
      preventDuplicates: false,
    );

void openSupportChat({String? question}) =>
    _push(ChatSupportScreen(initialQuestion: question));

void openSupportFaq(SupportContent content, SupportFaq faq) =>
    _push(SupportFaqScreen(content: content, faq: faq));

void openSupportForm(SupportContent content, SupportFormKind kind,
        {String? prefillType}) =>
    _push(SupportFormScreen(
        content: content, kind: kind, prefillType: prefillType));

/// Opens a category: FAQ categories show subcategories, the two form
/// categories show their issue / suggestion types.
void openSupportCategory(SupportContent content, SupportCategory category) {
  switch (category.id) {
    case 'report_problem':
      _push(SupportOptionListScreen(
          content: content, kind: SupportFormKind.report, category: category));
      break;
    case 'suggest_feature':
      _push(SupportOptionListScreen(
          content: content, kind: SupportFormKind.feature, category: category));
      break;
    default:
      _push(SupportCategoryScreen(content: content, category: category));
  }
}

Future<void> runSupportAction(SupportContent content, SupportAction action,
    {SupportFaq? faq}) async {
  switch (action.type) {
    case 'support_chat':
      openSupportChat();
      return;
    case 'support_form':
      openSupportForm(
        content,
        action.target == 'suggest_feature'
            ? SupportFormKind.feature
            : SupportFormKind.report,
        prefillType: action.prefillType,
      );
      return;
    case 'system_action':
      if (action.target == 'device_notification_settings') {
        await openAppSettings();
        return;
      }
      final url = SupportActions.urlFor(action.target);
      if (url == null) return;
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      return;
  }
}

/// Screens 3 & 4: subcategories of a FAQ category.
class SupportCategoryScreen extends StatelessWidget {
  const SupportCategoryScreen({
    super.key,
    required this.content,
    required this.category,
  });

  final SupportContent content;
  final SupportCategory category;

  @override
  Widget build(BuildContext context) {
    final subs = category.subcategories;
    return SupportScaffold(
      title: '',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          SupportHero(
            icon: supportIcon(category.icon),
            title: category.title,
            subtitle: category.subtitle,
          ),
          for (final s in subs)
            SupportTile(
              icon: supportIcon(s.icon),
              title: s.title,
              subtitle: s.subtitle,
              onTap: () {
                final faqs = content.faqsFor(category.id, s.id);
                if (faqs.length == 1) {
                  openSupportFaq(content, faqs.first);
                } else {
                  _push(SupportFaqListScreen(
                    content: content,
                    title: s.title,
                    icon: supportIcon(s.icon),
                    subtitle: s.subtitle,
                    faqs: faqs,
                  ));
                }
              },
            ),
        ],
      ),
    );
  }
}

/// FAQs of one subcategory.
class SupportFaqListScreen extends StatelessWidget {
  const SupportFaqListScreen({
    super.key,
    required this.content,
    required this.title,
    required this.faqs,
    this.icon,
    this.subtitle,
  });

  final SupportContent content;
  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<SupportFaq> faqs;

  @override
  Widget build(BuildContext context) {
    return SupportScaffold(
      title: '',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          SupportHero(
            icon: icon ?? Icons.help_outline_rounded,
            title: title,
            subtitle: subtitle,
          ),
          for (final f in faqs)
            SupportTile(
              title: f.question,
              subtitle: f.preview,
              onTap: () => openSupportFaq(content, f),
            ),
        ],
      ),
    );
  }
}

/// Screens 5 & 6: Report a Problem / Suggest a Feature type lists.
class SupportOptionListScreen extends StatelessWidget {
  const SupportOptionListScreen({
    super.key,
    required this.content,
    required this.kind,
    required this.category,
  });

  final SupportContent content;
  final SupportFormKind kind;
  final SupportCategory category;

  @override
  Widget build(BuildContext context) {
    final isReport = kind == SupportFormKind.report;
    final section =
        content.section(isReport ? 'report_problem' : 'feature_request');
    final options = isReport
        ? content.reportIssueTypes(listOnly: true)
        : content.featureTypes();
    final subtitle = content.resolve(
        (isReport ? section['intro'] : section['subtitle'])?.toString() ??
            category.subtitle);
    return SupportScaffold(
      title: '',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          SupportHero(
            icon: supportIcon(category.icon),
            title: category.title,
            subtitle: subtitle,
          ),
          for (final o in options)
            SupportTile(
              icon: supportIcon(o.icon),
              title: o.label,
              subtitle: o.subtitle,
              onTap: () => openSupportForm(content, kind, prefillType: o.id),
            ),
        ],
      ),
    );
  }
}

/// Screen 7: all popular questions with search.
class SupportPopularScreen extends StatefulWidget {
  const SupportPopularScreen({super.key, required this.content});

  final SupportContent content;

  @override
  State<SupportPopularScreen> createState() => _SupportPopularScreenState();
}

class _SupportPopularScreenState extends State<SupportPopularScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = SupportPalette.of(context);
    final c = widget.content;
    final home = c.section('support_home');
    final results = c.search(_query);
    return SupportScaffold(
      title:
          c.resolve(home['popular_title']?.toString() ?? 'Popular Questions'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Container(
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: p.border),
            ),
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
              style: TextStyle(color: p.ink, fontSize: 14.5),
              decoration: InputDecoration(
                hintText: c.resolve(
                    home['all_questions_search_placeholder']?.toString() ??
                        'Search help topics...'),
                hintStyle: TextStyle(color: p.muted),
                prefixIcon: Icon(Icons.search_rounded, color: p.muted),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (results.isEmpty)
            SupportCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Text(
                    'No matching help topics.',
                    style: TextStyle(color: p.ink, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  SupportPrimaryButton(
                    label: c.resolve(
                        home['cant_find_cta']?.toString() ?? 'Ask App Support'),
                    onPressed: () => openSupportChat(question: _query),
                  ),
                ],
              ),
            )
          else
            SupportCard(
              child: Column(
                children: [
                  for (var i = 0; i < results.length; i++)
                    SupportQuestionRow(
                      text: results[i].question,
                      showDivider: i < results.length - 1,
                      onTap: () => openSupportFaq(c, results[i]),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Screen 8: FAQ answer from the JSON.
class SupportFaqScreen extends StatefulWidget {
  const SupportFaqScreen({super.key, required this.content, required this.faq});

  final SupportContent content;
  final SupportFaq faq;

  @override
  State<SupportFaqScreen> createState() => _SupportFaqScreenState();
}

class _SupportFaqScreenState extends State<SupportFaqScreen> {
  bool? _helpful;

  @override
  Widget build(BuildContext context) {
    final p = SupportPalette.of(context);
    final c = widget.content;
    final faq = widget.faq;
    final feedback = c.section('answer_feedback');
    final steps = faq.steps;
    final actions = faq.actions;
    final related = faq.related;

    return SupportScaffold(
      title: '',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          SupportCard(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: p.iconBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.menu_book_outlined,
                          color: p.accent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(faq.question, style: p.serif(21))),
                  ],
                ),
                if (faq.answerTitle.isNotEmpty &&
                    faq.answerTitle != faq.question) ...[
                  const SizedBox(height: 14),
                  Text(
                    faq.answerTitle,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: p.accent,
                    ),
                  ),
                ],
                if (faq.body.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(faq.body,
                      style:
                          TextStyle(fontSize: 15, color: p.ink, height: 1.5)),
                ],
                for (final extra in faq.extraParagraphs) ...[
                  const SizedBox(height: 10),
                  Text(extra,
                      style:
                          TextStyle(fontSize: 15, color: p.ink, height: 1.5)),
                ],
                if (steps.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  for (var i = 0; i < steps.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: p.isDark
                                  ? const Color(0xFF8A5530)
                                  : p.headerTop,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              steps[i],
                              style: TextStyle(
                                  fontSize: 15, color: p.ink, height: 1.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  for (final a in actions)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: SupportPrimaryButton(
                        label: a.label,
                        onPressed: () => runSupportAction(c, a, faq: faq),
                      ),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _feedback(p, feedback),
          if (related.isNotEmpty) ...[
            const SizedBox(height: 22),
            Text(
              c.resolve(c.section('faq_detail')['related_title']?.toString() ??
                  'Related Articles'),
              style: p.serif(18),
            ),
            const SizedBox(height: 10),
            SupportCard(
              child: Column(
                children: [
                  for (var i = 0; i < related.length; i++)
                    SupportQuestionRow(
                      text: related[i].question,
                      showDivider: i < related.length - 1,
                      onTap: () => openSupportFaq(c, related[i]),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _feedback(SupportPalette p, Map<String, dynamic> feedback) {
    final c = widget.content;
    if (_helpful == null) {
      return Row(
        children: [
          Expanded(
            child: Text(
              c.resolve(feedback['prompt']?.toString() ?? 'Was this helpful?'),
              style: TextStyle(
                  fontSize: 14.5, color: p.ink, fontWeight: FontWeight.w600),
            ),
          ),
          _feedbackButton(
            p,
            Icons.thumb_up_alt_outlined,
            c.resolve(feedback['yes_label']?.toString() ?? 'Yes'),
            () => setState(() => _helpful = true),
          ),
          const SizedBox(width: 8),
          _feedbackButton(
            p,
            Icons.thumb_down_alt_outlined,
            c.resolve(feedback['no_label']?.toString() ?? 'No'),
            () => setState(() => _helpful = false),
          ),
        ],
      );
    }
    if (_helpful == true) {
      return Text(
        c.resolve(feedback['yes_response']?.toString() ?? ''),
        style: TextStyle(
            fontSize: 14.5, color: p.accent, fontWeight: FontWeight.w600),
      );
    }
    final onNo = (feedback['on_no'] as Map?)?['actions'];
    final label = onNo is List && onNo.isNotEmpty && onNo.first is Map
        ? c.resolve((onNo.first as Map)['label']?.toString() ?? '')
        : 'Ask App Support';
    return SupportCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            c.resolve(feedback['no_response']?.toString() ?? ''),
            style: TextStyle(fontSize: 14.5, color: p.ink),
          ),
          const SizedBox(height: 10),
          SupportPrimaryButton(
            label: label,
            onPressed: () => openSupportChat(question: widget.faq.question),
          ),
        ],
      ),
    );
  }

  Widget _feedbackButton(
      SupportPalette p, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: p.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: p.accent),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: p.ink, fontSize: 13.5, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
