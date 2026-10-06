import 'package:biblebookapp/view/screens/milestones/models/milestone_model.dart';

/// Static milestone catalog matching design (Connection / Prayer / Community).
class MilestonesData {
  MilestonesData._();

  static const List<MilestoneDef> all = [
    // —— Connection ——
    MilestoneDef(
      id: 'conn_7',
      category: MilestoneCategory.connection,
      title: '7 Days Connected',
      subtitle: 'A week of faithful connection with God.',
      target: 7,
      about:
          'Showing up for seven days builds a rhythm of seeking God first.',
      reward: 'Faithfulness begins with small daily steps.',
      icon: IconKind.lantern,
    ),
    MilestoneDef(
      id: 'conn_30',
      category: MilestoneCategory.connection,
      title: '30 Days Connected',
      subtitle: 'You have made time with God for 30 days.',
      target: 30,
      about:
          'A month of connection deepens trust and anchors your heart in Him.',
      reward: 'Strength grows when we stay connected to God.',
      icon: IconKind.wreath,
    ),
    MilestoneDef(
      id: 'conn_50',
      category: MilestoneCategory.connection,
      title: '50 Days Connected',
      subtitle: 'Fifty days of walking closely with the Lord.',
      target: 50,
      about:
          'Consistency over time shapes character and draws you nearer to God.',
      reward: 'He is faithful to those who seek Him daily.',
      icon: IconKind.lantern,
    ),
    MilestoneDef(
      id: 'conn_100',
      category: MilestoneCategory.connection,
      title: '100 Days Connected',
      subtitle: 'One hundred days of intentional connection.',
      target: 100,
      about:
          'A hundred days of presence becomes a testimony of steadfast love.',
      reward: 'Your roots grow deep when you abide in Him.',
      icon: IconKind.sprout,
    ),
    MilestoneDef(
      id: 'conn_365',
      category: MilestoneCategory.connection,
      title: '365 Days Connected',
      subtitle: 'A full year of daily connection with God.',
      target: 365,
      about:
          'A year of faithfulness marks a life shaped by devotion and grace.',
      reward: 'Well done — keep shining His light each day.',
      icon: IconKind.wreath,
    ),

    // —— Prayer ——
    MilestoneDef(
      id: 'pray_1',
      category: MilestoneCategory.prayer,
      title: 'First Prayer',
      subtitle: 'You shared your first prayer.',
      target: 1,
      about:
          'Sharing your first prayer opens a door of hope for yourself and others.',
      reward: 'Your voice matters in the house of prayer.',
      icon: IconKind.prayer,
    ),
    MilestoneDef(
      id: 'pray_10',
      category: MilestoneCategory.prayer,
      title: 'Praying Together',
      subtitle: 'Joined in prayer 10 times.',
      target: 10,
      about:
          'Standing with others in prayer builds unity and compassion.',
      reward: 'Where two or three gather, He is in the midst.',
      icon: IconKind.prayer,
    ),
    MilestoneDef(
      id: 'pray_50',
      category: MilestoneCategory.prayer,
      title: 'Prayer Companion',
      subtitle: 'Joined in prayer 50 times.',
      target: 50,
      about:
          'Standing together in prayer strengthens our faith and brings hope to others.',
      reward: 'A heart that prays makes a difference.',
      icon: IconKind.prayer,
    ),
    MilestoneDef(
      id: 'pray_100',
      category: MilestoneCategory.prayer,
      title: 'Faithful in Prayer',
      subtitle: 'Joined in prayer 100 times.',
      target: 100,
      about:
          'Faithful intercession leaves a lasting mark on hearts and homes.',
      reward: 'Keep watching and praying with perseverance.',
      icon: IconKind.prayer,
    ),
    MilestoneDef(
      id: 'pray_250',
      category: MilestoneCategory.prayer,
      title: 'Prayer Intercessor',
      subtitle: 'Joined in prayer 250 times.',
      target: 250,
      about:
          'An intercessor carries others before God with love and endurance.',
      reward: 'Blessed are those who pray without ceasing.',
      icon: IconKind.prayer,
    ),

    // —— Community ——
    MilestoneDef(
      id: 'comm_1',
      category: MilestoneCategory.community,
      title: 'Community Starter',
      subtitle: 'Made your first comment on a prayer.',
      target: 1,
      about:
          'Your first word of encouragement can lift a weary soul.',
      reward: 'Kind words plant seeds of hope.',
      icon: IconKind.community,
    ),
    MilestoneDef(
      id: 'comm_10',
      category: MilestoneCategory.community,
      title: 'Encourager',
      subtitle: 'Made 10 encouraging comments.',
      target: 10,
      about:
          'Encouragement multiplies when shared freely in community.',
      reward: 'Build one another up in love.',
      icon: IconKind.community,
    ),
    MilestoneDef(
      id: 'comm_50',
      category: MilestoneCategory.community,
      title: 'Faithful Supporter',
      subtitle: 'Made 50 encouraging comments.',
      target: 50,
      about:
          'Faithful support turns strangers into family in Christ.',
      reward: 'You are a blessing to many.',
      icon: IconKind.community,
    ),
    MilestoneDef(
      id: 'comm_100',
      category: MilestoneCategory.community,
      title: 'Community Builder',
      subtitle: 'Made 100 encouraging comments.',
      target: 100,
      about:
          'Builders create places where faith and friendship thrive.',
      reward: 'Your presence strengthens the body.',
      icon: IconKind.community,
    ),
    MilestoneDef(
      id: 'comm_250',
      category: MilestoneCategory.community,
      title: 'Light in Community',
      subtitle: 'Made 250 encouraging comments.',
      target: 250,
      about:
          'A consistent light guides many toward hope and belonging.',
      reward: 'Let your light shine before others.',
      icon: IconKind.community,
    ),
  ];

  static List<MilestoneDef> byCategory(MilestoneCategory c) =>
      all.where((m) => m.category == c).toList();

  static MilestoneDef? byId(String id) {
    try {
      return all.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  static String tabTitle(MilestoneCategory c) {
    switch (c) {
      case MilestoneCategory.connection:
        return 'Connection';
      case MilestoneCategory.prayer:
        return 'Prayer';
      case MilestoneCategory.community:
        return 'Community';
    }
  }

  static String tabIntro(MilestoneCategory c) {
    switch (c) {
      case MilestoneCategory.connection:
        return 'Celebrate your daily connection and lasting faithfulness.';
      case MilestoneCategory.prayer:
        return 'Celebrate your prayer journey and faithful time spent in prayer.';
      case MilestoneCategory.community:
        return 'Celebrate how you connect, support and encourage others in faith.';
    }
  }
}
