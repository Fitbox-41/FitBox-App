# R8 / ProGuard rules for the release build.
#
# Flutter, Firebase and Google Play Services ship their own consumer rules, so
# this file only covers what shrinking would otherwise strip incorrectly.

# Flutter engine entry points.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# flutter_local_notifications keeps notification details across a reboot by
# deserialising them with Gson; the model fields must survive obfuscation or
# scheduled/ongoing notifications break.
-keep class com.dexterous.** { *; }
-keepattributes *Annotation*
-keepattributes Signature
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Play Core is referenced by Flutter's deferred-components support, which this
# app doesn't use — don't fail the build over the missing classes.
-dontwarn com.google.android.play.core.**

# Keep line numbers so a crash report still points at a real line.
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
