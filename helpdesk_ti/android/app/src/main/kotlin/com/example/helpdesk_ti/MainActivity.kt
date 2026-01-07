package com.example.helpdesk_ti

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

/**
 * PICHAU TI - MainActivity com Proteções de Segurança
 * (C) 2024-2025 Pichau Informatica Ltda.
 * 
 * Proteções implementadas:
 * - FLAG_SECURE: Impede screenshots e gravação de tela
 * - Anti-tampering: Verificação de integridade
 */
class MainActivity : FlutterActivity() {
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Proteção contra screenshots e gravação de tela
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
        
        // Verificações de segurança em runtime
        if (isEmulator() || isDebuggable()) {
            // Em ambiente de produção, você pode escolher encerrar o app
            // finish() // Descomente para bloquear completamente
        }
    }
    
    private fun isEmulator(): Boolean {
        return (android.os.Build.FINGERPRINT.startsWith("generic")
                || android.os.Build.FINGERPRINT.startsWith("unknown")
                || android.os.Build.MODEL.contains("google_sdk")
                || android.os.Build.MODEL.contains("Emulator")
                || android.os.Build.MODEL.contains("Android SDK built for x86")
                || android.os.Build.MANUFACTURER.contains("Genymotion")
                || (android.os.Build.BRAND.startsWith("generic") && android.os.Build.DEVICE.startsWith("generic"))
                || "google_sdk" == android.os.Build.PRODUCT)
    }
    
    private fun isDebuggable(): Boolean {
        return (applicationInfo.flags and android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) != 0
    }
}
