# Add project specific ProGuard rules here.

# Keep Digio SDK classes
-keep class com.digio.** { *; }
-dontwarn com.digio.**

# Keep XmlPullParser related classes
-keep class org.xmlpull.** { *; }
-dontwarn org.xmlpull.**

# Keep Android resource parser
-keep class android.content.res.XmlResourceParser { *; }

# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Parcelables
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Suppress warnings for common libraries that might not be present
-dontwarn com.google.gson.**
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn retrofit2.**
-dontwarn sun.misc.**

# Keep attributes
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes Exceptions