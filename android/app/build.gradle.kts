import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "org.psito.chirp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // O flutter_local_notifications pede (as datas do java.time nos Androids velhos).
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "org.psito.chirp"
        // O AAudio (o som das notas de voz, pelo cpal) chegou no Android 8.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // A chave das versões publicadas vem do android/key.properties, que o CI escreve a
    // partir dos segredos (tool/create-android-key.sh). Sem ele, o release sai com a
    // chave de depuração, para o `flutter run --release` e o build do CI funcionarem.
    val keyFile = rootProject.file("key.properties")
    val release = keyFile.exists()
    if (release) {
        val key = Properties().apply { keyFile.inputStream().use { load(it) } }
        signingConfigs.create("release") {
            storeFile = rootProject.file(key.getProperty("storeFile"))
            storePassword = key.getProperty("storePassword")
            keyAlias = key.getProperty("keyAlias")
            keyPassword = key.getProperty("keyPassword")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(if (release) "release" else "debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
