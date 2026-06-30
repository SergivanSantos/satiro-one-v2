# =============================================
# LIMPEZA DE ARQUIVOS ANTIGOS - OBRA WIZARD
# =============================================

Write-Host "🗑️  Iniciando limpeza dos arquivos antigos..." -ForegroundColor Yellow

$obraPath = "lib\features\obra"

# Deletar arquivos antigos
Remove-Item "$obraPath\models\obra_piso.dart" -ErrorAction SilentlyContinue
Remove-Item "$obraPath\models\obra_ambiente.dart" -ErrorAction SilentlyContinue
Remove-Item "$obraPath\models\obra_servico.dart" -ErrorAction SilentlyContinue
Remove-Item "$obraPath\models\piso_template.dart" -ErrorAction SilentlyContinue
Remove-Item "$obraPath\models\ambiente_template.dart" -ErrorAction SilentlyContinue
Remove-Item "$obraPath\models\sistema.dart" -ErrorAction SilentlyContinue
Remove-Item "$obraPath\providers\obra_wizard_provider.dart" -ErrorAction SilentlyContinue

# Deletar telas antigas
Remove-Item "$obraPath\screens\obra_wizard_step*.dart" -ErrorAction SilentlyContinue
Remove-Item "$obraPath\screens\obra_wizard_screen.dart" -ErrorAction SilentlyContinue

Write-Host "✅ Limpeza concluída!" -ForegroundColor Green
Write-Host "📂 Arquivos restantes em lib\features\obra:" -ForegroundColor Cyan

Get-ChildItem -Path $obraPath -Recurse | Select-Object FullName