#!/usr/bin/env bash
# Post-instalación de Bazzite para ROG Ally X + Claude.
# Idempotente: puedes correrlo varias veces sin problema.
set -euo pipefail

KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ALLY_DIR="$HOME/ally"
BIN_DIR="$HOME/.local/bin"
APPS_DIR="$HOME/.local/share/applications"

say() { printf '\n\033[1;33m==> %s\033[0m\n' "$*"; }

if ! grep -qi bazzite /etc/os-release 2>/dev/null; then
  echo "esto no parece Bazzite. abortando." >&2
  exit 1
fi

mkdir -p "$ALLY_DIR" "$BIN_DIR" "$APPS_DIR"

say "apps flatpak (navegador, launchers, utilidades)"
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
FLATPAKS=(
  com.google.Chrome                 # para claude.ai como app web
  com.heroicgameslauncher.hgl       # Epic / GOG / Amazon
  net.davidotek.pupgui2             # ProtonUp-Qt: versiones de Proton-GE
  com.github.Matoking.protontricks
)
for app in "${FLATPAKS[@]}"; do
  flatpak install --user -y --noninteractive flathub "$app" || echo "no se pudo instalar $app, sigo"
done

say "Claude Code (CLI)"
if ! command -v claude >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/claude" ]; then
  curl -fsSL https://claude.ai/install.sh | bash
else
  echo "claude ya está instalado"
fi

say "contexto del dispositivo en $ALLY_DIR"
cp "$KIT_DIR/claude/CLAUDE.md" "$ALLY_DIR/CLAUDE.md"
install -m 755 "$KIT_DIR/bazzite/ally-doctor.sh" "$BIN_DIR/ally-doctor"

say "lanzadores (agrégalos a Steam con clic derecho → Add to Steam)"
cat > "$BIN_DIR/claude-ally" <<'EOF'
#!/usr/bin/env bash
# Abre Claude Code en ~/ally dentro de Konsole.
cd "$HOME/ally"
exec konsole --fullscreen -e "$HOME/.local/bin/claude"
EOF
chmod 755 "$BIN_DIR/claude-ally"

cat > "$APPS_DIR/claude-code-ally.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Claude Code
Comment=Claude en la terminal, con contexto del Ally X
Exec=$BIN_DIR/claude-ally
Icon=utilities-terminal
Terminal=false
Categories=Utility;
EOF

cat > "$APPS_DIR/claude-web.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Claude
Comment=claude.ai como app
Exec=flatpak run com.google.Chrome --app=https://claude.ai --start-fullscreen
Icon=internet-web-browser
Terminal=false
Categories=Network;
EOF

update-desktop-database "$APPS_DIR" 2>/dev/null || true

case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc" ;;
esac

say "listo"
cat <<EOF
siguientes pasos:
  1. abre una terminal nueva y corre:  claude   (para iniciar sesión)
  2. en el menú de apps: clic derecho en "Claude" y "Claude Code" → Add to Steam
  3. en Modo Juego, Steam + X abre el teclado en pantalla
  4. si algo falla:  ally-doctor  y luego  claude "lee diagnostico.txt"
EOF
