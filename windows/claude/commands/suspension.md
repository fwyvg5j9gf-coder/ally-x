---
description: por qué falló la suspensión (no regresó, se vació, el control murió)
---

El usuario quiere suspender y regresar al juego como en una consola. Algo falló.

1. Corre `powershell.exe -NoProfile -ExecutionPolicy Bypass -File herramientas/ally-doctor.ps1` y lee en `diagnostico.txt` las secciones **suspensión**, **suspensión y reanudación** y **dispositivos con problema**.
2. Lee `logs/pausa.log` completo (es la bitácora de ally-pausa: cada apagado/encendido de pantalla, qué juego estaba al frente, si el control se reinició y si se pudo volver al juego).
3. Si existe `reportes/suspension.html` (sleepstudy), busca las sesiones con más drenaje y sus "top offenders".
4. Cruza fechas: el momento que describe el usuario contra el log y los eventos.
5. Responde:
   - **qué pasó**: en una o dos líneas, con la hora.
   - **por qué**: causa probable con la evidencia (línea del log o evento).
   - **qué hacer**: pasos concretos. Opciones que puedes proponer:
     - ally-pausa con `-Control siempre` si el control se cae seguido sin marcar error
       (editar el argumento de la tarea "Ally Pausa" en `\Ally\`);
     - bajar las 3 h de hibernación de respaldo (`powercfg /setdcvalueindex SCHEME_CURRENT SUB_SLEEP HIBERNATEIDLE <seg>`);
     - quitar permiso de despertar a un dispositivo (`powercfg /devicedisablewake "<nombre>"`);
     - actualizar MCU/BIOS en Armoury Crate si el fallo es de firmware;
     - si un juego específico crashea al regresar: es del juego o su anti-cheat; recomendar pausarlo o ir al menú antes de suspender.
   Espera el ok del usuario antes de aplicar cambios.

Lo que describe el usuario: $ARGUMENTS
