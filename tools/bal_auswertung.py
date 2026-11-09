#!/usr/bin/env python3
"""Auswertung der Bot-Laeufe (Spec 4.1/4.3).

Liest alle logs_bal_*.log im Projektwurzelverzeichnis, zieht die
[BOT][LAUF]-Zeilen und rechnet je Zelle (Modus x Stufe x Profil)
Median / Min / Max / n.  Schreibt project/BALANCE_BERICHT.md.

Aufruf:  python tools/bal_auswertung.py            (nur Tabelle drucken)
         python tools/bal_auswertung.py --write    (Bericht schreiben)
"""
import glob, os, re, statistics, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PAT = re.compile(
    r"\[BOT\]\[LAUF\] profil=(\w+) modus=(\w+) stufe=(\w+) lauf=(\d+) "
    r"zeit=([\d.]+) welle=(\d+) tode=(\d+) treffer=(\d+) treffer60=([\d.]+) "
    r"schaden=(\d+) kills=(\d+) heilung=(\d+) ende=(\w+)")


def sammle():
    zellen = {}
    for pfad in sorted(glob.glob(os.path.join(ROOT, "logs_bal_mx_*.log"))):
        try:
            text = open(pfad, encoding="utf-8", errors="replace").read()
        except OSError:
            continue
        for m in PAT.finditer(text):
            profil, modus, stufe = m.group(1), m.group(2), m.group(3)
            zellen.setdefault((modus, stufe, profil), []).append({
                "zeit": float(m.group(5)), "welle": int(m.group(6)),
                "tode": int(m.group(7)), "treffer": int(m.group(8)),
                "treffer60": float(m.group(9)), "schaden": int(m.group(10)),
                "kills": int(m.group(11)), "heilung": int(m.group(12)),
                "ende": m.group(13), "log": os.path.basename(pfad),
            })
    return zellen


def mmss(s):
    s = float(s)
    return "%d:%04.1f" % (int(s // 60), s % 60)


def tabelle(zellen):
    zeilen = ["| Modus | Stufe | Profil | n | Median | Min | Max | Wellen/Runden (Median) | LP/60 s (Median) | Ende |",
              "|---|---|---|---|---|---|---|---|---|---|"]
    for key in sorted(zellen):
        modus, stufe, profil = key
        laeufe = zellen[key]
        z = sorted(r["zeit"] for r in laeufe)
        w = sorted(r["welle"] for r in laeufe)
        t60 = sorted(r["treffer60"] for r in laeufe)
        enden = sorted({r["ende"] for r in laeufe})
        zeilen.append("| %s | %s | %s | %d | **%s** | %s | %s | %d | %.1f | %s |" % (
            modus, stufe, profil, len(laeufe), mmss(statistics.median(z)),
            mmss(z[0]), mmss(z[-1]), int(statistics.median(w)),
            statistics.median(t60), "/".join(enden)))
    return "\n".join(zeilen)


if __name__ == "__main__":
    z = sammle()
    if not z:
        print("keine [BOT][LAUF]-Zeilen gefunden")
        sys.exit(1)
    txt = tabelle(z)
    print(txt)
    if "--write" in sys.argv:
        ziel = os.path.join(ROOT, "project", "BALANCE_BERICHT.md")
        alt = ""
        if os.path.exists(ziel):
            alt = open(ziel, encoding="utf-8").read()
            marke = "<!-- MESSUNG -->"
            if marke in alt:
                alt = alt.split(marke)[0]
        neu = alt + "<!-- MESSUNG -->\n## Messung Bot-Proxy (automatisch erzeugt)\n\n"
        neu += "Basis: `tools/bal_auswertung.py`, Rohlogs `logs_bal_mx_*.log` (Matrix `tools/bal_matrix.sh`).\n\n"
        neu += txt + "\n"
        open(ziel, "w", encoding="utf-8").write(neu)
        print("\ngeschrieben:", ziel)
