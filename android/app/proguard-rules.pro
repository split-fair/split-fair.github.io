# Flutter default ProGuard rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# In-app purchase
-keep class com.android.vending.billing.** { *; }

# Keep Google Play billing classes
-keep class com.google.android.gms.** { *; }

# Keep Google Play Core / deferred components (R8 missing class fix)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
