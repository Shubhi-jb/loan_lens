# ML Kit ProGuard Rules
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.ml.** { *; }
-keep class com.google.android.libraries.places.** { *; }
-keep class com.google.android.gms.common.internal.safeparcel.SafeParcelable { *; }

# Firebase ProGuard Rules
-keepattributes Signature, *Annotation*, EnclosingMethod, InnerClasses
-dontwarn com.google.firebase.**
-dontwarn com.google.mlkit.vision.text.**
-dontwarn com.google.android.gms.internal.ml.**
-keep class com.google.generativeai.** { *; }
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

