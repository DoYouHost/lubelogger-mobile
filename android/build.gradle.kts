allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // Some plugins (file_picker → flutter_plugin_android_lifecycle) require
    // compileSdk >= 36. Force it on every Android module so a plugin isn't
    // compiled against an older API than the app. Must run before the
    // evaluationDependsOn(":app") below, which evaluates the projects.
    afterEvaluate {
        extensions.findByName("android")?.let { ext ->
            (ext as com.android.build.gradle.BaseExtension).apply {
                val current = compileSdkVersion
                    ?.removePrefix("android-")
                    ?.toIntOrNull()
                if (current == null || current < 36) {
                    compileSdkVersion(36)
                }
            }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
