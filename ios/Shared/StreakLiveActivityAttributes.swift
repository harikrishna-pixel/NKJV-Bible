import ActivityKit
import Foundation

/// Shared ActivityKit attributes for the Daily Streak Live Activity.
/// Compiled into both Runner (start/update/end) and BibleHomeWidget (UI).
@available(iOS 16.1, *)
struct StreakLiveActivityAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    var streakCount: Int
    var stepsCompleted: Int
    var stepsTotal: Int
    var statusText: String
    /// Local calendar day (yyyy-MM-dd) this snapshot was written for.
    /// Optional for backward compatibility with older activities.
    var contentDayKey: String?
  }

  /// Static title shown with the activity.
  var title: String
}
