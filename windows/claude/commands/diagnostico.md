---
description: revisa el estado completo del Ally X y dice qué arreglar
---

1. Corre `powershell.exe -NoProfile -ExecutionPolicy Bypass -File herramientas/ally-doctor.ps1`.
2. Lee `diagnostico.txt` completo.
3. Responde así, corto:
   - **estado**: una línea (bien / con detalles / con problemas).
   - **lo que encontré**: máximo 5 puntos, del más importante al menos, cada uno con la causa probable y qué hacer.
   - **lo que está bien**: una línea.
4. Si algo se arregla con un comando, ofrécelo y espera mi ok antes de correrlo.

Contexto extra del usuario (puede venir vacío): $ARGUMENTS
