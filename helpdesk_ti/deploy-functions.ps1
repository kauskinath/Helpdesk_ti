# Script de Deploy das Cloud Functions
# Execute este script do diretório raiz do projeto

Write-Host "🚀 Iniciando deploy das Cloud Functions..." -ForegroundColor Cyan
Write-Host ""

# Verificar se Firebase CLI está instalado
Write-Host "🔍 Verificando Firebase CLI..." -ForegroundColor Yellow
$firebaseInstalled = Get-Command firebase -ErrorAction SilentlyContinue
if (-not $firebaseInstalled) {
    Write-Host "❌ Firebase CLI não encontrado!" -ForegroundColor Red
    Write-Host "   Instale com: npm install -g firebase-tools" -ForegroundColor Yellow
    exit 1
}
Write-Host "✅ Firebase CLI encontrado" -ForegroundColor Green
Write-Host ""

# Verificar se está logado no Firebase
Write-Host "🔍 Verificando login no Firebase..." -ForegroundColor Yellow
firebase projects:list 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  Você não está logado no Firebase" -ForegroundColor Yellow
    Write-Host "   Executando firebase login..." -ForegroundColor Cyan
    firebase login
}
Write-Host "✅ Logado no Firebase" -ForegroundColor Green
Write-Host ""

# Navegar para pasta functions
Write-Host "📂 Navegando para pasta functions..." -ForegroundColor Yellow
if (-not (Test-Path "functions")) {
    Write-Host "❌ Pasta functions não encontrada!" -ForegroundColor Red
    exit 1
}
Set-Location functions

# Instalar dependências
Write-Host "📦 Instalando dependências do Node.js..." -ForegroundColor Yellow
npm install
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erro ao instalar dependências!" -ForegroundColor Red
    Set-Location ..
    exit 1
}
Write-Host "✅ Dependências instaladas" -ForegroundColor Green
Write-Host ""

# Voltar para raiz
Set-Location ..

# Fazer deploy
Write-Host "🚀 Fazendo deploy das Cloud Functions..." -ForegroundColor Cyan
Write-Host "   (Isso pode levar alguns minutos...)" -ForegroundColor Yellow
Write-Host ""
firebase deploy --only functions

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "🎉 Deploy concluído com sucesso!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Próximos passos:" -ForegroundColor Cyan
    Write-Host "   1. Crie o índice do Firestore (clique no link do erro ou siga o guia)" -ForegroundColor White
    Write-Host "   2. Reconstrua o APK: flutter build apk --split-per-abi --release" -ForegroundColor White
    Write-Host "   3. Teste criando um novo chamado" -ForegroundColor White
    Write-Host ""
    Write-Host "📖 Consulte: GUIA_CONFIGURACAO_NOTIFICACOES.md" -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "❌ Erro no deploy!" -ForegroundColor Red
    Write-Host "   Verifique os erros acima" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "💡 Dica: Certifique-se que seu projeto Firebase está no plano Blaze" -ForegroundColor Yellow
    exit 1
}
