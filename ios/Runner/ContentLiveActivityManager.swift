import ActivityKit
import Foundation

/// Starts / updates / ends Memory Verse + Continue Reading Live Activities.
/// UI mirror only — does not change reading or streak logic.
enum ContentLiveActivityBridge {
  static func handle(call method: String, args: [String: Any]?) -> Any? {
    if #available(iOS 16.1, *) {
      return ContentLiveActivityManager.handle(method: method, args: args)
    }
    if method == "areEnabled" { return false }
    return nil
  }
}

@available(iOS 16.1, *)
private enum ContentLiveActivityManager {
  static func handle(method: String, args: [String: Any]?) -> Any? {
    switch method {
    case "areEnabled":
      return ActivityAuthorizationInfo().areActivitiesEnabled
    case "syncMemoryVerse":
      let reference = stringValue(args?["reference"], fallback: "Daily Verse")
      let snippet = stringValue(args?["verseSnippet"], fallback: "")
      let reviewed = intValue(args?["reviewedCount"], fallback: 0)
      let total = max(1, intValue(args?["reviewTotal"], fallback: 5))
      let forceStart = boolValue(args?["forceStart"], fallback: false)
      Task {
        await syncMemoryVerse(
          reference: reference,
          snippet: snippet,
          reviewed: reviewed,
          total: total,
          forceStart: forceStart
        )
      }
      return true
    case "syncContinueReading":
      let bookChapter = stringValue(args?["bookChapter"], fallback: "Scripture")
      let detail = stringValue(args?["detailLine"], fallback: "")
      let footer = stringValue(args?["footerText"], fallback: "")
      let forceStart = boolValue(args?["forceStart"], fallback: false)
      Task {
        await syncContinueReading(
          bookChapter: bookChapter,
          detail: detail,
          footer: footer,
          forceStart: forceStart
        )
      }
      return true
    case "endMemoryVerse":
      Task { await endAll(MemoryVerseLiveActivityAttributes.self) }
      return true
    case "endContinueReading":
      Task { await endAll(ContinueReadingLiveActivityAttributes.self) }
      return true
    case "endAll":
      Task {
        await endAll(MemoryVerseLiveActivityAttributes.self)
        await endAll(ContinueReadingLiveActivityAttributes.self)
      }
      return true
    default:
      return nil
    }
  }

  private static func stringValue(_ raw: Any?, fallback: String) -> String {
    if let v = raw as? String, !v.isEmpty { return v }
    return fallback
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

  private static func nextLocalStaleDate() -> Date {
    let calendar = Calendar.current
    let startOfToday = calendar.startOfDay(for: Date())
    if let next = calendar.date(byAdding: .day, value: 1, to: startOfToday) {
      return next.addingTimeInterval(5)
    }
    return Date().addingTimeInterval(60 * 60 * 24)
  }

  private static func syncMemoryVerse(
    reference: String,
    snippet: String,
    reviewed: Int,
    total: Int,
    forceStart: Bool
  ) async {
    guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
    let safeReviewed = min(max(0, reviewed), total)
    let status = "Reviewed \(safeReviewed)/\(total) times"
    let state = MemoryVerseLiveActivityAttributes.ContentState(
      reference: reference,
      verseSnippet: snippet,
      reviewedCount: safeReviewed,
      reviewTotal: total,
      statusText: status
    )
    let staleDate = nextLocalStaleDate()

    if let activity = Activity<MemoryVerseLiveActivityAttributes>.activities.first {
      if #available(iOS 16.2, *) {
        await activity.update(ActivityContent(state: state, staleDate: staleDate))
      } else {
        await activity.update(using: state)
      }
      return
    }

    guard forceStart || !reference.isEmpty else { return }
    let attributes = MemoryVerseLiveActivityAttributes(title: "Today's Memory Verse")
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
      NSLog("MemoryVerseLiveActivity: request failed: \(error.localizedDescription)")
    }
  }

  private static func syncContinueReading(
    bookChapter: String,
    detail: String,
    footer: String,
    forceStart: Bool
  ) async {
    guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
    let state = ContinueReadingLiveActivityAttributes.ContentState(
      bookChapter: bookChapter,
      detailLine: detail,
      footerText: footer
    )
    let staleDate = nextLocalStaleDate()

    if let activity = Activity<ContinueReadingLiveActivityAttributes>.activities.first {
      if #available(iOS 16.2, *) {
        await activity.update(ActivityContent(state: state, staleDate: staleDate))
      } else {
        await activity.update(using: state)
      }
      return
    }

    guard forceStart || !bookChapter.isEmpty else { return }
    let attributes = ContinueReadingLiveActivityAttributes(title: "Continue Reading")
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
      NSLog("ContinueReadingLiveActivity: request failed: \(error.localizedDescription)")
    }
  }

  private static func endAll<T: ActivityAttributes>(_ type: T.Type) async {
    for activity in Activity<T>.activities {
      await activity.end(using: nil, dismissalPolicy: .immediate)
    }
  }
}
