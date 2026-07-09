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

// MARK: - Container Background (iOS 17+)

/// Wraps widget content with the correct background for the OS: containerBackground on iOS 17+,
/// ZStack fallback on earlier iOS. Adopting containerBackground fixes "Please adopt containerBackground API" and widget not showing on iOS 17+ devices.
struct WidgetContainerBackground<Content: View>: View {
  let background: Color
  @ViewBuilder let content: () -> Content

  var body: some View {
    if #available(iOS 17.0, *) {
      content()
        .containerBackground(for: .widget) {
          background
        }
    } else {
      ZStack {
        background
        content()
      }
    }
  }
}

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
        .foregroundColor(oldPaperText)
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
      .foregroundColor(color)
  }
}

private struct WidgetImageSurface<Content: View>: View {
  let imageName: String
  let fallback: Color
  @ViewBuilder let content: () -> Content

  var body: some View {
    if #available(iOS 17.0, *) {
      content()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
          ZStack {
            Image(imageName)
              .resizable()
              .scaledToFill()
            RadialGradient(
              colors: [Color.clear, Color.black.opacity(0.18)],
              center: .center,
              startRadius: 20,
              endRadius: 180
            )
          }
        }
    } else {
      ZStack {
        fallback
        Image(imageName)
          .resizable()
          .scaledToFill()
        content()
      }
    }
  }
}

private struct OldPaperSurface<Content: View>: View {
  @ViewBuilder let content: () -> Content

  var body: some View {
    WidgetImageSurface(imageName: "widget_parchment_bg", fallback: oldPaperBackground) {
      content()
    }
  }
}

private struct LeatherSurface<Content: View>: View {
  @ViewBuilder let content: () -> Content

  var body: some View {
    if #available(iOS 17.0, *) {
      content()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
          ZStack {
            Image("widget_parchment_bg")
              .resizable()
              .scaledToFill()
            Color(red: 0.28, green: 0.16, blue: 0.10).opacity(0.84)
          }
        }
    } else {
      ZStack {
        leatherBackground
        Image("widget_parchment_bg")
          .resizable()
          .scaledToFill()
          .opacity(0.35)
        Color(red: 0.28, green: 0.16, blue: 0.10).opacity(0.75)
        content()
      }
    }
  }
}

private struct DarkWidgetButton: View {
  let title: String

  var body: some View {
    Text(title)
      .font(.system(size: 11, weight: .semibold, design: .serif))
      .foregroundColor(.white)
      .frame(maxWidth: .infinity)
      .padding(.vertical, 7)
      .background(oldPaperText)
      .clipShape(RoundedRectangle(cornerRadius: 8))
  }
}

private struct StaticWidgetEntry: TimelineEntry {
  let date: Date
}

private struct StaticWidgetProvider: TimelineProvider {
  func placeholder(in context: Context) -> StaticWidgetEntry {
    StaticWidgetEntry(date: Date())
  }

  func getSnapshot(in context: Context, completion: @escaping (StaticWidgetEntry) -> Void) {
    completion(StaticWidgetEntry(date: Date()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<StaticWidgetEntry>) -> Void) {
    completion(Timeline(entries: [StaticWidgetEntry(date: Date())], policy: .never))
  }
}

// Default content when app has not sent data
private let defaultVerseText = "The Lord is my shepherd; I shall not want."
private let defaultVerseRef = "Psalm 23:1"
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

  var body: some View {
    OldPaperSurface {
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
        OldPaperTitleRow(title: "Today's Verse")
        Text(plainVerseTextForWidget(entry.verseText))
          .font(.system(size: 13, weight: .bold, design: .serif))
          .foregroundColor(oldPaperText)
          .multilineTextAlignment(.center)
          .lineLimit(4)
          .minimumScaleFactor(0.82)
          .padding(.horizontal, 2)
        Spacer(minLength: 0)
        Text(entry.verseReference)
          .font(.system(size: 10, weight: .medium, design: .serif))
          .foregroundColor(oldPaperSecondary)
          .multilineTextAlignment(.center)
        WidgetFlourish()
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .padding(10)
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
    // Full-bleed layout for Medium/Large. On iOS 17+ we use containerBackground
    // with the same gradient to ensure edge-to-edge rendering inside widget bounds.
    if family == .systemLarge || family == .systemMedium {
      ZStack {
        LinearGradient(
          colors: [
            Color(red: 0.99, green: 0.86, blue: 0.76),
            Color(red: 0.98, green: 0.92, blue: 0.82)
          ],
          startPoint: .top,
          endPoint: .bottom
        )

        VStack(spacing: 0) {
            HStack {
              Spacer()
              HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                  .font(.caption)
                Text("\(entry.streakDays) days")
                  .font(.caption)
                  .fontWeight(.semibold)
              }
              .foregroundColor(.white)
              .padding(.horizontal, 10)
              .padding(.vertical, 4)
              .background(Color.white.opacity(0.22))
              .clipShape(Capsule())
              Spacer()
            }
            .padding(.top, 8)

            Text(entry.prayerTime)
              .font(.system(size: family == .systemLarge ? 54 : 44, weight: .bold, design: .rounded))
              .foregroundColor(.white)
              .padding(.top, 8)

            Spacer(minLength: 10)

            VStack(spacing: 8) {
              Text(entry.title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(oldPaperText)
                .multilineTextAlignment(.center)

              Text(entry.prayerText)
                .font(.body)
                .foregroundColor(oldPaperText)
                .lineLimit(family == .systemLarge ? 4 : 3)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)

              Text(entry.prayerReference)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(oldPaperSecondary)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(Color(red: 0.99, green: 0.96, blue: 0.90))
            .overlay(
              RoundedRectangle(cornerRadius: 18)
                .stroke(Color(red: 0.88, green: 0.82, blue: 0.73), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .padding(.horizontal, 18)

            Spacer()

            Text("Pray Now")
              .font(.headline)
              .fontWeight(.bold)
              .foregroundColor(.white)
              .frame(maxWidth: .infinity)
              .padding(.vertical, 12)
              .background(Color.orange)
              .clipShape(Capsule())
              .padding(.horizontal, 48)
              .padding(.bottom, 14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .padding(0)
      .widgetURL(URL(string: "biblebookapp://prayer?homeWidget"))
      .modifier(_PrayerWidgetGradientBackground())
    } else {
      OldPaperSurface {
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
            .foregroundColor(oldPaperText)
            .lineLimit(4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(12)
      }
      .widgetURL(URL(string: "biblebookapp://prayer?homeWidget"))
    }
  }
}

/// Applies prayer widget gradient as containerBackground on iOS 17+.
private struct _PrayerWidgetGradientBackground: ViewModifier {
  func body(content: Content) -> some View {
    if #available(iOS 17.0, *) {
      content
        .containerBackground(for: .widget) {
          LinearGradient(
            colors: [
              Color(red: 0.99, green: 0.86, blue: 0.76),
              Color(red: 0.98, green: 0.92, blue: 0.82)
            ],
            startPoint: .top,
            endPoint: .bottom
          )
        }
    } else {
      content
        .background(
          LinearGradient(
            colors: [
              Color(red: 0.99, green: 0.86, blue: 0.76),
              Color(red: 0.98, green: 0.92, blue: 0.82)
            ],
            startPoint: .top,
            endPoint: .bottom
          )
        )
    }
  }
}

private struct _VerseImageBackground: ViewModifier {
  func body(content: Content) -> some View {
    if #available(iOS 17.0, *) {
      content.containerBackground(for: .widget) {
        Image("widget_path_bg")
          .resizable()
          .scaledToFill()
      }
    } else {
      ZStack {
        Image("widget_path_bg")
          .resizable()
          .scaledToFill()
        content
      }
    }
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
    // Remove default widget content padding so the design is full-bleed (iOS 17+).
    .contentMarginsDisabled()
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

  var body: some View {
    OldPaperSurface {
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
          .foregroundColor(oldPaperText)
          .lineLimit(2)
        Text(entry.answer)
          .font(.caption)
          .foregroundColor(oldPaperSecondary)
          .lineLimit(3)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      .padding(12)
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

struct ContinueReadingView: View {
  var body: some View {
    LeatherSurface {
      ZStack {
        RoundedRectangle(cornerRadius: 10)
          .inset(by: 6)
          .stroke(
            leatherText.opacity(0.35),
            style: StrokeStyle(lineWidth: 1, dash: [5, 4])
          )
        VStack(alignment: .leading, spacing: 5) {
          Image(systemName: "bookmark.fill")
            .font(.system(size: 11))
            .foregroundColor(ribbonGold)
            .rotationEffect(.degrees(-12))
          Text("Continue Reading")
            .font(.system(size: 11, weight: .semibold, design: .serif))
            .foregroundColor(leatherText.opacity(0.92))
          Text("Genesis 12")
            .font(.system(size: 19, weight: .bold, design: .serif))
            .foregroundColor(leatherText)
          Text("Verse 8 of 26")
            .font(.system(size: 10, design: .serif))
            .foregroundColor(leatherText.opacity(0.88))
          HStack(spacing: 6) {
            GeometryReader { geo in
              ZStack(alignment: .leading) {
                Capsule().fill(Color.black.opacity(0.28))
                Capsule()
                  .fill(Color.white.opacity(0.92))
                  .frame(width: geo.size.width * 0.32)
              }
            }
            .frame(height: 5)
            Text("32%")
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
    .widgetURL(URL(string: "biblebookapp://verse?homeWidget"))
  }
}

struct ContinueReadingWidget: Widget {
  let kind: String = "ContinueReadingWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: StaticWidgetProvider()) { _ in
      ContinueReadingView()
    }
    .configurationDisplayName("Continue Reading")
    .description("Pick up where you left off in Scripture.")
  }
}

// MARK: - Reading Plan Widget

struct ReadingPlanView: View {
  var body: some View {
    OldPaperSurface {
      VStack(alignment: .leading, spacing: 5) {
        HStack {
          Text("Today's Reading")
            .font(.system(size: 11, weight: .semibold, design: .serif))
            .foregroundColor(oldPaperText)
          Spacer()
          Image(systemName: "calendar")
            .font(.system(size: 11))
            .foregroundColor(oldPaperSecondary)
        }
        planRow("Genesis 1", done: true)
        planRow("Genesis 2", done: false)
        planRow("Psalm 1", done: false)
        Spacer(minLength: 0)
        HStack {
          Text("1 / 3 Completed")
            .font(.system(size: 9, design: .serif))
            .foregroundColor(oldPaperSecondary)
          Spacer()
          Image(systemName: "pencil.and.scribble")
            .font(.system(size: 11))
            .foregroundColor(oldPaperSecondary)
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      .padding(10)
    }
    .widgetURL(URL(string: "biblebookapp://verse?homeWidget"))
  }

  private func planRow(_ title: String, done: Bool) -> some View {
    HStack(spacing: 7) {
      Image(systemName: done ? "checkmark.circle.fill" : "circle")
        .font(.system(size: 12))
        .foregroundColor(done ? oldPaperText : oldPaperSecondary.opacity(0.55))
      Text(title)
        .font(.system(size: 11, design: .serif))
        .foregroundColor(oldPaperText)
        .lineLimit(1)
    }
    .padding(.top, 2)
  }
}

struct ReadingPlanWidget: Widget {
  let kind: String = "ReadingPlanWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: StaticWidgetProvider()) { _ in
      ReadingPlanView()
    }
    .configurationDisplayName("Reading Plan")
    .description("Track today's Bible reading plan.")
  }
}

// MARK: - Weekly Reading Streak Widget

struct WeeklyReadingStreakView: View {
  private let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

  var body: some View {
    OldPaperSurface {
      VStack(alignment: .leading, spacing: 6) {
        HStack(spacing: 4) {
          Image(systemName: "flame.fill")
            .font(.system(size: 11))
            .foregroundColor(.orange)
          Text("Reading Streak")
            .font(.system(size: 11, weight: .semibold, design: .serif))
            .foregroundColor(oldPaperText)
        }
        HStack {
          ForEach(Array(days.enumerated()), id: \.offset) { index, day in
            VStack(spacing: 3) {
              Text(day)
                .font(.system(size: 7, weight: .medium, design: .serif))
                .foregroundColor(oldPaperSecondary)
              Image(systemName: index < 3 ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 10))
                .foregroundColor(index < 3 ? oldPaperText : oldPaperSecondary.opacity(0.45))
            }
            if index < days.count - 1 { Spacer(minLength: 0) }
          }
        }
        Rectangle()
          .fill(oldPaperAccent.opacity(0.25))
          .frame(height: 1)
          .padding(.vertical, 2)
        Text("7 Days")
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
    .widgetURL(URL(string: "biblebookapp://verse?homeWidget"))
  }
}

struct WeeklyReadingStreakWidget: Widget {
  let kind: String = "WeeklyReadingStreakWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: StaticWidgetProvider()) { _ in
      WeeklyReadingStreakView()
    }
    .configurationDisplayName("Weekly Reading Streak")
    .description("See your weekly reading streak.")
  }
}

// MARK: - Favorite Verse Widget

struct FavoriteVerseView: View {
  private let ribbonRed = Color(red: 0.75, green: 0.22, blue: 0.18)

  var body: some View {
    OldPaperSurface {
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
        Text("For God so loved the world, that he gave his only begotten Son, that whoever believes in him should not perish but have eternal life.")
          .font(.system(size: 10.5, design: .serif))
          .foregroundColor(oldPaperText)
          .multilineTextAlignment(.leading)
          .lineLimit(5)
          .minimumScaleFactor(0.84)
        Spacer(minLength: 0)
        Text("John 3:16")
          .font(.system(size: 10, weight: .medium, design: .serif))
          .foregroundColor(oldPaperSecondary)
          .frame(maxWidth: .infinity, alignment: .trailing)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .padding(10)
    }
    .widgetURL(URL(string: "biblebookapp://verse?homeWidget"))
  }
}

struct FavoriteVerseWidget: Widget {
  let kind: String = "FavoriteVerseWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: StaticWidgetProvider()) { _ in
      FavoriteVerseView()
    }
    .configurationDisplayName("Favorite Verse")
    .description("Your saved favorite verse.")
  }
}

// MARK: - Hourly Verse Widget

struct HourlyVerseView: View {
  var body: some View {
    OldPaperSurface {
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
        Text("Commit your work to the Lord, and your plans will be established.")
          .font(.system(size: 12, weight: .bold, design: .serif))
          .foregroundColor(oldPaperText)
          .multilineTextAlignment(.center)
          .lineLimit(4)
          .minimumScaleFactor(0.84)
        Text("Proverbs 16:3")
          .font(.system(size: 10, design: .serif))
          .foregroundColor(oldPaperSecondary)
          .frame(maxWidth: .infinity, alignment: .center)
        Spacer(minLength: 0)
        HStack {
          Text("Next verse in 42 min")
            .font(.system(size: 9, design: .serif))
            .foregroundColor(oldPaperSecondary)
          Spacer()
          Image(systemName: "hourglass")
            .font(.system(size: 10))
            .foregroundColor(oldPaperSecondary)
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .padding(10)
    }
    .widgetURL(URL(string: "biblebookapp://verse?homeWidget"))
  }
}

struct HourlyVerseWidget: Widget {
  let kind: String = "HourlyVerseWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: StaticWidgetProvider()) { _ in
      HourlyVerseView()
    }
    .configurationDisplayName("Hourly Verse")
    .description("A fresh verse every hour.")
  }
}

// MARK: - Random Bible Verse Widget

struct RandomBibleVerseView: View {
  var body: some View {
    OldPaperSurface {
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
        Text("Be still, and know that I am God.")
          .font(.system(size: 13, weight: .bold, design: .serif))
          .foregroundColor(oldPaperText)
          .multilineTextAlignment(.center)
          .lineLimit(3)
        Text("Psalm 46:10")
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
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .padding(10)
    }
    .widgetURL(URL(string: "biblebookapp://verse?homeWidget"))
  }
}

struct RandomBibleVerseWidget: Widget {
  let kind: String = "RandomBibleVerseWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: StaticWidgetProvider()) { _ in
      RandomBibleVerseView()
    }
    .configurationDisplayName("Random Bible Verse")
    .description("Discover a random Scripture verse.")
  }
}

// MARK: - Verse Image Widget

struct VerseImageView: View {
  var body: some View {
    VStack(spacing: 5) {
      Spacer(minLength: 0)
      Text("I can do all things through Christ who strengthens me.")
        .font(.system(size: 12, weight: .bold, design: .serif))
        .foregroundColor(oldPaperText)
        .multilineTextAlignment(.center)
        .lineLimit(4)
        .minimumScaleFactor(0.84)
      Text("Philippians 4:13")
        .font(.system(size: 10, weight: .medium, design: .serif))
        .foregroundColor(oldPaperSecondary)
      WidgetFlourish(color: flourishGold)
        .padding(.bottom, 2)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(10)
    .modifier(_VerseImageBackground())
    .widgetURL(URL(string: "biblebookapp://verse?homeWidget"))
  }
}

struct VerseImageWidget: Widget {
  let kind: String = "VerseImageWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: StaticWidgetProvider()) { _ in
      VerseImageView()
    }
    .configurationDisplayName("Verse Image")
    .description("A scenic verse image for your home screen.")
    .contentMarginsDisabled()
  }
}

// MARK: - Bible Trivia Widget

struct BibleTriviaView: View {
  var body: some View {
    OldPaperSurface {
      VStack(spacing: 7) {
        ZStack {
          Circle()
            .fill(oldPaperText)
            .frame(width: 30, height: 30)
          Text("?")
            .font(.system(size: 17, weight: .bold, design: .serif))
            .foregroundColor(oldPaperBackground)
        }
        OldPaperTitleRow(title: "Question of the Day")
        Text("Who built the ark?")
          .font(.system(size: 14, weight: .bold, design: .serif))
          .foregroundColor(oldPaperText)
          .multilineTextAlignment(.center)
          .lineLimit(2)
        Spacer(minLength: 0)
        DarkWidgetButton(title: "Tap to Answer")
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .padding(10)
    }
    .widgetURL(URL(string: "biblebookapp://chat?homeWidget"))
  }
}

struct BibleTriviaWidget: Widget {
  let kind: String = "BibleTriviaWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: StaticWidgetProvider()) { _ in
      BibleTriviaView()
    }
    .configurationDisplayName("Bible Trivia")
    .description("Answer a daily Bible question.")
  }
}

// MARK: - Prayer Reminder Widget

struct PrayerReminderView: View {
  var body: some View {
    OldPaperSurface {
      HStack(spacing: 10) {
        Image("widget_prayer_hands")
          .resizable()
          .scaledToFit()
          .frame(width: 52, height: 52)
        VStack(alignment: .leading, spacing: 5) {
          HStack(spacing: 4) {
            Text("Prayer Reminder")
              .font(.system(size: 11, weight: .semibold, design: .serif))
              .foregroundColor(oldPaperText)
            Image(systemName: "bell.fill")
              .font(.system(size: 9))
              .foregroundColor(oldPaperSecondary)
          }
          Text("Take one minute to talk to God.")
            .font(.system(size: 10, design: .serif))
            .foregroundColor(oldPaperSecondary)
            .lineLimit(2)
          DarkWidgetButton(title: "Let's Pray")
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
      .padding(10)
    }
    .widgetURL(URL(string: "biblebookapp://prayer?homeWidget"))
  }
}

struct PrayerReminderWidget: Widget {
  let kind: String = "PrayerReminderWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: StaticWidgetProvider()) { _ in
      PrayerReminderView()
    }
    .configurationDisplayName("Prayer Reminder")
    .description("A gentle reminder to pray.")
  }
}

// MARK: - Widget Bundle

@main
struct BibleHomeWidgetBundle: WidgetBundle {
  var body: some Widget {
    VerseOfTheDayWidget()
    ContinueReadingWidget()
    ReadingPlanWidget()
    WeeklyReadingStreakWidget()
    FavoriteVerseWidget()
    HourlyVerseWidget()
    RandomBibleVerseWidget()
    VerseImageWidget()
    BibleTriviaWidget()
    PrayerReminderWidget()
    BiblePrayerWidget()
    BibleChatWidget()
  }
}
