<#
.SYNOPSIS
  Junta el estado del Ally X en %USERPROFILE%\ally\diagnostico.txt para que
  Claude lo analice. Solo lee; no cambia nada.

.PARAMETER Abrir
  Al terminar abre el archivo (lo usa el acceso directo "Ally Doctor").
#>
param([switch]$Abrir)

$ally = Join-Path $env:USERPROFILE 'ally'
$out  = Join-Path $ally 'diagnostico.txt'
$rep  = Join-Path $ally 'reportes'
New-Item -ItemType Directory -Force -Path $rep | Out-Null
$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).
  IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

function Seccion($t) { "`n===== $t =====" }
function Tabla { $input | Format-Table -AutoSize -Wrap | Out-String -Width 200 }
function Lista { $input | Format-List | Out-String -Width 200 }

Write-Host 'revisando el Ally X...'
& {
  "diagnóstico ally-x — $(Get-Date -Format 'yyyy-MM-dd HH:mm')   (admin: $admin)"

  Seccion 'equipo'
  $os = Get-CimInstance Win32_OperatingSystem
  $bios = Get-CimInstance Win32_BIOS
  $cs = Get-CimInstance Win32_ComputerSystem
  "modelo:      $($cs.Manufacturer) $($cs.Model)"
  "windows:     $($os.Caption) $($os.Version) build $($os.BuildNumber)"
  "BIOS:        $($bios.SMBIOSBIOSVersion) ($('{0:yyyy-MM-dd}' -f $bios.ReleaseDate))"
  "encendido:   desde $('{0:yyyy-MM-dd HH:mm}' -f $os.LastBootUpTime) ($([int]((Get-Date) - $os.LastBootUpTime).TotalHours) h)"
  "memoria:     $([math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory)/1MB,1)) de $([math]::Round($os.TotalVisibleMemorySize/1MB,1)) GB en uso"

  Seccion 'gráficos y pantalla'
  Get-CimInstance Win32_VideoController | Select-Object Name, DriverVersion,
    @{n='DriverFecha';e={'{0:yyyy-MM-dd}' -f $_.DriverDate}},
    @{n='Resolucion';e={"$($_.CurrentHorizontalResolution)x$($_.CurrentVerticalResolution)"}},
    @{n='Hz';e={$_.CurrentRefreshRate}} | Tabla
  "HAGS (HwSchMode): $((Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' -ErrorAction SilentlyContinue).HwSchMode)"
  "DirectX global:   $((Get-ItemProperty 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences' -ErrorAction SilentlyContinue).DirectXUserGlobalSettings)"

  Seccion 'batería'
  $b = Get-CimInstance Win32_Battery
  if ($b) { "carga: $($b.EstimatedChargeRemaining) %   estado: $($b.BatteryStatus) (1=descargando, 2=conectado)" }
  $diseno = (Get-CimInstance -Namespace root\wmi -ClassName BatteryStaticData -ErrorAction SilentlyContinue).DesignedCapacity
  $llena  = (Get-CimInstance -Namespace root\wmi -ClassName BatteryFullChargedCapacity -ErrorAction SilentlyContinue).FullChargedCapacity
  if ($diseno -and $llena) {
    "salud: $([math]::Round(100 * $llena / $diseno)) %  ($llena de $diseno mWh de diseño)"
  }
  $bat = Join-Path $rep 'bateria.html'
  powercfg /batteryreport /output $bat 2>&1 | Out-Null
  "reporte de batería: $bat"
  if ($admin) {
    $sleep = Join-Path $rep 'suspension.html'
    powercfg /sleepstudy /output $sleep 2>&1 | Out-Null
    "estudio de suspensión: $sleep"
  } else {
    "estudio de suspensión: requiere correr como administrador"
  }

  Seccion 'energía'
  powercfg /getactivescheme
  powercfg /a
  "suspensión selectiva USB (0x0 = off):"
  powercfg /q SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 |
    Select-String 'Index' | ForEach-Object { "  $($_.Line.Trim())" }
  "hibernación: $(if (Test-Path "$env:SystemDrive\hiberfil.sys") { 'on' } else { 'off' })"

  Seccion 'software de ASUS'
  Get-AppxPackage -Name '*ArmouryCrate*' -ErrorAction SilentlyContinue | Select-Object Name, Version | Tabla
  Get-Service -Name '*Armoury*', 'ASUS*' -ErrorAction SilentlyContinue | Select-Object Name, Status, StartType | Tabla

  Seccion 'dispositivos con problema'
  $malos = Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue | Where-Object Status -ne 'OK'
  if ($malos) { $malos | Select-Object FriendlyName, Class, Status, InstanceId | Tabla } else { 'ninguno' }

  Seccion 'procesos (CPU acumulada)'
  Get-Process | Sort-Object CPU -Descending | Select-Object -First 15 Name, Id,
    @{n='CPU_s';e={[int]$_.CPU}}, @{n='MemMB';e={[int]($_.WorkingSet64/1MB)}} | Tabla

  Seccion 'procesos (memoria)'
  Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 10 Name,
    @{n='MemMB';e={[int]($_.WorkingSet64/1MB)}} | Tabla

  Seccion 'arranque automático'
  Get-CimInstance Win32_StartupCommand | Select-Object Name, Location, Command | Tabla

  Seccion 'suspensión y reanudación (últimos 20)'
  Get-WinEvent -FilterHashtable @{ LogName = 'System'; ProviderName = 'Microsoft-Windows-Kernel-Power', 'Microsoft-Windows-Power-Troubleshooter' } -MaxEvents 20 -ErrorAction SilentlyContinue |
    Select-Object TimeCreated, Id, @{n='Mensaje';e={($_.Message -split "`n")[0]}} | Tabla

  Seccion 'errores críticos del sistema (7 días)'
  Get-WinEvent -FilterHashtable @{ LogName = 'System'; Level = 1, 2; StartTime = (Get-Date).AddDays(-7) } -MaxEvents 30 -ErrorAction SilentlyContinue |
    Group-Object ProviderName, Id | Sort-Object Count -Descending |
    Select-Object Count, Name, @{n='Ejemplo';e={($_.Group[0].Message -split "`n")[0]}} | Tabla

  Seccion 'crashes de apps (7 días)'
  Get-WinEvent -FilterHashtable @{ LogName = 'Application'; Id = 1000; StartTime = (Get-Date).AddDays(-7) } -MaxEvents 20 -ErrorAction SilentlyContinue |
    ForEach-Object { $_.Properties[0].Value } | Group-Object | Sort-Object Count -Descending | Select-Object Count, Name | Tabla

  Seccion 'seguridad del núcleo'
  Get-CimInstance -Namespace root\Microsoft\Windows\DeviceGuard -ClassName Win32_DeviceGuard -ErrorAction SilentlyContinue |
    Select-Object @{n='VBS';e={@('off','configurado','corriendo')[$_.VirtualizationBasedSecurityStatus]}},
                  @{n='Servicios';e={$_.SecurityServicesRunning -join ','}} | Lista

  Seccion 'disco'
  Get-Volume | Where-Object DriveLetter | Select-Object DriveLetter, FileSystemLabel,
    @{n='LibreGB';e={[int]($_.SizeRemaining/1GB)}}, @{n='TotalGB';e={[int]($_.Size/1GB)}} | Tabla

  Seccion 'ally-x'
  $resp = Join-Path $ally 'respaldo.json'
  "respaldo de ajustes: $(if (Test-Path $resp) { $resp } else { 'no hay (instalar.ps1 no se ha corrido)' })"
} *>&1 | Out-File -FilePath $out -Encoding utf8

Write-Host "listo: $out"
if ($Abrir) { Start-Process notepad.exe $out }
