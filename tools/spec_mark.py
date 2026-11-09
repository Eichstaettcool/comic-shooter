#!/usr/bin/env python3
"""Markiert SPEC-Punkte als erledigt: python tools/spec_mark.py SPEC_X.md P1 P2.3

Setzt in jeder Tabellenzeile, die mit "| **<ID>**" beginnt, das LETZTE "[ ]"
auf "[x]" (Statusspalte). Gibt eine Zeile pro Treffer aus, damit ein Tippfehler
in der ID sofort auffaellt.
"""
import io
import re
import sys


def main() -> int:
    if len(sys.argv) < 3:
        print("Aufruf: spec_mark.py <spec.md> <ID> [<ID> ...]")
        return 2
    path = sys.argv[1]
    ids = sys.argv[2:]
    src = io.open(path, newline="", encoding="utf-8").read()
    crlf = "\r\n" in src
    s = src.replace("\r\n", "\n")
    lines = s.split("\n")
    hits = {i: 0 for i in ids}
    for n, line in enumerate(lines):
        for pid in ids:
            if not line.startswith("| **%s." % pid):
                continue
            if "[x]" in line:
                hits[pid] += 1
                continue
            idx = line.rfind("[ ]")
            if idx < 0:
                continue
            lines[n] = line[:idx] + "[x]" + line[idx + 3:]
            hits[pid] += 1
    out = "\n".join(lines)
    if crlf:
        out = out.replace("\n", "\r\n")
    io.open(path, "w", newline="", encoding="utf-8").write(out)
    for pid in ids:
        print("  %-6s Zeilen markiert: %d" % (pid, hits[pid]))
    missing = [p for p in ids if hits[p] == 0]
    if missing:
        print("FEHLER: keine Zeile gefunden fuer %s" % ", ".join(missing))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
