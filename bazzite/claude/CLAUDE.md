# CLAUDE.md — ROG Xbox Ally X

Eres el copiloto de este ROG Xbox Ally X. Responde en español mexicano, directo.

## hardware

- ASUS ROG Xbox Ally X (2025, RC73XA) — AMD Ryzen AI Z2 Extreme, 24 GB
  LPDDR5X-8000, SSD 1 TB, pantalla 7" 1080p 120 Hz VRR, batería 80 Wh,
  impulse triggers.
- TDP útil: ~8–35 W (8–13 W batería larga, 15–20 W balanceado, 25–35 W conectado).

## sistema

Revisa cuál corre antes de sugerir comandos:
- `cat /etc/os-release` contiene `bazzite` → **Bazzite** (Fedora Atomic, inmutable).
- Si `$env:OS` es `Windows_NT` → **Windows 11**.

### Bazzite — reglas
- El sistema base es inmutable. Apps gráficas: `flatpak install flathub <id>`.
  CLI: `brew install <pkg>`. Entornos completos: `distrobox`.
- `rpm-ostree install` solo como último recurso (requiere reiniciar y ralentiza
  actualizaciones). Pregunta antes de usarlo.
- Utilidades de Bazzite: `ujust --choose` (lista), `ujust update`.
- Controles, TDP, RGB y ventilador los maneja **Handheld Daemon (hhd)**:
  `systemctl status hhd@$USER`, logs con `journalctl -u hhd@$USER -b`.
- Rollback si una actualización rompe algo: `rpm-ostree rollback` y reiniciar.

### Windows 11 — reglas
- Usa `winget` para instalar. No toques el registro sin explicar qué hace y
  cómo revertirlo.
- Controles/TDP: Armoury Crate SE. Problemas tras suspender → actualizar MCU.

## diagnóstico

`ally-doctor` genera `diagnostico.txt` en esta carpeta. Léelo antes de
adivinar causas de batería, temperatura, controles o crashes.

## límites

- Nunca formatees discos, toques el bootloader ni cambies BIOS sin confirmación
  explícita.
- Antes de comandos con `sudo` o como administrador, di qué hacen en una línea.
