#!/usr/bin/env bash
# split_overlays.sh - Block E: sieben Overlays aus ui_manager auslagern.
# Jede Datei einzeln: hostify -> import -> Boot-Pruefung -> Stopp bei Fehler.
set -u
cd "$(dirname "$0")/.." || exit 2
SRC=project/scripts/ui_manager.gd
OK=0
FAILED=""

run_page() { # $1 = Klasse, $2 = Zieldatei, $3 = page-var, $4 = Funktionen
  local cls="$1" to="$2" var="$3" funcs="$4"
  echo "### $cls -> $to"
  python tools/hostify.py "$SRC" --class "$cls" --to "$to" --page-var "$var" --funcs "$funcs" || { echo "  hostify FEHLER"; FAILED="$FAILED $cls"; return; }
  ./Godot.exe --headless --path project --import >/dev/null 2>&1
  local err
  err=$(./Godot.exe --headless --path project --quit-after 20 2>&1 | grep -E "SCRIPT ERROR|Parse Error" | head -3)
  if [ -n "$err" ]; then
    echo "  BOOT FEHLER:"; echo "$err"
    FAILED="$FAILED $cls"
  else
    echo "  boot ok ($(wc -l < "$to") Zeilen)"
    OK=$((OK+1))
  fi
}

run_page UpgradeCards project/scripts/ui/overlays/upgrade_cards.gd _cards \
  show_upgrade_cards,hide_upgrade_cards,_on_card_pressed
run_page UpgradeToast project/scripts/ui/overlays/upgrade_toast.gd _toast \
  show_upgrade_toast,hide_upgrade_toast,_toast_text,_pop_toast,has_upgrade_toast
run_page PauseOverlay project/scripts/ui/overlays/pause.gd _pause \
  show_pause,hide_pause,_on_difficulty_set,_on_aim_set,refresh_difficulty_ui,refresh_aim_ui,_sync_setting_rows,show_tip
run_page DeathOverlay project/scripts/ui/overlays/death.gd _death \
  _create_death_screen,show_death_screen
run_page LobbyOverlay project/scripts/ui/overlays/lobby.gd _lobby \
  _build_lobby,show_lobby,update_lobby,hide_lobby,_on_lobby_ready_pressed,_on_lobby_start_pressed,_on_lobby_leave_pressed
run_page DisconnectOverlay project/scripts/ui/overlays/disconnect.gd _disc \
  _build_disconnect_screen,show_disconnect_screen,hide_disconnect_screen,_on_disconnect_back
run_page ShopRunOverlay project/scripts/ui/overlays/shop_run.gd _shoprun \
  show_shop,hide_shop,update_shop_coins,_build_shop,_on_shop_buy,_on_shop_continue

echo "### fertig: $OK/7 gruen, Probleme:${FAILED:- keine}"
wc -l "$SRC"
