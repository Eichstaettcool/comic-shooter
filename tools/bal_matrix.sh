#!/usr/bin/env bash
# v1.56: Messmatrix abarbeiten (Bot-Proxy). Startet je Zelle ein Godot headless.
cd "$(dirname "$0")/.." || exit 2
set -u
lauf() {  # modus stufe profil laeufe max ts datei
  COMIC_LANTEST=balbot COMIC_BAL_MODE=$1 COMIC_BAL_STUFE=$2 COMIC_BAL_PROFIL=$3 \
  COMIC_BAL_LAEUFE=$4 COMIC_BAL_MAX=$5 COMIC_BAL_TS=${6:-4} \
    ./Godot.exe --headless --path project > "$7" 2>&1
  echo "fertig: $7"
}
lauf endlos  leicht    anfaenger 2 13 4 logs_bal_mx_endlos_leicht.log
lauf endlos  normal    anfaenger 2 11 4 logs_bal_mx_endlos_normal.log
lauf endlos  schwer    anfaenger 2 8  4 logs_bal_mx_endlos_schwer.log
lauf endlos  hardcore  anfaenger 2 5  4 logs_bal_mx_endlos_hardcore.log
lauf wellen  leicht    anfaenger 2 8  4 logs_bal_mx_wellen_leicht.log
lauf wellen  normal    anfaenger 2 8  4 logs_bal_mx_wellen_normal.log
lauf wellen  schwer    anfaenger 2 6  4 logs_bal_mx_wellen_schwer.log
lauf wellen  hardcore  anfaenger 2 5  4 logs_bal_mx_wellen_hardcore.log
lauf runden  leicht    anfaenger 2 12 4 logs_bal_mx_runden_leicht.log
lauf runden  normal    anfaenger 2 10 4 logs_bal_mx_runden_normal.log
lauf runden  hart      anfaenger 2 8  4 logs_bal_mx_runden_hart.log
lauf endlos  normal    erfahren  2 11 4 logs_bal_mx_endlos_normal_erf.log
lauf endlos  schwer    erfahren  2 8  4 logs_bal_mx_endlos_schwer_erf.log
lauf wellen  normal    erfahren  2 8  4 logs_bal_mx_wellen_normal_erf.log
lauf runden  normal    erfahren  2 10 4 logs_bal_mx_runden_normal_erf.log
echo "MATRIX FERTIG"
