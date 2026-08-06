//
//  BibleHomeWidget.swift
//  BibleHomeWidget
//
//  iOS Home Screen Widget Extension: Verse of the day, Bible Prayer, Bible Chat.
//  Uses old-paper styling and default content when app has not yet provided data.
//  Adopts containerBackground API for iOS 17+ so widgets render correctly on all devices.
//

import SwiftUI
import WidgetKit

private let appGroupId = "group.com.balaklrapps.newkingsjamesversion"

// MARK: - Old Paper Theme

private let oldPaperBackground = Color(red: 0.95, green: 0.92, blue: 0.84)
private let oldPaperText = Color(red: 0.29, green: 0.22, blue: 0.18)
private let oldPaperSecondary = Color(red: 0.45, green: 0.35, blue: 0.28)
private let oldPaperAccent = Color(red: 0.55, green: 0.42, blue: 0.33)
private let leatherBackground = Color(red: 0.35, green: 0.22, blue: 0.15)
private let leatherText = Color(red: 0.93, green: 0.88, blue: 0.78)
private let ribbonGold = Color(red: 0.83, green: 0.69, blue: 0.22)
private let flourishGold = Color(red: 0.72, green: 0.52, blue: 0.18)

private struct OldPaperTitleRow: View {
  let title: String

  var body: some View {
    HStack(spacing: 6) {
      Rectangle()
        .fill(oldPaperAccent.opacity(0.35))
        .frame(height: 1)
      Text(title)
        .font(.system(size: 10, weight: .semibold, design: .serif))
        .foregroundStyle(oldPaperText)
        .widgetFullColorContent()
        .lineLimit(1)
        .minimumScaleFactor(0.8)
      Rectangle()
        .fill(oldPaperAccent.opacity(0.35))
        .frame(height: 1)
    }
  }
}

private struct WidgetFlourish: View {
  var color: Color = oldPaperAccent.opacity(0.55)

  var body: some View {
    Text("❦")
      .font(.system(size: 11, design: .serif))
      .foregroundStyle(color)
      .widgetFullColorContent()
  }
}

// MARK: - Widget backgrounds (solid gradients — reliable in Add Widget gallery; PNGs in nested containerBackground often fail preview)

private enum WidgetBackgroundStyle {
  case parchment
  case leather
  case prayerGuidance
  case verseScenic

  @ViewBuilder
  var background: some View {
    switch self {
    case .parchment:
      LinearGradient(
        colors: [
          Color(red: 0.97, green: 0.94, blue: 0.88),
          oldPaperBackground,
          Color(red: 0.90, green: 0.85, blue: 0.76),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    case .leather:
      LinearGradient(
        colors: [
          Color(red: 0.42, green: 0.28, blue: 0.18),
          leatherBackground,
          Color(red: 0.28, green: 0.16, blue: 0.10),
        ],
        startPoint: .top,
        endPoint: .bottom
      )
    case .prayerGuidance:
      LinearGradient(
        colors: [
          Color(red: 1.0, green: 0.92, blue: 0.84),
          Color(red: 0.99, green: 0.86, blue: 0.76),
          Color(red: 0.95, green: 0.78, blue: 0.68),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    case .verseScenic:
      LinearGradient(
        colors: [
          Color(red: 0.96, green: 0.93, blue: 0.86),
          Color(red: 0.88, green: 0.82, blue: 0.72),
          Color(red: 0.76, green: 0.68, blue: 0.55),
        ],
        startPoint: .top,
        endPoint: .bottom
      )
    }
  }
}

/// Optional asset image for Medium/Large widgets (small sizes keep gradient for clarity).
private struct WidgetBackgroundContainer<Content: View>: View {
  let style: WidgetBackgroundStyle
  let largeImage: String?
  private let content: () -> Content
  @Environment(\.widgetFamily) private var family

  init(
    style: WidgetBackgroundStyle,
    largeImage: String?,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.style = style
    self.largeImage = largeImage
    self.content = content
  }

  @ViewBuilder
  private var backgroundView: some View {
    if (family == .systemLarge || family == .systemMedium), let imageName = largeImage {
      ZStack {
        Image(imageName)
          .resizable()
          .scaledToFill()
        LinearGradient(
          colors: [
            Color.white.opacity(0.72),
            Color.white.opacity(0.52),
            Color(red: 0.95, green: 0.92, blue: 0.84).opacity(0.65),
          ],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      }
    } else {
      style.background
    }
  }

  var body: some View {
    if #available(iOSApplicationExtension 17.0, *) {
      content()
        .containerBackground(for: .widget) {
          backgroundView
        }
    } else {
      ZStack {
        backgroundView
        content()
      }
    }
  }
}

/// Single containerBackground per widget — required for iOS 17+ gallery and home screen.
private func widgetWithBackground<Content: View>(
  _ style: WidgetBackgroundStyle,
  largeImage: String? = nil,
  @ViewBuilder content: @escaping () -> Content
) -> some View {
  WidgetBackgroundContainer(style: style, largeImage: largeImage, content: content)
}

private func loadWeeklyStreakCount(from defaults: UserDefaults?) -> Int {
  if let raw = defaults?.string(forKey: "widget_weekly_streak_count_str"),
     let parsed = Int(raw.trimmingCharacters(in: .whitespacesAndNewlines)) {
    return max(parsed, 0)
  }
  if defaults?.object(forKey: "widget_weekly_streak_count") != nil {
    return max(defaults?.integer(forKey: "widget_weekly_streak_count") ?? 0, 0)
  }
  return 0
}

// MARK: - Verse of the Day Widget
private let defaultVerseText = "Be still and know that I am God."
private let defaultVerseRef = "Psalm 46:10"
private let defaultFavoriteVerseText = "For God so loved the world, that he gave his only begotten Son, that whoever believes in him should not perish but have eternal life."
private let defaultHourlyVerseText = "Commit your work to the Lord, and your plans will be established."
private let defaultHourlyVerseRef = "Proverbs 16:3"
private let defaultVerseImageText = "I can do all things through Christ who strengthens me."
private let defaultVerseImageRef = "Philippians 4:13"
private let defaultContinueBookChapter = "Genesis 12"
private let defaultContinueSubtitle = "Chapter 12 · 32% of book"
private let defaultContinueProgress = 0.32
private let defaultContinueProgressLabel = "32%"
private let defaultHourlyNextLabel = "Next verse in 42 min"
private let defaultPrayerText = "Lord, guide my heart today. Give me strength to face challenges and peace in uncertainty. May I reflect Your love to others. Amen."
private let defaultChatQuestion = "What is faith?"
private let defaultChatAnswer = "Faith is confidence in what we hope for and assurance about what we do not see. — Hebrews 11:1"

/// Removes `<br>` and other simple HTML tags for widget text (matches app-side sanitization).
private func plainVerseTextForWidget(_ raw: String) -> String {
  var s = raw
  s = s.replacingOccurrences(of: "<br/>", with: " ", options: .caseInsensitive)
  s = s.replacingOccurrences(of: "<br>", with: " ", options: .caseInsensitive)
  if let regex = try? NSRegularExpression(pattern: "<[^>]+>", options: []) {
    let range = NSRange(s.startIndex..., in: s)
    s = regex.stringByReplacingMatches(in: s, range: range, withTemplate: " ")
  }
  return s.replacingOccurrences(of: "  ", with: " ", options: [])
    .trimmingCharacters(in: .whitespacesAndNewlines)
}

private func loadSharedVerse(
  textKey: String,
  refKey: String,
  defaultText: String,
  defaultRef: String
) -> (String, String) {
  let defaults = UserDefaults(suiteName: appGroupId)
  var text = defaults?.string(forKey: textKey) ?? ""
  var ref = defaults?.string(forKey: refKey) ?? ""
  if text.isEmpty { text = defaultText }
  if ref.isEmpty { ref = defaultRef }
  return (plainVerseTextForWidget(text), ref)
}

private func parseWeeklyStreakStatuses(_ raw: String) -> [Int] {
  let parts = raw.split(separator: ",").map { Int($0.trimmingCharacters(in: .whitespaces)) ?? 0 }
  if parts.count >= 7 { return Array(parts.prefix(7)) }
  var padded = parts
  while padded.count < 7 { padded.append(0) }
  return padded
}

// MARK: - Verse of the Day Widget

struct VerseOfTheDayEntry: TimelineEntry {
  let date: Date
  let verseText: String
  let verseReference: String
}

struct VerseOfTheDayProvider: TimelineProvider {
  func placeholder(in context: Context) -> VerseOfTheDayEntry {
    VerseOfTheDayEntry(date: Date(), verseText: defaultVerseText, verseReference: defaultVerseRef)
  }

  func getSnapshot(in context: Context, completion: @escaping (VerseOfTheDayEntry) -> Void) {
    let defaults = UserDefaults(suiteName: appGroupId)
    var text = defaults?.string(forKey: "widget_verse_text") ?? ""
    var ref = defaults?.string(forKey: "widget_verse_reference") ?? ""
    if text.isEmpty { text = defaultVerseText }
    if ref.isEmpty { ref = defaultVerseRef }
    completion(VerseOfTheDayEntry(date: Date(), verseText: text, verseReference: ref))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<VerseOfTheDayEntry>) -> Void) {
    getSnapshot(in: context) { entry in
      completion(Timeline(entries: [entry], policy: .atEnd))
    }
  }
}

struct VerseOfTheDayView: View {
  var entry: VerseOfTheDayEntry
  @Environment(\.widgetFamily) private var family

  var body: some View {
    widgetWithBackground(.parchment, largeImage: "widget_path_bg") {
      Group {
        if family == .systemLarge {
          VStack(spacing: 10) {
            Spacer(minLength: 0)
            OldPaperTitleRow(title: "Daily Verse")
            Text(plainVerseTextForWidget(entry.verseText))
              .font(.system(size: 16, weight: .bold, design: .serif))
              .foregroundStyle(oldPaperText)
              .widgetFullColorContent()
              .multilineTextAlignment(.center)
              .lineLimit(6)
              .minimumScaleFactor(0.82)
              .padding(.horizontal, 8)
            Text(entry.verseReference)
              .font(.system(size: 12, weight: .medium, design: .serif))
              .foregroundStyle(oldPaperSecondary)
              .widgetFullColorContent()
              .multilineTextAlignment(.center)
            WidgetFlourish()
            Spacer(minLength: 0)
          }
        } else {
          VStack(spacing: 5) {
            ZStack {
              Image(systemName: "book.closed.fill")
                .font(.system(size: 12))
                .foregroundColor(oldPaperText)
              Image(systemName: "plus")
                .font(.system(size: 5, weight: .bold))
                .foregroundColor(oldPaperText)
                .offset(y: -1)
            }
            OldPaperTitleRow(title: "Daily Verse")
            Text(plainVerseTextForWidget(entry.verseText))
              .font(.system(size: 13, weight: .bold, design: .serif))
              .foregroundStyle(oldPaperText)
              .widgetFullColorContent()
              .multilineTextAlignment(.center)
              .lineLimit(4)
              .minimumScaleFactor(0.82)
              .padding(.horizontal, 2)
            Spacer(minLength: 0)
            Text(entry.verseReference)
              .font(.system(size: 10, weight: .medium, design: .serif))
              .foregroundStyle(oldPaperSecondary)
              .widgetFullColorContent()
              .multilineTextAlignment(.center)
            WidgetFlourish()
          }
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .padding(family == .systemLarge ? 16 : 10)
    }
    .widgetURL(URL(string: "biblebookapp://verse?homeWidget"))
  }
}

struct VerseOfTheDayWidget: Widget {
  let kind: String = "VerseOfTheDayWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: VerseOfTheDayProvider()) { entry in
      VerseOfTheDayView(entry: entry)
    }
    .configurationDisplayName("Daily Verse")
    .description("Today's Bible verse on your home screen.")
  }
}

/// Ensures labels render in the Add Widget gallery (WidgetKit may otherwise redact Text).
private extension View {
  @ViewBuilder
  func widgetFullColorContent() -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      self.widgetAccentable(false)
    } else {
      self
    }
  }
}

// MARK: - Bible Prayer Widget

struct BiblePrayerEntry: TimelineEntry {
  let date: Date
  let title: String
  let prayerText: String
  let prayerReference: String
  let prayerTime: String
  let streakDays: Int
}

struct BiblePrayerProvider: TimelineProvider {
  func placeholder(in context: Context) -> BiblePrayerEntry {
    BiblePrayerEntry(
      date: Date(),
      title: "Morning Prayer",
      prayerText: defaultPrayerText,
      prayerReference: "Proverbs 27:9",
      prayerTime: "08:30",
      streakDays: 0
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (BiblePrayerEntry) -> Void) {
    let defaults = UserDefaults(suiteName: appGroupId)
    let title = defaults?.string(forKey: "widget_bible_prayer_title") ?? "Morning Prayer"
    var text = defaults?.string(forKey: "widget_prayer_text") ?? ""
    let reference = defaults?.string(forKey: "widget_prayer_reference") ?? "Proverbs 27:9"
    let time = defaults?.string(forKey: "widget_prayer_time") ?? "08:30"
    let days = defaults?.integer(forKey: "widget_streak_days") ?? 0
    if text.isEmpty { text = defaultPrayerText }
    completion(
      BiblePrayerEntry(
        date: Date(),
        title: title,
        prayerText: text,
        prayerReference: reference,
        prayerTime: time,
        streakDays: days
      )
    )
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<BiblePrayerEntry>) -> Void) {
    getSnapshot(in: context) { entry in
      completion(Timeline(entries: [entry], policy: .atEnd))
    }
  }
}

struct BiblePrayerView: View {
  var entry: BiblePrayerEntry
  @Environment(\.widgetFamily) private var family

  var body: some View {
    if family == .systemLarge {
      biblePrayerExpandedLayout(showClock: true, useBackgroundImage: true)
        .widgetURL(URL(string: "biblebookapp://prayer?homeWidget"))
    } else if family == .systemMedium {
      // Same Bible Prayer background image/color as Large; compact layout fits safe area.
      widgetWithBackground(.prayerGuidance, largeImage: "widget_prayer_guidance_bg") {
        VStack(spacing: 6) {
          HStack {
            Spacer()
            HStack(spacing: 4) {
              Image(systemName: "flame.fill")
                .font(.system(size: 9, weight: .semibold))
              Text("\(entry.streakDays) days")
                .font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(.white)
            .widgetFullColorContent()
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.white.opacity(0.22))
            .clipShape(Capsule())
            Spacer()
          }

          VStack(spacing: 5) {
            Text(entry.title)
              .font(.caption)
              .fontWeight(.semibold)
              .foregroundStyle(oldPaperText)
              .widgetFullColorContent()
              .multilineTextAlignment(.center)

            Text(entry.prayerText)
              .font(.caption2)
              .foregroundStyle(oldPaperText)
              .widgetFullColorContent()
              .lineLimit(1)
              .multilineTextAlignment(.center)

            Text(entry.prayerReference)
              .font(.system(size: 10, weight: .semibold))
              .foregroundStyle(oldPaperSecondary)
              .widgetFullColorContent()

            Text("Pray Now")
              .font(.caption2)
              .fontWeight(.bold)
              .foregroundStyle(.white)
              .widgetFullColorContent()
              .frame(maxWidth: .infinity)
              .padding(.vertical, 6)
              .background(Color.orange)
              .clipShape(Capsule())
              .padding(.top, 2)
          }
          .padding(.horizontal, 10)
          .padding(.vertical, 8)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .background(Color(red: 0.99, green: 0.96, blue: 0.90))
          .overlay(
            RoundedRectangle(cornerRadius: 12)
              .stroke(Color(red: 0.88, green: 0.82, blue: 0.73), lineWidth: 1)
          )
          .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
      .widgetURL(URL(string: "biblebookapp://prayer?homeWidget"))
    } else {
      widgetWithBackground(.parchment) {
        VStack(alignment: .leading, spacing: 6) {
          HStack(spacing: 4) {
            Image(systemName: "hands.sparkles")
              .font(.caption)
              .foregroundColor(oldPaperAccent)
            Text(entry.title)
              .font(.caption)
              .fontWeight(.semibold)
              .foregroundColor(oldPaperAccent)
          }
          Text(entry.prayerText)
            .font(.subheadline)
            .foregroundStyle(oldPaperText)
            .widgetFullColorContent()
            .lineLimit(4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(12)
      }
      .widgetURL(URL(string: "biblebookapp://prayer?homeWidget"))
    }
  }

  @ViewBuilder
  private func biblePrayerExpandedLayout(
    showClock: Bool,
    useBackgroundImage: Bool
  ) -> some View {
    let isLarge = family == .systemLarge
    let outerPadding: CGFloat = isLarge ? 14 : 12
    let cardHPadding: CGFloat = isLarge ? 18 : 12
    let prayNowHPadding: CGFloat = isLarge ? 48 : 28

    Group {
      if useBackgroundImage {
        widgetWithBackground(.prayerGuidance, largeImage: "widget_prayer_guidance_bg") {
          biblePrayerExpandedContent(
            showClock: showClock,
            isLarge: isLarge,
            cardHPadding: cardHPadding,
            prayNowHPadding: prayNowHPadding
          )
          .padding(outerPadding)
        }
      } else {
        widgetWithBackground(.prayerGuidance) {
          biblePrayerExpandedContent(
            showClock: showClock,
            isLarge: isLarge,
            cardHPadding: cardHPadding,
            prayNowHPadding: prayNowHPadding
          )
          .padding(outerPadding)
        }
      }
    }
  }

  @ViewBuilder
  private func biblePrayerExpandedContent(
    showClock: Bool,
    isLarge: Bool,
    cardHPadding: CGFloat,
    prayNowHPadding: CGFloat
  ) -> some View {
    VStack(spacing: isLarge ? 0 : 6) {
      HStack {
        Spacer()
        HStack(spacing: 6) {
          Image(systemName: "flame.fill")
            .font(.caption2)
          Text("\(entry.streakDays) days")
            .font(.caption2)
            .fontWeight(.semibold)
        }
        .foregroundStyle(oldPaperAccent)
        .widgetFullColorContent()
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Color.white.opacity(0.55))
        .clipShape(Capsule())
        Spacer()
      }

      if showClock {
        Text(entry.prayerTime)
          .font(.system(size: 54, weight: .bold, design: .rounded))
          .foregroundStyle(oldPaperText)
          .widgetFullColorContent()
          .padding(.top, 6)
      }

      Spacer(minLength: isLarge ? 10 : 4)

      VStack(spacing: isLarge ? 8 : 6) {
        Text(entry.title)
          .font(isLarge ? .title3 : .subheadline)
          .fontWeight(.semibold)
          .foregroundStyle(oldPaperText)
          .widgetFullColorContent()
          .multilineTextAlignment(.center)

        Text(entry.prayerText)
          .font(isLarge ? .body : .caption)
          .foregroundStyle(oldPaperText)
          .widgetFullColorContent()
          .lineLimit(isLarge ? 4 : 2)
          .multilineTextAlignment(.center)
          .padding(.horizontal, 4)

        Text(entry.prayerReference)
          .font(isLarge ? .subheadline : .caption2)
          .fontWeight(.semibold)
          .foregroundStyle(oldPaperSecondary)
          .widgetFullColorContent()
      }
      .padding(.horizontal, cardHPadding)
      .padding(.vertical, isLarge ? 16 : 10)
      .frame(maxWidth: .infinity)
      .background(Color(red: 0.99, green: 0.96, blue: 0.90).opacity(0.92))
      .overlay(
        RoundedRectangle(cornerRadius: isLarge ? 18 : 14)
          .stroke(Color(red: 0.88, green: 0.82, blue: 0.73), lineWidth: 1)
      )
      .clipShape(RoundedRectangle(cornerRadius: isLarge ? 18 : 14))
      .padding(.horizontal, cardHPadding)

      Spacer(minLength: isLarge ? 8 : 4)

      Text("Pray Now")
        .font(isLarge ? .headline : .subheadline)
        .fontWeight(.bold)
        .foregroundStyle(.white)
        .widgetFullColorContent()
        .frame(maxWidth: .infinity)
        .padding(.vertical, isLarge ? 12 : 8)
        .background(Color.orange)
        .clipShape(Capsule())
        .padding(.horizontal, prayNowHPadding)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

struct BiblePrayerWidget: Widget {
  let kind: String = "BiblePrayerWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: BiblePrayerProvider()) { entry in
      BiblePrayerView(entry: entry)
    }
    .configurationDisplayName("Bible Prayer")
    .description("A moment of prayer on your home screen.")
  }
}

// MARK: - Bible Chat Widget

struct BibleChatEntry: TimelineEntry {
  let date: Date
  let question: String
  let answer: String
}

struct BibleChatProvider: TimelineProvider {
  func placeholder(in context: Context) -> BibleChatEntry {
    BibleChatEntry(date: Date(), question: defaultChatQuestion, answer: defaultChatAnswer)
  }

  func getSnapshot(in context: Context, completion: @escaping (BibleChatEntry) -> Void) {
    let defaults = UserDefaults(suiteName: appGroupId)
    var q = defaults?.string(forKey: "widget_chat_question") ?? ""
    var a = defaults?.string(forKey: "widget_chat_answer") ?? ""
    if q.isEmpty { q = defaultChatQuestion }
    if a.isEmpty { a = defaultChatAnswer }
    completion(BibleChatEntry(date: Date(), question: q, answer: a))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<BibleChatEntry>) -> Void) {
    getSnapshot(in: context) { entry in
      completion(Timeline(entries: [entry], policy: .atEnd))
    }
  }
}

struct BibleChatView: View {
  var entry: BibleChatEntry
  @Environment(\.widgetFamily) private var family

  var body: some View {
    widgetWithBackground(.parchment, largeImage: "widget_path_bg") {
      Group {
        if family == .systemLarge {
          VStack(spacing: 10) {
            Spacer(minLength: 0)
            HStack(spacing: 4) {
              Image(systemName: "message")
                .font(.caption)
                .foregroundColor(oldPaperAccent)
              Text("Bible Chat")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(oldPaperAccent)
            }
            Text("Q: " + entry.question)
              .font(.headline)
              .fontWeight(.medium)
              .foregroundStyle(oldPaperText)
              .widgetFullColorContent()
              .multilineTextAlignment(.center)
              .lineLimit(3)
              .padding(.horizontal, 8)
            Text(entry.answer)
              .font(.body)
              .foregroundStyle(oldPaperSecondary)
              .widgetFullColorContent()
              .multilineTextAlignment(.center)
              .lineLimit(5)
              .padding(.horizontal, 8)
            Spacer(minLength: 0)
          }
        } else {
          VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
              Image(systemName: "message")
                .font(.caption)
                .foregroundColor(oldPaperAccent)
              Text("Bible Chat")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(oldPaperAccent)
            }
            Text("Q: " + entry.question)
              .font(.subheadline)
              .fontWeight(.medium)
              .foregroundStyle(oldPaperText)
              .widgetFullColorContent()
              .lineLimit(2)
            Text(entry.answer)
              .font(.caption)
              .foregroundStyle(oldPaperSecondary)
              .widgetFullColorContent()
              .lineLimit(3)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .padding(family == .systemLarge ? 16 : 12)
    }
    .widgetURL(URL(string: "biblebookapp://chat?homeWidget"))
  }
}

struct BibleChatWidget: Widget {
  let kind: String = "BibleChatWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: BibleChatProvider()) { entry in
      BibleChatView(entry: entry)
    }
    .configurationDisplayName("Bible Chat")
    .description("A Bible Q&A on your home screen.")
  }
}

// MARK: - Continue Reading Widget

struct ContinueReadingEntry: TimelineEntry {
  let date: Date
  let bookChapter: String
  let subtitle: String
  let progress: Double
  let progressLabel: String
}

struct ContinueReadingProvider: TimelineProvider {
  func placeholder(in context: Context) -> ContinueReadingEntry {
    ContinueReadingEntry(
      date: Date(),
      bookChapter: defaultContinueBookChapter,
      subtitle: defaultContinueSubtitle,
      progress: defaultContinueProgress,
      progressLabel: defaultContinueProgressLabel
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (ContinueReadingEntry) -> Void) {
    let defaults = UserDefaults(suiteName: appGroupId)
    let bookChapter = defaults?.string(forKey: "widget_continue_book_chapter") ?? defaultContinueBookChapter
    let subtitle = defaults?.string(forKey: "widget_continue_subtitle") ?? defaultContinueSubtitle
    let progressRaw = defaults?.string(forKey: "widget_continue_progress") ?? ""
    let progress = Double(progressRaw) ?? defaultContinueProgress
    let progressLabel = defaults?.string(forKey: "widget_continue_progress_label") ?? defaultContinueProgressLabel
    completion(
      ContinueReadingEntry(
        date: Date(),
        bookChapter: bookChapter,
        subtitle: subtitle,
        progress: min(max(progress, 0), 1),
        progressLabel: progressLabel
      )
    )
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<ContinueReadingEntry>) -> Void) {
    getSnapshot(in: context) { entry in
      completion(Timeline(entries: [entry], policy: .atEnd))
    }
  }
}

struct ContinueReadingView: View {
  var entry: ContinueReadingEntry
  @Environment(\.widgetFamily) private var family

  var body: some View {
    // Brown leather gradient on every size (small/medium/large) — display-only.
    widgetWithBackground(.leather) {
      ZStack {
        RoundedRectangle(cornerRadius: 10)
          .inset(by: 6)
          .stroke(
            leatherText.opacity(0.35),
            style: StrokeStyle(lineWidth: 1, dash: [5, 4])
          )
        Group {
          if family == .systemLarge {
            VStack(spacing: 10) {
              Spacer(minLength: 0)
              Image(systemName: "bookmark.fill")
                .font(.system(size: 16))
                .foregroundColor(ribbonGold)
                .rotationEffect(.degrees(-12))
              Text("Continue Reading")
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundColor(leatherText.opacity(0.92))
              Text(entry.bookChapter)
                .font(.system(size: 24, weight: .bold, design: .serif))
                .foregroundColor(leatherText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
              Text(entry.subtitle)
                .font(.system(size: 12, design: .serif))
                .foregroundColor(leatherText.opacity(0.88))
                .multilineTextAlignment(.center)
                .lineLimit(2)
              HStack(spacing: 8) {
                GeometryReader { geo in
                  ZStack(alignment: .leading) {
                    Capsule().fill(Color.black.opacity(0.28))
                    Capsule()
                      .fill(Color.white.opacity(0.92))
                      .frame(width: geo.size.width * entry.progress)
                  }
                }
                .frame(height: 6)
                Text(entry.progressLabel)
                  .font(.system(size: 10, weight: .semibold, design: .serif))
                  .foregroundColor(leatherText)
              }
              .padding(.horizontal, 12)
              Text("Keep reading God's Word")
                .font(.system(size: 11, design: .serif))
                .foregroundColor(leatherText.opacity(0.88))
              Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(14)
          } else {
            VStack(alignment: .leading, spacing: 5) {
              Image(systemName: "bookmark.fill")
                .font(.system(size: 11))
                .foregroundColor(ribbonGold)
                .rotationEffect(.degrees(-12))
              Text("Continue Reading")
                .font(.system(size: 11, weight: .semibold, design: .serif))
                .foregroundColor(leatherText.opacity(0.92))
              Text(entry.bookChapter)
                .font(.system(size: 19, weight: .bold, design: .serif))
                .foregroundColor(leatherText)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
              Text(entry.subtitle)
                .font(.system(size: 10, design: .serif))
                .foregroundColor(leatherText.opacity(0.88))
                .lineLimit(2)
                .minimumScaleFactor(0.85)
              HStack(spacing: 6) {
                GeometryReader { geo in
                  ZStack(alignment: .leading) {
                    Capsule().fill(Color.black.opacity(0.28))
                    Capsule()
                      .fill(Color.white.opacity(0.92))
                      .frame(width: geo.size.width * entry.progress)
                  }
                }
                .frame(height: 5)
                Text(entry.progressLabel)
                  .font(.system(size: 9, weight: .semibold, design: .serif))
                  .foregroundColor(leatherText)
              }
              Spacer(minLength: 0)
              HStack {
                Text("Keep reading God's Word")
                  .font(.system(size: 9, design: .serif))
                  .foregroundColor(leatherText.opacity(0.88))
                Spacer()
                Image(systemName: "book.fill")
                  .font(.system(size: 11))
                  .foregroundColor(leatherText.opacity(0.88))
              }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(10)
          }
        }
      }
    }
    .widgetURL(URL(string: "biblebookapp://verse?homeWidget"))
  }
}

struct ContinueReadingWidget: Widget {
  let kind: String = "ContinueReadingWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: ContinueReadingProvider()) { entry in
      ContinueReadingView(entry: entry)
    }
    .configurationDisplayName("Continue Reading")
    .description("Pick up where you left off in Scripture.")
  }
}

// MARK: - Weekly Reading Streak Widget

struct WeeklyReadingStreakEntry: TimelineEntry {
  let date: Date
  let dayStatuses: [Int]
  let streakCount: Int
}

struct WeeklyReadingStreakProvider: TimelineProvider {
  func placeholder(in context: Context) -> WeeklyReadingStreakEntry {
    WeeklyReadingStreakEntry(date: Date(), dayStatuses: [1, 1, 1, 0, 0, 0, 0], streakCount: 7)
  }

  func getSnapshot(in context: Context, completion: @escaping (WeeklyReadingStreakEntry) -> Void) {
    let defaults = UserDefaults(suiteName: appGroupId)
    let statusRaw = defaults?.string(forKey: "widget_weekly_streak_status") ?? "1,1,1,0,0,0,0"
    let streakCount = loadWeeklyStreakCount(from: defaults)
    completion(
      WeeklyReadingStreakEntry(
        date: Date(),
        dayStatuses: parseWeeklyStreakStatuses(statusRaw),
        streakCount: streakCount
      )
    )
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<WeeklyReadingStreakEntry>) -> Void) {
    getSnapshot(in: context) { entry in
      completion(Timeline(entries: [entry], policy: .atEnd))
    }
  }
}

struct WeeklyReadingStreakView: View {
  var entry: WeeklyReadingStreakEntry
  @Environment(\.widgetFamily) private var family
  private let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

  private func iconName(for status: Int) -> String {
    switch status {
    case 1: return "checkmark.circle.fill"
    case 2: return "circle"
    default: return "circle"
    }
  }

  private func iconColor(for status: Int) -> Color {
    switch status {
    case 1: return oldPaperText
    case 2: return .orange.opacity(0.85)
    default: return oldPaperSecondary.opacity(0.45)
    }
  }

  private var streakLabel: String {
    entry.streakCount == 1 ? "1 Day" : "\(entry.streakCount) Days"
  }

  private var weekRow: some View {
    HStack {
      ForEach(Array(days.enumerated()), id: \.offset) { index, day in
        let status = index < entry.dayStatuses.count ? entry.dayStatuses[index] : 0
        VStack(spacing: 3) {
          Text(day)
            .font(.system(size: family == .systemLarge ? 9 : 7, weight: .medium, design: .serif))
            .foregroundColor(oldPaperSecondary)
          Image(systemName: iconName(for: status))
            .font(.system(size: family == .systemLarge ? 14 : 10))
            .foregroundColor(iconColor(for: status))
        }
        if index < days.count - 1 { Spacer(minLength: 0) }
      }
    }
  }

  var body: some View {
    widgetWithBackground(.parchment, largeImage: "widget_welcome_bg") {
      Group {
        if family == .systemLarge {
          VStack(spacing: 14) {
            Spacer(minLength: 0)
            HStack(spacing: 6) {
              Image(systemName: "flame.fill")
                .font(.system(size: 14))
                .foregroundColor(.orange)
              Text("Reading Streak")
                .font(.system(size: 14, weight: .semibold, design: .serif))
                .foregroundColor(oldPaperText)
            }
            weekRow
              .padding(.horizontal, 4)
            Rectangle()
              .fill(oldPaperAccent.opacity(0.25))
              .frame(height: 1)
              .padding(.horizontal, 8)
            Text(streakLabel)
              .font(.system(size: 28, weight: .bold, design: .serif))
              .foregroundColor(oldPaperText)
              .multilineTextAlignment(.center)
            Text("Keep it up!")
              .font(.system(size: 13, design: .serif))
              .foregroundColor(oldPaperSecondary)
              .multilineTextAlignment(.center)
            Spacer(minLength: 0)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .padding(16)
        } else {
          VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
              Image(systemName: "flame.fill")
                .font(.system(size: 11))
                .foregroundColor(.orange)
              Text("Reading Streak")
                .font(.system(size: 11, weight: .semibold, design: .serif))
                .foregroundColor(oldPaperText)
            }
            weekRow
            Rectangle()
              .fill(oldPaperAccent.opacity(0.25))
              .frame(height: 1)
              .padding(.vertical, 2)
            Text(streakLabel)
              .font(.system(size: 17, weight: .bold, design: .serif))
              .foregroundColor(oldPaperText)
            Text("Keep it up!")
              .font(.system(size: 10, design: .serif))
              .foregroundColor(oldPaperSecondary)
              .frame(maxWidth: .infinity, alignment: .center)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
          .padding(10)
        }
      }
    }
    .widgetURL(URL(string: "biblebookapp://verse?homeWidget"))
  }
}

struct WeeklyReadingStreakWidget: Widget {
  let kind: String = "WeeklyReadingStreakWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: WeeklyReadingStreakProvider()) { entry in
      WeeklyReadingStreakView(entry: entry)
    }
    .configurationDisplayName("Weekly Reading Streak")
    .description("See your weekly reading streak.")
  }
}

// MARK: - Favorite Verse Widget

struct FavoriteVerseEntry: TimelineEntry {
  let date: Date
  let verseText: String
  let verseReference: String
}

struct FavoriteVerseProvider: TimelineProvider {
  func placeholder(in context: Context) -> FavoriteVerseEntry {
    FavoriteVerseEntry(
      date: Date(),
      verseText: defaultFavoriteVerseText,
      verseReference: defaultVerseRef
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (FavoriteVerseEntry) -> Void) {
    let pair = loadSharedVerse(
      textKey: "widget_favorite_verse_text",
      refKey: "widget_favorite_verse_reference",
      defaultText: defaultFavoriteVerseText,
      defaultRef: defaultVerseRef
    )
    completion(FavoriteVerseEntry(date: Date(), verseText: pair.0, verseReference: pair.1))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<FavoriteVerseEntry>) -> Void) {
    getSnapshot(in: context) { entry in
      completion(Timeline(entries: [entry], policy: .atEnd))
    }
  }
}

struct FavoriteVerseView: View {
  var entry: FavoriteVerseEntry
  @Environment(\.widgetFamily) private var family
  private let ribbonRed = Color(red: 0.75, green: 0.22, blue: 0.18)

  var body: some View {
    widgetWithBackground(.parchment, largeImage: "widget_verse_image_bg") {
      Group {
        if family == .systemLarge {
          VStack(spacing: 10) {
            Spacer(minLength: 0)
            HStack(spacing: 6) {
              Image(systemName: "bookmark.fill")
                .font(.system(size: 14))
                .foregroundColor(ribbonRed)
              Text("Favorite Verse")
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundColor(oldPaperText)
            }
            Text(entry.verseText)
              .font(.system(size: 15, weight: .semibold, design: .serif))
              .foregroundColor(oldPaperText)
              .multilineTextAlignment(.center)
              .lineLimit(6)
              .minimumScaleFactor(0.84)
              .padding(.horizontal, 10)
            Text(entry.verseReference)
              .font(.system(size: 12, weight: .medium, design: .serif))
              .foregroundColor(oldPaperSecondary)
              .multilineTextAlignment(.center)
            Spacer(minLength: 0)
          }
        } else {
          VStack(spacing: 5) {
            HStack {
              Image(systemName: "bookmark.fill")
                .font(.system(size: 12))
                .foregroundColor(ribbonRed)
              Spacer()
              Image(systemName: "heart")
                .font(.system(size: 11))
                .foregroundColor(oldPaperSecondary)
            }
            Text(entry.verseText)
              .font(.system(size: 10.5, design: .serif))
              .foregroundColor(oldPaperText)
              .multilineTextAlignment(.leading)
              .lineLimit(5)
              .minimumScaleFactor(0.84)
            Spacer(minLength: 0)
            Text(entry.verseReference)
              .font(.system(size: 10, weight: .medium, design: .serif))
              .foregroundColor(oldPaperSecondary)
              .frame(maxWidth: .infinity, alignment: .trailing)
          }
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .padding(family == .systemLarge ? 16 : 10)
    }
    .widgetURL(URL(string: "biblebookapp://verse?homeWidget"))
  }
}

struct FavoriteVerseWidget: Widget {
  let kind: String = "FavoriteVerseWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: FavoriteVerseProvider()) { entry in
      FavoriteVerseView(entry: entry)
    }
    .configurationDisplayName("Favorite Verse")
    .description("Your saved favorite verse.")
  }
}

// MARK: - Hourly Verse Widget

struct HourlyVerseEntry: TimelineEntry {
  let date: Date
  let verseText: String
  let verseReference: String
  let nextLabel: String
}

struct HourlyVerseProvider: TimelineProvider {
  func placeholder(in context: Context) -> HourlyVerseEntry {
    HourlyVerseEntry(
      date: Date(),
      verseText: defaultHourlyVerseText,
      verseReference: defaultHourlyVerseRef,
      nextLabel: defaultHourlyNextLabel
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (HourlyVerseEntry) -> Void) {
    let defaults = UserDefaults(suiteName: appGroupId)
    let pair = loadSharedVerse(
      textKey: "widget_hourly_verse_text",
      refKey: "widget_hourly_verse_reference",
      defaultText: defaultHourlyVerseText,
      defaultRef: defaultHourlyVerseRef
    )
    let nextLabel = defaults?.string(forKey: "widget_hourly_next_label") ?? defaultHourlyNextLabel
    completion(
      HourlyVerseEntry(
        date: Date(),
        verseText: pair.0,
        verseReference: pair.1,
        nextLabel: nextLabel
      )
    )
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<HourlyVerseEntry>) -> Void) {
    getSnapshot(in: context) { entry in
      completion(Timeline(entries: [entry], policy: .atEnd))
    }
  }
}

struct HourlyVerseView: View {
  var entry: HourlyVerseEntry
  @Environment(\.widgetFamily) private var family

  var body: some View {
    widgetWithBackground(.parchment, largeImage: "widget_verse_image_bg") {
      Group {
        if family == .systemLarge {
          VStack(spacing: 10) {
            Spacer(minLength: 0)
            HStack(spacing: 6) {
              Image(systemName: "clock.fill")
                .font(.system(size: 13))
                .foregroundColor(oldPaperSecondary)
              Text("Hourly Verse")
                .font(.system(size: 14, weight: .semibold, design: .serif))
                .foregroundColor(oldPaperText)
            }
            Text(entry.verseText)
              .font(.system(size: 16, weight: .bold, design: .serif))
              .foregroundColor(oldPaperText)
              .multilineTextAlignment(.center)
              .lineLimit(6)
              .minimumScaleFactor(0.84)
              .padding(.horizontal, 10)
            Text(entry.verseReference)
              .font(.system(size: 12, design: .serif))
              .foregroundColor(oldPaperSecondary)
              .multilineTextAlignment(.center)
            Spacer(minLength: 0)
            HStack {
              Text(entry.nextLabel)
                .font(.system(size: 10, design: .serif))
                .foregroundColor(oldPaperSecondary)
              Spacer()
              Image(systemName: "hourglass")
                .font(.system(size: 11))
                .foregroundColor(oldPaperSecondary)
            }
          }
        } else {
          VStack(spacing: 5) {
            HStack(spacing: 4) {
              Image(systemName: "clock.fill")
                .font(.system(size: 10))
                .foregroundColor(oldPaperSecondary)
              Text("Hourly Verse")
                .font(.system(size: 11, weight: .semibold, design: .serif))
                .foregroundColor(oldPaperText)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            Text(entry.verseText)
              .font(.system(size: 12, weight: .bold, design: .serif))
              .foregroundColor(oldPaperText)
              .multilineTextAlignment(.center)
              .lineLimit(4)
              .minimumScaleFactor(0.84)
            Text(entry.verseReference)
              .font(.system(size: 10, design: .serif))
              .foregroundColor(oldPaperSecondary)
              .frame(maxWidth: .infinity, alignment: .center)
            Spacer(minLength: 0)
            HStack {
              Text(entry.nextLabel)
                .font(.system(size: 9, design: .serif))
                .foregroundColor(oldPaperSecondary)
              Spacer()
              Image(systemName: "hourglass")
                .font(.system(size: 10))
                .foregroundColor(oldPaperSecondary)
            }
          }
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .padding(family == .systemLarge ? 16 : 10)
    }
    .widgetURL(URL(string: "biblebookapp://verse?homeWidget"))
  }
}

struct HourlyVerseWidget: Widget {
  let kind: String = "HourlyVerseWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: HourlyVerseProvider()) { entry in
      HourlyVerseView(entry: entry)
    }
    .configurationDisplayName("Hourly Verse")
    .description("A fresh verse every hour.")
  }
}

// MARK: - Random Bible Verse Widget

struct RandomBibleVerseEntry: TimelineEntry {
  let date: Date
  let verseText: String
  let verseReference: String
}

struct RandomBibleVerseProvider: TimelineProvider {
  func placeholder(in context: Context) -> RandomBibleVerseEntry {
    RandomBibleVerseEntry(date: Date(), verseText: defaultVerseText, verseReference: defaultVerseRef)
  }

  func getSnapshot(in context: Context, completion: @escaping (RandomBibleVerseEntry) -> Void) {
    let pair = loadSharedVerse(
      textKey: "widget_random_verse_text",
      refKey: "widget_random_verse_reference",
      defaultText: defaultVerseText,
      defaultRef: defaultVerseRef
    )
    completion(RandomBibleVerseEntry(date: Date(), verseText: pair.0, verseReference: pair.1))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<RandomBibleVerseEntry>) -> Void) {
    getSnapshot(in: context) { entry in
      completion(Timeline(entries: [entry], policy: .atEnd))
    }
  }
}

struct RandomBibleVerseView: View {
  var entry: RandomBibleVerseEntry
  @Environment(\.widgetFamily) private var family

  var body: some View {
    widgetWithBackground(.parchment, largeImage: "widget_path_bg") {
      Group {
        if family == .systemLarge {
          VStack(spacing: 10) {
            Spacer(minLength: 0)
            HStack(spacing: 6) {
              Image(systemName: "shuffle")
                .font(.system(size: 13))
                .foregroundColor(oldPaperSecondary)
              Text("Random Verse")
                .font(.system(size: 14, weight: .semibold, design: .serif))
                .foregroundColor(oldPaperText)
            }
            Text(entry.verseText)
              .font(.system(size: 16, weight: .bold, design: .serif))
              .foregroundColor(oldPaperText)
              .multilineTextAlignment(.center)
              .lineLimit(6)
            Text(entry.verseReference)
              .font(.system(size: 12, design: .serif))
              .foregroundColor(oldPaperSecondary)
              .multilineTextAlignment(.center)
            Spacer(minLength: 0)
            Text("Tap to get a new verse")
              .font(.system(size: 10, design: .serif))
              .foregroundColor(oldPaperSecondary)
              .multilineTextAlignment(.center)
          }
        } else {
          VStack(spacing: 5) {
            HStack(spacing: 4) {
              Image(systemName: "shuffle")
                .font(.system(size: 10))
                .foregroundColor(oldPaperSecondary)
              Text("Random Verse")
                .font(.system(size: 11, weight: .semibold, design: .serif))
                .foregroundColor(oldPaperText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text(entry.verseText)
              .font(.system(size: 13, weight: .bold, design: .serif))
              .foregroundColor(oldPaperText)
              .multilineTextAlignment(.center)
              .lineLimit(3)
            Text(entry.verseReference)
              .font(.system(size: 10, design: .serif))
              .foregroundColor(oldPaperSecondary)
            Spacer(minLength: 0)
            HStack {
              Text("Tap to get a new verse")
                .font(.system(size: 9, design: .serif))
                .foregroundColor(oldPaperSecondary)
              Spacer()
              Image(systemName: "arrow.clockwise.circle")
                .font(.system(size: 11))
                .foregroundColor(oldPaperSecondary)
            }
          }
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .padding(family == .systemLarge ? 16 : 10)
    }
    .widgetURL(URL(string: "biblebookapp://verse?homeWidget"))
  }
}

struct RandomBibleVerseWidget: Widget {
  let kind: String = "RandomBibleVerseWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: RandomBibleVerseProvider()) { entry in
      RandomBibleVerseView(entry: entry)
    }
    .configurationDisplayName("Random Bible Verse")
    .description("Discover a random Scripture verse.")
  }
}

// MARK: - Verse Image Widget

struct VerseImageEntry: TimelineEntry {
  let date: Date
  let verseText: String
  let verseReference: String
}

struct VerseImageProvider: TimelineProvider {
  func placeholder(in context: Context) -> VerseImageEntry {
    VerseImageEntry(
      date: Date(),
      verseText: defaultVerseImageText,
      verseReference: defaultVerseImageRef
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (VerseImageEntry) -> Void) {
    let pair = loadSharedVerse(
      textKey: "widget_verse_image_text",
      refKey: "widget_verse_image_reference",
      defaultText: defaultVerseImageText,
      defaultRef: defaultVerseImageRef
    )
    completion(VerseImageEntry(date: Date(), verseText: pair.0, verseReference: pair.1))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<VerseImageEntry>) -> Void) {
    getSnapshot(in: context) { entry in
      completion(Timeline(entries: [entry], policy: .atEnd))
    }
  }
}

struct VerseImageView: View {
  var entry: VerseImageEntry
  @Environment(\.widgetFamily) private var family

  var body: some View {
    widgetWithBackground(.verseScenic, largeImage: "widget_verse_image_bg") {
      VStack(spacing: family == .systemLarge ? 10 : 5) {
        Spacer(minLength: 0)
        Text(entry.verseText)
          .font(.system(size: family == .systemLarge ? 16 : 12, weight: .bold, design: .serif))
          .foregroundStyle(oldPaperText)
          .widgetFullColorContent()
          .multilineTextAlignment(.center)
          .lineLimit(family == .systemLarge ? 6 : 4)
          .minimumScaleFactor(0.84)
          .padding(.horizontal, family == .systemLarge ? 12 : 4)
        Text(entry.verseReference)
          .font(.system(size: family == .systemLarge ? 12 : 10, weight: .medium, design: .serif))
          .foregroundStyle(oldPaperSecondary)
          .widgetFullColorContent()
          .multilineTextAlignment(.center)
        WidgetFlourish(color: flourishGold)
          .padding(.bottom, 2)
        Spacer(minLength: 0)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .padding(family == .systemLarge ? 16 : 10)
    }
    .widgetURL(URL(string: "biblebookapp://verse?homeWidget"))
  }
}

struct VerseImageWidget: Widget {
  let kind: String = "VerseImageWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: VerseImageProvider()) { entry in
      VerseImageView(entry: entry)
    }
    .configurationDisplayName("Verse Image")
    .description("A scenic verse image for your home screen.")
  }
}

// MARK: - Widget Bundle

@main
struct BibleHomeWidgetBundle: WidgetBundle {
  var body: some Widget {
    VerseOfTheDayWidget()
    ContinueReadingWidget()
    WeeklyReadingStreakWidget()
    FavoriteVerseWidget()
    HourlyVerseWidget()
    RandomBibleVerseWidget()
    VerseImageWidget()
    BiblePrayerWidget()
    BibleChatWidget()
    if #available(iOS 16.1, *) {
      StreakLiveActivityWidget()
      MemoryVerseLiveActivityWidget()
      ContinueReadingLiveActivityWidget()
    }
  }
}
