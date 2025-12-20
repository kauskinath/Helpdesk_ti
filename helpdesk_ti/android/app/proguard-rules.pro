# Regras de Ofuscacao ProGuard - PICHAU TI
# Este arquivo define como o codigo sera ofuscado e otimizado no build de release

# ========== CONFIGURACOES GERAIS ==========

# Manter informacoes de linha de codigo para stack traces
-keepattributes SourceFile,LineNumberTable

# Manter anotacoes
-keepattributes *Annotation*

# Manter assinaturas genericas
-keepattributes Signature

# Manter excecoes
-keepattributes Exceptions

# ========== IGNORAR AVISOS DE CLASSES OPCIONAIS ==========

# Play Core (classes opcionais que podem nao estar presentes)
-dontwarn com.google.android.play.core.**

# OkHttp (usado por algumas libs Firebase mas pode estar ausente)
-dontwarn com.squareup.okhttp.**
-dontwarn okhttp3.**

# Java 8+ features que podem nao estar disponiveis em todas as versoes
-dontwarn java.lang.reflect.AnnotatedType

# ========== FLUTTER ==========

# Manter classes do Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Manter métodos de plugin Flutter
-keepclassmembers class * {
    @io.flutter.embedding.engine.loader.FlutterLoader$* <methods>;
}

# ========== FIREBASE ==========

# Firebase Core
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Firebase Firestore
-keep class com.google.firebase.firestore.** { *; }
-keepclassmembers class com.google.firebase.firestore.** { *; }

# Firebase Auth
-keep class com.google.firebase.auth.** { *; }

# Firebase Messaging (FCM)
-keep class com.google.firebase.messaging.** { *; }
-keep class com.google.firebase.iid.** { *; }

# Firebase Storage
-keep class com.google.firebase.storage.** { *; }

# ========== GSON (usado pelo Firebase) ==========

-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Manter classes de modelo (adicione suas classes de dados aqui)
-keep class com.pichau.helpdesk_ti.models.** { *; }

# ========== KOTLIN ==========

-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}
-assumenosideeffects class kotlin.jvm.internal.Intrinsics {
    static void checkParameterIsNotNull(java.lang.Object, java.lang.String);
}

# ========== NOTIFICAÇÕES LOCAIS ==========

-keep class com.dexterous.** { *; }
-keep class androidx.core.app.** { *; }

# ========== PERMISSÕES ==========

-keep class com.baseflow.permissionhandler.** { *; }

# ========== IMAGE PICKER / FILE PICKER ==========

-keep class io.flutter.plugins.imagepicker.** { *; }
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# ========== SHARED PREFERENCES ==========

-keep class io.flutter.plugins.sharedpreferences.** { *; }

# ========== PATH PROVIDER ==========

-keep class io.flutter.plugins.pathprovider.** { *; }

# ========== URL LAUNCHER ==========

-keep class io.flutter.plugins.urllauncher.** { *; }

# ========== DEVICE INFO ==========

-keep class io.flutter.plugins.deviceinfo.** { *; }

# ========== PACKAGE INFO ==========

-keep class io.flutter.plugins.packageinfo.** { *; }

# ========== CACHED NETWORK IMAGE ==========

-keep class com.baseflow.cachednetworkimage.** { *; }

# ========== PDF VIEWER (Syncfusion) ==========

-keep class com.syncfusion.flutter.** { *; }
-dontwarn com.syncfusion.flutter.**

# ========== OTIMIZAÇÕES ==========

# Otimizar e reduzir tamanho
-optimizationpasses 5
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-verbose

# Remover logs em produção (opcional - comentar se quiser manter logs)
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

# ========== AVISOS SUPRIMIDOS ==========

-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**
-dontwarn javax.annotation.**
-dontwarn com.google.auto.value.**

# ========== PROTEÇÃO ADICIONAL ==========

# Ofuscar nomes de classes, métodos e campos
-repackageclasses 'com.pichau.obf'
-allowaccessmodification

# Remover código não usado
-dontshrink

# ========== COPYRIGHT ==========
# © 2024-2025 Pichau Informática Ltda
# Sistema Interno de Suporte Técnico
# Todos os direitos reservados
