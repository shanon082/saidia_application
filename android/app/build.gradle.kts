import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasKeystoreProperties = keystorePropertiesFile.exists()
if (hasKeystoreProperties) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

// android {
//     namespace = "com.example.saidia_app"
//     compileSdk = flutter.compileSdkVersion
//     ndkVersion = flutter.ndkVersion

//     compileOptions {
//         sourceCompatibility = JavaVersion.VERSION_17
//         targetCompatibility = JavaVersion.VERSION_17
//     }

//     kotlinOptions {
//         jvmTarget = JavaVersion.VERSION_17.toString()
//     }

//     defaultConfig {
//         // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
//         applicationId = "com.example.saidia_app"
//         // You can update the following values to match your application needs.
//         // For more information, see: https://flutter.dev/to/review-gradle-config.
//         minSdk = 24
//         targetSdk = 35
//         versionCode = flutter.versionCode
//         versionName = flutter.versionName
//     }

//     signingConfigs {
//         create("release") {
//             if (hasKeystoreProperties) {
//                 keyAlias = keystoreProperties["keyAlias"] as String
//                 keyPassword = keystoreProperties["keyPassword"] as String
//                 storeFile = rootProject.file(keystoreProperties["storeFile"] as String)
//                 storePassword = keystoreProperties["storePassword"] as String
//             }
//         }
//     }

//     buildTypes {
//         release {
//             // Use release signing when key.properties exists, otherwise fallback to debug.
//             signingConfig = if (hasKeystoreProperties) {
//                 signingConfigs.getByName("release")
//             } else {
//                 signingConfigs.getByName("debug")
//             }

//             isMinifyEnabled = false
//             isShrinkResources = false
//         }
//     }
//     packagingOptions {
//         resources {
//             excludes += "/META-INF/{AL2.0,LGPL2.1}"
//         }
//     }
// }

android {
    namespace = "com.example.saidia_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.saidia_app"
        minSdk = 24                    // Android 7+
        targetSdk = 35                 // Android 15
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasKeystoreProperties) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = rootProject.file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasKeystoreProperties) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }

    packagingOptions {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

flutter {
    source = "../.."
}
