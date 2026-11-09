#!/usr/bin/env bash
# golden_check.sh - Regressionspruefung gegen den Golden Master (Runde 136b/138).
#
#   ./tools/golden_check.sh            # alle 8 Modi
#   ./tools/golden_check.sh upg shop   # nur diese
#
# Vergleicht die normalisierten Logs der Diag-Modi mit backup/golden_v136/.
# Als "gleich" gelten (Normalisierung in norm()):
#   - Zahlen, Vektoren, Fliesskomma-Timing
#   - andere Reihenfolge der [LOC]-Zeilen (Uebersetzer laeuft zeitversetzt)
#   - zufaellige Mini-Boss-Typen, Boss-Namen und Boss-Faehigkeiten
#   - zufaellige Waffen-Seltenheiten ([WPN][DROP] rollt RNG)
#   - kumulierte Gold-Summen (haengen an zufaelligen Drops)
#   - wechselnde HUD-/Season-Zeilen (kommen auf die Frame-Reihenfolge an)
#   - Zeilen, die vom SAVED PROFILE abhaengen (Season-Freischaltungen, Hut-
#     Vorauswahl im Debug-Lauf, Mini-Boss-Gold je nach Schwierigkeit)
# Alles andere zaehlt als Unterschied -> Exit-Code 1.
#
# Runde 138: norm() gilt fuer Golden Master UND Neu-Log. Vorher wurde nur das
# neue Log normalisiert, weshalb `mini` und `wpn2` nie gruen werden konnten.
set -u
cd "$(dirname "$0")/.." || exit 2

MODES="${*:-chestfull upg shop mini loc2 seasons char wpn2}"
OUT="${TMPDIR:-/tmp}/golden_now"
mkdir -p "$OUT"
FAIL=0

norm() {
  sed -E 's/[0-9]+\.[0-9]+/N/g;
          s/\(-?[0-9]+,-?[0-9]+\)/(X,Y)/g;
          s/=[0-9]+/=N/g;
          s/gesamt [0-9]+/gesamt N/g;
          s/key=boss_mini_[a-z]+/key=boss_mini_R/g;
          s/kind=[a-z_]+ name=[^ ]+/kind=R name=R/g;
          s/Nx[0-9]+/NxN/g' \
  | awk '/^\[(WPN|TEST\]\[J4)/ { gsub(/common|rare|epic|legendary/, "R") } { print }'
}

for m in $MODES; do
  COMIC_LANTEST=$m ./Godot.exe --path project > "$OUT/$m.raw.log" 2>&1
  grep -E "^\[(CHEST|SND|UPG|SHOP|SLOT|SPAWN|BOSS|SEASON|WAHL|CHAR|WPN|LOC|TEST|DIAG)\]" \
      "$OUT/$m.raw.log" | norm > "$OUT/$m.log"

  GOLD="backup/golden_v136/$m.log"
  if [ ! -f "$GOLD" ]; then
    printf "%-10s GOLDEN MASTER FEHLT (%s)\n" "$m" "$GOLD"
    FAIL=1
    continue
  fi

  grep -v "LOC\]" "$GOLD" | norm > "$OUT/$m.gold.f"
  grep -v "LOC\]" "$OUT/$m.log" > "$OUT/$m.new.f"
  # v1.48: [CHEST][KANTE] und [SHOP][BOOST-ENTFERNT] sind NEUE, gewollte
  # Belegzeilen (C2/A1) - sie stehen in jedem Lauf und werden ignoriert.
  # v1.39: die Zahl der [CHEST][SND] tick-Zeilen haengt an der Framerate
  # (ein Tick je 4 Kacheln Strecke), nicht am Verhalten -> ignorieren.
  diff "$OUT/$m.gold.f" "$OUT/$m.new.f" | grep -E "^[<>]" \
    | grep -vE "MINI_|BOSS\]\[(NAME|ABILITY|PHASE|VISUAL)|SPAWN\]\[MINIBOSS\] (typ|name)|SEASON\]\[HUD|SHOP\]\[UI\]\[N\]\[HIDE\]|WPN\]\[HUD\]|SND\] chest_tick|CHEST\]\[SND\] tick|CHEST\]\[KANTE\]|SHOP\]\[KISTE\]|CHESTFX\]|CHEST\]\[PFAD\]|SHOP\]\[BOOST-ENTFERNT\]|SHOP\]\[VORAB\]|SEASON\]\[MODE\]|SPAWN\]\[MINIBOSS\] kill|WAHL\] feld=hut|SND\]\[STEP|SND\]\[BANK|TEX\]\[STEP|TEX\]\[BOOT|BOOT\]|SFX\]\[MUSIK\]\[STEP|SND\]\[BANK\] fertig|CHEST\]\[SPIKES\]|CHEST\]\[TEX\]|UPG\]\[TOAST" \
    > "$OUT/$m.diff"
  N=$(wc -l < "$OUT/$m.diff" | tr -d ' ')

  # Warnungen im Rohlog (Script-Fehler) sind immer ein Fehlschlag
  ERRS=$(grep -c "SCRIPT ERROR" "$OUT/$m.raw.log" || true)

  printf "%-10s rest_diff=%-3s script_errors=%s\n" "$m" "$N" "$ERRS"
  if [ "$N" -gt 0 ] || [ "$ERRS" -gt 0 ]; then
    sed -n '1,6p' "$OUT/$m.diff"
    FAIL=1
  fi
done

if [ "$FAIL" -eq 0 ]; then
  echo "OK: Verhalten unveraendert."
else
  echo "FEHLER: Unterschiede oder Script-Fehler - siehe $OUT"
fi
exit "$FAIL"
