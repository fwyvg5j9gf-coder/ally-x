# ally-x para Windows 11

Deja tu **ROG Xbox Ally X** (2025, RC73XA, Z2 Extreme) con Windows 11 rápido,
limpio y con Claude integrado como
técnico de cabecera. Todo lo que cambia queda respaldado y se deshace con un
doble clic.

## instalar

1. Descarga el repo: botón verde **Code → Download ZIP** en GitHub, o
   `git clone https://github.com/fwyvg5j9gf-coder/ally-x.git`.
2. Descomprime y entra a la carpeta `windows`.
3. Doble clic en **`instalar.cmd`** → acepta el permiso de administrador.
4. Revisa la lista de lo que se va a aplicar y responde `s`.
5. Reinicia.

Desde PowerShell también puedes elegir qué correr:

```powershell
.\instalar.ps1                          # recomendados (rendimiento, limpieza, suspension, handheld, claude, remoto)
.\instalar.ps1 -Apps                    # + Steam, Playnite y Heroic
.\instalar.ps1 -Agresivo                # + apaga VBS / Memory Integrity
.\instalar.ps1 -Modulos claude,apps     # solo esos módulos
.\instalar.ps1 -SinPreguntar            # sin confirmaciones
```

## qué hace cada módulo

### rendimiento
| ajuste | por qué |
|---|---|
| Modo juego on | Windows prioriza el juego en primer plano |
| Captura en segundo plano off | la grabación continua de Game Bar cuesta FPS y batería |
| Programación de GPU por hardware | menos latencia, requisito para Frame Generation |
| Optimizaciones para juegos en ventana + VRR | menos latencia y FreeSync también en modo sin bordes |
| Suspensión selectiva USB off | los controles del Ally van por USB interno; es la causa #1 de controles muertos tras suspender |
| Sin red durante suspensión con batería | evita que se vacíe en la mochila |
| Pantalla 3 min / suspender 10 min en batería | |

### limpieza
- Quita apps preinstaladas que no sirven en una portátil de juego: Clipchamp,
  Noticias, Clima, Solitario, Teams personal, Outlook nuevo, Mapas, Power
  Automate, Cortana, Copilot y similares. **Se conservan** Store, Xbox, Game
  Bar, Fotos, Calculadora, Terminal y Edge. Todo se reinstala desde la Store.
- Apaga widgets, botón de Copilot, Recall, apps sugeridas, recomendaciones del
  inicio, ID de publicidad y Bing en la búsqueda del inicio.
- Edge sin precarga ni ejecución en segundo plano.
- Telemetría al mínimo y servicios DiagTrack / dmwappushservice off.

### suspension — suspender y regresar al juego como en Switch
Presionas el botón de encendido, la pantalla se apaga, el juego se queda en
pausa en memoria. Lo vuelves a presionar y estás de regreso en segundos.

| ajuste | por qué |
|---|---|
| Botón de encendido = suspender | |
| Ningún dispositivo puede despertarlo | botones del control, red o touch no lo prenden dentro de la mochila; solo el botón de encendido |
| Sin temporizadores de activación en batería | Windows Update y tareas no lo despiertan |
| Inicio rápido off | deja drivers a medias: controles muertos, Wi-Fi que no regresa |
| Hibernación de respaldo a las 3 h | si lo dejas suspendido mucho tiempo, guarda el juego al SSD y se apaga; al encender regresas al mismo punto aunque pasen días. Es lo que evita perder la partida por batería |
| Agente **ally-pausa** | al regresar revisa el control y lo reinicia si se cayó, y te devuelve al juego si quedó detrás de otra ventana |

Además deja **Arreglar control** en el menú inicio, por si los botones dejan
de responder en cualquier momento.

**Límites honestos:** juegos en línea pierden la conexión mientras está
suspendido (igual que en Switch), y algunos anti-cheat cierran el juego al
regresar. Lo más seguro es pausar o ir al menú antes de suspender.

### handheld
- Teclado táctil automático al tocar un campo de texto.
- Revisa modelo, BIOS, driver de gráficos (avisa si tiene más de 6 meses),
  Armoury Crate SE, sus servicios y dispositivos con error.

### claude
- Instala **Claude** (app de escritorio), **Claude Code**, Git y Windows
  Terminal.
- Crea `%USERPROFILE%\ally\`, la carpeta de trabajo de Claude:

  ```
  ally\
  ├── CLAUDE.md          # Claude sabe qué equipo es, qué ya se ajustó y qué no tocar
  ├── .claude\commands\  # comandos propios (abajo)
  ├── herramientas\      # ally-doctor, ally-pausa, arreglar-control, claude-remoto, revertir
  ├── reportes\          # reportes HTML de batería y suspensión
  ├── logs\              # bitácora de cada instalación
  └── respaldo.json      # valores originales de todo lo que se cambió
  ```

- Accesos en el menú inicio (carpeta **Ally**) y escritorio:
  **Claude Code (Ally)**, **Claude remoto** y **Ally Doctor**.

### apps (opcional, `-Apps`)
Steam, Playnite (frontend de pantalla completa para control, junta todas tus
bibliotecas) y Heroic (Epic / GOG / Amazon sin sus launchers pesados).

### agresivo (opcional, `-Agresivo`)
Apaga VBS y Memory Integrity: 5–10 % más FPS en juegos limitados por CPU.
**Cuidado:** reduce la protección contra malware de kernel, y algunos
anti-cheat (Valorant, FACEIT) exigen que esté encendido.

## Claude en el Ally

Abre **Claude Code (Ally)** y usa los comandos:

| comando | qué hace |
|---|---|
| `/diagnostico` | revisa todo el equipo y te dice qué arreglar, en orden |
| `/bateria` | por qué se acaba la batería, jugando o suspendido |
| `/juego elden ring batería` | receta de TDP, resolución, FPS y ajustes para ese juego |
| `/limpieza` | qué sobra en segundo plano y qué conviene quitar |
| `/suspension se murió el control al regresar` | revisa la bitácora de ally-pausa y los eventos y te dice qué pasó |

O pregúntale normal: *"el control dejó de responder después de suspender"*,
*"instálame Discord"*, *"¿por qué se calienta tanto con Hades?"*.
Antes de cambiar algo te dice qué hace y cómo regresarlo.

**En la pantalla completa de Xbox:** Claude remoto y ally-pausa corren igual
(arrancan solos). Para Claude Code o Ally Doctor ve al escritorio: mantén el
botón **Xbox** → Escritorio. También puedes agregarlos a Steam como
*juego que no es de Steam* para abrirlos con el control. Teclado en pantalla:
botón Xbox → Game Bar → pestaña de ajustes (RB), o tocando un campo de texto.

La app **Claude** (de escritorio) sirve para platicar normal, sin acceso al
sistema.

## Claude remoto (desde tu celular)

Usa Claude en el Ally sin tenerlo en la mano: abre **Claude remoto** (menú
inicio → Ally, o escritorio) y en la app de Claude de tu celular entra a
**Code** y elige la sesión del Ally. Desde ahí le pides lo mismo que en la
pantalla: *"corre /diagnostico"*, *"¿cuánta batería tiene?"*,
*"descarga e instala Discord"*.

- La primera vez ábrelo a mano para iniciar sesión y aceptar el modo remoto.
- Arranca solo (minimizado) cada vez que prendes el Ally y se reabre si se
  cae. Si no lo quieres siempre: instala sin ese módulo
  (`-Modulos rendimiento,limpieza,suspension,handheld,claude`) o borra la tarea
  `\Ally\Claude remoto` en el Programador de tareas.
- Corre **sin permisos de administrador**: desde fuera no puede cambiar el
  sistema; esos ajustes te los deja listos para cuando tengas el Ally.
- Solo responde con el Ally encendido y con internet. Suspendido no contesta
  (a propósito: el módulo suspension evita que despierte solo).
- Requiere plan Pro o Max de Claude, igual que Claude Code.

## deshacer

Doble clic en **`revertir.cmd`** (o `%USERPROFILE%\ally\herramientas\revertir.ps1`).
Regresa cada valor de registro y servicio a como estaba antes y la energía a
valores de Windows. No desinstala Claude ni reinstala las apps quitadas.

Si algo sale muy mal: **Restaurar sistema** → punto "antes de ally-x".

## después de instalar, en Armoury Crate SE

1. **Update Center**: BIOS, MCU (firmware de controles) y drivers. Es la
   fuente correcta para el Ally; no uses drivers genéricos de AMD salvo que
   ASUS tenga meses sin publicar.
2. **Modos**: Silencioso (~13 W) para indies y batería, Rendimiento (~17 W)
   de diario, Turbo (hasta ~35 W) solo conectado; de 25 a 35 W casi no sube FPS.
3. **Memoria**: VRAM en automático; si un juego pesado tironea, prueba 6–8 GB.
