plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.geoquest.geoquest_philippines"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    signingConfigs {
        create("release") {
            storeFile = file("mapquest-release.jks")
            storePassword = "mapquest123"
            keyAlias = "mapquest"
            keyPassword = "mapquest123"
            enableV1Signing = true
            enableV2Signing = true
        }
    }

    defaultConfig {
        applicationId = "com.geoquest.geoquest_philippines"
        // Compatible from Android 7.0 (API 24) up to latest Android 14/15
        minSdk = 24
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
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
