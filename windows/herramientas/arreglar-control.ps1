<#
.SYNOPSIS
  Reinicia el control integrado del ROG Xbox Ally X (también Ally / Ally X)
  sin reiniciar el equipo.
  Úsalo cuando los botones dejan de responder (típico tras suspender).
#>
$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).
  IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $admin) {
  Start-Process powershell.exe -Verb RunAs -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`""
  exit
}

$dev = Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue |
  Where-Object InstanceId -match '^USB\\VID_0B05&PID_(1B4C|1ABE)\\' | Select-Object -First 1
if ($dev) {
  Write-Host "reiniciando $($dev.FriendlyName)..."
  pnputil /restart-device "$($dev.InstanceId)"
} else {
  Write-Host 'no encontré el control; buscando dispositivos de nuevo...'
  pnputil /scan-devices
}
$log = Join-Path $env:USERPROFILE 'ally\logs\pausa.log'
Add-Content -Path $log -Value ("{0:yyyy-MM-dd HH:mm:ss}  arreglar-control manual: {1}" -f (Get-Date), $(if ($dev) { $dev.InstanceId } else { 'no encontrado' })) -Encoding UTF8 -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
