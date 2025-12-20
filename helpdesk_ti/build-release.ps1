# Script de Build - PICHAU TI
# (C) 2024-2025 Pichau Informatica Ltda

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("apk", "appbundle", "both")]
    [string]$BuildType = "apk"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  BUILD AUTOMATIZADO - PICHAU TI" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar se esta na pasta do projeto
if (-not (Test-Path "pubspec.yaml")) {
    Write-Host "[ERRO] Execute este script na raiz do projeto Flutter!" -ForegroundColor Red
    exit 1
}

# Verificar se key.properties existe
if (-not (Test-Path "android\key.properties")) {
    Write-Host "[AVISO] key.properties nao encontrado!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "O build sera feito com assinatura de debug." -ForegroundColor Yellow
    Write-Host "Para build de producao, execute primeiro: .\gerar-keystore.ps1" -ForegroundColor Yellow
    Write-Host ""
    $continue = Read-Host "Deseja continuar mesmo assim? (S/N)"
    if ($continue -ne "S" -and $continue -ne "s") {
        Write-Host "[CANCELADO] Build cancelado." -ForegroundColor Red
        exit 0
    }
}

# Limpar builds anteriores
Write-Host "[INFO] Limpando builds anteriores..." -ForegroundColor Yellow
flutter clean | Out-Null
Write-Host "[OK] Limpeza concluida!" -ForegroundColor Green
Write-Host ""

# Obter dependencias
Write-Host "[INFO] Obtendo dependencias..." -ForegroundColor Yellow
flutter pub get | Out-Null
Write-Host "[OK] Dependencias obtidas!" -ForegroundColor Green
Write-Host ""

# Função para assinar APK manualmente
function Invoke-APKSigning {
    param(
        [string]$unsignedApk,
        [string]$signedApk
    )
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Magenta
    Write-Host "  ASSINANDO APK..." -ForegroundColor Magenta
    Write-Host "========================================" -ForegroundColor Magenta
    Write-Host ""
    
    # Carregar configurações do key.properties
    $keyPropsPath = "android\key.properties"
    if (-not (Test-Path $keyPropsPath)) {
        Write-Host "[AVISO] key.properties nao encontrado. APK nao sera assinado." -ForegroundColor Yellow
        return $false
    }
    
    $keyProps = @{}
    Get-Content $keyPropsPath | ForEach-Object {
        if ($_ -match '^([^=]+)=(.+)$') {
            $keyProps[$matches[1]] = $matches[2]
        }
    }
    
    # Verificar apksigner
    $apksignerPath = "C:\Users\User\AppData\Local\Android\sdk\build-tools\35.0.0\apksigner.bat"
    if (-not (Test-Path $apksignerPath)) {
        # Tentar encontrar apksigner em qualquer versão
        $buildToolsDir = "C:\Users\User\AppData\Local\Android\sdk\build-tools"
        $apksignerPath = Get-ChildItem -Path $buildToolsDir -Recurse -Filter "apksigner.bat" -ErrorAction SilentlyContinue | 
                         Select-Object -First 1 | 
                         Select-Object -ExpandProperty FullName
        
        if (-not $apksignerPath) {
            Write-Host "[ERRO] apksigner nao encontrado no Android SDK!" -ForegroundColor Red
            return $false
        }
    }
    
    Write-Host "[INFO] Keystore: $($keyProps['storeFile'])" -ForegroundColor Cyan
    Write-Host "[INFO] Alias: $($keyProps['keyAlias'])" -ForegroundColor Cyan
    Write-Host ""
    
    # Assinar APK
    $startTime = Get-Date
    & $apksignerPath sign `
        --ks $keyProps['storeFile'] `
        --ks-pass "pass:$($keyProps['storePassword'])" `
        --ks-key-alias $keyProps['keyAlias'] `
        --key-pass "pass:$($keyProps['keyPassword'])" `
        --out $signedApk `
        $unsignedApk
    $endTime = Get-Date
    $duration = $endTime - $startTime
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "[OK] APK assinado com sucesso!" -ForegroundColor Green
        Write-Host "   Tempo: $($duration.Seconds)s" -ForegroundColor Gray
        
        # Verificar assinatura
        Write-Host ""
        Write-Host "[INFO] Verificando assinatura..." -ForegroundColor Cyan
        $verifyOutput = & $apksignerPath verify --verbose $signedApk 2>&1
        
        if ($verifyOutput -match "Verified using v2 scheme.*: true" -and $verifyOutput -match "Verified using v3 scheme.*: true") {
            Write-Host "[OK] Assinatura v2 + v3 verificada!" -ForegroundColor Green
        } else {
            Write-Host "[AVISO] Verificacao de assinatura com avisos" -ForegroundColor Yellow
        }
        
        return $true
    } else {
        Write-Host ""
        Write-Host "[ERRO] Falha ao assinar APK!" -ForegroundColor Red
        return $false
    }
}

# Função para build APK
function Invoke-APKBuild {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  CONSTRUINDO APK..." -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    $startTime = Get-Date
    flutter build apk --release
    $endTime = Get-Date
    $duration = $endTime - $startTime
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "[OK] APK construido com sucesso!" -ForegroundColor Green
        Write-Host "   Tempo: $($duration.Minutes)m $($duration.Seconds)s" -ForegroundColor Gray
        Write-Host ""
        
        # APKs gerados pelo Flutter
        $unsignedApk = "build\app\outputs\apk\release\app-release.apk"
        $signedApk = "build\app\outputs\apk\release\app-release-signed.apk"
        
        # Assinar APK automaticamente
        $signed = Invoke-APKSigning -unsignedApk $unsignedApk -signedApk $signedApk
        
        if ($signed) {
            Write-Host ""
            Write-Host "[INFO] APK FINAL (assinado):" -ForegroundColor Cyan
            Write-Host "   $signedApk" -ForegroundColor White
            
            if (Test-Path $signedApk) {
                $size = (Get-Item $signedApk).Length / 1MB
                Write-Host "   Tamanho: $([math]::Round($size, 2)) MB" -ForegroundColor Gray
            }
        } else {
            Write-Host ""
            Write-Host "[AVISO] APK SEM ASSINATURA:" -ForegroundColor Yellow
            Write-Host "   $unsignedApk" -ForegroundColor White
            Write-Host ""
            Write-Host "[INFO] Execute manualmente:" -ForegroundColor Cyan
            Write-Host "   .\gerar-keystore.ps1" -ForegroundColor Gray
        }
    } else {
        Write-Host ""
        Write-Host "[ERRO] ao construir APK!" -ForegroundColor Red
        return $false
    }
    return $true
}

# Função para build AAB
function Invoke-AABBuild {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  CONSTRUINDO AAB (Android App Bundle)..." -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    $startTime = Get-Date
    flutter build appbundle --release
    $endTime = Get-Date
    $duration = $endTime - $startTime
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "[OK] AAB construido com sucesso!" -ForegroundColor Green
        Write-Host "   Tempo: $($duration.Minutes)m $($duration.Seconds)s" -ForegroundColor Gray
        Write-Host ""
        Write-Host "[INFO] Localizacao:" -ForegroundColor Cyan
        Write-Host "   build\app\outputs\bundle\release\app-release.aab"
        
        # Obter tamanho do arquivo
        $aabFile = "build\app\outputs\bundle\release\app-release.aab"
        if (Test-Path $aabFile) {
            $size = (Get-Item $aabFile).Length / 1MB
            Write-Host "   Tamanho: $([math]::Round($size, 2)) MB" -ForegroundColor Gray
        }
    } else {
        Write-Host ""
        Write-Host "[ERRO] ao construir AAB!" -ForegroundColor Red
        return $false
    }
    return $true
}

# Executar builds conforme tipo selecionado
$success = $true

switch ($BuildType) {
    "apk" {
        $success = Invoke-APKBuild
    }
    "appbundle" {
        $success = Invoke-AABBuild
    }
    "both" {
        $success = Invoke-APKBuild
        if ($success) {
            $success = Invoke-AABBuild
        }
    }
}

# Resumo final
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  RESUMO DO BUILD" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($success) {
    Write-Host "[OK] Build concluido com sucesso!" -ForegroundColor Green
    Write-Host ""
    Write-Host "[INFO] PROXIMOS PASSOS:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Teste o APK em dispositivos reais"
    Write-Host "2. Para Play Store, use o arquivo .aab"
    Write-Host "3. Para distribuicao direta, use: app-release-signed.apk"
    Write-Host ""
    
    Write-Host "[INFO] ARQUIVOS GERADOS:" -ForegroundColor Cyan
    Write-Host "   APK assinado: build\app\outputs\apk\release\app-release-signed.apk" -ForegroundColor White
    if (Test-Path "build\app\outputs\bundle\release\app-release.aab") {
        Write-Host "   AAB: build\app\outputs\bundle\release\app-release.aab" -ForegroundColor White
    }
    Write-Host ""
    
} else {
    Write-Host "[ERRO] Build falhou!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Verifique os erros acima e tente novamente." -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Pressione qualquer tecla para sair..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
