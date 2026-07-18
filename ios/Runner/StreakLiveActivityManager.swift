import ActivityKit
import Foundation

/// Starts / updates / ends Daily Streak Live Activity. Safe no-ops on unsupported iOS.
enum StreakLiveActivityManager {
  static func startOrUpdate(streakDays: Int, stepsCompleted: Int) {
    guard #available(iOS 16.2, *) else { return }
    guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

    let steps = max(0, min(stepsCompleted, 4))
    let days = max(0, streakDays)
    let title = days > 0 ? "Day \(days) Streak" : "Daily Streak"
    let status = statusText(for: steps)
    let state = StreakLiveActivityAttributes.ContentState(
      streakDays: days,
      stepsCompleted: steps,
      statusText: status
    )

    Task {
      // Update existing activities first
      for activity in Activity<StreakLiveActivityAttributes>.activities {
        await activity.update(
          ActivityContent(state: state, staleDate: nil)
        )
      }

      if Activity<StreakLiveActivityAttributes>.activities.isEmpty {
        let attributes = StreakLiveActivityAttributes(title: title)
        do {
          _ = try Activity.request(
            attributes: attributes,
            content: ActivityContent(state: state, staleDate: nil),
            pushType: nil
          )
        } catch {
          NSLog("StreakLiveActivity: request failed: \(error.localizedDescription)")
        }
      }
    }
  }

  static func end() {
    guard #available(iOS 16.2, *) else { return }

    Task {
      for activity in Activity<StreakLiveActivityAttributes>.activities {
        let finalState = StreakLiveActivityAttributes.ContentState(
          streakDays: activity.content.state.streakDays,
          stepsCompleted: 4,
          statusText: "Streak complete!"
        )
        await activity.end(
          ActivityContent(state: finalState, staleDate: nil),
          dismissalPolicy: .immediate
        )
      }
    }
  }

  @available(iOS 16.2, *)
  private static func statusText(for steps: Int) -> String {
    switch steps {
    case 0:
      return "Start your daily journey"
    case 1:
      return "Connection done · Keep going"
    case 2:
      return "Verse read · Keep going"
    case 3:
      return "Devotional done · One more step"
    default:
      return "Streak complete!"
    }
  }
}
