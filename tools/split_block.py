#!/usr/bin/env python3
"""split_block.py - viele Funktionen verschieben, aber jede einzeln.

Warum: SPEC_V138 verlangt "eine Funktion pro Schritt". Dieses Skript ruft
`split_func.py` genau einmal pro Funktion auf (kein Sammelschnitt), sortiert die
Reihenfolge aber topologisch: Funktionen, die andere Funktionen desselben
Blocks aufrufen, wandern erst nach ihren Abhaengigkeiten.

Plan-Datei (TSV, # = Kommentar):
    ziel/datei.gd       KlassenName    func_a,func_b,func_c

Benutzung:
    python tools/split_block.py project/scripts/texture_manager.gd tools/plan_c2.tsv
    python tools/split_block.py ... --dry     # nur Reihenfolge zeigen
"""
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SPLIT = os.path.join(HERE, "split_func.py")


def func_span(lines, name):
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


def order(src_lines, names):
    """Topologisch: Ziele zuerst verschieben, die nichts aus der Gruppe brauchen."""
    bodies = {}
    for n in names:
        span = func_span(src_lines, n)
        bodies[n] = "" if not span else "\n".join(src_lines[span[0]:span[1]])
    deps = {n: set() for n in names}
    for n in names:
        body = re.sub(r"#.*", "", bodies[n])
        for other in names:
            if other != n and re.search(r"(?<![.\w])" + other + r"\s*\(", body):
                deps[n].add(other)
    done, out = set(), []
    while len(out) < len(names):
        ready = [n for n in names if n not in done and not (deps[n] - done)]
        if not ready:
            # Zyklus: Rest in Originalreihenfolge
            out += [n for n in names if n not in done]
            break
        for n in ready:
            out.append(n)
            done.add(n)
    return out, deps


def main():
    src = sys.argv[1]
    plan = sys.argv[2]
    dry = "--dry" in sys.argv

    base = sys.argv[3] if len(sys.argv) > 3 and not sys.argv[3].startswith("--") else "RefCounted"
    entries = []
    for ln in open(plan, encoding="utf-8"):
        ln = ln.strip()
        if not ln or ln.startswith("#"):
            continue
        target, cls, funcs = [x.strip() for x in ln.split("\t")]
        entries.append((target, cls, [f for f in funcs.split(",") if f]))

    total = 0
    for target, cls, names in entries:
        lines = open(src, encoding="utf-8").read().split("\n")
        ordered, deps = order(lines, names)
        print("== %s -> %s (%d Funktionen)" % (cls, target, len(names)))
        for n in ordered:
            inner = sorted(d for d in deps[n] if d in names)
            print("   %-34s wartet auf: %s" % (n, ",".join(inner) or "-"))
        if dry:
            continue
        for n in ordered:
            r = subprocess.run([sys.executable, SPLIT, src, n, "--static",
                                "--class", cls, "--to", target, "--wrapper",
                                "--extends", base],
                               capture_output=True, text=True)
            ok = "-> Funktion" in r.stdout
            print("   %-34s %s" % (n, "verschoben" if ok else "FEHLER: " + r.stdout.strip().replace("\n", " ")))
            if not ok:
                return 1
            total += 1
    print("== fertig: %d Funktionen verschoben" % total)
    return 0


if __name__ == "__main__":
    sys.exit(main())
