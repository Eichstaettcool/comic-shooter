#!/usr/bin/env python3
"""D1 Pass 2 (sicher) — Splitter-Reste nachschneiden.

Pass 1 hat die Farbflaechen erwischt, aber Facetten anderer Helligkeit stehen
gelassen. Dieser Pass waechst vom erkannten Splitter aus - mit zwei Schranken,
damit er NICHT in die Kiste laeuft:

  1. raeumlich: nur innerhalb eines Fensters um den Splitter (BOX)
  2. farblich:  Wachstum nur ueber Pixel nahe der Splitterfarbe.
     Die schwarze Comic-Kontur wird nur als max. 2 Pixel breiter Ring
     mitgenommen und ist KEIN Weg weiter in die Kiste.

Er schreibt `open_<tier>.png` und `spikes_<tier>.png`.
"""
import os
import sys
from collections import deque

from PIL import Image, ImageDraw

BASE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "project", "assets", "chests")
SHOTS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "screenshots")

SHARD = {
    "premium": ((226, 116, 225), 100),
    "standard": ((190, 133, 200), 100),
    "silver": ((164, 161, 153), 60),
}
BOX = {
    "premium": (280, 100, 490, 290),
    "standard": (290, 110, 470, 250),
    "silver": (290, 110, 470, 250),
}
DARK_MAX = 100.0
CONTOUR_RINGS = 2


def dist(c1, c2):
    return ((c1[0] - c2[0]) ** 2 + (c1[1] - c2[1]) ** 2 + (c1[2] - c2[2]) ** 2) ** 0.5


def in_box(x, y, box):
    return box[0] <= x <= box[2] and box[1] <= y <= box[3]


def process(tier):
    open_path = os.path.join(BASE, "open_%s.png" % tier)
    spike_path = os.path.join(BASE, "spikes_%s.png" % tier)
    im = Image.open(open_path).convert("RGBA")
    sp_img = Image.open(spike_path).convert("RGBA")
    W, H = im.size
    px = im.load()
    sp = sp_img.load()
    ref, tol = SHARD[tier]
    box = BOX[tier]

    seeds = set()
    for y in range(H):
        for x in range(W):
            if sp[x, y][3] > 8 and in_box(x, y, box):
                seeds.add((x, y))
    colored = set()
    for (x, y) in seeds:
        r, g, b, a = sp[x, y]
        if a > 8 and dist((r, g, b), ref) < tol:
            colored.add((x, y))
    if not colored:
        # Kontur-Pixel als Start zulassen (Farbe kommt aus der Splittertextur)
        colored = set(seeds)
    if not colored:
        print("[D1][%s] FEHLER: keine Splitter-Pixel im Fenster" % tier)
        return 0
    print("[D1][%s] Start: %d Pixel, davon farbig %d" % (tier, len(seeds), len(colored)))

    grown = set(colored)
    q = deque(colored)
    while q:
        x, y = q.popleft()
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if not (0 <= nx < W and 0 <= ny < H) or (nx, ny) in grown or not in_box(nx, ny, box):
                continue
            r, g, b, a = px[nx, ny]
            if a < 8:
                continue
            if dist((r, g, b), ref) < tol:
                grown.add((nx, ny))
                q.append((nx, ny))

    front = set(grown)
    for _ in range(CONTOUR_RINGS):
        ring = set()
        for (x, y) in front:
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    nx, ny = x + dx, y + dy
                    if not (0 <= nx < W and 0 <= ny < H) or (nx, ny) in grown or not in_box(nx, ny, box):
                        continue
                    r, g, b, a = px[nx, ny]
                    if a > 8 and max(r, g, b) < DARK_MAX:
                        ring.add((nx, ny))
        grown |= ring
        front = ring
        if not ring:
            break

    print("[D1][%s] nachgewachsen: %d Pixel (gesamt %d im Fenster)"
          % (tier, len(grown) - len(seeds), len(grown)))

    spikes = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    spp = spikes.load()
    for (x, y) in grown:
        spp[x, y] = px[x, y]
    for (x, y) in grown:
        px[x, y] = (0, 0, 0, 0)

    im.save(open_path)
    spikes.save(spike_path)
    print("[D1][%s] aktualisiert: open_%s.png + spikes_%s.png" % (tier, tier, tier))
    return len(grown)


def sheet(tiers):
    cell = 256
    out = Image.new("RGBA", (cell * 3 + 40, cell * len(tiers) + 40), (18, 20, 26, 255))
    d = ImageDraw.Draw(out)
    for i, c in enumerate(["geschlossen", "offen (ohne Spitzen)", "spikes_*.png"]):
        d.text((20 + i * (cell + 10), 8), c, fill=(255, 255, 255, 255))
    for r, tier in enumerate(tiers):
        for i, name in enumerate(["chest_%s.png" % tier, "open_%s.png" % tier, "spikes_%s.png" % tier]):
            img = Image.open(os.path.join(BASE, name)).convert("RGBA")
            bg = Image.new("RGBA", (512, 512), (20, 170, 60, 255))
            bg.alpha_composite(img)
            out.alpha_composite(bg.resize((cell, cell), Image.LANCZOS),
                                (20 + i * (cell + 10), 26 + r * (cell + 10)))
        d.text((22, 26 + r * (cell + 10) + 4), tier, fill=(255, 255, 0, 255))
    os.makedirs(SHOTS, exist_ok=True)
    p = os.path.join(SHOTS, "212-kisten-spitzen-final.png")
    out.save(p)
    print("[D1][SHEET] %s" % p)


if __name__ == "__main__":
    tiers = sys.argv[1:] or ["premium", "standard", "silver"]
    for t in tiers:
        process(t)
    sheet(tiers)
