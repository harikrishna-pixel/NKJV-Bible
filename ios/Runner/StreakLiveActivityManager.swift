import ActivityKit
import Foundation

/// Starts / updates / ends the streak Live Activity. UI-only; no streak logic.
enum StreakLiveActivityBridge {
  static func handle(call method: String, args: [String: Any]?) -> Any? {
    if #available(iOS 16.1, *) {
      return StreakLiveActivityManager.handle(method: method, args: args)
    }
    if method == "areEnabled" { return false }
    return nil
  }
}

@available(iOS 16.1, *)
private enum StreakLiveActivityManager {
  static func handle(method: String, args: [String: Any]?) -> Any? {
    switch method {
    case "areEnabled":
      return ActivityAuthorizationInfo().areActivitiesEnabled
    case "sync":
      let streak = intValue(args?["streakCount"], fallback: 0)
      let steps = intValue(args?["stepsCompleted"], fallback: 0)
      let total = max(1, intValue(args?["stepsTotal"], fallback: 4))
      let forceStart = boolValue(args?["forceStart"], fallback: false)
      let contentDayKey = args?["contentDayKey"] as? String
      Task {
        await sync(
          streak: streak,
          steps: steps,
          total: total,
          forceStart: forceStart,
          contentDayKey: contentDayKey
        )
      }
      return true
    case "end":
      Task { await endAll() }
      return true
    default:
      return nil
    }
  }

  private static func intValue(_ raw: Any?, fallback: Int) -> Int {
    if let v = raw as? Int { return v }
    if let v = raw as? NSNumber { return v.intValue }
    if let v = raw as? String, let parsed = Int(v) { return parsed }
    return fallback
  }

  private static func boolValue(_ raw: Any?, fallback: Bool) -> Bool {
    if let v = raw as? Bool { return v }
    if let v = raw as? NSNumber { return v.boolValue }
    return fallback
  }

  private static func statusText(streak: Int, steps: Int, total: Int) -> String {
    if steps >= total {
      return "Streak complete today — great job!"
    }
    if steps > 0 {
      return "Keep going — \(steps)/\(total) steps today"
    }
    if streak > 0 {
      return "Complete today's journey to keep your streak"
    }
    return "Start today's journey to begin your streak"
  }

  /// Local yyyy-MM-dd for the snapshot (display-only day key).
  private static func localDayKey(for date: Date = Date()) -> String {
    let formatter = DateFormatter()
    formatter.calendar = Calendar.current
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = .current
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
  }

  /// Next local midnight (+5s) so the activity can be marked stale overnight.
  /// Display-only hint for WidgetKit; does not change streak data.
  private static func nextLocalStaleDate() -> Date {
    let calendar = Calendar.current
    let startOfToday = calendar.startOfDay(for: Date())
    if let next = calendar.date(byAdding: .day, value: 1, to: startOfToday) {
      return next.addingTimeInterval(5)
    }
    return Date().addingTimeInterval(60 * 60 * 24)
  }

  private static func sync(
    streak: Int,
    steps: Int,
    total: Int,
    forceStart: Bool,
    contentDayKey: String?
  ) async {
    guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

    let dayKey = {
      if let contentDayKey, !contentDayKey.isEmpty { return contentDayKey }
      return localDayKey()
    }()

    let state = StreakLiveActivityAttributes.ContentState(
      streakCount: max(0, streak),
      stepsCompleted: min(max(0, steps), total),
      stepsTotal: total,
      statusText: statusText(streak: streak, steps: steps, total: total),
      contentDayKey: dayKey
    )
    let staleDate = nextLocalStaleDate()

    let existing = Activity<StreakLiveActivityAttributes>.activities
    if let activity = existing.first {
      if #available(iOS 16.2, *) {
        await activity.update(
          ActivityContent(state: state, staleDate: staleDate)
        )
      } else {
        await activity.update(using: state)
      }
      return
    }

    // Only start a new activity when there is streak engagement, or forceStart.
    guard forceStart || streak > 0 || steps > 0 else { return }

    let attributes = StreakLiveActivityAttributes(title: "Daily Streak")
    do {
      if #available(iOS 16.2, *) {
        _ = try Activity.request(
          attributes: attributes,
          content: ActivityContent(state: state, staleDate: staleDate),
          pushType: nil
        )
      } else {
        _ = try Activity.request(
          attributes: attributes,
          contentState: state,
          pushType: nil
        )
      }
    } catch {
      // Safe no-op: Live Activity may be disabled or denied by the system.
      NSLog("StreakLiveActivity: request failed: \(error.localizedDescription)")
    }
  }

  private static func endAll() async {
    for activity in Activity<StreakLiveActivityAttributes>.activities {
      await activity.end(using: nil, dismissalPolicy: .immediate)
    }
  }
}
