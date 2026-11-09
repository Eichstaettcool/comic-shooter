#!/usr/bin/env bash
# Hilfsskript: Diag-Modus starten und Log schreiben.
#   ./run_diag.sh <modus> <logdatei>
set -u
MODE="$1"
OUT="$2"
cd "$(dirname "$0")" || exit 2
COMIC_LANTEST="$MODE" ./Godot.exe --path project > "$OUT" 2>&1
echo "rc=$? log=$OUT zeilen=$(wc -l < "$OUT")"
