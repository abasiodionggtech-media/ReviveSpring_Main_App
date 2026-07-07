import java.io.FileInputStream
import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

fun readDartDefines(): Map<String, String> {
    val encoded = project.findProperty("dart-defines") as? String ?: return emptyMap()
    return encoded
        .split(",")
        .mapNotNull { value ->
            runCatching {
                val decoded = String(Base64.getDecoder().decode(value))
                val separator = decoded.indexOf('=')
                if (separator <= 0) null
                else decoded.substring(0, separator) to decoded.substring(separator + 1)
            }.getOrNull()
        }
        .toMap()
}

val dartDefines = readDartDefines()

android {
    namespace = "com.revivespring"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.revivespring"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["ADMOB_APP_ID"] =
            dartDefines["ADMOB_ANDROID_APP_ID"]
                ?: "ca-app-pub-3940256099942544~3347511713"
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                val storeFilePath = keystoreProperties["storeFile"] as? String
                val storePasswordValue = keystoreProperties["storePassword"] as? String
                val keyAliasValue = keystoreProperties["keyAlias"] as? String
                val keyPasswordValue = keystoreProperties["keyPassword"] as? String

                if (!storeFilePath.isNullOrBlank() && !storePasswordValue.isNullOrBlank() && !keyAliasValue.isNullOrBlank() && !keyPasswordValue.isNullOrBlank()) {
                    keyAlias = keyAliasValue
                    keyPassword = keyPasswordValue
                    storeFile = file(storeFilePath)
                    storePassword = storePasswordValue
                } else {
                    throw GradleException("android/key.properties is missing required signing values. Copy android/key.properties.example and fill in your release keystore details.")
                }
            } else {
                throw GradleException("android/key.properties is required for release signing. Copy android/key.properties.example and configure your release keystore.")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
