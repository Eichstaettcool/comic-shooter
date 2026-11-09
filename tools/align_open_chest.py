#!/usr/bin/env python3
"""D1 — offene Kiste auf die geschlossene ausrichten.

Gemessen: `chest_*.png` hat seine Standflaeche bei y=464, `open_*.png` bei
y=490. Beim Texturtausch im Reveal springt die Kiste dadurch ~26 px nach unten
(auf dem Handy sichtbar). Dieses Werkzeug verschiebt die offene Kachel so,
dass Standflaeche (unterste Zeile) und Standmitte (x) exakt zur geschlossenen
passen, und schreibt `open_<tier>.png`.

Danach gilt: gleiche Leinwand, gleiche Standflaeche -> kein Versatz.
"""
import os
import sys

from PIL import Image

BASE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "project", "assets", "chests")


def base_row(img):
    W, H = img.size
    px = img.load()
    for y in range(H - 1, -1, -1):
        for x in range(W):
            if px[x, y][3] > 8:
                return y
    return -1


def base_span(img, row, depth=24):
    """x-Bereich der untersten `depth` Zeilen = Standflaeche."""
    W, H = img.size
    px = img.load()
    minx, maxx = W, 0
    for y in range(max(0, row - depth), row + 1):
        for x in range(W):
            if px[x, y][3] > 8:
                minx = min(minx, x)
                maxx = max(maxx, x)
    return minx, maxx


def process(tier):
    closed = Image.open(os.path.join(BASE, "chest_%s.png" % tier)).convert("RGBA")
    openp = os.path.join(BASE, "open_%s.png" % tier)
    opened = Image.open(openp).convert("RGBA")
    rc = base_row(closed)
    ro = base_row(opened)
    lc, hc = base_span(closed, rc)
    lo, ho = base_span(opened, ro)
    dy = ro - rc
    dx = int(round(((lo + ho) * 0.5) - ((lc + hc) * 0.5)))
    print("[D1][%s] Standflaeche geschlossen y=%d x=%d..%d | offen y=%d x=%d..%d"
          % (tier, rc, lc, hc, ro, lo, ho))
    print("[D1][%s] Versatz offen=dx %+d, dy %+d -> wird ausgeglichen" % (tier, dx, dy))
    if dx == 0 and dy == 0:
        print("[D1][%s] bereits ausgerichtet" % tier)
        return 0, 0

    out = Image.new("RGBA", closed.size, (0, 0, 0, 0))
    out.paste(opened, (-dx, -dy))
    out.save(openp)
    # Kontrolle
    chk = Image.open(openp).convert("RGBA")
    rn = base_row(chk)
    ln, hn = base_span(chk, rn)
    ok = (rn == rc) and abs(((ln + hn) * 0.5) - ((lc + hc) * 0.5)) <= 1.0
    print("[D1][%s] nachher y=%d x=%d..%d -> Standflaeche deckungsgleich: %s"
          % (tier, rn, ln, hn, str(ok)))
    return dx, dy


if __name__ == "__main__":
    for t in (sys.argv[1:] or ["premium", "standard", "silver"]):
        process(t)
