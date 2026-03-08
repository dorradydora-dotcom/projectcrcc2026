-keepattributes InnerClasses
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class androidx.work.** { *; }
-dontwarn androidx.work.**
-keep class com.google.firebase.messaging.** { *; }
-dontwarn com.google.firebase.messaging.**
-keep class io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingPlugin { *; }
-keep class com.google.firebase.** { *; }
-keep class androidx.work.impl.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes EnclosingMethod

# Agora SDK
-keep class io.agora.** { *; }
-keep class io.agora.rtc2.** { *; }
-keep class io.agora.rtc.** { *; }
-dontwarn io.agora.**

# Flutter CallKit
-keep class com.hiennv.flutter_callkit_incoming.** { *; }
-dontwarn com.hiennv.flutter_callkit_incoming.**

# General
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-keep class * implements java.io.Serializable { *; }

-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task