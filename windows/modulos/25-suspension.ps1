# Suspender y regresar al juego como en Switch / Steam Deck.
#
# El Ally X usa Modern Standby (S0ix): al presionar el botón de encendido el
# juego se queda en RAM y regresa en segundos. Lo que lo arruina en Windows:
#   1. se despierta solo (control, red, tareas) y se calienta en la mochila
#   2. se le acaba la batería suspendido y pierdes la partida
#   3. al regresar, el control no responde o el juego pierde el foco
# Este módulo ataca los tres.

Paso 'suspensión: botón de encendido'
# 1 = suspender, en corriente y en batería.
Set-Energia 'SUB_BUTTONS' 'PBUTTONACTION' 1 1
Ok 'botón de encendido = suspender'

Paso 'suspensión: que no se despierte solo'
# Temporizadores de activación: off en batería, solo importantes conectado.
Set-Energia 'SUB_SLEEP' 'RTCWAKE' 2 0
# Ningún dispositivo despierta al equipo (botones del control, touchpad, red).
# El botón de encendido no es un dispositivo de esta lista y sigue funcionando.
$armados = powercfg /devicequery wake_armed | Where-Object { $_ -and $_ -notmatch '^\s*(NONE|NINGUNO)\s*$' }
foreach ($d in $armados) {
  powercfg /devicedisablewake "$d" 2>$null
  if ($LASTEXITCODE -eq 0) {
    if ($script:Respaldo.despertar -notcontains $d) { $script:Respaldo.despertar += $d }
    $script:Cambios++
    Ok "ya no despierta: $d"
  }
}
if (-not $armados) { Ok 'ningún dispositivo puede despertarlo' }

Paso 'suspensión: hibernación de respaldo'
# El inicio rápido deja drivers a medio cargar (controles muertos, Wi-Fi que no
# regresa): se apaga. La hibernación sí se usa, pero solo como red de seguridad:
# tras 3 h suspendido con batería guarda la RAM al SSD y se apaga. Al encenderlo
# regresas al mismo punto del juego aunque pasen días.
powercfg /hibernate on
powercfg /hibernate /type full 2>$null
Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' 'HiberbootEnabled' 0
Set-Energia 'SUB_SLEEP' 'HIBERNATEIDLE' 0 10800
powercfg /setactive SCHEME_CURRENT
Ok 'inicio rápido off, hiberna tras 3 h suspendido en batería (conectado nunca)'

Paso 'suspensión: agente ally-pausa'
$herrDir = Join-Path $script:AllyDir 'herramientas'
New-Item -ItemType Directory -Force -Path $herrDir | Out-Null
foreach ($f in 'ally-pausa.ps1', 'arreglar-control.ps1') {
  Copy-Item (Join-Path $PSScriptRoot "..\herramientas\$f") $herrDir -Force
}
$pausa = Join-Path $herrDir 'ally-pausa.ps1'

# Corre al iniciar sesión, oculto, con permisos para reiniciar el control.
$accion = New-ScheduledTaskAction -Execute 'conhost.exe' `
  -Argument "--headless powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$pausa`""
$disparo = New-ScheduledTaskTrigger -AtLogOn -User "$env:USERDOMAIN\$env:USERNAME"
$quien = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Highest
$ajustes = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
  -ExecutionTimeLimit ([TimeSpan]::Zero) -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1) -MultipleInstances IgnoreNew
Register-ScheduledTask -TaskName 'Ally Pausa' -TaskPath '\Ally\' -Action $accion -Trigger $disparo `
  -Principal $quien -Settings $ajustes -Force | Out-Null
Start-ScheduledTask -TaskName 'Ally Pausa' -TaskPath '\Ally\'
Ok 'ally-pausa corriendo y programado al iniciar sesión'
Info 'al regresar de suspensión: revisa el control (lo reinicia si se cayó) y te devuelve al juego'
Info "bitácora: $(Join-Path $script:AllyDir 'logs\pausa.log')"

$menu = Join-Path ([Environment]::GetFolderPath('Programs')) 'Ally'
New-Item -ItemType Directory -Force -Path $menu | Out-Null
Nuevo-Acceso (Join-Path $menu 'Arreglar control.lnk') 'powershell.exe' `
  "-NoProfile -ExecutionPolicy Bypass -File `"$(Join-Path $herrDir 'arreglar-control.ps1')`"" $script:AllyDir 'shell32.dll,238'
Ok 'acceso "Arreglar control" en el menú inicio (carpeta Ally)'
