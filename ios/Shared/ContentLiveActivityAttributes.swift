import ActivityKit
import Foundation

/// Shared ActivityKit attributes for Memory Verse + Continue Reading Live Activities.
/// Display-only mirrors — no reading / streak business logic.
@available(iOS 16.1, *)
struct MemoryVerseLiveActivityAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    var reference: String
    var verseSnippet: String
    var reviewedCount: Int
    var reviewTotal: Int
    var statusText: String
  }

  var title: String
}

@available(iOS 16.1, *)
struct ContinueReadingLiveActivityAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    var bookChapter: String
    var detailLine: String
    var footerText: String
  }

  var title: String
}
