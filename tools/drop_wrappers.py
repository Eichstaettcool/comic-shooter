#!/usr/bin/env python3
"""drop_wrappers.py - Fassade entlasten: Wrapper loeschen, Aufrufe qualifizieren.

Nach dem Modul-Split stehen in der Fassade Ein-Zeilen-Wrapper
(`func _x(...): return GenY._x(...)`). Sie sind nur noetig, solange Aufrufer
aussen sie benutzen. Wenn alle Aufrufe aus der Fassade selbst kommen, werden
die Wrapper geloescht und die Aufrufe direkt auf die Modulklasse umgestellt.

    python tools/drop_wrappers.py project/scripts/texture_manager.gd
"""
import re
import sys

path = sys.argv[1]
src = open(path, encoding="utf-8").read()
lines = src.split("\n")

wrapper = re.compile(r"^func ([A-Za-z0-9_]+)\((.*)\)(?:\s*->\s*([A-Za-z0-9_\[\]]+))?:\s*(?:return\s+|)"
                     r"([A-Z][A-Za-z0-9_]*)\.\1\((.*)\)$")

mapping = {}
keep = []
removed = 0
for ln in lines:
    m = wrapper.match(ln)
    if m:
        mapping[m.group(1)] = m.group(4)
        removed += 1
        continue
    keep.append(ln)

print("Wrapper entfernt: %d, Module: %d" % (removed, len(set(mapping.values()))))

# Aufrufe in den verbliebenen Zeilen qualifizieren
out = []
touched = 0
for ln in keep:
    if ln.startswith(("#",)):
        out.append(ln)
        continue
    new = ln
    for name in sorted(mapping, key=len, reverse=True):
        pat = re.compile(r"(?<![.\w])" + name + r"\s*\(")
        if pat.search(new):
            new = pat.sub(mapping[name] + "." + name + "(", new)
            touched += 1
    out.append(new)

open(path, "w", encoding="utf-8").write("\n".join(out))
print("Aufrufe qualifiziert: %d Zeilen" % touched)
print("jetzt:", sum(1 for _ in open(path, encoding="utf-8")), "Zeilen")
