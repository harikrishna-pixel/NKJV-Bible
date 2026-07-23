import ActivityKit
import SwiftUI
import WidgetKit

/// Deep link when user taps the streak Live Activity (matches Flutter home widget routing).
private let kStreakLiveActivityURL = URL(string: "biblebookapp://streak?homeWidget")

/// Lock Screen + Dynamic Island UI for the Daily Streak Live Activity.
@available(iOS 16.1, *)
struct StreakLiveActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: StreakLiveActivityAttributes.self) { context in
      StreakLiveActivityLockScreenView(context: context)
        .widgetURL(kStreakLiveActivityURL)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Label {
            Text("Day \(context.state.streakCount)")
              .font(.headline)
          } icon: {
            Image(systemName: "flame.fill")
          }
          .foregroundColor(.orange)
          .widgetURL(kStreakLiveActivityURL)
        }
        DynamicIslandExpandedRegion(.trailing) {
          Text("\(context.state.stepsCompleted)/\(context.state.stepsTotal)")
            .font(.headline)
            .monospacedDigit()
            .widgetURL(kStreakLiveActivityURL)
        }
        DynamicIslandExpandedRegion(.bottom) {
          Text(context.state.statusText)
            .font(.caption)
            .foregroundColor(.secondary)
            .lineLimit(2)
            .widgetURL(kStreakLiveActivityURL)
        }
      } compactLeading: {
        Image(systemName: "flame.fill")
          .foregroundColor(.orange)
          .widgetURL(kStreakLiveActivityURL)
      } compactTrailing: {
        Text("\(context.state.streakCount)")
          .font(.caption2.weight(.bold))
          .monospacedDigit()
          .widgetURL(kStreakLiveActivityURL)
      } minimal: {
        Image(systemName: "flame.fill")
          .foregroundColor(.orange)
          .widgetURL(kStreakLiveActivityURL)
      }
    }
  }
}

@available(iOS 16.1, *)
private struct StreakLiveActivityLockScreenView: View {
  let context: ActivityViewContext<StreakLiveActivityAttributes>

  private let paper = Color(red: 0.95, green: 0.92, blue: 0.84)
  private let ink = Color(red: 0.29, green: 0.22, blue: 0.18)
  private let accent = Color(red: 0.55, green: 0.42, blue: 0.33)

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: "flame.fill")
        .font(.title2)
        .foregroundColor(.orange)

      VStack(alignment: .leading, spacing: 4) {
        Text(context.attributes.title)
          .font(.caption.weight(.semibold))
          .foregroundColor(accent)
        Text("Day \(context.state.streakCount) streak")
          .font(.headline)
          .foregroundColor(ink)
        Text(context.state.statusText)
          .font(.caption)
          .foregroundColor(ink.opacity(0.75))
          .lineLimit(2)
      }

      Spacer(minLength: 8)

      VStack(spacing: 2) {
        Text("\(context.state.stepsCompleted)/\(context.state.stepsTotal)")
          .font(.title3.weight(.bold))
          .monospacedDigit()
          .foregroundColor(ink)
        Text("today")
          .font(.caption2)
          .foregroundColor(accent)
      }
    }
    .padding(16)
    .activityBackgroundTint(paper)
    .activitySystemActionForegroundColor(ink)
  }
}
