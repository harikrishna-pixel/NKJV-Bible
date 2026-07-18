import ActivityKit
import Foundation

/// Shared attributes for Daily Streak Live Activity (app + widget extension).
@available(iOS 16.2, *)
struct StreakLiveActivityAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    var streakDays: Int
    var stepsCompleted: Int
    var statusText: String
  }

  var title: String
}
