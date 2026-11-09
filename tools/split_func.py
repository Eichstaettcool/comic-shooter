#!/usr/bin/env python3
"""split_func.py - GDScript-Funktionen sauber ausschneiden (Runde 137/138).

Warum: Beim ersten Versuch (Runde 137) wurden Funktionen per Zeilenbereich
geschnitten. Dabei wanderten `var`/`const`-Zeilen mit, die zwischen zwei
Funktionen standen - danach fehlten sie im Zielsript und `ui_style.gd`
hatte einen Parse-Fehler. Dieses Werkzeug schneidet ausschliesslich den
Funktionskoerper: `func NAME(...)` bis zur letzten Zeile mit Einrueckung > 0.

Benutzung
---------
  # nur anzeigen, was geschnitten wuerde
  python tools/split_func.py project/scripts/ui_manager.gd _hud_panel_sb --check

  # Funktion in eine neue Datei verschieben (statisch) und Wrapper erzeugen
  python tools/split_func.py project/scripts/ui_manager.gd _hud_panel_sb \
      --static --class UiStyle --to project/scripts/ui/ui_style.gd \
      --wrapper

Das Werkzeug schreibt NUR, wenn --to oder --wrapper gesetzt ist, und legt
vorher eine .bak-Kopie an. Es aendert nie mehr als eine Funktion.
"""
import argparse
import os
import re
import sys


def find_func(lines, name):
    """Gibt (start, end) zurueck: start = Zeile des `func`, end = exklusiv."""
    pat = re.compile(r"^func\s+" + re.escape(name) + r"\s*\(")
    start = None
    for i, ln in enumerate(lines):
        if pat.match(ln):
            start = i
            break
    if start is None:
        return None
    # Ende: erste Zeile mit Einrueckung 0 nach dem Kopf (inkl. Leerzeilen davor)
    end = len(lines)
    for j in range(start + 1, len(lines)):
        ln = lines[j]
        if ln.strip() == "":
            continue
        if not ln.startswith((" ", "\t")):
            end = j
            break
    # Leerzeilen am Ende nicht mitnehmen
    while end > start and lines[end - 1].strip() == "":
        end -= 1
    return start, end


def parse_signature(head_line):
    """(params, return_type) aus einer func-Zeile."""
    inner = head_line[head_line.index("(") + 1: head_line.rindex(")")]
    params = []
    depth = 0
    cur = ""
    for ch in inner:
        if ch in "([{":
            depth += 1
        elif ch in ")]}":
            depth -= 1
        if ch == "," and depth == 0:
            params.append(cur.strip())
            cur = ""
        else:
            cur += ch
    if cur.strip():
        params.append(cur.strip())
    names = [p.split(":")[0].split("=")[0].strip() for p in params if p]
    ret = ""
    tail = head_line[head_line.rindex(")") + 1:]
    m = re.search(r"->\s*([A-Za-z0-9_\[\]]+)", tail)
    if m:
        ret = m.group(1)
    return names, ret


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("file")
    ap.add_argument("name")
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--static", action="store_true")
    ap.add_argument("--class", dest="cls", default="")
    ap.add_argument("--to", default="")
    ap.add_argument("--wrapper", action="store_true")
    ap.add_argument("--extends", dest="base", default="RefCounted")
    a = ap.parse_args()

    src = open(a.file, encoding="utf-8").read()
    lines = src.split("\n")
    span = find_func(lines, a.name)
    if span is None:
        print("FEHLER: func %s nicht gefunden" % a.name)
        return 1
    start, end = span
    block = lines[start:end]
    # Kopf kann mehrzeilig sein (lange Default-Parameter werden umgebrochen).
    h_end = start
    depth = 0
    while True:
        depth += lines[h_end].count("(") - lines[h_end].count(")")
        if depth <= 0 or h_end + 1 >= len(lines):
            break
        h_end += 1
    head_one = " ".join(l.strip() for l in lines[start:h_end + 1])
    names, ret = parse_signature(head_one)
    print("== %s  (%d Zeilen, %d Parameter, return=%s)" % (a.name, end - start, len(names), ret or "-"))
    print("   Datei: %s  Zeilen %d..%d" % (a.file, start + 1, end))
    print("   Signatur: %s" % block[0].strip())
    if a.check:
        return 0

    if not (a.to or a.wrapper):
        print("   (Trockenlauf - nichts geschrieben. --to/--wrapper fehlen)")
        return 0

    moved = "\n".join(block)
    if a.static:
        moved = moved.replace("func %s(" % a.name, "static func %s(" % a.name, 1)

    # Ziel
    if a.to:
        os.makedirs(os.path.dirname(a.to), exist_ok=True)
        if os.path.exists(a.to):
            dst = open(a.to, encoding="utf-8").read()
            if re.search(r"^(?:static )?func\s+" + re.escape(a.name) + r"\s*\(", dst, re.M):
                print("FEHLER: %s steht schon in %s" % (a.name, a.to))
                return 1
        else:
            dst = ""
            if a.cls:
                dst = "class_name %s\nextends %s\n\n" % (a.cls, a.base)
        open(a.to + ".bak", "w", encoding="utf-8").write(dst)
        open(a.to, "w", encoding="utf-8").write(dst.rstrip("\n") + "\n\n\n" + moved + "\n")
        print("   -> Funktion in %s geschrieben" % a.to)

    # Quelle
    open(a.file + ".bak", "w", encoding="utf-8").write(src)
    out = lines[:start]
    if a.wrapper:
        call = ", ".join(names)
        target = a.cls if a.cls else "UiStyle"
        sig = head_one
        if a.static:
            # Wrapper bleibt normal (nicht statisch)
            sig = sig.replace("static func ", "func ")
        # Ein-Zeilen-Wrapper: kostet eine Zeile statt drei (Spec-Muster).
        # Rueckgabetyp void: kein `return <void-call>` (Parse-Fehler in GDScript).
        if re.search(r"->\s*void\s*:\s*$", sig):
            out.append("%s %s.%s(%s)" % (sig, target, a.name, call))
        else:
            out.append("%s return %s.%s(%s)" % (sig, target, a.name, call))
    out = out + lines[end:]
    open(a.file, "w", encoding="utf-8").write("\n".join(out))
    print("   -> aus %s entfernt%s" % (a.file, ", Wrapper eingefuegt" if a.wrapper else ""))
    print("   Naechster Schritt: ./Godot.exe --headless --path project --quit-after 20")
    return 0


if __name__ == "__main__":
    sys.exit(main())
