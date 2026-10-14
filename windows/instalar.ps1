<#
.SYNOPSIS
  Deja un ROG Ally X con Windows 11 rápido, limpio y con Claude integrado.

.DESCRIPTION
  Corre por módulos. Sin parámetros aplica los recomendados después de
  preguntarte. Todo cambio de registro y servicios queda respaldado en
  %USERPROFILE%\ally\respaldo.json y se deshace con revertir.ps1.

.EXAMPLE
  .\instalar.ps1                          # recomendados, con confirmación
  .\instalar.ps1 -Apps                    # además Steam, Playnite y Heroic
  .\instalar.ps1 -Modulos claude          # solo un módulo
  .\instalar.ps1 -Agresivo -SinPreguntar  # todo, incluido apagar VBS
#>
[CmdletBinding()]
param(
  [string[]]$Modulos,
  [switch]$Apps,
  [switch]$Agresivo,
  [switch]$SinPreguntar
)

$ErrorActionPreference = 'Continue'
. (Join-Path $PSScriptRoot 'lib\comun.ps1')

# Reabrir como administrador conservando los parámetros.
if (-not (Test-Admin)) {
  $argumentos = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"")
  if ($Modulos)      { $argumentos += @('-Modulos', ($Modulos -join ',')) }
  if ($Apps)         { $argumentos += '-Apps' }
  if ($Agresivo)     { $argumentos += '-Agresivo' }
  if ($SinPreguntar) { $argumentos += '-SinPreguntar' }
  Start-Process powershell.exe -Verb RunAs -ArgumentList $argumentos
  exit
}

$descripcion = [ordered]@{
  rendimiento = 'modo juego, GPU, captura en fondo apagada, energía del USB y suspensión'
  limpieza    = 'quita apps preinstaladas, widgets, Copilot, Recall, anuncios y telemetría opcional'
  handheld    = 'teclado táctil, hibernación, revisa Armoury Crate, BIOS y drivers'
  claude      = 'app Claude, Claude Code, Windows Terminal, carpeta ~\ally con comandos'
  apps        = 'Steam, Playnite y Heroic'
  agresivo    = 'apaga VBS / Memory Integrity (más FPS, menos protección)'
}

# Al reabrirse como admin llegan como "a,b"; se normaliza aquí.
$Modulos = @($Modulos | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim().ToLower() } | Where-Object { $_ })
$desconocidos = $Modulos | Where-Object { -not $descripcion.Contains($_) }
if ($desconocidos) {
  Write-Host "módulos desconocidos: $($desconocidos -join ', ')" -ForegroundColor Red
  Write-Host "disponibles: $($descripcion.Keys -join ', ')"
  exit 1
}

if (-not $Modulos) {
  $Modulos = @('rendimiento', 'limpieza', 'handheld', 'claude')
  if ($Apps)     { $Modulos += 'apps' }
  if ($Agresivo) { $Modulos += 'agresivo' }
}

Clear-Host
Write-Host 'ally-x para windows 11' -ForegroundColor Cyan
Write-Host 'se va a aplicar:'
foreach ($m in $Modulos) { Write-Host ("  - {0,-12} {1}" -f $m, $descripcion[$m]) }

if (-not $SinPreguntar) {
  $r = Read-Host "`n¿le damos? (s/n)"
  if ($r -notmatch '^[sSyY]') { Write-Host 'cancelado, no se cambió nada.'; exit }
}

Abrir-Respaldo
$logDir = Join-Path $script:AllyDir 'logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
Start-Transcript -Path (Join-Path $logDir ("instalar-{0:yyyyMMdd-HHmmss}.log" -f (Get-Date))) | Out-Null

Paso 'punto de restauración'
try {
  Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction Stop
  # Windows limita a uno cada 24 h; esto lo permite siempre.
  Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore' 'SystemRestorePointCreationFrequency' 0
  Checkpoint-Computer -Description 'antes de ally-x' -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
  Ok 'creado'
} catch {
  Aviso "no se pudo crear: $($_.Exception.Message)"
  if (-not $SinPreguntar) {
    $r = Read-Host 'sin punto de restauración igual queda el respaldo de registro. ¿sigo? (s/n)'
    if ($r -notmatch '^[sSyY]') { Stop-Transcript | Out-Null; exit }
  }
}

$orden = @{ rendimiento = 10; limpieza = 20; handheld = 30; claude = 40; apps = 50; agresivo = 90 }
foreach ($m in ($Modulos | Sort-Object { $orden[$_] })) {
  $archivo = Get-ChildItem (Join-Path $PSScriptRoot 'modulos') -Filter "*-$m.ps1" | Select-Object -First 1
  try {
    . $archivo.FullName
  } catch {
    Aviso "el módulo $m falló: $($_.Exception.Message)"
  }
  Guardar-Respaldo
}

Paso 'listo'
Info "$($script:Cambios) cambios aplicados. respaldo: $($script:RespaldoArc)"
Info "para deshacer: .\revertir.ps1"
Write-Host @'

siguientes pasos
  1. reinicia el Ally X
  2. Armoury Crate SE → Contenido → Update Center: BIOS, MCU y drivers al día
  3. abre "Claude" e inicia sesión; luego "Claude Code (Ally)" y también inicia sesión
  4. dentro de Claude Code prueba:  /diagnostico
'@
Stop-Transcript | Out-Null
if (-not $SinPreguntar) { Read-Host "`nenter para cerrar" | Out-Null }
