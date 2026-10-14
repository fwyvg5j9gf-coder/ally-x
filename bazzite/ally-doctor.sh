#!/usr/bin/env bash
# Junta diagnósticos del Ally X en ~/ally/diagnostico.txt para que Claude los lea.
# Solo lectura: no cambia nada del sistema.
set -uo pipefail

OUT="$HOME/ally/diagnostico.txt"
mkdir -p "$(dirname "$OUT")"

section() { printf '\n===== %s =====\n' "$1"; }
run() { "$@" 2>&1 || true; }

{
  echo "diagnóstico ally-x — $(date -Is)"

  section "sistema"
  run grep -E '^(NAME|VERSION|VARIANT)=' /etc/os-release
  run uname -r
  run rpm-ostree status --booted

  section "batería"
  for bat in /sys/class/power_supply/BAT*; do
    [ -d "$bat" ] || continue
    for f in status capacity energy_full energy_full_design power_now; do
      [ -r "$bat/$f" ] && echo "$f: $(cat "$bat/$f")"
    done
  done

  section "temperaturas"
  run sensors

  section "cpu / memoria"
  run lscpu | grep -E 'Model name|MHz'
  run free -h
  run uptime

  section "procesos que más consumen"
  run ps -eo pid,comm,%cpu,%mem --sort=-%cpu | head -n 15

  section "handheld daemon"
  run systemctl --no-pager status "hhd@$USER"
  run journalctl -u "hhd@$USER" -b --no-pager -n 50

  section "suspensión (último arranque)"
  run journalctl -b --no-pager -g 'suspend|resume|PM:' -n 40

  section "errores del kernel"
  run journalctl -k -b -p err --no-pager -n 40

  section "disco"
  run df -h / /var/home
} > "$OUT"

echo "guardado en $OUT"
