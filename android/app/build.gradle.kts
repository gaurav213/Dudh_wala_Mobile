import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing comes from a git-ignored `android/key.properties` file
// (storeFile/storePassword/keyAlias/keyPassword) when one exists. See the
// README for how to generate a real upload keystore before a Play Store
// release. Without it, release builds fall back to the debug keystore so
// `flutter run --release` / local CI still work — see the loud warning
// wired up on the `release` build type below.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.doodhkhata.doodh_khata_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.doodhkhata.doodh_khata_mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            if (hasReleaseKeystore) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                val storeRelease = System.getenv("STORE_RELEASE") == "1"
                if (storeRelease) {
                    throw GradleException(
                        "STORE_RELEASE=1 but android/key.properties is missing. " +
                            "Generate an upload keystore and add key.properties before " +
                            "building a Play Store AAB — see README / RELEASE_CHECKLIST.md."
                    )
                }
                // No android/key.properties — this is NOT a store-ready build.
                println(
                    "WARNING: android/key.properties not found. Signing the " +
                        "release build with the DEBUG keystore. This build " +
                        "must not be uploaded to the Play Store — see README " +
                        "for how to generate a real upload keystore."
                )
                signingConfig = signingConfigs.getByName("debug")
            }
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
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

