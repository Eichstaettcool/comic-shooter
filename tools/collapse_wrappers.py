#!/usr/bin/env python3
"""collapse_wrappers.py - 3-Zeilen-Wrapper zu Ein-Zeilen-Wrappern zusammenziehen.

Muster:
    func NAME(args) -> T:
        return UiStyle.NAME(args)
    <leer>
wird zu:
    func NAME(args) -> T: return UiStyle.NAME(args)

Nur Wrapper, die exakt auf das Zielobjekt delegieren, werden angefasst.
"""
import re
import sys

path = sys.argv[1]
target = sys.argv[2] if len(sys.argv) > 2 else "UiStyle"
lines = open(path, encoding="utf-8").read().split("\n")
out = []
i = 0
n = 0
while i < len(lines):
    ln = lines[i]
    if (ln.startswith("func ") and ln.rstrip().endswith(":")
            and i + 1 < len(lines)):
        body = lines[i + 1]
        m = re.match(r"^\t(return )?%s\.([A-Za-z0-9_]+)\((.*)\)$" % re.escape(target), body)
        if m and (i + 2 >= len(lines) or lines[i + 2].strip() == ""):
            out.append(ln.rstrip() + " " + body.strip())
            n += 1
            i += 2
            continue
    out.append(ln)
    i += 1
open(path, "w", encoding="utf-8").write("\n".join(out))
print("zusammengezogen: %d Wrapper" % n)
