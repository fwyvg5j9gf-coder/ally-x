# Funciones compartidas por instalar.ps1, revertir.ps1 y los módulos.
# Todo cambio de registro o servicio pasa por aquí para quedar respaldado.

$script:AllyDir     = Join-Path $env:USERPROFILE 'ally'
$script:RespaldoArc = Join-Path $script:AllyDir 'respaldo.json'
$script:Respaldo    = [ordered]@{ registro = [ordered]@{}; servicios = [ordered]@{}; despertar = @() }
$script:Cambios     = 0

function Paso($msg)  { Write-Host "`n==> $msg" -ForegroundColor Yellow }
function Ok($msg)    { Write-Host "    ok  $msg" -ForegroundColor Green }
function Aviso($msg) { Write-Host "    !!  $msg" -ForegroundColor DarkYellow }
function Info($msg)  { Write-Host "        $msg" -ForegroundColor Gray }

function Test-Admin {
  ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).
    IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Abrir-Respaldo {
  New-Item -ItemType Directory -Force -Path $script:AllyDir | Out-Null
  if (-not (Test-Path $script:RespaldoArc)) { return }
  $json = Get-Content $script:RespaldoArc -Raw -Encoding UTF8 | ConvertFrom-Json
  foreach ($p in $json.registro.PSObject.Properties)  { $script:Respaldo.registro[$p.Name]  = $p.Value }
  foreach ($p in $json.servicios.PSObject.Properties) { $script:Respaldo.servicios[$p.Name] = $p.Value }
  if ($json.despertar) { $script:Respaldo.despertar = @($json.despertar) }
}

function Guardar-Respaldo {
  $script:Respaldo | ConvertTo-Json -Depth 5 | Set-Content -Path $script:RespaldoArc -Encoding UTF8
}

# Escribe un valor de registro. La primera vez que se toca una clave guarda su
# valor original; correr el instalador otra vez no pisa ese respaldo.
function Set-Reg {
  param(
    [Parameter(Mandatory)] [string]$Path,
    [Parameter(Mandatory)] [string]$Name,
    [Parameter(Mandatory)] $Value,
    [ValidateSet('DWord', 'String', 'QWord')] [string]$Type = 'DWord'
  )
  $clave = "$Path|$Name"
  if (-not $script:Respaldo.registro.Contains($clave)) {
    $actual = $null; $existia = $false
    if (Test-Path $Path) {
      $p = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
      if ($null -ne $p) { $existia = $true; $actual = $p.$Name }
    }
    $script:Respaldo.registro[$clave] = [ordered]@{
      Path = $Path; Name = $Name; Existia = $existia; Valor = $actual; Tipo = $Type
    }
  }
  if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
  Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type
  $script:Cambios++
}

# Cambia el tipo de arranque de un servicio y lo detiene si queda deshabilitado.
function Set-Servicio {
  param([Parameter(Mandatory)] [string]$Nombre, [ValidateSet('Disabled', 'Manual', 'Automatic')] [string]$Inicio)
  $svc = Get-Service -Name $Nombre -ErrorAction SilentlyContinue
  if (-not $svc) { Info "servicio $Nombre no existe, se omite"; return }
  if (-not $script:Respaldo.servicios.Contains($Nombre)) {
    $script:Respaldo.servicios[$Nombre] = [string]$svc.StartType
  }
  Set-Service -Name $Nombre -StartupType $Inicio
  if ($Inicio -eq 'Disabled' -and $svc.Status -eq 'Running') {
    Stop-Service -Name $Nombre -Force -ErrorAction SilentlyContinue
  }
  $script:Cambios++
}

# powercfg sobre el plan activo, para corriente (AC) y batería (DC).
function Set-Energia {
  param([string]$Subgrupo, [string]$Ajuste, [int]$AC, [int]$DC)
  powercfg /setacvalueindex SCHEME_CURRENT $Subgrupo $Ajuste $AC 2>$null
  $codigo = $LASTEXITCODE
  powercfg /setdcvalueindex SCHEME_CURRENT $Subgrupo $Ajuste $DC 2>$null
  if ($codigo -ne 0 -or $LASTEXITCODE -ne 0) { Aviso "powercfg no aceptó $Ajuste (puede no existir en este equipo)" }
}

function Instalar-Winget {
  param([Parameter(Mandatory)] [string]$Id, [string]$Nombre = $Id)
  if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Aviso "winget no está disponible; instala 'App Installer' desde la Microsoft Store"
    return
  }
  winget list --id $Id -e --accept-source-agreements *> $null
  if ($LASTEXITCODE -eq 0) { Ok "$Nombre ya estaba instalado"; return }
  winget install --id $Id -e --silent --accept-source-agreements --accept-package-agreements
  if ($LASTEXITCODE -eq 0) { Ok "$Nombre instalado" } else { Aviso "no se pudo instalar $Nombre (código $LASTEXITCODE)" }
}

# Fusiona pares "Clave=Valor;" en la cadena de preferencias globales de DirectX
# sin borrar lo que ya tenga (p. ej. AutoHDREnable).
function Set-DirectXGlobal {
  param([hashtable]$Pares)
  $path = 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences'
  $name = 'DirectXUserGlobalSettings'
  $actual = (Get-ItemProperty -Path $path -Name $name -ErrorAction SilentlyContinue).$name
  $mapa = [ordered]@{}
  if ($actual) {
    foreach ($par in $actual.Split(';')) {
      if ($par -match '^(.+?)=(.*)$') { $mapa[$Matches[1]] = $Matches[2] }
    }
  }
  foreach ($k in $Pares.Keys) { $mapa[$k] = $Pares[$k] }
  $nuevo = (($mapa.Keys | ForEach-Object { "$_=$($mapa[$_])" }) -join ';') + ';'
  Set-Reg $path $name $nuevo 'String'
}

function Nuevo-Acceso {
  param([string]$Ruta, [string]$Destino, [string]$Argumentos = '', [string]$Carpeta = '', [string]$Icono = '')
  $shell = New-Object -ComObject WScript.Shell
  $lnk = $shell.CreateShortcut($Ruta)
  $lnk.TargetPath = $Destino
  $lnk.Arguments = $Argumentos
  if ($Carpeta) { $lnk.WorkingDirectory = $Carpeta }
  if ($Icono)   { $lnk.IconLocation = $Icono }
  $lnk.Save()
}
