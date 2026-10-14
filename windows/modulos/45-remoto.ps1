# Claude remoto siempre disponible (incluido en la instalación recomendada):
# abre Claude Code en modo remoto al iniciar sesión y lo reabre si se cae, para
# usarlo desde la app de Claude del celular.
# Corre SIN permisos de administrador a propósito: desde fuera no se pueden
# cambiar registro del sistema, servicios ni energía.

Paso 'remoto: Claude remoto al iniciar sesión'
$script = Join-Path $script:AllyDir 'herramientas\claude-remoto.ps1'
if (-not (Test-Path $script)) {
  Copy-Item (Join-Path $PSScriptRoot '..\herramientas\claude-remoto.ps1') $script -Force
}

$accion = New-ScheduledTaskAction -Execute 'powershell.exe' `
  -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Minimized -File `"$script`" -Reintentar"
$disparo = New-ScheduledTaskTrigger -AtLogOn -User "$env:USERDOMAIN\$env:USERNAME"
# Unos segundos después del inicio, cuando ya hay red.
$disparo.Delay = 'PT30S'
$quien = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Limited
$ajustes = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
  -ExecutionTimeLimit ([TimeSpan]::Zero) -MultipleInstances IgnoreNew
Register-ScheduledTask -TaskName 'Claude remoto' -TaskPath '\Ally\' -Action $accion -Trigger $disparo `
  -Principal $quien -Settings $ajustes -Force | Out-Null
Ok 'arranca minimizado al iniciar sesión y se reabre si se cae'
Info 'la primera vez ábrelo a mano ("Claude remoto" en el menú inicio) para iniciar sesión y aceptar el modo remoto'
