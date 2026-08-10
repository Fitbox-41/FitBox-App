import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Google Maps API key is read from android/local.properties (gitignored) so it
// never lands in source control:  MAPS_API_KEY=AIza....
val mapsApiKey: String = Properties().apply {
    val f = rootProject.file("local.properties")
    if (f.exists()) FileInputStream(f).use { load(it) }
}.getProperty("MAPS_API_KEY") ?: ""

// Release signing. Credentials live in android/key.properties (gitignored)
// alongside the keystore itself — neither is ever committed. See RELEASE.md for
// how to generate them.
//
// If the file is absent the build falls back to the debug key so that
// `flutter run --release` still works on a machine without the keystore. That
// fallback is for development only: Google Play rejects debug-signed uploads,
// and the debug key is a well-known shared key, so a build signed with it must
// never be distributed as a real release.
val keystoreProperties = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) FileInputStream(f).use { load(it) }
}
val hasReleaseKeystore = keystoreProperties.getProperty("storeFile") != null

android {
    namespace = "com.fitboxsports.fitbox"
    compileSdk = maxOf(flutter.compileSdkVersion, 36) // Health Connect requires 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Required by flutter_local_notifications (uses java.time via desugaring).
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.fitboxsports.app"
        minSdk = maxOf(flutter.minSdkVersion, 26) // Health Connect requires 26+
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Injected into AndroidManifest as ${MAPS_API_KEY}.
        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                logger.warn(
                    "\n*** No android/key.properties found — signing this RELEASE build with the " +
                    "DEBUG key. Fine for local testing; Google Play will reject it and it must " +
                    "not be distributed. See android/RELEASE.md. ***\n"
                )
                signingConfigs.getByName("debug")
            }
            // Shrink and obfuscate the release build: smaller download, and the
            // Dart/Java symbol names aren't handed to anyone who unzips the APK.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
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
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
