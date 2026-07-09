#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The "widget_leather_bg" asset catalog image resource.
static NSString * const ACImageNameWidgetLeatherBg AC_SWIFT_PRIVATE = @"widget_leather_bg";

/// The "widget_parchment_bg" asset catalog image resource.
static NSString * const ACImageNameWidgetParchmentBg AC_SWIFT_PRIVATE = @"widget_parchment_bg";

/// The "widget_path_bg" asset catalog image resource.
static NSString * const ACImageNameWidgetPathBg AC_SWIFT_PRIVATE = @"widget_path_bg";

/// The "widget_prayer_hands" asset catalog image resource.
static NSString * const ACImageNameWidgetPrayerHands AC_SWIFT_PRIVATE = @"widget_prayer_hands";

/// The "widget_verse_image_bg" asset catalog image resource.
static NSString * const ACImageNameWidgetVerseImageBg AC_SWIFT_PRIVATE = @"widget_verse_image_bg";

#undef AC_SWIFT_PRIVATE
