import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // Apply the Kotlin Android plugin so the `kotlin { compilerOptions { ... } }`
    // block at the bottom of this file resolves. Version is declared in
    // `android/settings.gradle.kts` with `apply false` so it propagates here.
    // Without this, CI fails with:
    //   "Unresolved reference 'compilerOptions'"
    //   "fun DependencyHandler.kotlin / PluginDependenciesSpec.kotlin"
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.bloom.wadhakir"
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.bloom.wadhakir"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { File(it as String) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            // Signing configuration for release builds
            signingConfig = signingConfigs.getByName("release")
            
            // Enable code shrinking, obfuscation, and optimization
            isMinifyEnabled = true
            isShrinkResources = true
            
            // Use proguard rules
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Required for edge-to-edge support on Android 15 (API 35)
    implementation("androidx.core:core-ktx:1.13.1")
    
    // Google Play feature delivery (Android 14 compatible)
    implementation("com.google.android.play:feature-delivery:2.1.0")
    implementation("com.google.android.play:feature-delivery-ktx:2.1.0")
}
