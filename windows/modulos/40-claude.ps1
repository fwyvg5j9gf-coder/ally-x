# Claude en el Ally X: app de escritorio, Claude Code y una carpeta de trabajo
# con contexto del equipo, comandos propios y herramientas de diagnóstico.

Paso 'claude: programas'
Instalar-Winget 'Git.Git' 'Git (Claude Code lo necesita en Windows)'
if (-not (Get-Command wt.exe -ErrorAction SilentlyContinue)) {
  Instalar-Winget 'Microsoft.WindowsTerminal' 'Windows Terminal'
}
Instalar-Winget 'Anthropic.Claude' 'Claude (app de escritorio)'

$claudeExe = Join-Path $env:USERPROFILE '.local\bin\claude.exe'
if (Test-Path $claudeExe) {
  Ok 'Claude Code ya estaba instalado'
} else {
  try {
    Invoke-RestMethod https://claude.ai/install.ps1 | Invoke-Expression
    if (Test-Path $claudeExe) { Ok 'Claude Code instalado' } else { Aviso 'el instalador de Claude Code terminó pero no encuentro claude.exe' }
  } catch {
    Aviso "no se pudo instalar Claude Code: $($_.Exception.Message)"
  }
}

# Asegura ~\.local\bin en el PATH del usuario.
$binDir = Split-Path $claudeExe
$pathUsuario = [Environment]::GetEnvironmentVariable('Path', 'User')
if (($pathUsuario -split ';') -notcontains $binDir) {
  [Environment]::SetEnvironmentVariable('Path', "$pathUsuario;$binDir".TrimStart(';'), 'User')
  Ok "agregado $binDir al PATH"
}

Paso "claude: carpeta de trabajo $script:AllyDir"
$origen = Join-Path $PSScriptRoot '..\claude' | Resolve-Path
Copy-Item (Join-Path $origen 'CLAUDE.md') $script:AllyDir -Force
$cmdDir = Join-Path $script:AllyDir '.claude\commands'
New-Item -ItemType Directory -Force -Path $cmdDir | Out-Null
Copy-Item (Join-Path $origen 'commands\*.md') $cmdDir -Force
$herrDir = Join-Path $script:AllyDir 'herramientas'
New-Item -ItemType Directory -Force -Path $herrDir | Out-Null
Copy-Item (Join-Path $PSScriptRoot '..\herramientas\*.ps1') $herrDir -Force
Copy-Item (Join-Path $PSScriptRoot '..\revertir.ps1') $herrDir -Force
Copy-Item (Join-Path $PSScriptRoot '..\lib') $script:AllyDir -Recurse -Force
Ok 'CLAUDE.md, comandos (/diagnostico /bateria /juego /limpieza) y herramientas copiados'

Paso 'claude: accesos directos'
$menu = Join-Path ([Environment]::GetFolderPath('Programs')) 'Ally'
New-Item -ItemType Directory -Force -Path $menu | Out-Null
$escritorio = [Environment]::GetFolderPath('Desktop')
$wt = (Get-Command wt.exe -ErrorAction SilentlyContinue).Source

if ($wt) {
  $destino = $wt
  $argumentos = "-d `"$script:AllyDir`" --title `"Claude Code`" `"$claudeExe`""
} else {
  $destino = 'powershell.exe'
  $argumentos = "-NoExit -Command `"Set-Location '$script:AllyDir'; & '$claudeExe'`""
}
foreach ($dir in $menu, $escritorio) {
  Nuevo-Acceso (Join-Path $dir 'Claude Code (Ally).lnk') $destino $argumentos $script:AllyDir "$claudeExe,0"
}
$doctor = Join-Path $herrDir 'ally-doctor.ps1'
Nuevo-Acceso (Join-Path $menu 'Ally Doctor.lnk') 'powershell.exe' `
  "-NoProfile -ExecutionPolicy Bypass -File `"$doctor`" -Abrir" $script:AllyDir 'shell32.dll,23'
Ok "en el menú inicio (carpeta Ally) y en el escritorio"
Info 'para abrirlos con el control: Armoury Crate SE → Biblioteca → agregar, o Steam → Agregar juego que no es de Steam'
