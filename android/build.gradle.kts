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

    // Force plugin subprojects (e.g. flutter_volume_controller) to use a modern
    // compileSdk so their transitive AndroidX deps (which require API 33/34+)
    // satisfy AAR metadata checks. Must be registered before evaluationDependsOn.
    afterEvaluate {
        val androidExt = project.extensions.findByName("android")
        if (androidExt is com.android.build.gradle.BaseExtension) {
            val current = androidExt.compileSdkVersion?.removePrefix("android-")?.toIntOrNull() ?: 0
            if (current < 37) {
                androidExt.compileSdkVersion(37)
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
