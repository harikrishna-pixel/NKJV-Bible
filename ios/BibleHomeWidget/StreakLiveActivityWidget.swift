import ActivityKit
import SwiftUI
import WidgetKit

/// Deep link when user taps the streak Live Activity (matches Flutter home widget routing).
private let kStreakLiveActivityURL = URL(string: "biblebookapp://streak?homeWidget")

/// Display-only: local yyyy-MM-dd for Live Activity day checks (no streak logic).
@available(iOS 16.1, *)
private enum StreakLiveActivityDay {
  static func key(for date: Date = Date()) -> String {
    let formatter = DateFormatter()
    formatter.calendar = Calendar.current
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = .current
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
  }

  /// `context.isStale` is iOS 16.2+; treat as not stale on 16.1.
  static func isStale(
    _ context: ActivityViewContext<StreakLiveActivityAttributes>
  ) -> Bool {
    if #available(iOS 16.2, *) {
      return context.isStale
    }
    return false
  }

  /// Effective steps for UI: if snapshot is from a prior local day, show 0.
  static func displaySteps(
    state: StreakLiveActivityAttributes.ContentState,
    isStale: Bool,
    now: Date
  ) -> Int {
    let total = max(1, state.stepsTotal)
    if let day = state.contentDayKey, !day.isEmpty, day != key(for: now) {
      return 0
    }
    // Legacy activities (no day key): after staleDate, treat as new day.
    if (state.contentDayKey == nil || state.contentDayKey?.isEmpty == true), isStale {
      return 0
    }
    return min(max(0, state.stepsCompleted), total)
  }

  static func displayStatus(
    state: StreakLiveActivityAttributes.ContentState,
    steps: Int,
    now: Date
  ) -> String {
    let total = max(1, state.stepsTotal)
    let dayMismatch = {
      guard let day = state.contentDayKey, !day.isEmpty else { return false }
      return day != key(for: now)
    }()
    if dayMismatch || (steps == 0 && state.stepsCompleted > 0) {
      if state.streakCount > 0 {
        return "Complete today's journey to keep your streak"
      }
      return "Start today's journey to begin your streak"
    }
    if steps >= total {
      return "Streak complete today — great job!"
    }
    if steps > 0 {
      return "Keep going — \(steps)/\(total) steps today"
    }
    if !state.statusText.isEmpty { return state.statusText }
    if state.streakCount > 0 {
      return "Complete today's journey to keep your streak"
    }
    return "Start today's journey to begin your streak"
  }
}

/// Lock Screen + Dynamic Island UI for the Daily Streak Live Activity.
@available(iOS 16.1, *)
struct StreakLiveActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: StreakLiveActivityAttributes.self) { context in
      // Periodic refresh so calendar day rollover can update display without app open.
      TimelineView(.periodic(from: .now, by: 60)) { timeline in
        StreakLiveActivityLockScreenView(
          context: context,
          now: timeline.date
        )
      }
      .widgetURL(kStreakLiveActivityURL)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          TimelineView(.periodic(from: .now, by: 60)) { timeline in
            let steps = StreakLiveActivityDay.displaySteps(
              state: context.state,
              isStale: StreakLiveActivityDay.isStale(context),
              now: timeline.date
            )
            Label {
              Text("Day \(context.state.streakCount)")
                .font(.headline)
            } icon: {
              Image(systemName: "flame.fill")
            }
            .foregroundColor(.orange)
            .opacity(steps == 0 && context.state.stepsCompleted > 0 ? 0.95 : 1)
          }
          .widgetURL(kStreakLiveActivityURL)
        }
        DynamicIslandExpandedRegion(.trailing) {
          TimelineView(.periodic(from: .now, by: 60)) { timeline in
            let steps = StreakLiveActivityDay.displaySteps(
              state: context.state,
              isStale: StreakLiveActivityDay.isStale(context),
              now: timeline.date
            )
            Text("\(steps)/\(max(1, context.state.stepsTotal))")
              .font(.headline)
              .monospacedDigit()
          }
          .widgetURL(kStreakLiveActivityURL)
        }
        DynamicIslandExpandedRegion(.bottom) {
          TimelineView(.periodic(from: .now, by: 60)) { timeline in
            let steps = StreakLiveActivityDay.displaySteps(
              state: context.state,
              isStale: StreakLiveActivityDay.isStale(context),
              now: timeline.date
            )
            Text(
              StreakLiveActivityDay.displayStatus(
                state: context.state,
                steps: steps,
                now: timeline.date
              )
            )
            .font(.caption)
            .foregroundColor(.secondary)
            .lineLimit(2)
          }
          .widgetURL(kStreakLiveActivityURL)
        }
      } compactLeading: {
        Image(systemName: "flame.fill")
          .foregroundColor(.orange)
          .widgetURL(kStreakLiveActivityURL)
      } compactTrailing: {
        TimelineView(.periodic(from: .now, by: 60)) { timeline in
          let steps = StreakLiveActivityDay.displaySteps(
            state: context.state,
            isStale: StreakLiveActivityDay.isStale(context),
            now: timeline.date
          )
          // Compact trailing: show streak day count still; steps reset is on expanded/lock.
          Text("\(context.state.streakCount)")
            .font(.caption2.weight(.bold))
            .monospacedDigit()
            .opacity(steps == 0 && context.state.stepsCompleted > 0 ? 0.9 : 1)
        }
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
  let now: Date

  private let paper = Color(red: 0.95, green: 0.92, blue: 0.84)
  private let ink = Color(red: 0.29, green: 0.22, blue: 0.18)
  private let accent = Color(red: 0.55, green: 0.42, blue: 0.33)

  var body: some View {
    let total = max(1, context.state.stepsTotal)
    let steps = StreakLiveActivityDay.displaySteps(
      state: context.state,
      isStale: StreakLiveActivityDay.isStale(context),
      now: now
    )
    let status = StreakLiveActivityDay.displayStatus(
      state: context.state,
      steps: steps,
      now: now
    )

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
        Text(status)
          .font(.caption)
          .foregroundColor(ink.opacity(0.75))
          .lineLimit(2)
      }

      Spacer(minLength: 8)

      VStack(spacing: 2) {
        Text("\(steps)/\(total)")
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
