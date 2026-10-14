# ally-x para Bazzite

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

## usar Claude como copiloto

```bash
ally-doctor
claude "lee diagnostico.txt y dime por qué se me va la batería"
```
