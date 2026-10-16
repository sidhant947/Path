-keep class com.sidhant.path.widget.** { *; }
-keep class com.sidhant.path.service.** { *; }
-keep class com.sidhant.path.receiver.** { *; }
-keep class com.sidhant.path.data.** { *; }
-keep class androidx.glance.** { *; }
-keep class androidx.datastore.** { *; }
-keep class androidx.health.connect.** { *; }
-keep class androidx.work.** { *; }
-dontwarn androidx.work.**
-keep class androidx.room.** { *; }
-dontwarn androidx.room.**
-keep class * extends androidx.room.RoomDatabase { *; }
-keep class * extends androidx.work.ListenableWorker {
    <init>(android.content.Context, androidx.work.WorkerParameters);
}
-dontwarn kotlinx.coroutines.**
