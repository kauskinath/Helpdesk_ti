# Script de Geracao de Keystore - PICHAU TI
# (C) 2024-2025 Pichau Informatica Ltda

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  GERADOR DE KEYSTORE - PICHAU TI" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar se keytool esta disponivel
$keytool = Get-Command keytool -ErrorAction SilentlyContinue
if (-not $keytool) {
    Write-Host "[ERRO] keytool nao encontrado!" -ForegroundColor Red
    Write-Host ""
    Write-Host "O keytool faz parte do JDK (Java Development Kit)." -ForegroundColor Yellow
    Write-Host "Instale o JDK e tente novamente." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Download: https://www.oracle.com/java/technologies/downloads/" -ForegroundColor Cyan
    exit 1
}

Write-Host "[OK] keytool encontrado!" -ForegroundColor Green
Write-Host ""

# Criar diretorio para keystores se nao existir
$keystoreDir = "C:\KeystoresPichau"
if (-not (Test-Path $keystoreDir)) {
    Write-Host "[INFO] Criando diretorio: $keystoreDir" -ForegroundColor Yellow
    New-Item -ItemType Directory -Force -Path $keystoreDir | Out-Null
    Write-Host "[OK] Diretorio criado!" -ForegroundColor Green
    Write-Host ""
}

# Configuracoes
$keystoreFile = "$keystoreDir\pichau-ti-release-key.jks"
$keyAlias = "pichau-ti-key"
$validity = 10000  # ~27 anos

Write-Host "[INFO] INFORMACOES DO KEYSTORE:" -ForegroundColor Cyan
Write-Host "   Arquivo: $keystoreFile"
Write-Host "   Alias: $keyAlias"
Write-Host "   Validade: $validity dias (~27 anos)"
Write-Host ""

# Verificar se keystore ja existe
if (Test-Path $keystoreFile) {
    Write-Host "[AVISO] Keystore ja existe!" -ForegroundColor Yellow
    Write-Host "   $keystoreFile" -ForegroundColor Yellow
    Write-Host ""
    $overwrite = Read-Host "Deseja sobrescrever? (S/N)"
    if ($overwrite -ne "S" -and $overwrite -ne "s") {
        Write-Host "[CANCELADO] Operacao cancelada." -ForegroundColor Red
        exit 0
    }
    Remove-Item $keystoreFile -Force
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  PREENCHA OS DADOS ABAIXO" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "[IMPORTANTE] Anote todas as senhas em local seguro!" -ForegroundColor Yellow
Write-Host ""

# Solicitar informacoes
Write-Host "[1] Senha do Keystore (minimo 6 caracteres):" -ForegroundColor Cyan
$storePassword = Read-Host -AsSecureString
$storePwdPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($storePassword))

Write-Host ""
Write-Host "[2] Senha da Key (pode ser a mesma ou diferente):" -ForegroundColor Cyan
$keyPassword = Read-Host -AsSecureString
$keyPwdPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($keyPassword))

Write-Host ""
Write-Host "[3] Nome completo (ex: Pichau Informatica):" -ForegroundColor Cyan
$cn = Read-Host

Write-Host ""
Write-Host "[4] Unidade Organizacional (ex: Departamento de TI):" -ForegroundColor Cyan
$ou = Read-Host

Write-Host ""
Write-Host "[5] Organizacao (ex: Pichau Informatica Ltda):" -ForegroundColor Cyan
$o = Read-Host

Write-Host ""
Write-Host "[6] Cidade:" -ForegroundColor Cyan
$l = Read-Host

Write-Host ""
Write-Host "[7] Estado (sigla, ex: SP):" -ForegroundColor Cyan
$st = Read-Host

Write-Host ""
Write-Host "[8] Pais (BR para Brasil):" -ForegroundColor Cyan
$c = Read-Host

# Construir DN (Distinguished Name)
$dname = "CN=$cn, OU=$ou, O=$o, L=$l, ST=$st, C=$c"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  GERANDO KEYSTORE..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Comando keytool
$keytoolArgs = @(
    "-genkeypair"
    "-v"
    "-keystore", $keystoreFile
    "-alias", $keyAlias
    "-keyalg", "RSA"
    "-keysize", "2048"
    "-validity", $validity
    "-dname", $dname
    "-storepass", $storePwdPlain
    "-keypass", $keyPwdPlain
)

try {
    & keytool $keytoolArgs
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  [OK] KEYSTORE GERADO COM SUCESSO!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "[INFO] Localizacao: $keystoreFile" -ForegroundColor Cyan
    Write-Host ""
    
    # Criar arquivo key.properties
    $keyPropsFile = ".\android\key.properties"
    $keyPropsContent = @"
storePassword=$storePwdPlain
keyPassword=$keyPwdPlain
keyAlias=$keyAlias
storeFile=$($keystoreFile -replace '\\', '/')
"@
    
    Write-Host "[INFO] Criando arquivo key.properties..." -ForegroundColor Yellow
    Set-Content -Path $keyPropsFile -Value $keyPropsContent -Encoding UTF8
    Write-Host "[OK] Arquivo criado: $keyPropsFile" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  PROXIMOS PASSOS" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. [OK] Keystore gerado: $keystoreFile"
    Write-Host "2. [OK] Arquivo key.properties criado"
    Write-Host "3. [IMPORTANTE] FACA BACKUP do keystore em 3+ locais seguros"
    Write-Host "4. [IMPORTANTE] ANOTE as senhas em cofre de senhas"
    Write-Host "5. [OK] Execute: flutter build apk --release"
    Write-Host ""
    
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "  IMPORTANTE - LEIA COM ATENCAO!" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "[NUNCA] compartilhe o arquivo .jks" -ForegroundColor Red
    Write-Host "[NUNCA] commite key.properties no Git" -ForegroundColor Red
    Write-Host "[NUNCA] perca o backup do keystore" -ForegroundColor Red
    Write-Host ""
    Write-Host "Se perder o keystore, NAO SERA POSSIVEL atualizar" -ForegroundColor Red
    Write-Host "o app na Play Store!" -ForegroundColor Red
    Write-Host ""
    
} catch {
    Write-Host ""
    Write-Host "[ERRO] ao gerar keystore:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    exit 1
}

Write-Host "Pressione qualquer tecla para sair..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
