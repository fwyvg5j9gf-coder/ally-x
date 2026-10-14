# Desactiva Virtualization Based Security y Memory Integrity (HVCI).
# Ganancia típica: 5-10 % más FPS en juegos limitados por CPU.
# Costo: menos protección contra malware que ataca el kernel.
# Algunos anti-cheat (p. ej. Valorant/Vanguard, FACEIT) exigen HVCI encendido.

Paso 'agresivo: VBS y Memory Integrity'
Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity' 'Enabled' 0
Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard' 'EnableVirtualizationBasedSecurity' 0
Ok 'off (aplica al reiniciar)'
Info 'si un juego con anti-cheat se queja, corre revertir.ps1 o reactívalo en'
Info 'Seguridad de Windows → Seguridad del dispositivo → Aislamiento del núcleo'
