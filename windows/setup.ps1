<#
  Limpieza segura + ajustes de rendimiento para ROG Ally X en Windows 11,
  e instalación de Claude (app de escritorio + Claude Code).

  Uso (PowerShell como administrador):
    Set-ExecutionPolicy -Scope Process Bypass -Force
    .\setup.ps1             # ajustes seguros
    .\setup.ps1 -Agresivo   # además desactiva VBS/HVCI (más FPS, menos seguridad)

  Todo lo que toca se puede revertir; ver comentarios de cada bloque.
#>
param([switch]$Agresivo)

$ErrorActionPreference = 'Continue'
function Say($msg) { Write-Host "`n==> $msg" -ForegroundColor Yellow }
function Set-Reg($path, $name, $value, $type = 'DWord') {
  if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
  Set-ItemProperty -Path $path -Name $name -Value $value -Type $type
}

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).
  IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { Write-Error 'corre PowerShell como administrador.'; exit 1 }

$KitDir  = Split-Path -Parent $PSScriptRoot
$AllyDir = Join-Path $env:USERPROFILE 'ally'

Say 'punto de restauración'
Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue
Checkpoint-Computer -Description 'antes de ally-x setup' -RestorePointType MODIFY_SETTINGS -ErrorAction SilentlyContinue

Say 'modo juego on, game dvr off'
# revertir: borrar estos valores o ponerlos en 1/0 inverso
Set-Reg 'HKCU:\Software\Microsoft\GameBar' 'AutoGameModeEnabled' 1
Set-Reg 'HKCU:\Software\Microsoft\GameBar' 'AllowAutoGameMode' 1
Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 0
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 0

Say 'programación de GPU acelerada por hardware'
Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' 'HwSchMode' 2

Say 'menos ruido de fondo: widgets, sugerencias, copilot en barra, telemetría opcional'
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' 'AllowNewsAndInterests' 0
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ShowCopilotButton' 0
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-338388Enabled' 0
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SystemPaneSuggestionsEnabled' 0
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry' 1  # 1 = solo datos requeridos
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications' 'GlobalUserDisabled' 1

Say 'hibernación off (libera ~24 GB y evita fallas al reanudar)'
# revertir: powercfg /hibernate on
powercfg /hibernate off

if ($Agresivo) {
  Say 'desactivando VBS / Memory Integrity (requiere reiniciar)'
  # revertir: Seguridad de Windows → Seguridad del dispositivo → Aislamiento del núcleo → on
  Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity' 'Enabled' 0
  Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard' 'EnableVirtualizationBasedSecurity' 0
}

Say 'instalando Git, app de Claude y Claude Code'
if (Get-Command winget -ErrorAction SilentlyContinue) {
  winget install --id Git.Git -e --accept-source-agreements --accept-package-agreements --silent
  winget install --id Anthropic.Claude -e --accept-source-agreements --accept-package-agreements --silent
} else {
  Write-Warning 'winget no está disponible; instala "App Installer" desde la Microsoft Store.'
}
# Claude Code se instala por usuario, no requiere admin
Invoke-RestMethod https://claude.ai/install.ps1 | Invoke-Expression

Say "contexto del dispositivo en $AllyDir"
New-Item -ItemType Directory -Force -Path $AllyDir | Out-Null
Copy-Item (Join-Path $KitDir 'claude\CLAUDE.md') (Join-Path $AllyDir 'CLAUDE.md') -Force
Copy-Item (Join-Path $PSScriptRoot 'ally-doctor.ps1') (Join-Path $AllyDir 'ally-doctor.ps1') -Force

$shell = New-Object -ComObject WScript.Shell
$lnk = $shell.CreateShortcut((Join-Path ([Environment]::GetFolderPath('Desktop')) 'Claude Code (Ally).lnk'))
$lnk.TargetPath = 'powershell.exe'
$lnk.Arguments = '-NoExit -Command "Set-Location $env:USERPROFILE\ally; claude"'
$lnk.WorkingDirectory = $AllyDir
$lnk.Save()

Say 'listo — reinicia el Ally X'
@"
siguientes pasos:
  1. Armoury Crate → Update Center: actualiza BIOS, MCU y drivers
  2. abre "Claude" (menú inicio) e inicia sesión
  3. acceso "Claude Code (Ally)" en el escritorio → inicia sesión la primera vez
  4. si algo falla:  ~\ally\ally-doctor.ps1  y luego  claude "lee diagnostico.txt"
"@ | Write-Host
