# Script de Deploy para Firebase Hosting
# Helpdesk TI - Versão Web

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  DEPLOY - HELPDESK TI WEB" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar se está no diretório correto
if (-not (Test-Path "pubspec.yaml")) {
    Write-Host "ERRO: Execute este script na raiz do projeto Flutter!" -ForegroundColor Red
    exit 1
}

# Passo 1: Limpar builds anteriores
Write-Host "[1/4] Limpando builds anteriores..." -ForegroundColor Yellow
flutter clean
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: Falha ao limpar o projeto!" -ForegroundColor Red
    exit 1
}

# Passo 2: Obter dependências
Write-Host ""
Write-Host "[2/4] Obtendo dependências..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: Falha ao obter dependências!" -ForegroundColor Red
    exit 1
}

# Passo 3: Build da versão web
Write-Host ""
Write-Host "[3/4] Gerando build web em modo release..." -ForegroundColor Yellow
flutter build web --release -t lib/main_web.dart
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: Falha ao gerar build web!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Build web gerado com sucesso!" -ForegroundColor Green
Write-Host "Arquivos em: build/web" -ForegroundColor Gray

# Passo 4: Deploy no Firebase Hosting
Write-Host ""
Write-Host "[4/4] Realizando deploy no Firebase Hosting..." -ForegroundColor Yellow
firebase deploy --only hosting
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: Falha no deploy do Firebase!" -ForegroundColor Red
    Write-Host "Verifique se você está logado: firebase login" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  DEPLOY CONCLUÍDO COM SUCESSO!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Sua aplicação está disponível em:" -ForegroundColor Cyan
Write-Host "https://helpdesk-ti-4bbf2.web.app" -ForegroundColor White
Write-Host "https://helpdesk-ti-4bbf2.firebaseapp.com" -ForegroundColor White
Write-Host ""
