# TensorFlow Lite GPU delegate rules
-dontwarn org.tensorflow.lite.gpu.GpuDelegateFactory$Options
-dontwarn org.tensorflow.lite.gpu.GpuDelegate
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }

# Keep TFLite support library classes
-dontwarn org.tensorflow.**
-keep class org.tensorflow.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# General Flutter rules
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**
