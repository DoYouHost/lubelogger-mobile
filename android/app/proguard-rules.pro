# R8 keep rules for release builds. Flutter enables R8 minification + full mode
# by default for release, and auto-appends this file to the R8 config when it
# exists (see FlutterPlugin.kt).

# WorkManager (reminder notifications) uses a Room database whose generated
# `WorkDatabase_Impl` is instantiated reflectively via its no-arg constructor.
# Room 2.6.x's consumer rule keeps the class name but NOT the constructor, and
# R8 full mode strips members reached only by reflection — so the app crashes at
# launch with `NoSuchMethodException: androidx.work.impl.WorkDatabase_Impl.<init>`.
# Keep the no-arg constructor of every Room database subclass. (`extends` matches
# indirect subclasses, covering WorkDatabase_Impl -> WorkDatabase -> RoomDatabase.)
-keep class * extends androidx.room.RoomDatabase { <init>(); }
