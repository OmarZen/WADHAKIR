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
            // Only populate when key.properties exists. Assigning nulls here and
            // then wiring this config into the release build type produces
            // spectacularly unhelpful errors: `assembleRelease` fails with
            // `SigningConfig "release" is missing required property "storeFile"`,
            // and `bundleRelease` fails with a bare
            // `java.lang.NullPointerException (no error message)` from
            // FinalizeBundleTask — neither of which says "you have no keystore".
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String?
                keyPassword = keystoreProperties["keyPassword"] as String?
                // Gradle's project.file(), NOT java.io.File(): a raw File() with a
                // relative path like "../upload-keystore.jks" resolves against the
                // JVM's working directory — which is the Gradle daemon's dir, not
                // this project — and fails with
                //   Keystore file '/home/runner/.gradle/daemon/9.3.1/../upload-keystore.jks' not found
                // project.file() resolves relative to android/app/, so
                // "../upload-keystore.jks" correctly means android/upload-keystore.jks
                // (where CI writes it). Absolute paths pass through unchanged.
                storeFile = keystoreProperties["storeFile"]?.let { file(it as String) }
                storePassword = keystoreProperties["storePassword"] as String?
            }
        }
    }

    buildTypes {
        release {
            // Sign with the real upload key when android/key.properties is
            // present (CI writes it from secrets before a tagged build; see
            // .github/workflows/build-and-release.yml). Otherwise fall back to
            // debug signing so `flutter build apk/appbundle --release` still
            // works locally for size checks and R8/shrinker verification.
            //
            // A debug-signed artifact CANNOT be uploaded to Google Play — Play
            // rejects it because the signature does not match the upload key. To
            // produce an uploadable build locally you need android/key.properties
            // (both it and *.jks are gitignored):
            //
            //     storePassword=<KEYSTORE_STORE_PASSWORD>
            //     keyPassword=<KEYSTORE_KEY_PASSWORD>
            //     keyAlias=<KEYSTORE_KEY_ALIAS>
            //     storeFile=../upload-keystore.jks
            //
            // Easier: push a `v*` tag and let CI build the signed AAB.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                logger.warn(
                    "⚠️  android/key.properties not found — signing the release " +
                    "build with the DEBUG key. This artifact is fine for local " +
                    "testing but Google Play WILL reject it."
                )
                signingConfigs.getByName("debug")
            }

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
