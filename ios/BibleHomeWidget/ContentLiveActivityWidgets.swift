import ActivityKit
import SwiftUI
import WidgetKit

private let kMemoryVerseLiveActivityURL = URL(string: "biblebookapp://verse?homeWidget")
private let kContinueReadingLiveActivityURL = URL(string: "biblebookapp://verse?homeWidget")

private let paper = Color(red: 0.95, green: 0.92, blue: 0.84)
private let ink = Color(red: 0.29, green: 0.22, blue: 0.18)
private let accent = Color(red: 0.55, green: 0.42, blue: 0.33)

/// Lock Screen + Dynamic Island UI for Today's Memory Verse Live Activity.
@available(iOS 16.1, *)
struct MemoryVerseLiveActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: MemoryVerseLiveActivityAttributes.self) { context in
      MemoryVerseLockScreenView(context: context)
        .widgetURL(kMemoryVerseLiveActivityURL)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Label {
            Text("Memory")
              .font(.headline)
          } icon: {
            Image(systemName: "text.book.closed")
          }
          .foregroundColor(accent)
          .widgetURL(kMemoryVerseLiveActivityURL)
        }
        DynamicIslandExpandedRegion(.trailing) {
          Text("\(context.state.reviewedCount)/\(context.state.reviewTotal)")
            .font(.headline)
            .monospacedDigit()
            .widgetURL(kMemoryVerseLiveActivityURL)
        }
        DynamicIslandExpandedRegion(.bottom) {
          VStack(alignment: .leading, spacing: 2) {
            Text(context.state.reference)
              .font(.subheadline.weight(.semibold))
            Text(context.state.statusText)
              .font(.caption)
              .foregroundColor(.secondary)
          }
          .widgetURL(kMemoryVerseLiveActivityURL)
        }
      } compactLeading: {
        Image(systemName: "text.book.closed")
          .foregroundColor(accent)
          .widgetURL(kMemoryVerseLiveActivityURL)
      } compactTrailing: {
        Text("\(context.state.reviewedCount)/\(context.state.reviewTotal)")
          .font(.caption2.weight(.bold))
          .monospacedDigit()
          .widgetURL(kMemoryVerseLiveActivityURL)
      } minimal: {
        Image(systemName: "text.book.closed")
          .foregroundColor(accent)
          .widgetURL(kMemoryVerseLiveActivityURL)
      }
    }
  }
}

@available(iOS 16.1, *)
private struct MemoryVerseLockScreenView: View {
  let context: ActivityViewContext<MemoryVerseLiveActivityAttributes>

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: "text.book.closed")
        .font(.title2)
        .foregroundColor(accent)

      VStack(alignment: .leading, spacing: 4) {
        Text(context.attributes.title)
          .font(.caption.weight(.semibold))
          .foregroundColor(accent)
        Text(context.state.reference)
          .font(.headline)
          .foregroundColor(ink)
          .lineLimit(1)
        if !context.state.verseSnippet.isEmpty {
          Text(context.state.verseSnippet)
            .font(.caption)
            .foregroundColor(ink.opacity(0.75))
            .lineLimit(2)
        }
        Text(context.state.statusText)
          .font(.caption2)
          .foregroundColor(ink.opacity(0.7))
      }

      Spacer(minLength: 8)

      VStack(spacing: 2) {
        Text("\(context.state.reviewedCount)/\(context.state.reviewTotal)")
          .font(.title3.weight(.bold))
          .monospacedDigit()
          .foregroundColor(ink)
        Text("reviews")
          .font(.caption2)
          .foregroundColor(accent)
      }
    }
    .padding(16)
    .activityBackgroundTint(paper)
    .activitySystemActionForegroundColor(ink)
  }
}

/// Lock Screen + Dynamic Island UI for Continue Reading Live Activity.
@available(iOS 16.1, *)
struct ContinueReadingLiveActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: ContinueReadingLiveActivityAttributes.self) { context in
      ContinueReadingLockScreenView(context: context)
        .widgetURL(kContinueReadingLiveActivityURL)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Label {
            Text("Reading")
              .font(.headline)
          } icon: {
            Image(systemName: "book.fill")
          }
          .foregroundColor(accent)
          .widgetURL(kContinueReadingLiveActivityURL)
        }
        DynamicIslandExpandedRegion(.trailing) {
          Image(systemName: "bookmark.fill")
            .foregroundColor(.orange)
            .widgetURL(kContinueReadingLiveActivityURL)
        }
        DynamicIslandExpandedRegion(.bottom) {
          VStack(alignment: .leading, spacing: 2) {
            Text(context.state.bookChapter)
              .font(.subheadline.weight(.semibold))
            Text(context.state.detailLine)
              .font(.caption)
              .foregroundColor(.secondary)
              .lineLimit(1)
            Text(context.state.footerText)
              .font(.caption2)
              .foregroundColor(.secondary)
              .lineLimit(1)
          }
          .widgetURL(kContinueReadingLiveActivityURL)
        }
      } compactLeading: {
        Image(systemName: "book.fill")
          .foregroundColor(accent)
          .widgetURL(kContinueReadingLiveActivityURL)
      } compactTrailing: {
        Image(systemName: "bookmark.fill")
          .foregroundColor(.orange)
          .widgetURL(kContinueReadingLiveActivityURL)
      } minimal: {
        Image(systemName: "book.fill")
          .foregroundColor(accent)
          .widgetURL(kContinueReadingLiveActivityURL)
      }
    }
  }
}

@available(iOS 16.1, *)
private struct ContinueReadingLockScreenView: View {
  let context: ActivityViewContext<ContinueReadingLiveActivityAttributes>

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: "book.fill")
        .font(.title2)
        .foregroundColor(accent)

      VStack(alignment: .leading, spacing: 4) {
        Text(context.attributes.title)
          .font(.caption.weight(.semibold))
          .foregroundColor(accent)
        Text(context.state.bookChapter)
          .font(.headline)
          .foregroundColor(ink)
          .lineLimit(1)
        if !context.state.detailLine.isEmpty {
          Text(context.state.detailLine)
            .font(.caption)
            .foregroundColor(ink.opacity(0.75))
            .lineLimit(1)
        }
        if !context.state.footerText.isEmpty {
          Text(context.state.footerText)
            .font(.caption2)
            .foregroundColor(ink.opacity(0.7))
            .lineLimit(1)
        }
      }

      Spacer(minLength: 8)

      Image(systemName: "bookmark.fill")
        .font(.title3)
        .foregroundColor(.orange)
    }
    .padding(16)
    .activityBackgroundTint(paper)
    .activitySystemActionForegroundColor(ink)
  }
}
