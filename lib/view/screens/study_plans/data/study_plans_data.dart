import '../models/study_plan_model.dart';

class StudyPlansData {
  // Define all study plans organized by categories
  static final List<StudyPlan> allStudyPlans = [
    // Love Category (3 plans)
    StudyPlan(
      id: 'love-1',
      title: 'God\'s Unconditional Love',
      description:
          'Discover the depth of God\'s love for you through Scripture. This 7-day journey will help you understand and experience divine love.',
      category: 'Love',
      verses: [
        'John 3:16',
        'Romans 8:38-39',
        '1 John 4:8',
        'Ephesians 3:17-19',
        'Jeremiah 31:3',
      ],
      durationDays: 7,
    ),
    StudyPlan(
      id: 'love-2',
      title: 'Love Your Neighbor',
      description:
          'Learn what it means to love others as Christ loved us. Practical guidance for showing love in daily life.',
      category: 'Love',
      verses: [
        'Matthew 22:39',
        '1 Corinthians 13:4-7',
        'John 13:34-35',
        'Romans 13:10',
        'Galatians 5:14',
      ],
      durationDays: 5,
    ),
    StudyPlan(
      id: 'love-3',
      title: 'Walking in Love',
      description:
          'Develop a lifestyle of love that reflects Christ. Transform your relationships through biblical love.',
      category: 'Love',
      verses: [
        'Ephesians 5:2',
        'Colossians 3:14',
        '1 Peter 4:8',
        '1 John 3:18',
        'Philippians 1:9-10',
      ],
      durationDays: 6,
    ),

    // Joy Category (5 plans)
    StudyPlan(
      id: 'joy-1',
      title: 'The Joy of Salvation',
      description:
          'Rediscover the joy that comes from knowing Christ. A refreshing look at the source of true happiness.',
      category: 'Joy',
      verses: [
        'Psalm 51:12',
        'Nehemiah 8:10',
        'Philippians 4:4',
        'Romans 15:13',
        'Psalm 16:11',
      ],
      durationDays: 5,
    ),
    StudyPlan(
      id: 'joy-2',
      title: 'Joy in Trials',
      description:
          'Find joy even in difficult circumstances. Learn how to maintain a joyful spirit through challenges.',
      category: 'Joy',
      verses: [
        'James 1:2-4',
        'Romans 5:3-5',
        '1 Peter 1:6-8',
        'Habakkuk 3:17-18',
        '2 Corinthians 8:2',
      ],
      durationDays: 7,
    ),
    StudyPlan(
      id: 'joy-3',
      title: 'Fruit of the Spirit: Joy',
      description:
          'Cultivate supernatural joy as part of the Spirit\'s fruit in your life.',
      category: 'Joy',
      verses: [
        'Galatians 5:22-23',
        'John 15:11',
        'Philippians 1:25',
        'Romans 14:17',
        'Psalm 126:5-6',
      ],
      durationDays: 6,
    ),
    StudyPlan(
      id: 'joy-4',
      title: 'Joyful Praise and Worship',
      description:
          'Experience the joy that comes from praising God. Learn to worship with gladness.',
      category: 'Joy',
      verses: [
        'Psalm 100:1-2',
        'Psalm 95:1-2',
        'Isaiah 61:10',
        'Zephaniah 3:17',
        'Psalm 30:5',
      ],
      durationDays: 5,
    ),
    StudyPlan(
      id: 'joy-5',
      title: 'Joy in God\'s Presence',
      description:
          'Discover the fullness of joy found in God\'s presence. Draw near to Him and experience true delight.',
      category: 'Joy',
      verses: [
        'Psalm 16:11',
        'Psalm 21:6',
        'Acts 2:28',
        'Psalm 43:4',
        'Psalm 89:15-16',
      ],
      durationDays: 5,
    ),

    // Faith Category (4 plans)
    StudyPlan(
      id: 'faith-1',
      title: 'Building Strong Faith',
      description:
          'Strengthen your faith through God\'s Word. Learn what true faith looks like and how to grow it.',
      category: 'Faith',
      verses: [
        'Hebrews 11:1',
        'Romans 10:17',
        'Mark 11:22-24',
        'James 1:6',
        'Matthew 21:22',
      ],
      durationDays: 7,
    ),
    StudyPlan(
      id: 'faith-2',
      title: 'Faith in Action',
      description:
          'Put your faith to work. Discover how faith and works go hand in hand.',
      category: 'Faith',
      verses: [
        'James 2:14-17',
        'James 2:20-26',
        'Galatians 5:6',
        'Hebrews 11:7-8',
        '1 Thessalonians 1:3',
      ],
      durationDays: 6,
    ),
    StudyPlan(
      id: 'faith-3',
      title: 'Living by Faith',
      description:
          'Walk by faith, not by sight. Learn to trust God completely in every area of life.',
      category: 'Faith',
      verses: [
        '2 Corinthians 5:7',
        'Habakkuk 2:4',
        'Romans 1:17',
        'Galatians 2:20',
        'Hebrews 10:38',
      ],
      durationDays: 5,
    ),
    StudyPlan(
      id: 'faith-4',
      title: 'Heroes of Faith',
      description:
          'Be inspired by biblical examples of great faith. Learn from those who trusted God against all odds.',
      category: 'Faith',
      verses: [
        'Hebrews 11:4-40',
        'Genesis 22:1-18',
        'Daniel 3:16-18',
        'Joshua 1:9',
        'Proverbs 3:5-6',
      ],
      durationDays: 8,
    ),

    // Peace Category (3 plans)
    StudyPlan(
      id: 'peace-1',
      title: 'Perfect Peace',
      description:
          'Find God\'s perfect peace that surpasses understanding. Rest in His promises.',
      category: 'Peace',
      verses: [
        'Isaiah 26:3',
        'Philippians 4:6-7',
        'John 14:27',
        'Colossians 3:15',
        'Romans 5:1',
      ],
      durationDays: 5,
    ),
    StudyPlan(
      id: 'peace-2',
      title: 'Peace in the Storm',
      description:
          'Maintain peace even when life is chaotic. Learn to anchor your soul in Christ.',
      category: 'Peace',
      verses: [
        'Mark 4:39-40',
        'Psalm 46:1-3',
        'Isaiah 43:2',
        'Psalm 29:11',
        'John 16:33',
      ],
      durationDays: 6,
    ),
    StudyPlan(
      id: 'peace-3',
      title: 'Prince of Peace',
      description:
          'Know Jesus as your Prince of Peace. Experience the peace that only He can give.',
      category: 'Peace',
      verses: [
        'Isaiah 9:6',
        'Ephesians 2:14',
        'Romans 15:33',
        '2 Thessalonians 3:16',
        'Hebrews 13:20-21',
      ],
      durationDays: 5,
    ),

    // Hope Category (4 plans)
    StudyPlan(
      id: 'hope-1',
      title: 'Living Hope',
      description:
          'Discover the living hope we have in Christ. Be encouraged and strengthened.',
      category: 'Hope',
      verses: [
        '1 Peter 1:3-4',
        'Romans 15:13',
        'Hebrews 6:19',
        'Psalm 39:7',
        'Jeremiah 29:11',
      ],
      durationDays: 5,
    ),
    StudyPlan(
      id: 'hope-2',
      title: 'Hope for Tomorrow',
      description:
          'Build confidence in God\'s plans for your future. Trust His promises.',
      category: 'Hope',
      verses: [
        'Jeremiah 29:11',
        'Proverbs 23:18',
        'Romans 8:28',
        'Lamentations 3:22-23',
        'Psalm 42:5',
      ],
      durationDays: 6,
    ),
    StudyPlan(
      id: 'hope-3',
      title: 'Hope in Difficult Times',
      description:
          'Find hope when facing challenges. God is faithful even in hardship.',
      category: 'Hope',
      verses: [
        'Psalm 42:11',
        'Romans 5:3-5',
        '2 Corinthians 4:16-18',
        'Psalm 130:5-7',
        'Isaiah 40:31',
      ],
      durationDays: 7,
    ),
    StudyPlan(
      id: 'hope-4',
      title: 'The Blessed Hope',
      description:
          'Look forward to Christ\'s return with joyful expectation. Our ultimate hope.',
      category: 'Hope',
      verses: [
        'Titus 2:13',
        '1 Thessalonians 4:13-18',
        'Revelation 21:4',
        '1 John 3:2-3',
        'Philippians 3:20-21',
      ],
      durationDays: 5,
    ),

    // Wisdom Category (3 plans)
    StudyPlan(
      id: 'wisdom-1',
      title: 'Seeking God\'s Wisdom',
      description:
          'Learn how to gain wisdom from God. Discover the source of true understanding.',
      category: 'Wisdom',
      verses: [
        'James 1:5',
        'Proverbs 2:6',
        'Proverbs 9:10',
        'Colossians 2:3',
        'Psalm 111:10',
      ],
      durationDays: 5,
    ),
    StudyPlan(
      id: 'wisdom-2',
      title: 'Wisdom for Daily Living',
      description:
          'Apply biblical wisdom to everyday situations. Make wise choices.',
      category: 'Wisdom',
      verses: [
        'Proverbs 3:5-6',
        'Proverbs 4:7',
        'Ecclesiastes 7:12',
        'Proverbs 16:16',
        'Proverbs 19:20',
      ],
      durationDays: 6,
    ),
    StudyPlan(
      id: 'wisdom-3',
      title: 'Christ Our Wisdom',
      description:
          'Discover how Jesus is the wisdom of God. Find all wisdom in Him.',
      category: 'Wisdom',
      verses: [
        '1 Corinthians 1:30',
        'Colossians 2:3',
        'Matthew 11:28-30',
        'Luke 2:52',
        'John 1:1-4',
      ],
      durationDays: 5,
    ),

    // Courage Category (3 plans)
    StudyPlan(
      id: 'courage-1',
      title: 'Be Strong and Courageous',
      description:
          'Draw courage from God\'s promises. He is with you wherever you go.',
      category: 'Courage',
      verses: [
        'Joshua 1:9',
        'Deuteronomy 31:6',
        'Psalm 27:14',
        'Isaiah 41:10',
        '2 Timothy 1:7',
      ],
      durationDays: 5,
    ),
    StudyPlan(
      id: 'courage-2',
      title: 'Courage to Stand',
      description:
          'Stand firm in your faith. Learn to be bold for Christ.',
      category: 'Courage',
      verses: [
        'Ephesians 6:13',
        '1 Corinthians 16:13',
        'Psalm 31:24',
        'Proverbs 28:1',
        'Acts 4:13',
      ],
      durationDays: 6,
    ),
    StudyPlan(
      id: 'courage-3',
      title: 'Overcoming Fear with Courage',
      description:
          'Replace fear with faith and courage. God has not given us a spirit of fear.',
      category: 'Courage',
      verses: [
        '2 Timothy 1:7',
        'Psalm 56:3-4',
        'Isaiah 41:13',
        'Hebrews 13:6',
        'Psalm 118:6',
      ],
      durationDays: 5,
    ),

    // Forgiveness Category (3 plans)
    StudyPlan(
      id: 'forgiveness-1',
      title: 'God\'s Forgiveness',
      description:
          'Experience the freedom of God\'s complete forgiveness. You are fully pardoned.',
      category: 'Forgiveness',
      verses: [
        '1 John 1:9',
        'Ephesians 1:7',
        'Psalm 103:12',
        'Micah 7:19',
        'Acts 3:19',
      ],
      durationDays: 5,
    ),
    StudyPlan(
      id: 'forgiveness-2',
      title: 'Forgiving Others',
      description:
          'Learn to forgive as God forgave you. Release bitterness and embrace peace.',
      category: 'Forgiveness',
      verses: [
        'Matthew 6:14-15',
        'Ephesians 4:32',
        'Colossians 3:13',
        'Mark 11:25',
        'Luke 6:37',
      ],
      durationDays: 6,
    ),
    StudyPlan(
      id: 'forgiveness-3',
      title: 'Freedom Through Forgiveness',
      description:
          'Break free from the chains of unforgiveness. Experience healing and restoration.',
      category: 'Forgiveness',
      verses: [
        'Matthew 18:21-22',
        'Luke 23:34',
        'Romans 12:19-21',
        '2 Corinthians 2:7',
        'Hebrews 12:15',
      ],
      durationDays: 7,
    ),

    // Healing Category (3 plans)
    StudyPlan(
      id: 'healing-1',
      title: 'God Our Healer',
      description:
          'Know God as Jehovah Rapha, the Lord who heals. Trust in His healing power.',
      category: 'Healing',
      verses: [
        'Exodus 15:26',
        'Psalm 103:2-3',
        'Jeremiah 30:17',
        '3 John 1:2',
        'James 5:14-15',
      ],
      durationDays: 5,
    ),
    StudyPlan(
      id: 'healing-2',
      title: 'Healing for Body and Soul',
      description:
          'Find wholeness in Christ. He heals both physical and emotional wounds.',
      category: 'Healing',
      verses: [
        'Psalm 147:3',
        'Isaiah 53:5',
        '1 Peter 2:24',
        'Psalm 41:3',
        'Proverbs 4:20-22',
      ],
      durationDays: 6,
    ),
    StudyPlan(
      id: 'healing-3',
      title: 'Walking in Divine Health',
      description:
          'Live in the health that God desires for you. Partner with His healing grace.',
      category: 'Healing',
      verses: [
        'Proverbs 3:7-8',
        'Proverbs 4:20-22',
        'Psalm 107:20',
        'Jeremiah 33:6',
        'Malachi 4:2',
      ],
      durationDays: 5,
    ),
  ];

  // Get categories with count
  static Map<String, int> getCategoriesWithCount() {
    final Map<String, int> categoryCounts = {};
    for (var plan in allStudyPlans) {
      categoryCounts[plan.category] =
          (categoryCounts[plan.category] ?? 0) + 1;
    }
    return categoryCounts;
  }

  // Get study plans by category
  static List<StudyPlan> getStudyPlansByCategory(String category) {
    return allStudyPlans.where((plan) => plan.category == category).toList();
  }

  // Get all categories
  static List<String> getAllCategories() {
    return allStudyPlans.map((plan) => plan.category).toSet().toList()..sort();
  }
}
