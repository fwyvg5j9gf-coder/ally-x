<#
.SYNOPSIS
  Abre Claude Code en modo remoto dentro de %USERPROFILE%\ally para que puedas
  usarlo desde la app de Claude en tu celular (sección Code).

.PARAMETER Reintentar
  Si la sesión se cae (suspensión, sin internet), la vuelve a abrir sola.
  Lo usa la tarea "Claude remoto" que arranca al iniciar sesión.
#>
param([switch]$Reintentar)

$ally = Join-Path $env:USERPROFILE 'ally'
$claude = Join-Path $env:USERPROFILE '.local\bin\claude.exe'
if (-not (Test-Path $claude)) { $claude = (Get-Command claude -ErrorAction SilentlyContinue).Source }
if (-not $claude) {
  Write-Host 'no encontré Claude Code. corre instalar.ps1 -Modulos claude' -ForegroundColor Red
  Read-Host 'enter para cerrar' | Out-Null
  exit 1
}

$log = Join-Path $ally 'logs\remoto.log'
New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null
function Log($m) { Add-Content -Path $log -Value ("{0:yyyy-MM-dd HH:mm:ss}  {1}" -f (Get-Date), $m) -Encoding UTF8 }

Set-Location $ally
$host.UI.RawUI.WindowTitle = 'Claude remoto (Ally)'
Write-Host 'Claude remoto: abre la app de Claude en tu celular → Code, y elige esta sesión.' -ForegroundColor Cyan
Write-Host 'cerrar esta ventana corta el acceso remoto.' -ForegroundColor Gray

do {
  Log 'sesión remota iniciada'
  & $claude remote-control
  Log "sesión remota terminó (código $LASTEXITCODE)"
  if ($Reintentar) {
    Write-Host 'la sesión se cerró; reintento en 30 s...' -ForegroundColor DarkYellow
    Start-Sleep -Seconds 30
  }
} while ($Reintentar)
