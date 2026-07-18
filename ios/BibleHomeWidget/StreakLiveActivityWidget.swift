import ActivityKit
import SwiftUI
import WidgetKit

@available(iOSApplicationExtension 16.2, *)
struct StreakLiveActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: StreakLiveActivityAttributes.self) { context in
      // Lock Screen / Banner
      HStack(spacing: 12) {
        ZStack {
          Circle()
            .fill(Color(red: 0.79, green: 0.64, blue: 0.15).opacity(0.25))
            .frame(width: 40, height: 40)
          Image(systemName: "flame.fill")
            .foregroundColor(Color(red: 0.79, green: 0.64, blue: 0.15))
            .font(.system(size: 18, weight: .semibold))
        }

        VStack(alignment: .leading, spacing: 2) {
          Text(context.attributes.title)
            .font(.system(size: 13, weight: .semibold, design: .serif))
            .foregroundColor(.white)
          Text(context.state.statusText)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.white.opacity(0.85))
            .lineLimit(1)
        }

        Spacer(minLength: 0)

        Text("\(min(context.state.stepsCompleted, 4))/4")
          .font(.system(size: 14, weight: .bold, design: .rounded))
          .foregroundColor(Color(red: 0.79, green: 0.64, blue: 0.15))
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .activityBackgroundTint(Color(red: 0.29, green: 0.22, blue: 0.18).opacity(0.92))
      .activitySystemActionForegroundColor(.white)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          HStack(spacing: 6) {
            Image(systemName: "flame.fill")
              .foregroundColor(Color(red: 0.79, green: 0.64, blue: 0.15))
            Text(context.attributes.title)
              .font(.system(size: 14, weight: .semibold, design: .serif))
              .lineLimit(1)
          }
        }
        DynamicIslandExpandedRegion(.trailing) {
          Text("\(min(context.state.stepsCompleted, 4))/4")
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundColor(Color(red: 0.79, green: 0.64, blue: 0.15))
        }
        DynamicIslandExpandedRegion(.bottom) {
          Text(context.state.statusText)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.white.opacity(0.9))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
      } compactLeading: {
        Image(systemName: "flame.fill")
          .foregroundColor(Color(red: 0.79, green: 0.64, blue: 0.15))
      } compactTrailing: {
        Text("\(min(context.state.stepsCompleted, 4))/4")
          .font(.system(size: 12, weight: .bold, design: .rounded))
          .foregroundColor(Color(red: 0.79, green: 0.64, blue: 0.15))
      } minimal: {
        Image(systemName: "flame.fill")
          .foregroundColor(Color(red: 0.79, green: 0.64, blue: 0.15))
      }
    }
  }
}
