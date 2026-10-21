import 'dart:convert';
import 'dart:io';

import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:flutter/services.dart';

/// Reads `assets/support_content.v1.4.json` and applies its visibility,
/// placeholder and platform rules. Read-only; never sends anything.
class SupportContent {
  SupportContent._(this.raw);

  static const String assetPath = 'assets/support_content.v1.4.json';

  /// Feature flags this app supports (see `feature_flags` in the JSON).
  static Set<String> enabledFeatures = {
    'downloadable_content',
    'resume_position',
    'audio',
    'audio_playback_controls',
    'verse_images',
    'daily_verse',
    'reading_plans',
    'widgets',
    'wallpapers',
    'streaks',
    'account',
    'backup_sync',
    'credits',
    'premium',
    'subscriptions',
    'free_trial',
    'bible_assistant',
    'prayer',
    'ads',
    'rewarded_ads',
    'generated_or_shared_content',
    'ai_chat',
    'ai_length_credits',
    'ai_prayer',
    'prayer_wall',
    'offline_daily_content',
    if (BibleInfo.folders.length > 1) 'multiple_versions',
  };

  static SupportContent? _cache;

  static Future<SupportContent> load() async {
    final cached = _cache;
    if (cached != null) return cached;
    final text = await rootBundle.loadString(assetPath);
    final content =
        SupportContent._(Map<String, dynamic>.from(jsonDecode(text) as Map));
    _cache = content;
    return content;
  }

  final Map<String, dynamic> raw;

  Map<String, dynamic> section(String key) =>
      Map<String, dynamic>.from((raw[key] as Map?) ?? const {});

  String text(String sectionKey, String key, [String fallback = '']) =>
      resolve(section(sectionKey)[key]?.toString() ?? fallback);

  // ---- placeholders ----

  static String get storeName =>
      Platform.isIOS ? 'the App Store' : 'Google Play';

  String resolve(String input) {
    if (!input.contains('{{')) return input;
    final fallbacks = Map<String, dynamic>.from(
        ((raw['variables'] as Map?)?['fallbacks'] as Map?) ?? const {});
    final values = <String, String>{
      'APP_NAME': BibleInfo.bible_shortName,
      'STORE_NAME': storeName,
    };
    return input.replaceAllMapped(RegExp(r'\{\{(\w+)\}\}'), (m) {
      final key = m.group(1)!;
      final v = values[key] ?? '';
      if (v.isNotEmpty) return v;
      return fallbacks[key]?.toString() ?? '';
    });
  }

  // ---- visibility ----

  static List<String> _list(dynamic v) =>
      v is List ? v.map((e) => e.toString()).toList() : const [];

  bool isVisible(Map item) {
    final all = _list(item['requires_feature']);
    if (!all.every(enabledFeatures.contains)) return false;
    final any = _list(item['requires_any_feature']);
    if (any.isNotEmpty && !any.any(enabledFeatures.contains)) return false;
    final none = _list(item['excludes_feature']);
    if (none.any(enabledFeatures.contains)) return false;
    return true;
  }

  // ---- categories ----

  List<SupportCategory> get categories {
    final list = ((raw['categories'] as List?) ?? const [])
        .whereType<Map>()
        .where(isVisible)
        .map((m) => SupportCategory(Map<String, dynamic>.from(m), this))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return list;
  }

  SupportCategory? category(String id) {
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  // ---- FAQ ----

  List<SupportFaq>? _faqs;

  List<SupportFaq> get faqs => _faqs ??= ((raw['faq'] as List?) ?? const [])
      .whereType<Map>()
      .where(isVisible)
      .map((m) => SupportFaq(Map<String, dynamic>.from(m), this))
      .toList();

  SupportFaq? faq(String id) {
    for (final f in faqs) {
      if (f.id == id) return f;
    }
    return null;
  }

  List<SupportFaq> faqsFor(String categoryId, [String? subcategoryId]) {
    final list = faqs
        .where((f) =>
            f.categoryId == categoryId &&
            (subcategoryId == null || f.subcategoryId == subcategoryId))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return list;
  }

  /// Visible FAQs with a popular_rank, best first.
  List<SupportFaq> get popularFaqs {
    final list = faqs.where((f) => f.popularRank != null).toList()
      ..sort((a, b) => a.popularRank!.compareTo(b.popularRank!));
    return list;
  }

  int get popularLimit =>
      (section('support_home')['popular_limit'] as num?)?.toInt() ?? 5;

  List<SupportFaq> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return popularFaqs;
    final words = q.split(RegExp(r'\s+')).where((w) => w.length > 1).toList();
    final scored = <SupportFaq, int>{};
    for (final f in faqs) {
      final question = f.question.toLowerCase();
      final keywords = f.keywords.map((k) => k.toLowerCase()).toList();
      var score = 0;
      if (question.contains(q)) score += 10;
      if (keywords.any((k) => k.contains(q) || q.contains(k))) score += 8;
      for (final w in words) {
        if (question.contains(w)) score += 2;
        if (keywords.any((k) => k.contains(w))) score += 1;
      }
      if (score > 0) scored[f] = score;
    }
    final list = scored.keys.toList()
      ..sort((a, b) => scored[b]!.compareTo(scored[a]!));
    return list;
  }

  /// Chat-side match per `support_chat.routing.local_match`.
  /// [best] = confident answer, else [suggestions] for "Did you mean...".
  ({SupportFaq? best, List<SupportFaq> suggestions}) localMatch(String text) {
    const none = (best: null, suggestions: <SupportFaq>[]);
    final routing = Map<String, dynamic>.from(
        ((section('support_chat')['routing'] as Map?)?['local_match']
                as Map?) ??
            const {});
    if (routing['enabled'] == false) return none;
    final q = _normalize(text);
    if (q.isEmpty) return none;
    final maxWords =
        (routing['max_words_for_auto_answer'] as num?)?.toInt() ?? 12;
    final words = q.split(' ');
    if (words.length > maxWords) return none;

    final qTokens = _tokens(q);
    final scores = <SupportFaq, int>{};
    for (final f in faqs) {
      final question = _normalize(f.question);
      var score = 0;
      if (question == q) score += 100;
      if (question.contains(q) || q.contains(question)) score += 10;
      final keywordTokens = <String>{};
      for (final k in f.keywords) {
        final key = _normalize(k);
        if (key.isEmpty) continue;
        keywordTokens.addAll(_tokens(key));
        if (q.contains(key)) score += 8 + key.split(' ').length;
      }
      final questionTokens = _tokens(question);
      for (final t in qTokens) {
        if (questionTokens.contains(t)) {
          score += 3;
        } else if (keywordTokens.contains(t)) {
          score += 2;
        }
      }
      if (score > 0) scores[f] = score;
    }
    if (scores.isEmpty) return none;
    final ranked = scores.keys.toList()
      ..sort((a, b) => scores[b]!.compareTo(scores[a]!));
    final top = scores[ranked.first]!;
    if (top < 3) return none;
    final second = ranked.length > 1 ? scores[ranked[1]]! : 0;
    final max =
        ((routing['on_ambiguous_match'] as Map?)?['max_suggestions'] as num?)
                ?.toInt() ??
            3;
    final suggestions = ranked
        .where((f) => scores[f]! >= 3 && scores[f]! >= top * 0.6)
        .take(max)
        .toList();
    if (top >= 8 && top >= second * 1.25 || suggestions.length == 1) {
      return (best: ranked.first, suggestions: <SupportFaq>[]);
    }
    return (best: null, suggestions: suggestions);
  }

  static const _stopWords = {
    'the',
    'and',
    'for',
    'how',
    'can',
    'does',
    'did',
    'why',
    'what',
    'where',
    'when',
    'who',
    'you',
    'your',
    'my',
    'mine',
    'is',
    'are',
    'was',
    'not',
    "isn't",
    "doesn't",
    "don't",
    "can't",
    "won't",
    'with',
    'this',
    'that',
    'from',
    'have',
    'has',
    'get',
    'use',
    'any',
    'all',
    'app',
    'into',
    'out',
    'it',
    "it's",
    'its',
    'will',
    'there',
    'they',
    'them',
    'our',
    'about',
    'keep',
    'keeps',
    'still',
    'please',
    'help',
    'want',
    'need',
    'work',
    'works',
    'working',
  };

  /// Meaningful words, lightly stemmed so "crashes"/"crashing" both match.
  static Set<String> _tokens(String normalized) => normalized
      .split(' ')
      .where((w) => w.length > 2 && !_stopWords.contains(w))
      .map(_stem)
      .toSet();

  static String _stem(String w) {
    for (final suffix in ['ing', 'es', 'ed', 's']) {
      if (w.length > suffix.length + 3 && w.endsWith(suffix)) {
        return w.substring(0, w.length - suffix.length);
      }
    }
    return w;
  }

  String get ambiguousMessage =>
      resolve(((((section('support_chat')['routing'] as Map?)?['local_match']
                  as Map?)?['on_ambiguous_match'] as Map?)?['message'])
              ?.toString() ??
          'Did you mean one of these?');

  static String _normalize(String s) => s
      .toLowerCase()
      .replaceAll('’', "'")
      .replaceAll(RegExp(r"[^a-z0-9' ]"), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  // ---- forms ----

  List<SupportOption> reportIssueTypes({bool listOnly = false}) {
    final types = (section('report_problem')['issue_types'] as List?) ?? [];
    return types
        .whereType<Map>()
        .where(isVisible)
        .where((m) => !listOnly || m['show_in_list'] == true)
        .map((m) => SupportOption(Map<String, dynamic>.from(m), this))
        .toList();
  }

  List<SupportOption> featureTypes() {
    final types = (section('feature_request')['feature_types'] as List?) ?? [];
    return types
        .whereType<Map>()
        .where(isVisible)
        .map((m) => SupportOption(Map<String, dynamic>.from(m), this))
        .toList();
  }

  List<Map<String, dynamic>> formFields(String sectionKey) =>
      ((section(sectionKey)['fields'] as List?) ?? const [])
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();

  /// Visible suggested chat prompts, limited per `suggested_prompts_limit`.
  List<String> get suggestedPrompts {
    final chat = section('support_chat');
    final limit = (chat['suggested_prompts_limit'] as num?)?.toInt() ?? 4;
    return ((chat['suggested_prompts'] as List?) ?? const [])
        .whereType<Map>()
        .where(isVisible)
        .map((m) => resolve(m['text']?.toString() ?? ''))
        .where((t) => t.isNotEmpty)
        .take(limit)
        .toList();
  }

  String get chatWelcome {
    final chat = section('support_chat');
    final purchases = enabledFeatures.contains('premium') ||
        enabledFeatures.contains('credits');
    return resolve((purchases
                ? chat['welcome_message']
                : chat['welcome_message_no_purchases'])
            ?.toString() ??
        '');
  }
}

class SupportCategory {
  SupportCategory(this.raw, this.content);
  final Map<String, dynamic> raw;
  final SupportContent content;

  String get id => raw['id']?.toString() ?? '';
  String get title => content.resolve(raw['title']?.toString() ?? '');
  String get subtitle => content.resolve(raw['subtitle']?.toString() ?? '');
  String get homeSubtitle => content
      .resolve((raw['home_subtitle'] ?? raw['subtitle'])?.toString() ?? '');
  String get icon => raw['icon']?.toString() ?? '';
  int get order => (raw['order'] as num?)?.toInt() ?? 0;

  /// Visible subcategories that still have at least one visible FAQ.
  List<SupportSubcategory> get subcategories {
    final list = ((raw['subcategories'] as List?) ?? const [])
        .whereType<Map>()
        .where(content.isVisible)
        .map((m) => SupportSubcategory(Map<String, dynamic>.from(m), this))
        .where((s) => content.faqsFor(id, s.id).isNotEmpty)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return list;
  }
}

class SupportSubcategory {
  SupportSubcategory(this.raw, this.category);
  final Map<String, dynamic> raw;
  final SupportCategory category;

  String get id => raw['id']?.toString() ?? '';
  String get title => category.content.resolve(raw['title']?.toString() ?? '');
  String get subtitle =>
      category.content.resolve(raw['subtitle']?.toString() ?? '');
  String get icon => raw['icon']?.toString() ?? '';
  int get order => (raw['order'] as num?)?.toInt() ?? 0;
}

class SupportOption {
  SupportOption(this.raw, this.content);
  final Map<String, dynamic> raw;
  final SupportContent content;

  String get id => raw['id']?.toString() ?? '';
  String get label => content.resolve(raw['label']?.toString() ?? '');
  String get subtitle => content.resolve(raw['ui_subtitle']?.toString() ?? '');
  String get icon => raw['icon']?.toString() ?? '';

  List<SupportFaq> get quickFixes =>
      SupportContent._list(raw['quick_fix_faq_ids'])
          .map(content.faq)
          .whereType<SupportFaq>()
          .toList();
}

class SupportAction {
  const SupportAction({
    required this.type,
    required this.label,
    required this.target,
    this.prefillType,
  });
  final String type;
  final String label;
  final String target;
  final String? prefillType;
}

class SupportFaq {
  SupportFaq(this.raw, this.content);
  final Map<String, dynamic> raw;
  final SupportContent content;

  String get id => raw['id']?.toString() ?? '';
  String get categoryId => raw['category_id']?.toString() ?? '';
  String get subcategoryId => raw['subcategory_id']?.toString() ?? '';
  int get order => (raw['order'] as num?)?.toInt() ?? 0;
  int? get popularRank => (raw['popular_rank'] as num?)?.toInt();
  String get question => content.resolve(raw['question']?.toString() ?? '');
  String get preview => content.resolve(raw['preview']?.toString() ?? '');
  List<String> get keywords => SupportContent._list(raw['keywords']);

  Map<String, dynamic> get _answer {
    final base = Map<String, dynamic>.from((raw['answer'] as Map?) ?? const {});
    final overrides = raw['platform_overrides'];
    if (overrides is Map) {
      final platform = overrides[Platform.isIOS ? 'ios' : 'android'];
      if (platform is Map) base.addAll(Map<String, dynamic>.from(platform));
    }
    return base;
  }

  String get answerTitle =>
      content.resolve(_answer['title']?.toString() ?? question);

  String get body => content.resolve(_answer['body']?.toString() ?? '');

  List<String> get _appendTexts =>
      ((_answer['append_if_feature'] as List?) ?? const [])
          .whereType<Map>()
          .where((m) =>
              SupportContent.enabledFeatures.contains(m['feature']?.toString()))
          .map((m) => content.resolve(m['text']?.toString() ?? ''))
          .where((t) => t.isNotEmpty)
          .toList();

  /// Steps, with conditional text appended as extra final steps.
  List<String> get steps {
    final base =
        SupportContent._list(_answer['steps']).map(content.resolve).toList();
    if (base.isEmpty) return base;
    return [...base, ..._appendTexts];
  }

  /// Extra paragraphs when the answer has no steps.
  List<String> get extraParagraphs =>
      SupportContent._list(_answer['steps']).isEmpty ? _appendTexts : const [];

  bool get offerHuman => (raw['escalation'] as Map?)?['offer_human'] == true;

  List<SupportAction> get actions {
    final registry = content.section('action_registry');
    final requirements = Map<String, dynamic>.from(
        (registry['route_requirements'] as Map?) ?? const {});
    final result = <SupportAction>[];
    for (final a in ((raw['actions'] as List?) ?? const []).whereType<Map>()) {
      final type = a['type']?.toString() ?? '';
      final target = a['target']?.toString() ?? '';
      if (!SupportActions.supports(type, target)) continue;
      final req = requirements[target];
      if (req is Map && !content.isVisible(req)) continue;
      result.add(SupportAction(
        type: type,
        label: content.resolve(a['label']?.toString() ?? ''),
        target: target,
        prefillType: a['prefill_type']?.toString(),
      ));
    }
    return result;
  }

  List<SupportFaq> get related {
    final limit =
        (content.section('faq_detail')['related_limit'] as num?)?.toInt() ?? 3;
    return SupportContent._list(raw['related_faq_ids'])
        .map(content.faq)
        .whereType<SupportFaq>()
        .take(limit)
        .toList();
  }
}

/// Which action targets this app implements. Anything else is hidden.
class SupportActions {
  SupportActions._();

  static bool supports(String type, String target) {
    switch (type) {
      case 'support_chat':
        return target == 'support_chat' || target == 'human_handoff';
      case 'support_form':
        return target == 'report_problem' || target == 'suggest_feature';
      case 'system_action':
        return const {
          'subscription_management',
          'store_purchase_support',
          'app_store_update',
          'device_notification_settings',
          'privacy_policy',
          'terms_of_use',
        }.contains(target);
      default:
        return false;
    }
  }

  static String? urlFor(String target) {
    switch (target) {
      case 'subscription_management':
      case 'store_purchase_support':
        return Platform.isIOS
            ? 'https://apps.apple.com/account/subscriptions'
            : 'https://play.google.com/store/account/subscriptions';
      case 'app_store_update':
        return Platform.isIOS
            ? 'https://apps.apple.com/app/id${BibleInfo.apple_AppId}'
            : 'https://play.google.com/store/apps/details?id=${BibleInfo.android_Package_Name}';
      case 'privacy_policy':
        return BibleInfo.privacyPolicyURL;
      case 'terms_of_use':
        return BibleInfo.termsandConditionURL;
      default:
        return null;
    }
  }
}
