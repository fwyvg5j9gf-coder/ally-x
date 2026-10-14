# Junta diagnósticos del Ally X en %USERPROFILE%\ally\diagnostico.txt para Claude.
# Solo lectura: no cambia nada del sistema.
$Out = Join-Path $env:USERPROFILE 'ally\diagnostico.txt'
New-Item -ItemType Directory -Force -Path (Split-Path $Out) | Out-Null
$tmp = Join-Path $env:TEMP 'ally-battery.html'

& {
  "diagnóstico ally-x — $(Get-Date -Format o)"

  "`n===== sistema ====="
  Get-CimInstance Win32_OperatingSystem | Select-Object Caption, Version, LastBootUpTime | Format-List | Out-String
  Get-CimInstance Win32_BIOS | Select-Object SMBIOSBIOSVersion, ReleaseDate | Format-List | Out-String

  "`n===== batería ====="
  Get-CimInstance Win32_Battery | Select-Object EstimatedChargeRemaining, BatteryStatus | Format-List | Out-String
  powercfg /batteryreport /output $tmp | Out-Null
  "reporte completo: $tmp"

  "`n===== plan de energía ====="
  powercfg /getactivescheme

  "`n===== procesos que más consumen ====="
  Get-Process | Sort-Object CPU -Descending | Select-Object -First 15 Name, Id, CPU,
    @{n='MemMB';e={[int]($_.WorkingSet64/1MB)}} | Format-Table | Out-String

  "`n===== arranque automático ====="
  Get-CimInstance Win32_StartupCommand | Select-Object Name, Command | Format-Table -AutoSize | Out-String

  "`n===== suspensión (últimos eventos) ====="
  Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='Microsoft-Windows-Power-Troubleshooter','Microsoft-Windows-Kernel-Power'} -MaxEvents 20 -ErrorAction SilentlyContinue |
    Select-Object TimeCreated, Id, Message | Format-List | Out-String

  "`n===== errores del sistema (24 h) ====="
  Get-WinEvent -FilterHashtable @{LogName='System'; Level=1,2; StartTime=(Get-Date).AddDays(-1)} -MaxEvents 30 -ErrorAction SilentlyContinue |
    Select-Object TimeCreated, ProviderName, Message | Format-List | Out-String

  "`n===== VBS / memory integrity ====="
  Get-CimInstance -Namespace root\Microsoft\Windows\DeviceGuard -ClassName Win32_DeviceGuard -ErrorAction SilentlyContinue |
    Select-Object VirtualizationBasedSecurityStatus, SecurityServicesRunning | Format-List | Out-String

  "`n===== disco ====="
  Get-PSDrive -PSProvider FileSystem | Format-Table Name, Used, Free | Out-String
} | Out-File -FilePath $Out -Encoding utf8

"guardado en $Out"
