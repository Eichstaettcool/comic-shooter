#!/usr/bin/env python3
"""repair_consts.py - abgerissene mehrzeilige Konstanten wiederherstellen.

move_consts hat bei `const NAME = {` nur die Kopfzeile verschoben, der Rumpf
blieb in der Quelle. Dieses Skript sammelt den Rumpf in der Quelle ein, schreibt
die vollstaendige Definition ins Ziel und entfernt den Rest aus der Quelle.
"""
import re
import sys

SRC = "project/scripts/player_controller.gd"
DST = "project/scripts/entities/player/weapons.gd"
NAMES = ["WEAPON_DATA", "RARITY_COLOR", "WEAPON_RARITY"]


def grab(lines, i):
    """Sammelt ab Zeile i (Rumpf ohne Kopf) bis zum Schliessen der Klammer."""
    depth, out, j = 0, [], i
    while j < len(lines):
        ln = lines[j]
        depth += ln.count("{") + ln.count("[") - ln.count("}") - ln.count("]")
        out.append(ln)
        j += 1
        if depth <= 0 and ("}" in ln or "]" in ln):
            break
    return out, j


src = open(SRC, encoding="utf-8").read().split("\n")
fixed = {}
drop = set()
for name in NAMES:
    for i, ln in enumerate(src):
        if ln.startswith("const %s := " % name):
            body, end = grab(src, i + 1)
            fixed[name] = "const %s := {%s" % (name, "\n" + "\n".join(body))
            for k in range(i + 1, end):
                drop.add(k)
            print("%-14s Rumpf %d Zeilen" % (name, end - i - 1))
            break

src = [ln for i, ln in enumerate(src) if i not in drop]
open(SRC, "w", encoding="utf-8").write("\n".join(src))

dst = open(DST, encoding="utf-8").read().split("\n")
out = []
for ln in dst:
    m = re.match(r"^const ([A-Za-z0-9_]+) (=|:=) \{$", ln)
    if m and m.group(1) in fixed:
        out.append(fixed[m.group(1)])
    else:
        out.append(ln)
open(DST, "w", encoding="utf-8").write("\n".join(out))
print("Zieldatei mit %d vollstaendigen Konstanten" % len(fixed))
