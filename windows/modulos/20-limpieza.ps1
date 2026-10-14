# Quita lo que consume batería y atención sin aportar nada en una portátil de juego.
# Se conservan: Microsoft Store, Xbox y Game Bar (Game Pass), Fotos, Calculadora,
# Terminal, Reproductor multimedia, Edge.

Paso 'limpieza: apps preinstaladas'
$sobran = @(
  'Clipchamp.Clipchamp'
  'Microsoft.BingNews'
  'Microsoft.BingWeather'
  'Microsoft.BingSearch'
  'Microsoft.GetHelp'
  'Microsoft.Getstarted'
  'Microsoft.MicrosoftOfficeHub'
  'Microsoft.MicrosoftSolitaireCollection'
  'Microsoft.OutlookForWindows'
  'Microsoft.People'
  'Microsoft.PowerAutomateDesktop'
  'Microsoft.Todos'
  'Microsoft.WindowsFeedbackHub'
  'Microsoft.WindowsMaps'
  'Microsoft.Windows.DevHome'
  'Microsoft.Copilot'
  'Microsoft.549981C3F5F10'   # Cortana
  'MicrosoftCorporationII.QuickAssist'
  'MicrosoftTeams'
  'MSTeams'
)
$aprovisionadas = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
foreach ($app in $sobran) {
  $quitada = $false
  Get-AppxPackage -Name $app -ErrorAction SilentlyContinue | ForEach-Object {
    Remove-AppxPackage -Package $_.PackageFullName -ErrorAction SilentlyContinue
    $quitada = $true
  }
  # También de la imagen, para que no regresen con usuarios nuevos.
  $aprovisionadas | Where-Object DisplayName -eq $app | ForEach-Object {
    Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue | Out-Null
    $quitada = $true
  }
  if ($quitada) { Ok "quitada $app" }
}
Info 'cualquiera se reinstala desde la Microsoft Store'

Paso 'limpieza: widgets, Copilot y Recall'
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' 'AllowNewsAndInterests' 0
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarDa' 0
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ShowCopilotButton' 0
Set-Reg 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot' 'TurnOffWindowsCopilot' 1
Set-Reg 'HKCU:\Software\Policies\Microsoft\Windows\WindowsAI' 'DisableAIDataAnalysis' 1
Ok 'off'

Paso 'limpieza: anuncios y sugerencias'
$cdm = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
foreach ($v in 'SubscribedContent-338388Enabled', 'SubscribedContent-338389Enabled',
               'SubscribedContent-353694Enabled', 'SubscribedContent-353696Enabled',
               'SystemPaneSuggestionsEnabled', 'SilentInstalledAppsEnabled', 'SoftLandingEnabled') {
  Set-Reg $cdm $v 0
}
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Start_IrisRecommendations' 0
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' 'Enabled' 0
# Búsqueda del menú inicio solo local: más rápida y sin Bing.
Set-Reg 'HKCU:\Software\Policies\Microsoft\Windows\Explorer' 'DisableSearchBoxSuggestions' 1
Ok 'sin apps sugeridas, recomendaciones, ID de publicidad ni Bing en inicio'

Paso 'limpieza: procesos de fondo'
# Edge precargado al encender y corriendo cerrado.
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' 'StartupBoostEnabled' 0
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' 'BackgroundModeEnabled' 0
# Actualizaciones solo desde Microsoft, sin subir a otros equipos.
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization' 'DODownloadMode' 0
Ok 'Edge sin precarga ni fondo, sin compartir actualizaciones P2P'

Paso 'limpieza: telemetría opcional'
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry' 1   # 1 = solo datos requeridos
Set-Servicio 'DiagTrack' 'Disabled'
Set-Servicio 'dmwappushservice' 'Disabled'
Ok 'telemetría al mínimo'
