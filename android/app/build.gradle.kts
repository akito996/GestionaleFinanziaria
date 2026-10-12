import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Chiave di firma definitiva: android/key.properties + keystore, creati dalla CI
// a partire dai secret di GitHub (mai nel repository, vedi .gitignore).
// Senza, l'APK è firmato con la chiave di debug: solo per prova.
val chiaveProperties = Properties()
val chiaveFile = rootProject.file("key.properties")
if (chiaveFile.exists()) {
    FileInputStream(chiaveFile).use { chiaveProperties.load(it) }
}

android {
    namespace = "io.github.akito996.gestionale_finanziaria"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "io.github.akito996.gestionale_finanziaria"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("definitiva") {
            if (chiaveFile.exists()) {
                keyAlias = chiaveProperties["keyAlias"] as String
                keyPassword = chiaveProperties["keyPassword"] as String
                storeFile = file(chiaveProperties["storeFile"] as String)
                storePassword = chiaveProperties["storePassword"] as String
            }
        }
    }

    // Due app installabili insieme sullo stesso telefono:
    // - "ufficiale": quella con i dati veri;
    // - "prova": per provare le novità senza toccare i dati veri.
    flavorDimensions += "versione"
    productFlavors {
        create("ufficiale") {
            dimension = "versione"
            manifestPlaceholders["nomeApp"] = "GestionaleFinanziaria"
        }
        create("prova") {
            dimension = "versione"
            applicationIdSuffix = ".prova"
            versionNameSuffix = "-prova"
            manifestPlaceholders["nomeApp"] = "GF Prova"
        }
    }

    buildTypes {
        release {
            signingConfig =
                if (chiaveFile.exists()) {
                    signingConfigs.getByName("definitiva")
                } else {
                    signingConfigs.getByName("debug")
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
