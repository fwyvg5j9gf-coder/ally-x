---
description: busca lo que sobra en segundo plano y propone quitarlo
---

1. Corre `powershell.exe -NoProfile -ExecutionPolicy Bypass -File herramientas/ally-doctor.ps1` y lee las secciones de procesos y arranque automático en `diagnostico.txt`.
2. Revisa también tareas programadas de terceros:
   `powershell.exe -NoProfile -Command "Get-ScheduledTask | Where-Object { $_.State -ne 'Disabled' -and $_.TaskPath -notlike '\Microsoft\*' } | Select-Object TaskName, TaskPath | Format-Table -AutoSize"`
3. Arma una tabla: nombre, qué es, cuánto consume, recomendación (quitar / desactivar del arranque / dejar) y por qué.
   - Nunca propongas tocar: Armoury Crate y servicios ASUS, drivers AMD, Defender, Windows Update, servicios de Xbox si usa Game Pass.
4. Espera a que el usuario elija qué aplicar. Para cada cambio: di cómo revertirlo.

Notas del usuario: $ARGUMENTS
