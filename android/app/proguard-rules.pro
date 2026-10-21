# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# GetX
-keep class com.example.** { *; }
-keepclassmembers class * extends io.flutter.embedding.engine.plugins.FlutterPlugin {
    public *;
}

# Dio HTTP client
-keep class com.example.dio.** { *; }
-dontwarn okio.**
-dontwarn javax.annotation.**
-keepclasseswithmembers class * {
    @retrofit2.http.* <methods>;
}

# Image picker
-keep class androidx.lifecycle.** { *; }
-keep class * implements androidx.lifecycle.LifecycleObserver {
    <init>(...);
}
-keep class * extends androidx.lifecycle.ViewModel {
    <init>(...);
}
-keepclassmembers class androidx.lifecycle.Lifecycle$State { *; }
-keepclassmembers class androidx.lifecycle.Lifecycle$Event { *; }

# File picker
-keep class androidx.documentfile.** { *; }

# Connectivity Plus
-keep class android.net.ConnectivityManager { *; }
-keep class android.net.NetworkInfo { *; }

# Shared Preferences
-keep class androidx.preference.** { *; }

# Quill Editor
-keep class com.example.flutter_quill.** { *; }

# Gson (if used for JSON parsing)
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Keep model classes
-keep class com.gstv.gstv_admin.model.** { *; }
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Keep Parcelable implementations
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep Serializable implementations
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep native methods
-keepclassmembers class * {
    native <methods>;
}

# Keep enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep annotation default values
-keepattributes AnnotationDefault

# Google Play Core (fixes R8 missing classes)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Flutter deferred components
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# Google Play Services
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Additional Flutter rules
-keep class io.flutter.embedding.android.** { *; }
-keep class io.flutter.embedding.engine.** { *; }

# AndroidX
-keep class androidx.** { *; }
-dontwarn androidx.**

# Retrofit (if using)
-dontwarn retrofit2.**
-keep class retrofit2.** { *; }
-keepattributes Signature
-keepattributes Exceptions

# OkHttp
-dontwarn okhttp3.**
-keep class okhttp3.** { *; }

# Okio
-dontwarn okio.**
-keep class okio.** { *; }

# Apache Tika and XML Stream (fixes R8 missing classes error)
-dontwarn org.apache.tika.**
-dontwarn javax.xml.stream.**
-keep class org.apache.tika.** { *; }
-keep class javax.xml.stream.** { *; }

# Additional XML processing classes
-dontwarn javax.xml.**
-keep class javax.xml.** { *; }

# Video thumbnail plugin specific rules
-keep class xyz.justsoft.video_thumbnail.** { *; }
-dontwarn xyz.justsoft.video_thumbnail.**

# Additional missing classes that might cause R8 issues
-dontwarn org.slf4j.**
-dontwarn org.apache.commons.**
-dontwarn org.apache.log4j.**
-dontwarn org.apache.logging.**
-dontwarn com.sun.jna.**
-dontwarn sun.misc.Unsafe

# Keep all classes that might be referenced by reflection
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Upgrader package rules
-keep class com.larryaasen.upgrader.** { *; }
-dontwarn com.larryaasen.upgrader.**

# Connectivity Plus specific rules
-keep class io.flutter.plugins.connectivity.** { *; }
-dontwarn io.flutter.plugins.connectivity.**