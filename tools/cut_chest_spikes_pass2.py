#!/usr/bin/env python3
"""D1 Pass 2 — Splitter-Reste nachschneiden.

Pass 1 (`cut_chest_spikes.py`) hat die Farbflaechen erwischt, aber Facetten in
anderer Helligkeit stehen gelassen. Dieser Pass waechst vom schon erkannten
Splitter (`spikes_<tier>.png`) ueber die Splitterfarbe weiter:

  * Nachbarpixel, deren Farbe nah an der Splitterfarbe liegt (Distanz < TOL)
  * oder die dunkel sind (Comic-Kontur) und an bereits Erkanntem haengen

Er schreibt `open_<tier>.png` (ohne Reste) und `spikes_<tier>.png` (vollstaendig).
"""
import os
import sys
from collections import deque

from PIL import Image, ImageDraw

BASE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "project", "assets", "chests")
SHOTS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "screenshots")

# Referenzfarbe des Splitters je Stufe + Toleranz
SHARD = {
    "premium": ((226, 116, 225), 95),
    "standard": ((190, 133, 200), 95),
    "silver": ((164, 161, 153), 55),
}


def dist(c1, c2):
    return ((c1[0] - c2[0]) ** 2 + (c1[1] - c2[1]) ** 2 + (c1[2] - c2[2]) ** 2) ** 0.5


def process(tier):
    open_path = os.path.join(BASE, "open_%s.png" % tier)
    spike_path = os.path.join(BASE, "spikes_%s.png" % tier)
    im = Image.open(open_path).convert("RGBA")
    sp_img = Image.open(spike_path).convert("RGBA")
    W, H = im.size
    px = im.load()
    sp = sp_img.load()
    ref, tol = SHARD[tier]

    # Startmenge: alles, was schon als Splitter markiert ist
    in_set = set()
    for y in range(H):
        for x in range(W):
            if sp[x, y][3] > 8:
                in_set.add((x, y))
    if not in_set:
        print("[D1][%s] FEHLER: keine Splitter im Startbild - Pass 2 uebersprungen" % tier)
        return 0

    # BFS-Wachstum
    q = deque(in_set)
    added = 0
    while q:
        x, y = q.popleft()
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                nx, ny = x + dx, y + dy
                if not (0 <= nx < W and 0 <= ny < H):
                    continue
                if (nx, ny) in in_set:
                    continue
                r, g, b, a = px[nx, ny]
                if a < 8:
                    continue
                near_color = dist((r, g, b), ref) < tol
                dark = max(r, g, b) < 95
                if near_color or dark:
                    in_set.add((nx, ny))
                    q.append((nx, ny))
                    added += 1

    print("[D1][%s] Pass 2: %d Pixel nachgeschnitten (Start %d, jetzt %d)"
          % (tier, added, len(in_set) - added, len(in_set)))

    # Spitzen-Textur neu aufbauen: alle erkannten Pixel mit Originalfarbe
    spikes = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    spp = spikes.load()
    # vorher die Spitzen aus dem offenen Bild retten, BEVOR geloescht wird
    for (x, y) in in_set:
        spp[x, y] = px[x, y]
    for (x, y) in in_set:
        px[x, y] = (0, 0, 0, 0)

    im.save(open_path)
    spikes.save(spike_path)
    print("[D1][%s] aktualisiert: open_%s.png + spikes_%s.png" % (tier, tier, tier))
    return added


def sheet(tiers):
    cell = 256
    out = Image.new("RGBA", (cell * 3 + 40, cell * len(tiers) + 40), (18, 20, 26, 255))
    d = ImageDraw.Draw(out)
    cols = ["geschlossen", "offen (ohne Spitzen)", "spikes_*.png"]
    for i, c in enumerate(cols):
        d.text((20 + i * (cell + 10), 8), c, fill=(255, 255, 255, 255))
    for r, tier in enumerate(tiers):
        imgs = [
            Image.open(os.path.join(BASE, "chest_%s.png" % tier)).convert("RGBA"),
            Image.open(os.path.join(BASE, "open_%s.png" % tier)).convert("RGBA"),
            Image.open(os.path.join(BASE, "spikes_%s.png" % tier)).convert("RGBA"),
        ]
        for i, img in enumerate(imgs):
            bg = Image.new("RGBA", (512, 512), (20, 170, 60, 255))
            bg.alpha_composite(img)
            out.alpha_composite(bg.resize((cell, cell), Image.LANCZOS),
                                (20 + i * (cell + 10), 26 + r * (cell + 10)))
        d.text((22, 26 + r * (cell + 10) + 4), tier, fill=(255, 255, 0, 255))
    os.makedirs(SHOTS, exist_ok=True)
    p = os.path.join(SHOTS, "211-kisten-spitzen-pass2.png")
    out.save(p)
    print("[D1][SHEET] %s" % p)


if __name__ == "__main__":
    tiers = sys.argv[1:] or ["premium", "standard", "silver"]
    for t in tiers:
        process(t)
    sheet(tiers)
