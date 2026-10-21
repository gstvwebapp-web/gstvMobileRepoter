# R8 specific rules to fix missing classes issues

# Apache Tika and XML Stream classes
-dontwarn org.apache.tika.**
-dontwarn javax.xml.stream.**
-dontwarn javax.xml.**
-dontwarn org.slf4j.**
-dontwarn org.apache.commons.**
-dontwarn org.apache.log4j.**
-dontwarn org.apache.logging.**
-dontwarn com.sun.jna.**
-dontwarn sun.misc.Unsafe

# Keep classes that might be referenced by reflection
-keep class org.apache.tika.** { *; }
-keep class javax.xml.stream.** { *; }
-keep class javax.xml.** { *; }

# Video thumbnail plugin
-keep class xyz.justsoft.video_thumbnail.** { *; }
-dontwarn xyz.justsoft.video_thumbnail.**

# Flutter and Dart specific
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

# Connectivity Plus
-keep class io.flutter.plugins.connectivity.** { *; }
-dontwarn io.flutter.plugins.connectivity.**

# Upgrader package
-keep class com.larryaasen.upgrader.** { *; }
-dontwarn com.larryaasen.upgrader.**

# GetX
-keep class com.example.** { *; }
-keepclassmembers class * extends io.flutter.embedding.engine.plugins.FlutterPlugin {
    public *;
}

# Dio HTTP client
-dontwarn okio.**
-dontwarn javax.annotation.**
-keep class okio.** { *; }
-keep class retrofit2.** { *; }
-dontwarn retrofit2.**

# Image picker and file handling
-keep class androidx.lifecycle.** { *; }
-keep class androidx.documentfile.** { *; }

# Network related
-keep class android.net.ConnectivityManager { *; }
-keep class android.net.NetworkInfo { *; }

# Gson (JSON parsing)
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Keep model classes
-keep class com.gstv.gstv_admin.model.** { *; }

# Keep Parcelable and Serializable
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

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

# Google Play Services and Core
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# AndroidX
-keep class androidx.** { *; }
-dontwarn androidx.**

# Additional missing classes that cause R8 issues
-dontwarn java.lang.instrument.**
-dontwarn java.lang.management.**
-dontwarn java.util.logging.**
-dontwarn javax.management.**
-dontwarn javax.naming.**
-dontwarn javax.servlet.**
-dontwarn org.ietf.jgss.**
-dontwarn org.w3c.dom.**
-dontwarn org.xml.sax.**

# Keep classes with @SerializedName annotations
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Flutter deferred components
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# Additional Flutter embedding
-keep class io.flutter.embedding.android.** { *; }
-keep class io.flutter.embedding.engine.** { *; }
