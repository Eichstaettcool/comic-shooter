#!/usr/bin/env python3
"""extract_registry.py - _gen_boot/_gen_run in eine Registry-Datei auslagern.

Die beiden Funktionen sind reine Zuordnungslisten `key -> Zeichner`. Sie wandern
in `texture/gen_registry.gd` (zustandslos), die Fassade behaelt Namen und Guard.

Wichtig: von UNTEN nach OBEN arbeiten - sonst verschieben sich die Zeilennummern
der zweiten Funktion und der Schnitt landet an der falschen Stelle (Fehler beim
ersten Versuch).

    python tools/extract_registry.py
"""
import re

TM = "project/scripts/texture_manager.gd"
REG = "project/scripts/texture/gen_registry.gd"


def span(lines, name):
    pat = re.compile(r"^func\s+" + name + r"\s*\(")
    for i, ln in enumerate(lines):
        if pat.match(ln):
            start = i
            break
    else:
        raise SystemExit("nicht gefunden: " + name)
    end = len(lines)
    for j in range(start + 1, len(lines)):
        if lines[j].strip() == "":
            continue
        if not lines[j].startswith((" ", "\t")):
            end = j
            break
    while end > start and lines[end - 1].strip() == "":
        end -= 1
    return start, end


blocks = {}
for name in ("_gen_run", "_gen_boot"):   # von unten nach oben
    lines = open(TM, encoding="utf-8").read().split("\n")
    start, end = span(lines, name)
    body = lines[start:end]
    assert "_built[" in body[3], body[:5]
    rest = body[4:]
    clean = []
    for ln in rest:
        ln = ln.replace("textures[", "tex[")
        ln = ln.replace("_load_external(", "host._load_external(")
        ln = ln.replace("_load_chest_png(", "host._load_chest_png(")
        clean.append(ln)
    blocks[name] = clean
    new = lines[:start] + body[:4] + [
        "\tGenRegistry.%s(textures, self)" % name.lstrip("_")] + lines[end:]
    open(TM, "w", encoding="utf-8").write("\n".join(new))
    print("%s ausgelagert (%d Zeilen), Fassade jetzt %d Zeilen" % (name, len(clean), len(new)))

reg = ["class_name GenRegistry", "extends RefCounted", "",
       "# Runde 138: Zuordnung Textur-Key -> Zeichner-Modul.",
       "# Reine Daten, kein Zustand: der Aufrufer reicht das textures-Dictionary",
       "# und die Fassade herein (fuer _load_external/_load_chest_png).", ""]
for name in ("_gen_boot", "_gen_run"):
    reg.append("static func %s(tex: Dictionary, host: Node) -> void:" % name.lstrip("_"))
    reg += blocks[name]
    reg += ["", ""]
open(REG, "w", encoding="utf-8").write("\n".join(reg).rstrip("\n") + "\n")
print("gen_registry.gd: %d Zeilen" % len(reg))
