#!/usr/bin/env python3
"""move_scripts.py - Block I: Skripte in die Zielordner verschieben.

Verschiebt die Dateien (inkl. `.uid`) und zieht alle `res://scripts/...`-Pfade in
`project.godot`, `scenes/*.tscn` und allen `.gd` nach. Prueft danach, dass kein
alter Pfad mehr referenziert wird.

    python tools/move_scripts.py [--dry]
"""
import os
import re
import shutil
import sys

DRY = "--dry" in sys.argv
ROOT = "project"

# alt -> neu (relativ zu project/)
MAP = {
    "scripts/texture_manager.gd": "scripts/autoload/texture_manager.gd",
    "scripts/sound_manager.gd": "scripts/autoload/sound_manager.gd",
    "scripts/loc.gd": "scripts/autoload/loc.gd",
    "scripts/net_manager.gd": "scripts/net/net_manager.gd",
    "scripts/loot_table.gd": "scripts/systems/loot_table.gd",
    "scripts/chest_system.gd": "scripts/systems/chest_system.gd",
    "scripts/corruption_zone.gd": "scripts/systems/corruption_zone.gd",
    "scripts/lan_diag_tmp.gd": "scripts/tools/lan_diag_tmp.gd",
    "scripts/ui_manager.gd": "scripts/ui/ui_manager.gd",
    "scripts/projectile.gd": "scripts/entities/projectile.gd",
    "scripts/item_system.gd": "scripts/entities/item_system.gd",
    "scripts/chest_ui.gd": "scripts/ui/chest_ui.gd",
    "scripts/monster_spawner.gd": "scripts/entities/monster/monster_spawner.gd",
}


def main():
    moved = 0
    for old, new in MAP.items():
        src = os.path.join(ROOT, old)
        dst = os.path.join(ROOT, new)
        if not os.path.exists(src):
            print("  fehlt schon: %s" % old)
            continue
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        if DRY:
            print("  wuerde: %s -> %s" % (old, new))
        else:
            shutil.move(src, dst)
            uid = src + ".uid"
            if os.path.exists(uid):
                shutil.move(uid, dst + ".uid")
            print("  verschoben: %s -> %s" % (old, new))
        moved += 1

    # Pfade in allen Textdateien nachziehen
    changed = 0
    for base, _, files in os.walk(ROOT):
        for f in files:
            if not f.endswith((".gd", ".tscn", ".godot", ".cfg", ".md")):
                continue
            p = os.path.join(base, f)
            try:
                text = open(p, encoding="utf-8").read()
            except UnicodeDecodeError:
                continue
            orig = text
            for old, new in MAP.items():
                text = text.replace("res://" + old, "res://" + new)
            if text != orig:
                if not DRY:
                    open(p, "w", encoding="utf-8").write(text)
                changed += 1
                print("  Pfade angepasst: %s" % p.replace("\\", "/"))
    print("== %d Dateien verschoben, %d Dateien mit Pfad-Fixes" % (moved, changed))

    # Kontrolle: kein alter Pfad mehr vorhanden
    leftovers = []
    for base, _, files in os.walk(ROOT):
        for f in files:
            if not f.endswith((".gd", ".tscn", ".godot")):
                continue
            p = os.path.join(base, f)
            text = open(p, encoding="utf-8", errors="ignore").read()
            for old in MAP:
                if "res://" + old in text:
                    leftovers.append("%s -> %s" % (p, old))
    if leftovers:
        print("WARNUNG: alte Pfade noch vorhanden:")
        for l in leftovers:
            print("  " + l)
        return 1
    print("== keine alten Pfade mehr")
    return 0


if __name__ == "__main__":
    sys.exit(main())
