import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val uploadPropertiesFile = rootProject.file("key.properties")
val uploadProperties = Properties().apply {
    if (uploadPropertiesFile.exists()) uploadPropertiesFile.inputStream().use { load(it) }
}

android {
    namespace = "com.sofien.daylock"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.sofien.daylock"
        // AppAuth browser callback; public routing metadata, not an OAuth secret.
        manifestPlaceholders["appAuthRedirectScheme"] = "com.example.daylock.microsoft"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        testInstrumentationRunner = "com.sofien.daylock.RestrictedAppsInstrumentation"
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (uploadPropertiesFile.exists()) {
            create("upload") {
                fun requiredProperty(name: String): String =
                    uploadProperties.getProperty(name)?.takeIf { it.isNotBlank() }
                        ?: throw GradleException("Missing $name in android/key.properties")
                storeFile = rootProject.file(requiredProperty("storeFile"))
                storePassword = requiredProperty("storePassword")
                keyAlias = requiredProperty("keyAlias")
                keyPassword = requiredProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Never fall back to the debug key for a Play release.
            signingConfig = signingConfigs.findByName("upload")
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
    testImplementation("junit:junit:4.13.2")
    // JVM tests exercise the same JSON codec; production uses Android's org.json.
    testImplementation("org.json:json:20240303")
}

// Keep debug and unit-test tasks usable, but never produce an unsigned release by accident.
tasks.configureEach {
    if (name == "bundleRelease" || name == "assembleRelease" || name == "packageRelease") {
        doFirst {
            if (!uploadPropertiesFile.exists()) {
                throw GradleException("Release signing is not configured: create android/key.properties with upload key details.")
            }
        }
    }
}
