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

private let appGroupId = "group.com.balaklrapps.nivbible"

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

// Default content when app has not sent data
private let defaultVerseText = "For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life."
private let defaultVerseRef = "John 3:16"
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
    WidgetContainerBackground(background: oldPaperBackground) {
      VStack(alignment: .leading, spacing: 6) {
        Text("Verse of the Day")
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundColor(oldPaperAccent)
        Text(plainVerseTextForWidget(entry.verseText))
          .font(.subheadline)
          .foregroundColor(oldPaperText)
          .lineLimit(4)
        Text(entry.verseReference)
          .font(.caption)
          .fontWeight(.medium)
          .foregroundColor(oldPaperSecondary)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      .padding(12)
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
    .configurationDisplayName("Verse of the Day")
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
      .modifier(_WidgetGradientBackground())
    } else {
      WidgetContainerBackground(background: oldPaperBackground) {
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

/// Applies a containerBackground gradient on iOS 17+ so widgets render full-bleed.
private struct _WidgetGradientBackground: ViewModifier {
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
    WidgetContainerBackground(background: oldPaperBackground) {
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

// MARK: - Widget Bundle

@main
struct BibleHomeWidgetBundle: WidgetBundle {
  var body: some Widget {
    VerseOfTheDayWidget()
    BiblePrayerWidget()
    BibleChatWidget()
  }
}
