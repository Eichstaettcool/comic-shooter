#!/usr/bin/env bash
# split_core.sh - Block G3..G7: Core-Module aus game_manager.gd auslagern.
set -u
cd "$(dirname "$0")/.." || exit 2
SRC=project/scripts/game_manager.gd
OK=0; FAILED=""

run_mod() { # $1 Klasse, $2 Zieldatei, $3 page-var, $4 Funktionen
  local cls="$1" to="$2" var="$3" funcs="$4"
  echo "### $cls -> $to"
  python tools/hostify.py "$SRC" --class "$cls" --to "$to" --page-var "$var" --funcs "$funcs" || { FAILED="$FAILED $cls"; return; }
  python tools/postfix_pages.py --facade "$SRC" "$to" | grep -v unveraendert
  ./Godot.exe --headless --path project --import >/dev/null 2>&1
  local err
  err=$(./Godot.exe --headless --path project --quit-after 20 2>&1 | grep -E "SCRIPT ERROR|Parse Error" | head -3)
  if [ -n "$err" ]; then
    echo "  BOOT FEHLER:"; echo "$err"; FAILED="$FAILED $cls"
  else
    echo "  boot ok ($(wc -l < "$to") Zeilen)"; OK=$((OK+1))
  fi
}

# UPGRADES-Tabelle vorher auslagern (sonst 200 Zeilen doppelt)
printf 'class_name UpgradesModule\nextends RefCounted\n\n# Runde 138: Upgrades aus game_manager.gd\nvar host: Node = null\n' > project/scripts/core/upgrades.gd
python tools/move_consts.py "$SRC" project/scripts/core/upgrades.gd UpgradesModule UPGRADES

run_mod UpgradesModule project/scripts/core/upgrades.gd _upg \
  _upgrade_options,_open_upgrade_ui,_on_upgrade_chosen,_apply_upgrade_local,_on_upgrade_earned,_on_upgrade_toast_tapped
run_mod WavesModule project/scripts/core/waves.gd _waves \
  _start_wave,_next_wave,wave_balance,_recount_wave
run_mod BossesModule project/scripts/core/bosses.gd _boss \
  _spawn_boss,_biome_boss_type,_biome_boss_name,_mini_boss_type,_mini_boss_display_name,name_miniboss,on_miniboss_killed
run_mod ShopLogic project/scripts/core/shop_logic.gd _shopl \
  shop_price,shop_price_mult,chest_price,_build_shop_offers,buy_quick,buy_boost,shop_offer_ids
run_mod SpawnApi project/scripts/core/spawn_api.gd _spawn \
  spawn_monster_at,spawn_projectile,spawn_run_chest_at,_pick_random_monster_type

echo "### fertig: $OK/5 gruen, Probleme:${FAILED:- keine}"
wc -l "$SRC" project/scripts/core/*.gd
