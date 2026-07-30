Clear-Host

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "        ATLAS DEV KIT v1.0" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Bienvenido Marcos 👋" -ForegroundColor Green
Write-Host ""
Write-Host "Comprobando Git..."

if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-Host "[OK] Git instalado" -ForegroundColor Green
}
else {
    Write-Host "[ERROR] Git no encontrado" -ForegroundColor Red
}
Write-Host ""
Write-Host "Comprobando Node.js..."

if (Get-Command node -ErrorAction SilentlyContinue) {
    Write-Host "[OK] Node.js instalado" -ForegroundColor Green
}
else {
    Write-Host "[ERROR] Node.js no encontrado" -ForegroundColor Red
}
Write-Host ""
Write-Host "Comprobando npm..."

if (Get-Command npm -ErrorAction SilentlyContinue) {
    Write-Host "[OK] npm instalado" -ForegroundColor Green
}
else {
    Write-Host "[ERROR] npm no encontrado" -ForegroundColor Red
}