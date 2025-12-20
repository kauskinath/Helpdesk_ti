# Script de Deploy das Cloud Functions
# Helpdesk TI - Notificações em Background

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  DEPLOY CLOUD FUNCTIONS - HELPDESK TI" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar se esta no diretorio correto
if (-not (Test-Path "functions\index.js")) {
    Write-Host "ERRO: Execute este script na pasta raiz do projeto!" -ForegroundColor Red
    Write-Host "   Caminho correto: C:\Users\User\Desktop\PROJETOS\helpdesk_ti" -ForegroundColor Yellow
    exit 1
}

Write-Host "Passo 1: Verificando dependencias..." -ForegroundColor Yellow
Set-Location functions

if (-not (Test-Path "node_modules")) {
    Write-Host "   Instalando dependencias (primeira vez)..." -ForegroundColor White
    npm install
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Erro ao instalar dependencias!" -ForegroundColor Red
        exit 1
    }
    Write-Host "Dependencias instaladas!" -ForegroundColor Green
} else {
    Write-Host "Dependencias ja instaladas!" -ForegroundColor Green
}

Set-Location ..

Write-Host ""
Write-Host "Passo 2: Verificando autenticacao Firebase..." -ForegroundColor Yellow
$null = firebase projects:list 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Voce nao esta logado no Firebase!" -ForegroundColor Red
    Write-Host "   Execute: firebase login" -ForegroundColor Yellow
    exit 1
}
Write-Host "Autenticado!" -ForegroundColor Green

Write-Host ""
Write-Host "Passo 3: Fazendo deploy das Cloud Functions..." -ForegroundColor Yellow
Write-Host "   Projeto: helpdesk-ti-4bbf2" -ForegroundColor White
Write-Host "   Isso pode levar 2-5 minutos..." -ForegroundColor White
Write-Host ""

firebase deploy --only functions

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  DEPLOY CONCLUIDO COM SUCESSO!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Functions deployadas:" -ForegroundColor Cyan
    Write-Host "   1. notificarNovoChamado" -ForegroundColor White
    Write-Host "   2. notificarAtualizacaoChamado" -ForegroundColor White
    Write-Host "   3. notificarNovoComentario" -ForegroundColor White
    Write-Host "   4. limparTokensInvalidos" -ForegroundColor White
    Write-Host ""
    Write-Host "Verificar no console:" -ForegroundColor Cyan
    Write-Host "   https://console.firebase.google.com/project/helpdesk-ti-4bbf2/functions" -ForegroundColor Blue
    Write-Host ""
    Write-Host "Ver logs em tempo real:" -ForegroundColor Cyan
    Write-Host "   firebase functions:log" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Proximos passos:" -ForegroundColor Cyan
    Write-Host "   1. Teste criar um chamado com app fechado" -ForegroundColor White
    Write-Host "   2. Verifique se recebeu a notificacao push" -ForegroundColor White
    Write-Host "   3. Monitore os logs por erros" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "  ERRO NO DEPLOY" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Possiveis causas:" -ForegroundColor Yellow
    Write-Host "1. Voce nao fez upgrade para Blaze Plan" -ForegroundColor White
    Write-Host "   Solucao: https://console.firebase.google.com/project/helpdesk-ti-4bbf2/usage" -ForegroundColor Blue
    Write-Host ""
    Write-Host "2. Erro de autenticacao" -ForegroundColor White
    Write-Host "   Solucao: firebase logout; firebase login" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "3. Erro nas dependencias" -ForegroundColor White
    Write-Host "   Solucao: Set-Location functions; npm install" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Consulte o guia completo: GUIA_CLOUD_FUNCTIONS.md" -ForegroundColor Cyan
    exit 1
}
