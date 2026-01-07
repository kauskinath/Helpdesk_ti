import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Carregar propriedades do keystore (sintaxe Kotlin)
val keystorePropertiesFile = File(rootProject.projectDir, "key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    println("✓ Keystore properties carregado de: ${keystorePropertiesFile.absolutePath}")
    println("DEBUG - Chaves disponiveis: ${keystoreProperties.keys.joinToString()}")
    keystoreProperties.forEach { key, value ->
        println("  [$key] = [${if (key.toString().contains("assword")) "***" else value}]")
    }
} else {
    println("✗ Keystore properties NAO encontrado em: ${keystorePropertiesFile.absolutePath}")
    println("✗ Build usara assinatura debug")
}

android {
    namespace = "com.example.helpdesk_ti"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlin {
        jvmToolchain(17)
    }

    // Configuração de assinatura
    signingConfigs {
        create("release") {
            val alias = keystoreProperties.getProperty("keyAlias") ?: ""
            val keyPass = keystoreProperties.getProperty("keyPassword") ?: ""
            val storeFilePath = keystoreProperties.getProperty("storeFile") ?: ""
            val storePass = keystoreProperties.getProperty("storePassword") ?: ""
            
            println("[SIGNING] Configurando assinatura release:")
            println("  keyAlias: ${if (alias.isNotEmpty()) alias else "VAZIO"}")
            println("  keyPassword: ${if (keyPass.isNotEmpty()) "***" else "VAZIO"}")
            println("  storeFile: $storeFilePath")
            println("  storePassword: ${if (storePass.isNotEmpty()) "***" else "VAZIO"}")
            
            keyAlias = alias
            keyPassword = keyPass
            storeFile = file(storeFilePath)
            storePassword = storePass
        }
    }

    defaultConfig {
        // Package name (mantido como com.example temporariamente para compatibilidade com Firebase)
        // TODO: Atualizar no Firebase Console e alterar para com.pichau.helpdesk_ti
        applicationId = "com.example.helpdesk_ti"
        minSdk = 24  // Android 7.0 - suporte completo para FCM
        targetSdk = 35  // Android 15 - compatibilidade máxima
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Informações de copyright e desenvolvedor
        manifestPlaceholders["appName"] = "PICHAU TI"
        manifestPlaceholders["appDescription"] = "Sistema Interno de Suporte Tecnico"
        manifestPlaceholders["copyright"] = "(C) 2024-2025 Pichau Informatica Ltda"
        manifestPlaceholders["developer"] = "Pichau Informatica - Departamento de TI"
    }

    buildTypes {
        release {
            // Usar assinatura de release (keystore customizado)
            signingConfig = signingConfigs.getByName("release")
            println("[BUILD TYPE RELEASE] Aplicando signingConfig: ${signingConfig?.name}")
            
            // ========== PROTEÇÃO MÁXIMA CONTRA ENGENHARIA REVERSA ==========
            
            // Ofuscação e minificação ATIVADAS
            isMinifyEnabled = true      // Ofusca nomes de classes/métodos
            isShrinkResources = true    // Remove recursos não utilizados
            
            // ProGuard com otimização agressiva
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            
            // Desabilitar debug em release
            isDebuggable = false
            isJniDebuggable = false
            
            // Otimizações de código nativo
            ndk {
                debugSymbolLevel = "NONE"  // Remove símbolos de debug
            }
        }
        
        debug {
            // Debug também protegido para testes
            isMinifyEnabled = false
            isShrinkResources = false
            isDebuggable = true
        }
    }
    
    // Desabilitar backup do app (proteção de dados)
    defaultConfig {
        // ... configurações existentes ...
    }
    
    // Configurações de empacotamento
    packaging {
        resources {
            // Remover arquivos desnecessários que podem expor informações
            excludes += listOf(
                "META-INF/DEPENDENCIES",
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt",
                "META-INF/NOTICE",
                "META-INF/NOTICE.txt",
                "META-INF/*.kotlin_module",
                "META-INF/versions/**"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
