<#
.SYNOPSIS
  Agente ligero que hace que suspender el Ally X se sienta como en una consola.

.DESCRIPTION
  Escucha cuándo se apaga y se prende la pantalla (botón de encendido o
  inactividad). Al apagarse anota qué juego estaba al frente y cuántos
  dispositivos del control hay. Al regresar:
    - si el control desapareció o tiene error, lo reinicia;
    - devuelve el juego al frente (después de suspender suele quedar detrás
      de Armoury Crate o del escritorio).
  Todo queda en %USERPROFILE%\ally\logs\pausa.log para que Claude lo revise.

  Lo instala el módulo suspension como tarea programada al iniciar sesión.

.PARAMETER Control
  si-falla (default) reinicia el control solo si se cayó; siempre lo reinicia
  en cada regreso; nunca no lo toca.
#>
param(
  [ValidateSet('si-falla', 'siempre', 'nunca')] [string]$Control = 'si-falla',
  [switch]$SinVolverAlJuego
)

$ErrorActionPreference = 'Continue'
$logDir = Join-Path $env:USERPROFILE 'ally\logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$log = Join-Path $logDir 'pausa.log'
function Log($m) {
  $linea = "{0:yyyy-MM-dd HH:mm:ss}  {1}" -f (Get-Date), $m
  Add-Content -Path $log -Value $linea -Encoding UTF8
  if ((Get-Item $log).Length -gt 1MB) { Move-Item $log "$log.1" -Force }
}

# Una sola instancia.
$mutex = New-Object System.Threading.Mutex($false, 'Local\AllyPausa')
if (-not $mutex.WaitOne(0)) { exit }

Add-Type -ReferencedAssemblies System.Windows.Forms -TypeDefinition @'
using System;
using System.Collections.Concurrent;
using System.Runtime.InteropServices;
using System.Text;
using System.Windows.Forms;

public class AllyVigia : NativeWindow {
  [DllImport("user32.dll")] static extern IntPtr RegisterPowerSettingNotification(IntPtr h, ref Guid g, int flags);
  static Guid DisplayState = new Guid("6FE69556-704A-47A0-8F24-C28D936FDA47");
  const int WM_POWERBROADCAST = 0x0218, PBT_POWERSETTINGCHANGE = 0x8013;

  public ConcurrentQueue<string> Cola = new ConcurrentQueue<string>();

  public AllyVigia() {
    CreateHandle(new CreateParams());
    RegisterPowerSettingNotification(Handle, ref DisplayState, 0);
  }

  protected override void WndProc(ref Message m) {
    if (m.Msg == WM_POWERBROADCAST) {
      int wp = m.WParam.ToInt32();
      if (wp == PBT_POWERSETTINGCHANGE) {
        // POWERBROADCAST_SETTING: GUID (16) + DataLength (4) + Data
        int estado = Marshal.ReadInt32(m.LParam, 20); // 0 apagada, 1 prendida, 2 atenuada
        Cola.Enqueue("pantalla:" + estado);
      } else if (wp == 0x4) {
        Cola.Enqueue("evento:suspender");
      } else if (wp == 0x12 || wp == 0x7) {
        Cola.Enqueue("evento:reanudar");
      }
    }
    base.WndProc(ref m);
  }

  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int cmd);
  [DllImport("user32.dll")] public static extern bool IsWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr h);
  [DllImport("user32.dll")] static extern void keybd_event(byte vk, byte scan, uint flags, UIntPtr extra);

  // Windows no deja que un proceso de fondo robe el foco; simular Alt lo permite.
  public static bool Enfocar(IntPtr h) {
    if (!IsWindow(h)) return false;
    if (IsIconic(h)) ShowWindow(h, 9); // SW_RESTORE
    keybd_event(0x12, 0, 0, UIntPtr.Zero);
    keybd_event(0x12, 0, 2, UIntPtr.Zero);
    return SetForegroundWindow(h);
  }
}
'@

# Procesos que no cuentan como "el juego".
$noJuegos = @(
  'explorer', 'ShellExperienceHost', 'StartMenuExperienceHost', 'SearchHost', 'LockApp',
  'ArmouryCrate', 'ArmouryCrateSE', 'ArmourySocketServer', 'ROGLiveService',
  'steamwebhelper', 'Playnite.FullscreenApp', 'Playnite.DesktopApp',
  'WindowsTerminal', 'powershell', 'pwsh', 'conhost', 'claude', 'Claude',
  'ApplicationFrameHost', 'TextInputHost', 'GameBar', 'XboxPcApp'
)

# Ally (1ABE) y Ally X (1B4C). Solo el dispositivo USB padre, no sus interfaces.
$patronControl = '^USB\\VID_0B05&PID_(1B4C|1ABE)\\'
function Get-Control { Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue | Where-Object InstanceId -match $patronControl }

function Reiniciar-Control($motivo) {
  $dev = Get-Control | Select-Object -First 1
  if ($dev) {
    $r = pnputil /restart-device "$($dev.InstanceId)" 2>&1
    Log "control reiniciado ($motivo): $($r -join ' ')"
  } else {
    pnputil /scan-devices | Out-Null
    Log "control no encontrado ($motivo); se pidió volver a detectar dispositivos"
  }
}

$vigia = New-Object AllyVigia
Log "ally-pausa iniciado (control: $Control, volver al juego: $(-not $SinVolverAlJuego))"

$apagadaDesde = $null
$juego = $null
$controlesAntes = 0

while ($true) {
  [System.Windows.Forms.Application]::DoEvents()
  $msg = $null
  while ($vigia.Cola.TryDequeue([ref]$msg)) {
    switch -Regex ($msg) {
      '^evento:' { Log $msg }

      '^pantalla:0$' {
        if ($apagadaDesde) { break }
        $apagadaDesde = Get-Date
        $hwnd = [AllyVigia]::GetForegroundWindow()
        $procId = [uint32]0
        [void][AllyVigia]::GetWindowThreadProcessId($hwnd, [ref]$procId)
        $p = Get-Process -Id $procId -ErrorAction SilentlyContinue
        $juego = if ($p -and $noJuegos -notcontains $p.ProcessName) { @{ Hwnd = $hwnd; Id = $procId; Nombre = $p.ProcessName } } else { $null }
        $controlesAntes = @(Get-Control).Count
        $txt = if ($juego) { $juego.Nombre } else { 'ninguno' }
        Log "pantalla apagada. al frente: $txt. control presente: $($controlesAntes -gt 0)"
      }

      '^pantalla:1$' {
        if (-not $apagadaDesde) { break }
        $fuera = (Get-Date) - $apagadaDesde
        $apagadaDesde = $null
        Log ("pantalla prendida tras {0:hh\:mm\:ss}" -f $fuera)
        if ($fuera.TotalSeconds -lt 5) { break }

        # Dar tiempo a que los drivers terminen de despertar.
        Start-Sleep -Seconds 3

        if ($Control -ne 'nunca') {
          $ctl = @(Get-Control)
          $malo = $ctl | Where-Object Status -ne 'OK'
          if ($Control -eq 'siempre') { Reiniciar-Control 'siempre' }
          elseif ($controlesAntes -gt 0 -and $ctl.Count -eq 0) { Reiniciar-Control 'desapareció' }
          elseif ($malo) { Reiniciar-Control "estado $($malo[0].Status)" }
          else { Log 'control ok' }
        }

        if ($juego -and -not $SinVolverAlJuego) {
          if (Get-Process -Id $juego.Id -ErrorAction SilentlyContinue) {
            Start-Sleep -Milliseconds 500
            $ok = [AllyVigia]::Enfocar($juego.Hwnd)
            Log "volver a $($juego.Nombre): $(if ($ok) { 'ok' } else { 'Windows no lo permitió' })"
          } else {
            Log "$($juego.Nombre) ya no está corriendo (se cerró o crasheó durante la suspensión)"
          }
        }
        $juego = $null
      }
    }
  }
  Start-Sleep -Milliseconds 250
}
