# Ajustes de uso como portátil táctil y revisión del software de ASUS.

Paso 'handheld: teclado táctil'
# Aparece solo al tocar un campo de texto sin teclado físico conectado.
Set-Reg 'HKCU:\Software\Microsoft\TabletTip\1.7' 'EnableDesktopModeAutoInvoke' 1
Set-Reg 'HKCU:\Software\Microsoft\TabletTip\1.7' 'TipbandDesiredVisibility' 1
Ok 'teclado táctil automático y botón en la barra'

Paso 'handheld: revisión de Armoury Crate, BIOS y drivers'
$bios = Get-CimInstance Win32_BIOS
$modelo = (Get-CimInstance Win32_ComputerSystem).Model
Info "modelo: $modelo"
Info "BIOS:   $($bios.SMBIOSBIOSVersion) ($('{0:yyyy-MM-dd}' -f $bios.ReleaseDate))"
if ($modelo -notmatch 'RC73X') { Aviso 'el modelo no parece ROG Xbox Ally X (RC73XA); los ajustes aplican igual pero revisa' }

$ctl = Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue | Where-Object InstanceId -match '^USB\\VID_0B05&PID_(1B4C|1ABE)\\'
if ($ctl) { Ok "control integrado detectado: $($ctl[0].InstanceId)" }
else { Aviso 'no detecté el control integrado con los IDs conocidos; ally-pausa no podrá reiniciarlo. Corre Ally Doctor y pásale a Claude la sección "dispositivos ASUS"' }

$gpu = Get-CimInstance Win32_VideoController | Where-Object Name -match 'AMD|Radeon' | Select-Object -First 1
if ($gpu) {
  Info "GPU:    $($gpu.Name), driver $($gpu.DriverVersion) ($('{0:yyyy-MM-dd}' -f $gpu.DriverDate))"
  if ($gpu.DriverDate -lt (Get-Date).AddMonths(-6)) {
    Aviso 'el driver de gráficos tiene más de 6 meses; actualízalo desde Armoury Crate'
  }
}

$ac = Get-AppxPackage -Name '*ArmouryCrate*' -ErrorAction SilentlyContinue
if ($ac) { Ok "Armoury Crate SE $($ac.Version)" }
else { Aviso 'no encontré Armoury Crate SE: sin él no hay control de TDP ni de botones. Instálalo desde rog.asus.com' }

foreach ($s in Get-Service -Name '*Armoury*', 'ASUS*' -ErrorAction SilentlyContinue) {
  if ($s.StartType -ne 'Disabled' -and $s.Status -ne 'Running') { Aviso "servicio $($s.Name) detenido" }
}

$malos = Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue | Where-Object Status -in 'Error', 'Degraded', 'Unknown'
if ($malos) {
  Aviso 'dispositivos con problema:'
  $malos | ForEach-Object { Info "  $($_.FriendlyName) [$($_.Class)] $($_.Status)" }
} else {
  Ok 'todos los dispositivos sin errores'
}

Info 'Update Center de Armoury Crate es la fuente correcta de BIOS, MCU y drivers del Ally.'
