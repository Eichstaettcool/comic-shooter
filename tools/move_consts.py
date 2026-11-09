#!/usr/bin/env python3
"""move_consts.py - const-Definitionen in ein Zielmodul verschieben, Aliase bleiben.

Warum: GDScript braucht die Konstanten dort, wo der Code steht. Die oeffentlichen
Namen (TextureManager.HAT_NAMES usw.) muessen aber weiter funktionieren - deshalb
bleibt in der Quelle ein `const NAME := Ziel.NAME` stehen.

Wichtig: mehrzeilige Konstanten (Dicts/Arrays) werden ueber Klammertiefe
eingesammelt - die erste Fassung brach nach der ersten Zeile ab und riss den
Rumpf ab (Fehler in Runde 138).

    python tools/move_consts.py quelle.gd ziel.gd TexDraw OUTLINE SHADOW ...
"""
import re
import sys


def const_span(lines, name):
    """(start, end) einer const-Definition, mehrzeilig korrekt."""
    pat = re.compile(r"^const\s+" + re.escape(name) + r"\b")
    for i, ln in enumerate(lines):
        if not pat.match(ln):
            continue
        depth = ln.count("[") + ln.count("{") - ln.count("]") - ln.count("}")
        j = i
        while depth > 0 and j + 1 < len(lines):
            j += 1
            depth += lines[j].count("[") + lines[j].count("{")
            depth -= lines[j].count("]") + lines[j].count("}")
        return i, j + 1
    return None


def main():
    src_path, dst_path, cls = sys.argv[1], sys.argv[2], sys.argv[3]
    names = sys.argv[4:]
    src = open(src_path, encoding="utf-8").read().split("\n")
    dst = open(dst_path, encoding="utf-8").read().rstrip("\n")

    moved, replacements = [], {}
    for n in names:
        span = const_span(src, n)
        if not span:
            print("FEHLT in Quelle: %s" % n)
            continue
        block = src[span[0]:span[1]]
        moved.append("\n".join(block))
        replacements[span[0]] = (span[1], "const %s := %s.%s" % (n, cls, n))
        print("verschoben: %-16s %d Zeile(n)" % (n, span[1] - span[0]))

    out, i = [], 0
    while i < len(src):
        if i in replacements:
            end, alias = replacements[i]
            out.append(alias)
            i = end
            continue
        out.append(src[i])
        i += 1

    open(dst_path, "w", encoding="utf-8").write(dst + "\n\n" + "\n".join(moved) + "\n")
    open(src_path, "w", encoding="utf-8").write("\n".join(out))
    print("geschrieben: %s (+%d consts), %s mit Aliasen" % (dst_path, len(moved), src_path))


if __name__ == "__main__":
    main()
