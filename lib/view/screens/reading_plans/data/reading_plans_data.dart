import 'package:biblebookapp/view/screens/reading_plans/models/reading_plan_model.dart';

/// Presentation-only Reading Plan catalog.
/// 7-day keeps original topics; 15 / 30 / 50 each use different topics,
/// verses, and background images. Does not alter Study Plans or DB logic.
class ReadingPlansData {
  ReadingPlansData._();

  static const List<int> durations = [7, 15, 30, 50];

  static const String _imgLove =
      'assets/study_plan_images/Gemini_Generated_Image_uwge7ruwge7ruwge.png';
  static const String _imgJoy = 'assets/study_plan_images/Joy Scene.png';
  static const String _imgFaith = 'assets/study_plan_images/Faith Scene.png';
  static const String _imgPeace =
      'assets/study_plan_images/Peace Symbol Integration.png';
  static const String _imgHope =
      'assets/study_plan_images/Hope and Love Scene.png';
  static const String _imgWisdom =
      'assets/study_plan_images/Peace and Wisdom Scene.png';
  static const String _imgCourage = 'assets/study_plan_images/Courage Scene.png';
  static const String _imgForgive =
      'assets/study_plan_images/Gemini_Generated_Image_5weyjf5weyjf5wey.png';
  static const String _imgHeal = 'assets/study_plan_images/Healing Scene.png';

  /// Topics are scoped per duration — not shared across 7 / 15 / 30 / 50.
  static final Map<int, List<_TopicSpec>> _topicsByDuration = {
    // —— 7 days (original topics) ——
    7: [
      _TopicSpec(
        topic: 'Love',
        description: 'Grow in God’s love and share it with others.',
        backgroundAsset: _imgLove,
        verses: _vLove,
      ),
      _TopicSpec(
        topic: 'Joy',
        description: 'Rediscover lasting joy rooted in Christ.',
        backgroundAsset: _imgJoy,
        verses: _vJoy,
      ),
      _TopicSpec(
        topic: 'Faith',
        description: 'Strengthen trust in God’s promises.',
        backgroundAsset: _imgFaith,
        verses: _vFaith,
      ),
      _TopicSpec(
        topic: 'Peace',
        description: 'Rest in the peace that surpasses understanding.',
        backgroundAsset: _imgPeace,
        verses: _vPeace,
      ),
      _TopicSpec(
        topic: 'Hope',
        description: 'Hold onto hope through every season.',
        backgroundAsset: _imgHope,
        verses: _vHope,
      ),
      _TopicSpec(
        topic: 'Wisdom',
        description: 'Walk in godly wisdom for daily life.',
        backgroundAsset: _imgWisdom,
        verses: _vWisdom,
      ),
      _TopicSpec(
        topic: 'Courage',
        description: 'Face challenges with bold faith.',
        backgroundAsset: _imgCourage,
        verses: _vCourage,
      ),
      _TopicSpec(
        topic: 'Forgiveness',
        description: 'Receive and extend forgiveness freely.',
        backgroundAsset: _imgForgive,
        verses: _vForgiveness,
      ),
      _TopicSpec(
        topic: 'Healing',
        description: 'Find restoration for body, mind, and spirit.',
        backgroundAsset: _imgHeal,
        verses: _vHealing,
      ),
    ],

    // —— 15 days (different topics + images) ——
    15: [
      _TopicSpec(
        topic: 'Grace',
        description: 'Live in the gift of God’s unearned favor.',
        backgroundAsset: _imgHeal,
        verses: _vGrace,
      ),
      _TopicSpec(
        topic: 'Trust',
        description: 'Lean on the Lord in every decision.',
        backgroundAsset: _imgWisdom,
        verses: _vTrust,
      ),
      _TopicSpec(
        topic: 'Gratitude',
        description: 'Cultivate a thankful heart each day.',
        backgroundAsset: _imgJoy,
        verses: _vGratitude,
      ),
      _TopicSpec(
        topic: 'Patience',
        description: 'Wait on God with steady endurance.',
        backgroundAsset: _imgPeace,
        verses: _vPatience,
      ),
      _TopicSpec(
        topic: 'Kindness',
        description: 'Reflect Christ’s kindness to others.',
        backgroundAsset: _imgHope,
        verses: _vKindness,
      ),
      _TopicSpec(
        topic: 'Humility',
        description: 'Walk gently under God’s mighty hand.',
        backgroundAsset: _imgForgive,
        verses: _vHumility,
      ),
      _TopicSpec(
        topic: 'Prayer',
        description: 'Deepen your daily conversation with God.',
        backgroundAsset: _imgFaith,
        verses: _vPrayer,
      ),
      _TopicSpec(
        topic: 'Worship',
        description: 'Lift your heart in praise and adoration.',
        backgroundAsset: _imgCourage,
        verses: _vWorship,
      ),
      _TopicSpec(
        topic: 'Light',
        description: 'Shine as light in a dark world.',
        backgroundAsset: _imgLove,
        verses: _vLight,
      ),
    ],

    // —— 30 days (different topics + images) ——
    30: [
      _TopicSpec(
        topic: 'Strength',
        description: 'Find strength renewed in the Lord.',
        backgroundAsset: _imgCourage,
        verses: _vStrength,
      ),
      _TopicSpec(
        topic: 'Comfort',
        description: 'Receive God’s comfort in hard seasons.',
        backgroundAsset: _imgHope,
        verses: _vComfort,
      ),
      _TopicSpec(
        topic: 'Guidance',
        description: 'Follow God’s leading step by step.',
        backgroundAsset: _imgWisdom,
        verses: _vGuidance,
      ),
      _TopicSpec(
        topic: 'Renewal',
        description: 'Be transformed by a renewed mind.',
        backgroundAsset: _imgHeal,
        verses: _vRenewal,
      ),
      _TopicSpec(
        topic: 'Rest',
        description: 'Enter the rest God offers your soul.',
        backgroundAsset: _imgPeace,
        verses: _vRest,
      ),
      _TopicSpec(
        topic: 'Purpose',
        description: 'Live with God-shaped purpose.',
        backgroundAsset: _imgFaith,
        verses: _vPurpose,
      ),
      _TopicSpec(
        topic: 'Mercy',
        description: 'Receive and show the mercy of God.',
        backgroundAsset: _imgForgive,
        verses: _vMercy,
      ),
      _TopicSpec(
        topic: 'Truth',
        description: 'Stand firm in the truth of Scripture.',
        backgroundAsset: _imgLove,
        verses: _vTruth,
      ),
      _TopicSpec(
        topic: 'Freedom',
        description: 'Walk in the freedom Christ purchased.',
        backgroundAsset: _imgJoy,
        verses: _vFreedom,
      ),
    ],

    // —— 50 days (different topics + images) ——
    50: [
      _TopicSpec(
        topic: 'Discipleship',
        description: 'Follow Jesus more closely day by day.',
        backgroundAsset: _imgFaith,
        verses: _vDiscipleship,
      ),
      _TopicSpec(
        topic: 'Stewardship',
        description: 'Honor God with all He has entrusted.',
        backgroundAsset: _imgWisdom,
        verses: _vStewardship,
      ),
      _TopicSpec(
        topic: 'Perseverance',
        description: 'Press on through trials with endurance.',
        backgroundAsset: _imgCourage,
        verses: _vPerseverance,
      ),
      _TopicSpec(
        topic: 'Holiness',
        description: 'Pursue a life set apart for God.',
        backgroundAsset: _imgLove,
        verses: _vHoliness,
      ),
      _TopicSpec(
        topic: 'Compassion',
        description: 'Care for others with Christlike heart.',
        backgroundAsset: _imgHeal,
        verses: _vCompassion,
      ),
      _TopicSpec(
        topic: 'Integrity',
        description: 'Live uprightly in private and public.',
        backgroundAsset: _imgForgive,
        verses: _vIntegrity,
      ),
      _TopicSpec(
        topic: 'Kingdom',
        description: 'Seek first the kingdom of God.',
        backgroundAsset: _imgHope,
        verses: _vKingdom,
      ),
      _TopicSpec(
        topic: 'Fruitfulness',
        description: 'Abide in Christ and bear lasting fruit.',
        backgroundAsset: _imgJoy,
        verses: _vFruitfulness,
      ),
      _TopicSpec(
        topic: 'Presence',
        description: 'Abide in the nearness of God.',
        backgroundAsset: _imgPeace,
        verses: _vPresence,
      ),
    ],
  };

  static List<List<String>> _buildDays(List<String> pool, int days) {
    final safe = pool.isEmpty
        ? const <String>['John 3:16', 'Romans 5:8', '1 John 4:8']
        : pool;
    final out = <List<String>>[];
    for (var d = 0; d < days; d++) {
      final base = d * 3;
      out.add([
        safe[base % safe.length],
        safe[(base + 1) % safe.length],
        safe[(base + 2) % safe.length],
      ]);
    }
    return out;
  }

  static List<ReadingPlan> get allPlans {
    final plans = <ReadingPlan>[];
    for (final days in durations) {
      final specs = _topicsByDuration[days] ?? const <_TopicSpec>[];
      for (final spec in specs) {
        final slug = spec.topic.toLowerCase().replaceAll(' ', '-');
        plans.add(
          ReadingPlan(
            id: 'rp-$slug-$days',
            title: '$days-Day ${spec.topic} Plan',
            topic: spec.topic,
            description: spec.description,
            durationDays: days,
            dayVerses: _buildDays(spec.verses, days),
            backgroundAsset: spec.backgroundAsset,
          ),
        );
      }
    }
    return plans;
  }

  static List<ReadingPlan> plansForDuration(int? days) {
    if (days == null) return allPlans;
    return allPlans.where((p) => p.durationDays == days).toList();
  }

  static ReadingPlan? byId(String id) {
    try {
      return allPlans.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  // ——— Verse pools (7-day originals) ———
  static const List<String> _vLove = [
    'John 3:16', 'Romans 8:38-39', '1 John 4:8', 'Ephesians 3:17-19',
    'Jeremiah 31:3', 'Matthew 22:39', '1 Corinthians 13:4-7', 'John 13:34-35',
    'Romans 13:10', 'Galatians 5:14', 'Ephesians 5:2', 'Colossians 3:14',
    '1 Peter 4:8', '1 John 3:18', 'Philippians 1:9-10', 'Romans 5:8',
    '1 John 4:19', 'Deuteronomy 6:5', 'Mark 12:30-31', 'Luke 6:27',
    'John 15:12', 'Romans 12:9', '1 Thessalonians 3:12',
  ];
  static const List<String> _vJoy = [
    'Psalm 51:12', 'Nehemiah 8:10', 'Philippians 4:4', 'Romans 15:13',
    'Psalm 16:11', 'James 1:2-4', 'Romans 5:3-5', '1 Peter 1:6-8',
    'Habakkuk 3:17-18', 'Galatians 5:22-23', 'John 15:11', 'Philippians 1:25',
    'Psalm 100:1-2', 'Isaiah 61:10', 'Psalm 30:5', 'Luke 2:10',
    'John 16:22', 'Psalm 118:24', 'Isaiah 12:3', 'Proverbs 17:22',
    '1 Thessalonians 5:16', 'Psalm 32:11', 'Isaiah 55:12',
  ];
  static const List<String> _vFaith = [
    'Hebrews 11:1', 'Romans 10:17', 'Mark 11:22-24', 'James 1:6',
    'Matthew 21:22', 'Hebrews 11:6', '2 Corinthians 5:7', 'Ephesians 2:8-9',
    'Galatians 2:20', 'Romans 1:17', 'Matthew 17:20', 'Hebrews 12:2',
    '1 John 5:4', 'Romans 4:20-21', 'James 2:17', 'Proverbs 3:5-6',
    'Psalm 37:5', 'Isaiah 41:10', 'Joshua 1:9', 'John 14:1',
    'Philippians 4:13', 'Hebrews 10:23', 'Psalm 56:3-4',
  ];
  static const List<String> _vPeace = [
    'John 14:27', 'Philippians 4:6-7', 'Isaiah 26:3', 'Colossians 3:15',
    'Romans 5:1', 'Psalm 29:11', 'Matthew 5:9', 'Romans 12:18',
    'Isaiah 9:6', 'Ephesians 2:14', 'Psalm 4:8', 'Psalm 119:165',
    'John 16:33', 'Psalm 46:10', 'Numbers 6:24-26', 'Romans 8:6',
    'Ephesians 4:3', '2 Thessalonians 3:16', 'Isaiah 32:17', 'James 3:18',
    'Mark 4:39', 'Psalm 23:2', 'Isaiah 54:10',
  ];
  static const List<String> _vHope = [
    'Romans 15:13', 'Jeremiah 29:11', 'Psalm 42:5', 'Hebrews 6:19',
    'Romans 5:5', '1 Peter 1:3', 'Lamentations 3:21-23', 'Psalm 71:5',
    'Isaiah 40:31', 'Romans 8:24-25', 'Titus 2:13', 'Colossians 1:27',
    'Psalm 130:5', 'Psalm 31:24', 'Isaiah 43:2', 'Romans 12:12',
    'Hebrews 10:23', 'Psalm 33:18', 'Jeremiah 17:7', '1 Thessalonians 5:8',
    '1 John 3:3', 'Psalm 62:5', 'Micah 7:7',
  ];
  static const List<String> _vWisdom = [
    'Proverbs 3:5-6', 'James 1:5', 'Proverbs 9:10', 'Proverbs 4:7',
    'Colossians 2:3', 'Proverbs 2:6', 'Proverbs 16:16', 'Psalm 111:10',
    'Proverbs 1:7', 'James 3:17', 'Ephesians 5:15-16', 'Psalm 90:12',
    'Proverbs 3:13', 'Proverbs 4:5', 'Matthew 7:24', '1 Corinthians 1:30',
    'Colossians 1:9', 'Proverbs 11:2', 'Proverbs 15:33', 'Isaiah 33:6',
    'Daniel 2:21', 'Proverbs 19:20', 'Romans 11:33',
  ];
  static const List<String> _vCourage = [
    'Joshua 1:9', 'Deuteronomy 31:6', 'Psalm 27:1', 'Isaiah 41:10',
    '2 Timothy 1:7', 'Psalm 31:24', '1 Corinthians 16:13', 'Ephesians 6:10',
    'Hebrews 13:6', 'Psalm 56:3-4', 'Romans 8:31', 'Psalm 118:6',
    'Acts 4:13', '1 Samuel 17:45', 'Isaiah 43:1', 'Matthew 10:28',
    'Luke 12:32', 'John 16:33', 'Romans 8:37', '2 Corinthians 12:9',
    'Philippians 4:13', 'Psalm 23:4', 'Psalm 46:1-2',
  ];
  static const List<String> _vForgiveness = [
    '1 John 1:9', 'Ephesians 1:7', 'Psalm 103:12', 'Micah 7:19',
    'Acts 3:19', 'Matthew 6:14-15', 'Ephesians 4:32', 'Colossians 3:13',
    'Mark 11:25', 'Luke 6:37', 'Matthew 18:21-22', 'Luke 23:34',
    'Isaiah 1:18', 'Isaiah 43:25', 'Psalm 32:1', 'Psalm 51:1-2',
    'Romans 8:1', 'Colossians 1:14', 'Hebrews 8:12', 'James 5:15',
    'Proverbs 17:9', 'Isaiah 55:7', 'Jeremiah 31:34',
  ];
  static const List<String> _vHealing = [
    'Exodus 15:26', 'Psalm 103:2-3', 'Jeremiah 30:17', '3 John 1:2',
    'James 5:14-15', 'Psalm 147:3', 'Isaiah 53:5', '1 Peter 2:24',
    'Psalm 41:3', 'Proverbs 4:20-22', 'Proverbs 3:7-8', 'Psalm 107:20',
    'Matthew 4:23', 'Mark 5:34', 'Luke 4:18', 'Acts 10:38',
    'Isaiah 61:1', 'Psalm 30:2', 'Matthew 8:16-17', 'James 5:16',
    'Revelation 21:4', 'Psalm 23:3', 'Jeremiah 17:14',
  ];

  // ——— 15-day topics ———
  static const List<String> _vGrace = [
    'Ephesians 2:8-9', '2 Corinthians 12:9', 'Romans 5:20', 'Titus 2:11',
    'John 1:16', 'Hebrews 4:16', 'Romans 3:24', '2 Timothy 1:9',
    'Acts 20:32', '1 Peter 5:10', 'James 4:6', 'Romans 6:14',
    '2 Corinthians 9:8', 'Ephesians 1:7', 'Colossians 1:6', '1 Corinthians 15:10',
    'Romans 11:6', 'Galatians 2:21', 'Hebrews 12:15', 'Jude 1:4',
    'Acts 15:11', 'Romans 5:15', '2 Peter 3:18', 'Ephesians 4:7',
    'Titus 3:7', 'Romans 5:17', '1 Timothy 1:14', 'Hebrews 13:9',
    'Acts 4:33', '2 Corinthians 8:9', 'John 1:17', 'Romans 4:16',
    'Galatians 5:4', 'Ephesians 3:2', 'Colossians 4:6', '1 Peter 4:10',
    'Psalm 84:11', 'Psalm 103:8', 'Isaiah 30:18', 'Zechariah 12:10',
    'Luke 2:40', 'Acts 11:23', 'Romans 1:5', '2 Corinthians 1:12',
    'Galatians 1:15',
  ];
  static const List<String> _vTrust = [
    'Proverbs 3:5-6', 'Psalm 37:5', 'Isaiah 26:3', 'Psalm 9:10',
    'Jeremiah 17:7', 'Psalm 56:3', 'Nahum 1:7', 'Psalm 62:8',
    'Isaiah 12:2', 'Psalm 28:7', '2 Samuel 22:31', 'Psalm 91:2',
    'Isaiah 50:10', 'Psalm 118:8', 'Proverbs 16:20', 'Psalm 20:7',
    'Isaiah 41:10', 'Psalm 13:5', 'Job 13:15', 'Psalm 25:2',
    'Isaiah 43:2', 'Psalm 31:14', 'Proverbs 29:25', 'Psalm 40:4',
    'Isaiah 30:15', 'Psalm 84:12', '1 Timothy 4:10', 'Psalm 112:7',
    'Isaiah 26:4', 'Psalm 143:8', '2 Corinthians 1:9', 'Psalm 146:3',
    'Micah 7:7', 'Psalm 4:5', 'Isaiah 57:13', 'Psalm 22:4',
    'Hebrews 2:13', 'Psalm 52:8', 'Isaiah 40:31', 'Psalm 115:9',
    'Romans 15:13', 'Psalm 125:1', 'Isaiah 25:9', 'Psalm 18:2',
    'John 14:1',
  ];
  static const List<String> _vGratitude = [
    '1 Thessalonians 5:18', 'Psalm 100:4', 'Colossians 3:15', 'Psalm 107:1',
    'Ephesians 5:20', 'Psalm 136:1', 'Colossians 2:7', 'Psalm 95:2',
    'Philippians 4:6', 'Psalm 9:1', '1 Chronicles 16:34', 'Psalm 118:24',
    'Colossians 4:2', 'Psalm 30:12', 'Hebrews 12:28', 'Psalm 69:30',
    '2 Corinthians 9:15', 'Psalm 28:7', 'Jonah 2:9', 'Psalm 50:14',
    'Luke 17:16', 'Psalm 92:1', '1 Timothy 4:4', 'Psalm 103:1-2',
    'Colossians 3:17', 'Psalm 116:17', 'Ephesians 1:16', 'Psalm 147:7',
    'Romans 1:21', 'Psalm 105:1', '2 Thessalonians 1:3', 'Psalm 75:1',
    'Daniel 2:23', 'Psalm 34:1', '1 Corinthians 15:57', 'Psalm 86:12',
    'Revelation 11:17', 'Psalm 138:1', 'Isaiah 12:1', 'Psalm 145:10',
    'Nehemiah 12:46', 'Psalm 149:1', 'Ezra 3:11', 'Psalm 66:1-2',
    'Habakkuk 3:18',
  ];
  static const List<String> _vPatience = [
    'Romans 12:12', 'James 5:7-8', 'Galatians 5:22', 'Psalm 37:7',
    'Ecclesiastes 7:8', 'Colossians 1:11', 'Hebrews 10:36', 'Psalm 27:14',
    'Romans 8:25', 'Isaiah 40:31', '2 Peter 3:9', 'Psalm 40:1',
    'Lamentations 3:25-26', 'Proverbs 14:29', '1 Thessalonians 5:14',
    'Psalm 130:5', 'James 1:3-4', 'Proverbs 15:18', 'Romans 15:4',
    'Psalm 25:5', 'Hebrews 6:15', 'Proverbs 16:32', 'Luke 21:19',
    'Psalm 62:5', '2 Timothy 2:24', 'Proverbs 19:11', 'Revelation 3:10',
    'Psalm 33:20', '1 Corinthians 13:4', 'Isaiah 30:18', 'Psalm 37:9',
    'Habakkuk 2:3', 'Micah 7:7', 'Psalm 130:6', 'Romans 2:7',
    'Colossians 3:12', 'Psalm 145:15', 'Isaiah 25:9', 'Psalm 39:7',
    'James 5:11', 'Psalm 119:84', 'Proverbs 25:15', 'Psalm 52:9',
    'Hebrews 12:1',
  ];
  static const List<String> _vKindness = [
    'Ephesians 4:32', 'Colossians 3:12', 'Proverbs 11:17', 'Luke 6:35',
    'Galatians 5:22', 'Proverbs 19:22', 'Micah 6:8', 'Romans 12:10',
    'Titus 3:4', 'Proverbs 31:26', '1 Corinthians 13:4', '2 Samuel 9:1',
    'Zechariah 7:9', 'Proverbs 14:21', 'Isaiah 54:8', 'Proverbs 3:3',
    'Ruth 2:20', 'Psalm 117:2', 'Hosea 6:6', 'Proverbs 16:24',
    'Luke 10:33-34', 'Proverbs 21:21', 'Isaiah 63:7', 'Proverbs 12:25',
    'Acts 28:2', 'Proverbs 15:1', 'Jeremiah 9:24', 'Proverbs 20:28',
    'Romans 2:4', 'Nehemiah 9:17', 'Psalm 141:5', 'Proverbs 25:21-22',
    'Matthew 5:7', 'Psalm 23:6', 'Isaiah 16:5', 'Psalm 36:7',
    '2 Corinthians 6:6', 'Psalm 63:3', 'Joel 2:13', 'Psalm 145:17',
    '1 Peter 2:3', 'Psalm 100:5', 'Lamentations 3:22', 'Psalm 119:76',
    'Isaiah 55:3',
  ];
  static const List<String> _vHumility = [
    'Philippians 2:3-4', 'James 4:6', '1 Peter 5:5-6', 'Micah 6:8',
    'Proverbs 22:4', 'Matthew 23:12', 'Proverbs 11:2', 'Luke 14:11',
    'Romans 12:3', 'Proverbs 16:18', 'Colossians 3:12', 'Proverbs 15:33',
    'Matthew 5:5', 'Proverbs 18:12', 'Isaiah 66:2', 'Proverbs 29:23',
    'John 13:14-15', 'Psalm 25:9', '2 Chronicles 7:14', 'Psalm 147:6',
    'Zephaniah 2:3', 'Psalm 149:4', 'Isaiah 57:15', 'Matthew 18:4',
    'Luke 18:14', 'Proverbs 3:34', 'Romans 12:16', 'Ephesians 4:2',
    'Numbers 12:3', 'Psalm 131:1-2', 'Isaiah 2:11', 'Daniel 4:37',
    'Matthew 11:29', 'Luke 1:52', 'James 4:10', '1 Corinthians 15:9',
    '2 Corinthians 12:9', 'Philippians 2:5-8', '1 Timothy 1:15',
    'Psalm 34:2', 'Isaiah 29:19', 'Psalm 138:6', 'Proverbs 27:2',
    'Matthew 20:26-27', 'Luke 22:26',
  ];
  static const List<String> _vPrayer = [
    'Philippians 4:6', '1 Thessalonians 5:17', 'Matthew 6:6', 'James 5:16',
    'Jeremiah 33:3', 'Matthew 7:7', 'Psalm 145:18', 'Romans 12:12',
    'Colossians 4:2', '1 John 5:14', 'Luke 18:1', 'Psalm 55:17',
    'Mark 11:24', 'Ephesians 6:18', 'Psalm 5:3', 'Matthew 6:9-10',
    'John 15:7', 'Psalm 66:19', 'Daniel 6:10', 'Psalm 34:17',
    'Luke 11:9', 'Psalm 141:2', 'Acts 1:14', 'Psalm 86:6',
    'Hebrews 4:16', 'Psalm 102:17', '1 Timothy 2:1', 'Psalm 17:6',
    'James 1:5', 'Psalm 18:6', 'Romans 8:26', 'Psalm 116:1-2',
    'Matthew 21:22', 'Psalm 4:1', 'John 14:13', 'Psalm 65:2',
    'Acts 4:31', 'Psalm 88:13', 'Ephesians 3:20', 'Psalm 143:1',
    'Luke 6:12', 'Psalm 28:2', 'Isaiah 56:7', 'Psalm 6:9',
    '2 Chronicles 7:14',
  ];
  static const List<String> _vWorship = [
    'Psalm 95:6', 'John 4:23-24', 'Psalm 100:2', 'Romans 12:1',
    'Psalm 29:2', 'Hebrews 12:28', 'Psalm 96:9', 'Revelation 4:11',
    'Psalm 150:6', '1 Chronicles 16:29', 'Psalm 63:3-4', 'Isaiah 6:3',
    'Psalm 99:5', 'Revelation 15:4', 'Psalm 86:9', 'Exodus 15:2',
    'Psalm 34:3', 'Habakkuk 3:17-18', 'Psalm 47:1', 'Nehemiah 9:6',
    'Psalm 145:3', 'Isaiah 25:1', 'Psalm 8:1', 'Revelation 5:12',
    'Psalm 66:4', 'Daniel 4:37', 'Psalm 148:13', 'Isaiah 12:5',
    'Psalm 92:1', 'Luke 4:8', 'Psalm 113:3', 'Revelation 7:12',
    'Psalm 135:3', 'Isaiah 42:10', 'Psalm 103:1', 'Matthew 4:10',
    'Psalm 138:2', 'Revelation 19:5', 'Psalm 149:1', 'Isaiah 43:21',
    'Psalm 71:8', 'Acts 16:25', 'Psalm 57:7', 'Hebrews 13:15',
    'Psalm 33:1',
  ];
  static const List<String> _vLight = [
    'Matthew 5:14-16', 'John 8:12', 'Psalm 119:105', 'Isaiah 60:1',
    'Ephesians 5:8', '1 John 1:5', 'Psalm 27:1', 'Isaiah 9:2',
    'John 1:4-5', '2 Corinthians 4:6', 'Psalm 18:28', 'Isaiah 42:6',
    'Philippians 2:15', 'Psalm 36:9', 'Isaiah 58:8', 'John 12:36',
    'Psalm 43:3', 'Proverbs 4:18', 'Isaiah 60:19', '1 Thessalonians 5:5',
    'Psalm 112:4', 'Isaiah 2:5', 'John 9:5', 'Psalm 97:11',
    'Daniel 12:3', 'Psalm 4:6', 'Isaiah 49:6', 'Luke 11:36',
    'Psalm 119:130', 'Revelation 21:23', 'Psalm 139:12', 'Isaiah 30:26',
    'Acts 13:47', 'Psalm 76:4', 'Micah 7:8', 'Psalm 89:15',
    'Job 29:3', 'Psalm 104:2', 'Isaiah 51:4', 'Psalm 56:13',
    'Zechariah 14:7', 'Psalm 67:1', 'Isaiah 60:3', 'Psalm 80:3',
    'Numbers 6:25',
  ];

  // ——— 30-day topics ———
  static const List<String> _vStrength = [
    'Philippians 4:13', 'Isaiah 40:29-31', 'Psalm 28:7', 'Ephesians 6:10',
    '2 Corinthians 12:9', 'Psalm 46:1', 'Joshua 1:9', 'Psalm 18:32',
    'Isaiah 41:10', 'Nehemiah 8:10', 'Psalm 73:26', 'Habakkuk 3:19',
    'Psalm 59:17', 'Isaiah 12:2', 'Psalm 138:3', 'Exodus 15:2',
    'Psalm 29:11', 'Isaiah 40:28', 'Psalm 68:35', 'Deuteronomy 31:6',
    'Psalm 84:5', 'Isaiah 30:15', 'Psalm 118:14', '2 Timothy 1:7',
    'Psalm 144:1', 'Isaiah 35:3-4', 'Psalm 27:14', 'Zechariah 4:6',
    'Psalm 105:4', '1 Chronicles 16:11', 'Psalm 31:24', 'Isaiah 45:24',
    'Psalm 147:5', 'Daniel 10:19', 'Psalm 18:1', 'Isaiah 33:2',
    'Psalm 71:16', 'Micah 5:4', 'Psalm 99:4', 'Isaiah 26:4',
    'Psalm 21:13', 'Joel 3:16', 'Psalm 22:19', 'Isaiah 63:1',
    'Psalm 61:3', 'Isaiah 49:5', 'Psalm 140:7', 'Isaiah 50:7',
    'Psalm 59:9', 'Isaiah 41:13',
  ];
  static const List<String> _vComfort = [
    '2 Corinthians 1:3-4', 'Psalm 23:4', 'Isaiah 40:1', 'Matthew 5:4',
    'Psalm 119:76', 'Isaiah 49:13', 'John 14:16', 'Psalm 94:19',
    'Isaiah 51:12', 'Romans 15:4', 'Psalm 86:17', 'Isaiah 66:13',
    '2 Thessalonians 2:16-17', 'Psalm 71:21', 'Isaiah 12:1', 'John 14:18',
    'Psalm 119:50', 'Isaiah 61:2', '2 Corinthians 7:6', 'Psalm 23:2-3',
    'Lamentations 3:22-23', 'Psalm 34:18', 'Isaiah 41:13', 'Psalm 147:3',
    'Isaiah 57:18', 'Psalm 30:5', 'Nahum 1:7', 'Psalm 46:1',
    'Isaiah 43:2', 'Psalm 55:22', 'Matthew 11:28', 'Psalm 9:9',
    'Isaiah 25:8', 'Psalm 116:5', 'Jeremiah 31:13', 'Psalm 42:11',
    'Isaiah 51:3', 'Psalm 77:2', 'Zechariah 1:17', 'Psalm 119:82',
    'Isaiah 66:12', 'Psalm 138:7', 'Hosea 2:14', 'Psalm 103:13',
    'Isaiah 40:11', 'Psalm 145:14', 'Jeremiah 8:18', 'Psalm 4:1',
    'Isaiah 54:11', 'Psalm 27:5',
  ];
  static const List<String> _vGuidance = [
    'Psalm 32:8', 'Proverbs 3:5-6', 'Isaiah 30:21', 'Psalm 25:4-5',
    'James 1:5', 'Psalm 119:105', 'Isaiah 58:11', 'Psalm 48:14',
    'Proverbs 16:9', 'Psalm 73:24', 'Isaiah 42:16', 'Psalm 23:3',
    'Proverbs 16:3', 'Psalm 37:23', 'Isaiah 48:17', 'Psalm 25:9',
    'Proverbs 11:14', 'Psalm 143:8', 'Isaiah 28:26', 'Psalm 5:8',
    'Proverbs 20:24', 'Psalm 31:3', 'Isaiah 58:14', 'Psalm 27:11',
    'Proverbs 16:1', 'Psalm 139:24', 'Isaiah 30:20', 'Psalm 61:2',
    'Proverbs 16:33', 'Psalm 43:3', 'Isaiah 45:13', 'Psalm 67:4',
    'Proverbs 19:21', 'Psalm 78:72', 'Isaiah 49:10', 'Psalm 119:133',
    'Proverbs 21:1', 'Psalm 25:12', 'Isaiah 55:8-9', 'Psalm 139:10',
    'Proverbs 24:6', 'Psalm 73:23', 'Isaiah 41:18', 'Psalm 16:7',
    'Proverbs 15:22', 'Psalm 119:35', 'Isaiah 63:14', 'Psalm 77:20',
    'Proverbs 3:23', 'Psalm 107:7',
  ];
  static const List<String> _vRenewal = [
    'Romans 12:2', '2 Corinthians 4:16', 'Isaiah 40:31', 'Psalm 51:10',
    'Ephesians 4:23', 'Lamentations 3:22-23', 'Titus 3:5', 'Psalm 103:5',
    'Isaiah 43:19', 'Colossians 3:10', 'Psalm 104:30', 'Isaiah 57:15',
    'Ezekiel 36:26', 'Psalm 23:3', 'Isaiah 41:18', 'Revelation 21:5',
    'Psalm 51:12', 'Isaiah 61:3', 'Habakkuk 3:2', 'Psalm 85:6',
    'Isaiah 35:6-7', 'Psalm 119:25', 'Joel 2:25', 'Psalm 71:20',
    'Isaiah 55:12', 'Psalm 80:3', 'Hosea 6:1-2', 'Psalm 90:14',
    'Isaiah 58:8', 'Psalm 119:37', 'Jeremiah 31:4', 'Psalm 126:4',
    'Isaiah 60:1', 'Psalm 51:7', 'Ezekiel 37:5', 'Psalm 119:40',
    'Isaiah 65:17', 'Psalm 68:9', 'Micah 7:19', 'Psalm 119:107',
    'Isaiah 62:2', 'Psalm 145:14', 'Zephaniah 3:17', 'Psalm 119:149',
    'Isaiah 32:15', 'Psalm 119:156', 'Jeremiah 33:6', 'Psalm 80:19',
    'Isaiah 44:3', 'Psalm 119:159',
  ];
  static const List<String> _vRest = [
    'Matthew 11:28-29', 'Psalm 23:2', 'Hebrews 4:9-10', 'Exodus 33:14',
    'Psalm 62:1', 'Isaiah 30:15', 'Psalm 4:8', 'Jeremiah 6:16',
    'Psalm 116:7', 'Isaiah 40:31', 'Psalm 37:7', 'Mark 6:31',
    'Psalm 46:10', 'Isaiah 14:3', 'Psalm 55:6', 'Isaiah 28:12',
    'Psalm 91:1', 'Isaiah 32:18', 'Psalm 127:2', 'Zephaniah 3:17',
    'Psalm 131:2', 'Isaiah 63:14', 'Psalm 94:13', 'Isaiah 11:10',
    'Psalm 37:11', 'Isaiah 66:1', 'Psalm 119:165', 'Isaiah 57:2',
    'Psalm 16:9', 'Isaiah 26:3', 'Psalm 3:5', 'Isaiah 65:10',
    'Psalm 139:3', 'Proverbs 19:23', 'Psalm 29:10', 'Ecclesiastes 4:6',
    'Psalm 34:14', 'Isaiah 58:13', 'Psalm 51:12', 'Ruth 1:9',
    'Psalm 60:6', 'Isaiah 34:14', 'Psalm 77:6', 'Isaiah 35:10',
    'Psalm 85:8', 'Isaiah 66:12', 'Psalm 95:11', 'Isaiah 28:16',
    'Psalm 100:2', 'Isaiah 61:2',
  ];
  static const List<String> _vPurpose = [
    'Jeremiah 29:11', 'Ephesians 2:10', 'Romans 8:28', 'Proverbs 19:21',
    'Psalm 138:8', 'Isaiah 46:10', 'Philippians 1:6', 'Psalm 57:2',
    'Isaiah 14:24', 'Proverbs 16:4', 'Psalm 33:11', 'Isaiah 55:11',
    'Acts 13:36', 'Psalm 139:16', 'Isaiah 43:7', '2 Timothy 1:9',
    'Psalm 20:4', 'Isaiah 49:5', 'Colossians 1:16', 'Psalm 40:8',
    'Isaiah 42:5', 'Proverbs 16:9', 'Psalm 119:105', 'Isaiah 61:1',
    '1 Corinthians 10:31', 'Psalm 73:24', 'Isaiah 45:9', 'Proverbs 20:5',
    'Psalm 25:12', 'Isaiah 48:17', 'Romans 12:2', 'Psalm 37:5',
    'Isaiah 26:12', 'Ecclesiastes 3:1', 'Psalm 90:12', 'Isaiah 58:11',
    'Philippians 2:13', 'Psalm 119:133', 'Isaiah 30:21', 'Proverbs 3:6',
    'Psalm 16:11', 'Isaiah 41:4', 'Acts 20:24', 'Psalm 119:54',
    'Isaiah 44:24', 'Proverbs 16:3', 'Psalm 143:10', 'Isaiah 49:6',
    '1 Peter 2:9', 'Psalm 86:11',
  ];
  static const List<String> _vMercy = [
    'Lamentations 3:22-23', 'Micah 6:8', 'Psalm 103:8', 'Ephesians 2:4',
    'Titus 3:5', 'Psalm 86:5', 'Luke 6:36', 'Psalm 145:9',
    'James 2:13', 'Psalm 51:1', 'Isaiah 55:7', 'Psalm 23:6',
    'Matthew 5:7', 'Psalm 136:1', 'Hosea 6:6', 'Psalm 25:6',
    'Jude 1:21', 'Psalm 57:10', 'Isaiah 30:18', 'Psalm 89:1',
    'Hebrews 4:16', 'Psalm 100:5', 'Joel 2:13', 'Psalm 119:77',
    'Romans 9:15', 'Psalm 130:7', 'Isaiah 63:7', 'Psalm 69:16',
    '1 Peter 1:3', 'Psalm 86:15', 'Daniel 9:9', 'Psalm 119:156',
    'Luke 1:50', 'Psalm 103:11', 'Nehemiah 9:31', 'Psalm 119:132',
    'Romans 12:1', 'Psalm 40:11', 'Isaiah 54:7', 'Psalm 51:1-2',
    'Micah 7:18', 'Psalm 6:4', 'Exodus 34:6', 'Psalm 77:8',
    'Isaiah 14:1', 'Psalm 94:18', 'Jeremiah 3:12', 'Psalm 119:64',
    'Habakkuk 3:2', 'Psalm 123:2',
  ];
  static const List<String> _vTruth = [
    'John 14:6', 'John 8:32', 'Psalm 119:160', 'Ephesians 4:15',
    'John 17:17', 'Psalm 25:5', '2 Timothy 2:15', 'Psalm 119:142',
    'John 16:13', 'Psalm 43:3', 'Ephesians 6:14', 'Psalm 86:11',
    '1 John 1:6', 'Psalm 119:30', 'Proverbs 12:17', 'Psalm 15:2',
    'Isaiah 65:16', 'Psalm 119:151', 'Zechariah 8:16', 'Psalm 31:5',
    'John 1:14', 'Psalm 119:43', '3 John 1:4', 'Psalm 85:10',
    'Isaiah 45:19', 'Psalm 119:90', 'Proverbs 23:23', 'Psalm 40:11',
    'John 18:37', 'Psalm 119:142', 'Ephesians 1:13', 'Psalm 57:10',
    'Isaiah 59:14', 'Psalm 119:160', '1 Timothy 2:4', 'Psalm 96:13',
    'John 4:24', 'Psalm 119:172', '2 Thessalonians 2:13', 'Psalm 138:2',
    'Isaiah 61:8', 'Psalm 119:142', 'Colossians 1:5', 'Psalm 119:142',
    'Proverbs 8:7', 'Psalm 119:151', 'Isaiah 42:3', 'Psalm 19:9',
    'John 8:36', 'Psalm 119:142',
  ];
  static const List<String> _vFreedom = [
    'John 8:36', 'Galatians 5:1', '2 Corinthians 3:17', 'Romans 8:2',
    'Psalm 119:45', 'Isaiah 61:1', 'Galatians 5:13', 'Psalm 118:5',
    'Romans 6:18', 'Psalm 146:7', 'Isaiah 58:6', 'Luke 4:18',
    'Romans 8:21', 'Psalm 119:32', 'John 8:32', 'Psalm 34:4',
    'Isaiah 42:7', 'Acts 13:39', 'Psalm 107:14', 'Isaiah 49:9',
    'Romans 6:22', 'Psalm 116:16', 'Galatians 2:4', 'Psalm 51:12',
    'Isaiah 45:13', '1 Peter 2:16', 'Psalm 119:45', 'Isaiah 61:1',
    'James 1:25', 'Psalm 25:17', 'Isaiah 58:9', 'Psalm 142:7',
    'Romans 7:6', 'Psalm 18:19', 'Isaiah 43:1', 'Psalm 124:7',
    'Galatians 4:7', 'Psalm 107:16', 'Isaiah 52:2', 'Psalm 118:5',
    'Romans 8:15', 'Psalm 31:8', 'Isaiah 35:5', 'Psalm 66:12',
    '2 Timothy 1:7', 'Psalm 119:45', 'Isaiah 40:9', 'Psalm 146:7',
    'Hebrews 2:15', 'Psalm 107:14',
  ];

  // ——— 50-day topics ———
  static const List<String> _vDiscipleship = [
    'Matthew 28:19-20', 'Luke 9:23', 'John 8:31', 'Matthew 16:24',
    'John 13:35', 'Acts 11:26', 'John 15:8', 'Matthew 10:38',
    'Luke 14:27', 'John 12:26', 'Matthew 4:19', 'Mark 8:34',
    'John 15:5', 'Luke 6:40', 'Matthew 11:29', 'Acts 2:42',
    'John 14:15', 'Matthew 7:24', 'Luke 11:28', 'John 10:27',
    'Matthew 5:16', 'Acts 6:7', 'John 15:16', 'Matthew 22:37',
    'Luke 10:27', 'John 21:19', 'Matthew 6:33', 'Acts 14:22',
    'John 17:18', 'Matthew 10:24', 'Luke 14:33', 'John 15:14',
    'Matthew 9:9', 'Acts 9:26', 'John 8:12', 'Matthew 19:21',
    'Luke 5:11', 'John 6:68', 'Matthew 8:22', 'Acts 16:5',
    'John 12:25', 'Matthew 13:23', 'Luke 8:15', 'John 17:3',
    'Matthew 25:21', 'Acts 20:28', 'John 14:21', 'Matthew 5:48',
    'Luke 12:33', 'John 15:10',
  ];
  static const List<String> _vStewardship = [
    '1 Peter 4:10', 'Luke 16:10', '1 Corinthians 4:2', 'Matthew 25:21',
    'Proverbs 3:9', 'Malachi 3:10', '2 Corinthians 9:6-7', 'Luke 12:48',
    'Psalm 24:1', 'Proverbs 27:23', '1 Timothy 6:17-18', 'Matthew 6:21',
    'Proverbs 13:11', 'Luke 6:38', 'Colossians 3:23', 'Proverbs 21:5',
    'Genesis 1:28', 'Matthew 6:33', 'Proverbs 11:24', 'Luke 19:17',
    'Deuteronomy 8:18', 'Proverbs 22:7', '1 Timothy 6:6', 'Ecclesiastes 5:10',
    'Proverbs 28:20', 'Matthew 25:29', 'Proverbs 10:4', 'Luke 16:11',
    'Haggai 2:8', 'Proverbs 14:23', '2 Corinthians 8:12', 'Proverbs 16:8',
    'Psalm 37:21', 'Proverbs 19:17', 'Luke 12:15', 'Proverbs 23:4',
    '1 Timothy 5:8', 'Proverbs 6:6-8', 'Matthew 6:19-20', 'Proverbs 15:16',
    'Luke 14:28', 'Proverbs 21:20', '2 Corinthians 9:11', 'Proverbs 11:25',
    'Psalm 112:5', 'Proverbs 27:18', 'Luke 16:13', 'Proverbs 30:8-9',
    'Matthew 10:8', 'Proverbs 3:27',
  ];
  static const List<String> _vPerseverance = [
    'James 1:12', 'Hebrews 12:1', 'Romans 5:3-4', 'Galatians 6:9',
    '2 Thessalonians 3:13', 'Hebrews 10:36', 'James 1:2-4', 'Romans 8:25',
    '2 Timothy 4:7', 'Hebrews 12:2', '1 Corinthians 15:58', 'Romans 12:12',
    'Revelation 3:10', 'Hebrews 6:12', '2 Timothy 2:12', 'Romans 2:7',
    'James 5:11', 'Hebrews 3:14', '1 Timothy 6:12', 'Hebrews 11:27',
    'Philippians 3:14', 'Hebrews 10:23', '2 Corinthians 4:8-9', 'Romans 15:4',
    'Revelation 2:10', 'Hebrews 12:3', '1 Peter 1:6-7', '2 Timothy 2:3',
    'Hebrews 11:1', 'Romans 8:37', 'Revelation 2:3', 'Hebrews 6:15',
    '1 Corinthians 9:24', 'Hebrews 12:7', 'James 5:7', 'Romans 5:5',
    'Revelation 14:12', 'Hebrews 4:11', '1 Peter 5:9', '2 Thessalonians 1:4',
    'Hebrews 10:35', 'Romans 8:18', 'Revelation 21:7', 'Hebrews 11:13',
    '1 Thessalonians 1:3', 'Hebrews 12:11', 'James 1:3', 'Romans 5:2',
    'Revelation 3:11', 'Hebrews 13:5',
  ];
  static const List<String> _vHoliness = [
    '1 Peter 1:15-16', 'Hebrews 12:14', 'Leviticus 20:26', '2 Corinthians 7:1',
    'Ephesians 1:4', '1 Thessalonians 4:7', 'Psalm 99:9', 'Isaiah 6:3',
    'Romans 12:1', '1 John 3:3', 'Psalm 24:3-4', 'Isaiah 35:8',
    'Colossians 3:12', 'Psalm 15:1-2', 'Isaiah 57:15', '1 Timothy 2:8',
    'Psalm 51:10', 'Isaiah 52:11', '2 Timothy 2:21', 'Psalm 119:9',
    'Isaiah 61:10', 'Hebrews 10:10', 'Psalm 86:2', 'Isaiah 4:3',
    '1 Corinthians 3:17', 'Psalm 96:9', 'Isaiah 62:12', 'Romans 6:22',
    'Psalm 110:3', 'Isaiah 63:15', 'Ephesians 5:27', 'Psalm 89:35',
    'Isaiah 65:16', '1 Peter 2:9', 'Psalm 145:17', 'Isaiah 5:16',
    'Hebrews 12:10', 'Psalm 30:4', 'Isaiah 41:16', '2 Peter 3:11',
    'Psalm 77:13', 'Isaiah 29:23', 'Revelation 4:8', 'Psalm 97:12',
    'Isaiah 58:13', '1 Thessalonians 5:23', 'Psalm 103:1', 'Isaiah 6:5',
    'Hebrews 9:14', 'Psalm 119:140',
  ];
  static const List<String> _vCompassion = [
    'Colossians 3:12', 'Psalm 103:13', 'Matthew 9:36', 'Lamentations 3:22',
    'Ephesians 4:32', 'Psalm 145:9', 'Luke 10:33', 'Isaiah 49:15',
    '1 Peter 3:8', 'Psalm 86:15', 'Matthew 14:14', 'Isaiah 54:10',
    'Zechariah 7:9', 'Psalm 111:4', 'Mark 6:34', 'Isaiah 63:7',
    '2 Corinthians 1:3', 'Psalm 116:5', 'Luke 7:13', 'Isaiah 30:18',
    'Jude 1:22', 'Psalm 119:77', 'Matthew 15:32', 'Isaiah 49:10',
    'Romans 12:15', 'Psalm 25:6', 'Mark 1:41', 'Isaiah 51:12',
    'Hebrews 4:15', 'Psalm 51:1', 'Luke 15:20', 'Isaiah 66:13',
    '1 John 3:17', 'Psalm 69:16', 'Matthew 20:34', 'Isaiah 58:7',
    'James 2:15-16', 'Psalm 40:11', 'Mark 8:2', 'Isaiah 61:1',
    'Proverbs 19:17', 'Psalm 103:8', 'Luke 6:36', 'Isaiah 16:5',
    'Micah 6:8', 'Psalm 145:8', 'Matthew 25:40', 'Isaiah 58:10',
    'Galatians 6:2', 'Psalm 72:13',
  ];
  static const List<String> _vIntegrity = [
    'Proverbs 11:3', 'Psalm 15:2', 'Proverbs 28:6', 'Psalm 25:21',
    'Proverbs 10:9', 'Psalm 41:12', 'Proverbs 19:1', 'Psalm 26:1',
    'Proverbs 20:7', 'Psalm 78:72', 'Proverbs 2:7', 'Psalm 101:2',
    'Proverbs 11:20', 'Psalm 119:1', 'Proverbs 13:6', 'Psalm 7:8',
    'Proverbs 16:17', 'Psalm 84:11', 'Proverbs 21:3', 'Psalm 119:80',
    'Job 2:3', 'Psalm 26:11', 'Proverbs 28:18', 'Psalm 37:18',
    'Proverbs 14:2', 'Psalm 112:5', 'Proverbs 22:1', 'Psalm 119:121',
    'Micah 6:8', 'Psalm 15:1', 'Proverbs 4:25-27', 'Psalm 119:142',
    'Isaiah 33:15', 'Psalm 24:4', 'Proverbs 12:22', 'Psalm 119:163',
    'Zechariah 8:16', 'Psalm 51:6', 'Proverbs 16:13', 'Psalm 119:29',
    'Isaiah 26:7', 'Psalm 119:104', 'Proverbs 8:8', 'Psalm 119:128',
    'Job 27:5', 'Psalm 26:1', 'Proverbs 11:5', 'Psalm 119:140',
    'Daniel 6:4', 'Psalm 15:2',
  ];
  static const List<String> _vKingdom = [
    'Matthew 6:33', 'Luke 17:21', 'Matthew 4:17', 'Romans 14:17',
    'Matthew 5:3', 'Luke 12:32', 'Matthew 13:44', 'John 18:36',
    'Matthew 5:10', 'Luke 11:2', 'Matthew 13:31', 'Colossians 1:13',
    'Matthew 6:10', 'Luke 13:29', 'Matthew 19:14', 'Hebrews 12:28',
    'Matthew 13:45', 'Luke 16:16', 'Matthew 11:12', '1 Corinthians 4:20',
    'Matthew 25:34', 'Luke 9:62', 'Matthew 18:3', 'Revelation 11:15',
    'Matthew 13:47', 'Luke 8:1', 'Matthew 21:43', 'Acts 28:31',
    'Matthew 5:19', 'Luke 4:43', 'Matthew 16:19', 'Daniel 2:44',
    'Matthew 8:11', 'Luke 10:9', 'Matthew 12:28', 'Psalm 145:13',
    'Matthew 13:11', 'Luke 18:16', 'Matthew 22:2', 'Isaiah 9:7',
    'Matthew 24:14', 'Luke 22:29', 'Matthew 25:1', 'Psalm 103:19',
    'Matthew 7:21', 'Luke 23:42', 'Matthew 13:24', 'Isaiah 52:7',
    'Matthew 18:4', 'Luke 12:31',
  ];
  static const List<String> _vFruitfulness = [
    'John 15:5', 'Galatians 5:22-23', 'Psalm 1:3', 'John 15:8',
    'Matthew 7:17', 'Colossians 1:10', 'Psalm 92:14', 'John 15:16',
    'Matthew 13:23', 'Philippians 1:11', 'Psalm 128:3', 'Hosea 14:8',
    'Matthew 3:8', 'Ephesians 5:9', 'Psalm 104:13', 'Isaiah 27:6',
    'Luke 8:15', 'Romans 7:4', 'Psalm 72:16', 'Isaiah 37:31',
    'John 12:24', '2 Corinthians 9:10', 'Psalm 85:12', 'Isaiah 55:10-11',
    'Matthew 21:43', 'Hebrews 12:11', 'Psalm 107:37', 'Isaiah 32:15',
    'Luke 6:43', 'James 3:17', 'Psalm 147:8', 'Ezekiel 17:8',
    'John 15:2', 'Romans 6:22', 'Psalm 65:9', 'Isaiah 4:2',
    'Matthew 12:33', 'Philippians 4:17', 'Psalm 67:6', 'Isaiah 61:3',
    'Luke 13:6-9', 'Colossians 1:6', 'Psalm 80:8', 'Isaiah 5:1',
    'John 4:36', 'Hebrews 6:7', 'Psalm 85:11', 'Isaiah 45:8',
    'Matthew 13:8', 'Galatians 6:8',
  ];
  static const List<String> _vPresence = [
    'Psalm 16:11', 'Exodus 33:14', 'Psalm 139:7', 'Matthew 28:20',
    'Psalm 23:4', 'Isaiah 41:10', 'Psalm 46:1', 'John 14:23',
    'Psalm 91:1', 'Isaiah 43:2', 'Psalm 27:4', 'Hebrews 13:5',
    'Psalm 84:1-2', 'Isaiah 57:15', 'Psalm 145:18', 'James 4:8',
    'Psalm 73:28', 'Isaiah 12:6', 'Psalm 140:13', 'Zephaniah 3:17',
    'Psalm 31:20', 'Isaiah 63:9', 'Psalm 89:15', 'Revelation 21:3',
    'Psalm 114:7', 'Isaiah 26:9', 'Psalm 68:8', 'Acts 17:27',
    'Psalm 42:2', 'Isaiah 30:29', 'Psalm 63:1-2', '1 John 4:12',
    'Psalm 95:2', 'Isaiah 55:6', 'Psalm 100:2', 'Jeremiah 23:23',
    'Psalm 105:4', 'Isaiah 8:10', 'Psalm 132:14', 'Ezekiel 48:35',
    'Psalm 148:13', 'Isaiah 60:19', 'Psalm 16:8', 'Haggai 1:13',
    'Psalm 21:6', 'Isaiah 7:14', 'Psalm 51:11', 'Matthew 18:20',
    'Psalm 139:10', 'Isaiah 41:13',
  ];
}

class _TopicSpec {
  const _TopicSpec({
    required this.topic,
    required this.description,
    required this.backgroundAsset,
    required this.verses,
  });

  final String topic;
  final String description;
  final String backgroundAsset;
  final List<String> verses;
}
