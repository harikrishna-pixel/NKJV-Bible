#Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep flutter_local_notifications classes
-keep class com.dexterous.** { *; }
-keep class android.graphics.drawable.Icon { *; }

# Keep flutter_local_notifications receiver
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Keep WorkManager classes (if using background services)
-keep class androidx.work.** { *; }

# Keep reflection-based classes
-keepattributes *Annotation*
-keep class * extends android.app.Service { *; }

# Keep all BroadcastReceiver classes
-keep class * extends android.content.BroadcastReceiver { *; }

-keepattributes Signature
-keep class com.google.gson.reflect.TypeToken { *; }

# Add project specific ProGuard rules here.
# By default, the flags in this file are appended to flags specified
# in /usr/local/google/home/samstern/android-sdk-linux/tools/proguard/proguard-android.txt
# You can edit the include path and order by changing the proguardFiles
# directive in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# Add any project specific keep options here:

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# Keep custom model classes
-keep class com.google.firebase.** { *; }


# To ignore minifyEnabled: true error
# https://github.com/flutter/flutter/issues/19250
#https://github.com/flutter/flutter/issues/37441
-ignorewarnings
-keep class * {
    public private *;
}