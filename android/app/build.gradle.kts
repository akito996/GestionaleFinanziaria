import java.io.FileInputStream
import java.net.URI
import java.security.MessageDigest
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
            // Schema v3: permette in futuro di cambiare chiave di firma senza
            // reinstallare l'app (rotazione della chiave).
            enableV3Signing = true
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
            // Regole per la lettura delle foto (vedi proguard-rules.pro).
            proguardFiles("proguard-rules.pro")
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

// ------------------------------------------------------------------------
// Lettura delle foto (scontrini, contratti) solo su Android, tutta sul
// telefono: Tesseract open source (Apache-2.0). Versioni fissate e impronte
// SHA-256 verificate a ogni build: se cambiano, la build si ferma.

val tesseract = "cz.adaptech.tesseract4android:tesseract4android:4.9.0"
val improntaTesseract = "bce5d6413a1a5ae3d7240033fbbc851ba3217d0a08d9769400e17a077f42cb2a"

dependencies {
    implementation(tesseract)
    // Sblocco con impronta, viso o PIN (AndroidX, Apache-2.0).
    implementation("androidx.biometric:biometric:1.1.0")
}

fun sha256(file: File): String =
    MessageDigest.getInstance("SHA-256").digest(file.readBytes())
        .joinToString("") { "%02x".format(it) }

val verificaTesseract = tasks.register("verificaTesseract") {
    val libreria = configurations.detachedConfiguration(
        project.dependencies.create("$tesseract@aar"),
    )
    doLast {
        val impronta = sha256(libreria.singleFile)
        check(impronta == improntaTesseract) {
            "Tesseract4Android: impronta $impronta diversa da quella attesa"
        }
    }
}
tasks.named("preBuild") { dependsOn(verificaTesseract) }

/** Scarica il modello italiano (tessdata_best 4.1.0) e lo mette negli asset. */
abstract class ModelloLettura : DefaultTask() {
    @get:Input
    abstract val indirizzo: Property<String>

    @get:Input
    abstract val impronta: Property<String>

    /** Copia condivisa tra le varianti: si scarica una volta sola. */
    @get:Internal
    abstract val copia: RegularFileProperty

    @get:OutputDirectory
    abstract val cartella: DirectoryProperty

    @TaskAction
    fun prepara() {
        val scaricato = copia.get().asFile
        fun digest(f: File) = MessageDigest.getInstance("SHA-256").digest(f.readBytes())
            .joinToString("") { "%02x".format(it) }
        if (!scaricato.exists() || digest(scaricato) != impronta.get()) {
            scaricato.parentFile.mkdirs()
            URI(indirizzo.get()).toURL().openStream().use { entrata ->
                scaricato.outputStream().use { entrata.copyTo(it) }
            }
        }
        val trovata = digest(scaricato)
        check(trovata == impronta.get()) {
            "Modello di lettura: impronta $trovata diversa da quella attesa"
        }
        val destinazione = cartella.get().file("tessdata/ita.traineddata").asFile
        destinazione.parentFile.mkdirs()
        scaricato.copyTo(destinazione, overwrite = true)
    }
}

androidComponents {
    onVariants { variante ->
        val nome = variante.name.replaceFirstChar { it.uppercase() }
        val modello = tasks.register<ModelloLettura>("modelloLettura$nome") {
            indirizzo.set(
                "https://raw.githubusercontent.com/tesseract-ocr/tessdata_best/4.1.0/ita.traineddata",
            )
            impronta.set("8df9c89176fb93f56bf4b2d4ede04c01c1f31d4b7697fbd76cc336df700f3f38")
            copia.set(rootProject.layout.buildDirectory.file("modello-lettura/ita.traineddata"))
        }
        variante.sources.assets?.addGeneratedSourceDirectory(modello, ModelloLettura::cartella)
    }
}
