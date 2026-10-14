<#
.SYNOPSIS
  Deshace lo que hizo instalar.ps1 usando %USERPROFILE%\ally\respaldo.json.

.DESCRIPTION
  Restaura cada valor de registro y tipo de arranque de servicio a como estaba
  antes de la primera ejecución, y regresa la energía a valores de Windows.
  No reinstala apps quitadas (están en la Microsoft Store) ni desinstala Claude.
#>
[CmdletBinding()]
param([switch]$SinPreguntar)

$ErrorActionPreference = 'Continue'
$lib = @("$PSScriptRoot\lib\comun.ps1", "$PSScriptRoot\..\lib\comun.ps1") | Where-Object { Test-Path $_ } | Select-Object -First 1
. $lib

if (-not (Test-Admin)) {
  $a = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"")
  if ($SinPreguntar) { $a += '-SinPreguntar' }
  Start-Process powershell.exe -Verb RunAs -ArgumentList $a
  exit
}

if (-not (Test-Path $script:RespaldoArc)) {
  Write-Host "no hay respaldo en $($script:RespaldoArc); nada que revertir." -ForegroundColor Red
  exit 1
}
Abrir-Respaldo
$n = $script:Respaldo.registro.Count + $script:Respaldo.servicios.Count + @($script:Respaldo.despertar).Count
Write-Host "se van a restaurar $n valores a como estaban antes de ally-x."
if (-not $SinPreguntar -and (Read-Host '¿sigo? (s/n)') -notmatch '^[sSyY]') { exit }

Paso 'registro'
foreach ($e in $script:Respaldo.registro.Values) {
  try {
    if ($e.Existia) {
      if (-not (Test-Path $e.Path)) { New-Item -Path $e.Path -Force | Out-Null }
      Set-ItemProperty -Path $e.Path -Name $e.Name -Value $e.Valor -Type $e.Tipo
    } elseif (Test-Path $e.Path) {
      Remove-ItemProperty -Path $e.Path -Name $e.Name -ErrorAction SilentlyContinue
    }
  } catch {
    Aviso "$($e.Path)\$($e.Name): $($_.Exception.Message)"
  }
}
Ok "$($script:Respaldo.registro.Count) valores"

Paso 'servicios'
foreach ($nombre in $script:Respaldo.servicios.Keys) {
  $inicio = $script:Respaldo.servicios[$nombre]
  if ($inicio -eq 'AutomaticDelayedStart') { $inicio = 'Automatic' }
  Set-Service -Name $nombre -StartupType $inicio -ErrorAction SilentlyContinue
  if ($inicio -eq 'Automatic') { Start-Service -Name $nombre -ErrorAction SilentlyContinue }
  Ok "$nombre → $inicio"
}

Paso 'suspensión'
Unregister-ScheduledTask -TaskName 'Ally Pausa' -TaskPath '\Ally\' -Confirm:$false -ErrorAction SilentlyContinue
Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe'" -ErrorAction SilentlyContinue |
  Where-Object CommandLine -match 'ally-pausa\.ps1' | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
Ok 'agente ally-pausa detenido y quitado'
foreach ($d in $script:Respaldo.despertar) {
  powercfg /deviceenablewake "$d" 2>$null
  Ok "puede despertar otra vez: $d"
}
$script:Respaldo.despertar = @()
powercfg /setacvalueindex SCHEME_CURRENT SUB_SLEEP RTCWAKE 1
powercfg /setdcvalueindex SCHEME_CURRENT SUB_SLEEP RTCWAKE 1

Paso 'energía'
powercfg /hibernate on
powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 1
powercfg /setdcvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 1
powercfg /setacvalueindex SCHEME_CURRENT fea3413e-7e05-4911-9a71-700331f1c294 f15576e8-98b7-4186-b944-eafa664402d9 2
powercfg /setdcvalueindex SCHEME_CURRENT fea3413e-7e05-4911-9a71-700331f1c294 f15576e8-98b7-4186-b944-eafa664402d9 2
powercfg /change monitor-timeout-dc 5
powercfg /change standby-timeout-dc 15
powercfg /setactive SCHEME_CURRENT
Ok 'valores de Windows'

Move-Item $script:RespaldoArc ($script:RespaldoArc -replace '\.json$', "-restaurado-$(Get-Date -Format yyyyMMdd-HHmmss).json") -Force
Paso 'listo, reinicia para que todo aplique'
if (-not $SinPreguntar) { Read-Host 'enter para cerrar' | Out-Null }
