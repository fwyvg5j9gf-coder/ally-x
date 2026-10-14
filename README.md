# ally-x — sistema para tu ROG Ally X con Claude integrado

Kit para dejar tu ROG Ally X funcionando bien y con Claude a la mano, sea en
**Bazzite** (recomendado) o en **Windows 11**.

## ¿bazzite o windows 11?

| | Bazzite (Linux) | Windows 11 |
|---|---|---|
| Rendimiento en juegos | igual o mejor en la mayoría (Proton) | nativo, pero cargado de procesos |
| Batería | mejor, menos procesos de fondo | peor |
| Suspender / reanudar | confiable (modo juego tipo Steam Deck) | falla seguido |
| Controles, TDP, ventilador | Handheld Daemon (HHD) ya incluido | Armoury Crate (pesado) |
| Juegos con anti-cheat (Valorant, Fortnite, CoD) | **no funcionan** | funcionan |
| Game Pass / launchers raros | parcial (Heroic, Lutris) | completo |
| Claude | Claude Code (terminal) + claude.ai como app web | app de escritorio Claude + Claude Code |

**Recomendación:** si no dependes de juegos con anti-cheat de kernel, ve por
**Bazzite**. Si sí, quédate en Windows pero límpialo con `windows/setup.ps1`.
También puedes hacer dual boot (Bazzite + Windows) en el SSD.

## estructura

```
ally-x/
├── bazzite/
│   ├── setup.sh          # post-instalación: apps, Claude Code, accesos directos
│   └── ally-doctor.sh    # junta diagnósticos para que Claude los lea
├── windows/
│   ├── setup.ps1         # limpieza segura + ajustes de rendimiento + Claude
│   └── ally-doctor.ps1   # mismo diagnóstico, versión Windows
└── claude/
    └── CLAUDE.md         # contexto del dispositivo para Claude Code
```

## ruta A — Bazzite

1. Descarga la imagen desde https://bazzite.gg eligiendo:
   *Handheld/HTPC → ASUS ROG Ally X → GPU AMD* (imagen `bazzite-deck`).
2. Flashea a una USB con Fedora Media Writer, Ventoy o balenaEtcher.
3. En el Ally X: apagado, mantén **Vol −** y presiona **Power** → elige la USB.
4. Instala. Al terminar arranca en Modo Juego (como Steam Deck).
5. Cambia a Escritorio (Steam → Power → Switch to Desktop), abre Konsole y corre:

   ```bash
   git clone https://github.com/fwyvg5j9gf-coder/ally-x.git ~/ally-x
   bash ~/ally-x/bazzite/setup.sh
   ```

6. Inicia sesión en Claude: `claude` en la terminal y sigue el login.

Después del setup tendrás:
- `claude` en terminal, trabajando desde `~/ally` con el contexto del Ally X.
- **Claude** (claude.ai como app) y **Claude Code** en el menú de apps.
- Ambos se pueden agregar a Steam (clic derecho → *Add to Steam*) para usarlos
  desde Modo Juego.
- Teclado en pantalla: botón **Steam + X** en Modo Juego.

## ruta B — Windows 11

Descarga o clona este repo, abre PowerShell **como administrador** dentro de la carpeta y corre:

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
.\windows\setup.ps1              # ajustes seguros + Claude
.\windows\setup.ps1 -Agresivo    # además apaga VBS/HVCI (+FPS, -seguridad)
```

Qué hace (todo reversible):
- Plan de energía y Modo Juego activados, Game DVR/captura en fondo apagado.
- Apaga widgets, sugerencias, Copilot en barra y telemetría opcional.
- Instala la app de escritorio **Claude**, **Git** y **Claude Code**.
- Crea `%USERPROFILE%\ally` con el `CLAUDE.md` del dispositivo.
- Con `-Agresivo`: desactiva Memory Integrity / VBS (5–10% más FPS en
  algunos juegos; reduce protección contra malware a nivel kernel).

Ajustes manuales recomendados:
- **Armoury Crate**: actualiza BIOS, MCU y drivers desde *Update Center*.
  Usa modo *Performance* (17–25 W) conectado y *Silent/Turbo* según juego.
- **Drivers AMD**: los de ASUS primero; los genéricos de AMD solo si ASUS
  tiene meses sin actualizar.
- Si los controles fallan después de suspender: actualiza MCU en Armoury
  Crate, es el bug más común del Ally.

## usar Claude como copiloto del Ally

`claude/CLAUDE.md` le dice a Claude qué hardware tienes, qué sistema corre y
qué comandos son seguros. Desde `~/ally` (o `%USERPROFILE%\ally`):

```bash
ally-doctor            # genera ~/ally/diagnostico.txt
claude "lee diagnostico.txt y dime por qué se me va la batería"
```

Ejemplos de lo que le puedes pedir:
- "el control no responde después de suspender, revisa el log"
- "instálame Heroic y configura mis juegos de Epic"
- "ponme un perfil de 15 W para jugar Hades en el avión"
