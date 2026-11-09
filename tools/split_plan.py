#!/usr/bin/env python3
"""split_plan.py - zeigt vor dem Schnitt, ob eine Funktion statisch verschiebbar ist.

Prueft pro Funktion:
  - `self.` / `self(`             -> nicht statisch moeglich
  - Zugriff auf Member-Variablen  -> nicht statisch moeglich
  - Aufrufe anderer Funktionen der Quelldatei (muessen im Ziel existieren)
  - Konstanten, die im Ziel stehen muessen

Benutzung:
  python tools/split_plan.py project/scripts/ui_manager.gd _hud_panel_sb _make_chip
  python tools/split_plan.py --file project/scripts/ui_manager.gd --all
"""
import argparse
import re
import sys


def find_func(lines, name):
    pat = re.compile(r"^func\s+" + re.escape(name) + r"\s*\(")
    for i, ln in enumerate(lines):
        if pat.match(ln):
            start = i
            break
    else:
        return None
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


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("args", nargs="*")
    ap.add_argument("--file", dest="f2")
    ap.add_argument("--all", action="store_true")
    ap.add_argument("--target", default="", help="bereits vorhandene Funktionen im Zielmodul")
    a = ap.parse_args()

    if a.f2:
        path = a.f2
        names = a.args
    else:
        if not a.args:
            print("FEHLER: Datei fehlt")
            return 2
        path = a.args[0]
        names = a.args[1:]
    src = open(path, encoding="utf-8").read()
    lines = src.split("\n")

    funcs = [m.group(1) for m in re.finditer(r"^func\s+([A-Za-z0-9_]+)\s*\(", src, re.M)]
    vars_ = set(m.group(1) for m in re.finditer(r"^(?:var|@onready var)\s+([A-Za-z0-9_]+)", src, re.M))
    consts = set(m.group(1) for m in re.finditer(r"^const\s+([A-Za-z0-9_]+)", src, re.M))
    have_in_target = set()
    if a.target:
        t = open(a.target, encoding="utf-8").read()
        have_in_target = set(re.findall(r"^static func\s+([A-Za-z0-9_]+)\s*\(", t, re.M))
        have_in_target |= set(re.findall(r"^func\s+([A-Za-z0-9_]+)\s*\(", t, re.M))

    todo = names or (funcs if a.all else [])
    for name in todo:
        span = find_func(lines, name)
        if not span:
            print("%-32s FEHLT" % name)
            continue
        start, end = span
        body = "\n".join(lines[start:end])
        body_nocode = re.sub(r"#.*", "", body)
        flags = []
        if re.search(r"\bself\b", body_nocode):
            flags.append("SELF")
        used_vars = sorted(v for v in vars_ if re.search(r"(?<![.\w])" + v + r"\b", body_nocode))
        if used_vars:
            flags.append("VAR:" + ",".join(used_vars))
        calls = sorted(set(c for c in funcs
                           if c != name and re.search(r"(?<![.\w])" + c + r"\s*\(", body_nocode)))
        missing = [c for c in calls if c not in have_in_target]
        if missing:
            flags.append("CALL:" + ",".join(missing))
        used_consts = sorted(c for c in consts if re.search(r"\b" + c + r"\b", body_nocode))
        if used_consts:
            flags.append("CONST:" + ",".join(used_consts))
        print("%-32s %4d Zeilen  %s" % (name, end - start, " | ".join(flags) if flags else "sauber"))


if __name__ == "__main__":
    sys.exit(main())
