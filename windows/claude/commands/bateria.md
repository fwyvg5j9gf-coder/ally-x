---
description: por qué se acaba la batería, jugando o suspendido
---

1. Corre `powershell.exe -NoProfile -ExecutionPolicy Bypass -File herramientas/ally-doctor.ps1`.
2. Lee `diagnostico.txt` (secciones batería, energía, procesos, suspensión).
3. Lee `reportes/bateria.html` y, si existe, `reportes/suspension.html`. Son grandes: busca las tablas de uso reciente, capacidad y sesiones de suspensión con mayor drenaje.
4. Corre `powercfg /lastwake` y `powercfg /waketimers` para ver qué despierta al equipo.
5. Dime:
   - salud de la batería en % y si es normal para su edad;
   - duración real que estoy teniendo y si cuadra con mi uso (80 Wh: ~2 h a 25 W, ~4 h a 13 W, más en indies con FPS limitados);
   - los 3 mayores culpables de drenaje y qué hacer con cada uno;
   - si se pierde batería suspendido: cuánto por hora y por qué.

Situación que describe el usuario: $ARGUMENTS
