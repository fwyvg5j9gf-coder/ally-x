# Rendimiento en juegos y comportamiento de energía pensado para portátil.

Paso 'rendimiento: modo juego y captura'
Set-Reg 'HKCU:\Software\Microsoft\GameBar' 'AutoGameModeEnabled' 1
Set-Reg 'HKCU:\Software\Microsoft\GameBar' 'AllowAutoGameMode' 1
# La grabación en segundo plano cuesta FPS y batería aunque no la uses.
Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 0
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 0
Ok 'modo juego on, captura en fondo off (la Game Bar sigue disponible)'

Paso 'rendimiento: GPU'
# Programación de GPU acelerada por hardware (requiere reiniciar).
Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' 'HwSchMode' 2
# Optimizaciones para juegos en ventana: menos latencia y VRR en modo sin bordes.
Set-DirectXGlobal @{ SwapEffectUpgradeEnable = '1'; VRROptimizeEnable = '1' }
Ok 'HAGS on, optimizaciones en ventana y VRR on'

Paso 'rendimiento: energía'
# Suspensión selectiva de USB off: los controles internos del Ally van por USB
# y es la causa más común de que dejen de responder tras suspender.
Set-Energia '2a737441-1930-4402-8d77-b2bebba308a3' '48e6b7a6-50f5-4782-a5d4-53bb8f07e226' 0 0
# Sin red durante la suspensión en batería: evita que se vacíe en la mochila.
Set-Energia 'fea3413e-7e05-4911-9a71-700331f1c294' 'f15576e8-98b7-4186-b944-eafa664402d9' 1 0
# Tiempos en batería: pantalla 3 min, suspender 10 min.
powercfg /change monitor-timeout-dc 3
powercfg /change standby-timeout-dc 10
powercfg /setactive SCHEME_CURRENT
Ok 'USB sin suspensión selectiva, sin red en suspensión con batería, tiempos ajustados'

# Hibernación e inicio rápido los maneja el módulo suspension.
