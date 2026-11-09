#!/usr/bin/env python3
"""D1 — Kisten-Spitzen ausschneiden.

Die gemalten `open_*.png` enthalten Reste der Hintergrund-Freistellung:
flache Strahlen-/Splitter-Formen, die aus der Kiste herausragen (Premium:
violett, Standard: lila, Silber: warmgrau). Dieses Werkzeug entfernt sie
pixelgenau und schreibt

  * `open_<tier>.png`        (ohne Spitzen)
  * `spikes_<tier>.png`      (nur die Spitzen, eigener Ursprung = 512er Leinwand)
  * `screenshots/210-kisten-spitzen.png` (Kontaktblatt vorher/nachher)

Regel pro Stufe: Farbmaske -> groesste Komponente (Innenschein) behalten,
Rest innerhalb des Strahlen-Fensters loeschen, Kontur mitnehmen.
"""
import colorsys
import os
import sys
from collections import deque

from PIL import Image

BASE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "project", "assets", "chests")
SHOTS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "screenshots")

# Farbregel je Stufe: (h_min, h_max, s_min, s_max, v_min)
RULES = {
    "premium": (276.0, 324.0, 0.26, 0.74, 0.50),
    "standard": (280.0, 340.0, 0.18, 0.60, 0.62),
    "silver": (8.0, 70.0, 0.04, 0.15, 0.48),
}
# Fenster, in dem Strahlen liegen duerfen (Originalpixel der 512er Kachel)
WINDOW = {
    "premium": (296, 108, 480, 310),
    "standard": (300, 120, 470, 300),
    "silver": (300, 120, 470, 300),
}


def color_match(px, rule, window):
    x, y = px
    if not (window[0] <= x <= window[2] and window[1] <= y <= window[3]):
        return False
    h_min, h_max, s_min, s_max, v_min = rule
    return True


def build_mask(im, rule, window):
    W, H = im.size
    px = im.load()
    mask = [[False] * W for _ in range(H)]
    for y in range(window[1], window[3] + 1):
        for x in range(window[0], window[2] + 1):
            r, g, b, a = px[x, y]
            if a < 200:
                continue
            h, s, v = colorsys.rgb_to_hsv(r / 255.0, g / 255.0, b / 255.0)
            hd = h * 360.0
            if rule[0] <= hd <= rule[1] and rule[2] <= s <= rule[3] and v > rule[4]:
                mask[y][x] = True
    return mask


def components(mask):
    H = len(mask)
    W = len(mask[0])
    seen = [[False] * W for _ in range(H)]
    out = []
    for y0 in range(H):
        for x0 in range(W):
            if not mask[y0][x0] or seen[y0][x0]:
                continue
            q = deque([(x0, y0)])
            seen[y0][x0] = True
            pts = []
            while q:
                x, y = q.popleft()
                pts.append((x, y))
                for dx in (-1, 0, 1):
                    for dy in (-1, 0, 1):
                        nx, ny = x + dx, y + dy
                        if 0 <= nx < W and 0 <= ny < H and mask[ny][nx] and not seen[ny][nx]:
                            seen[ny][nx] = True
                            q.append((nx, ny))
            out.append(pts)
    out.sort(key=lambda p: -len(p))
    return out


def grow(pts, radius, W, H):
    """Dilatieren (Quadrat) - nimmt die schwarze Kontur der Strahlen mit."""
    grid = set(pts)
    out = set()
    for (x, y) in grid:
        for dx in range(-radius, radius + 1):
            for dy in range(-radius, radius + 1):
                nx, ny = x + dx, y + dy
                if 0 <= nx < W and 0 <= ny < H:
                    out.add((nx, ny))
    return out


def process(tier):
    path = os.path.join(BASE, "open_%s.png" % tier)
    im = Image.open(path).convert("RGBA")
    W, H = im.size
    rule = RULES[tier]
    window = WINDOW[tier]
    mask = build_mask(im, rule, window)
    comps = components(mask)
    if not comps:
        print("[D1][%s] FEHLER: keine Farbmaske getroffen - nichts geaendert" % tier)
        return None, None, 0
    # groesste Komponente = Innenschein der offenen Kiste -> behalten
    keep_beam = comps[0]
    beam_px = len(keep_beam)
    spike_sets = [c for c in comps[1:] if len(c) >= 60]
    if tier != "premium":
        # bei standard/silver ist der Innenschein nicht die groesste Komponente
        spike_sets = [c for c in comps if len(c) >= 60]
        beam_px = 0
    spike_pts = []
    for c in spike_sets:
        spike_pts.extend(c)
    print("[D1][%s] Farbmaske: %d Komponenten, Innenschein=%d px, Spitzen=%d px in %d Teilen"
          % (tier, len(comps), beam_px, len(spike_pts), len(spike_sets)))

    # Kontur mitnehmen: dunkle Pixel direkt an den Spitzen
    grown = grow(spike_pts, 7, W, H)
    px = im.load()
    delete = set(spike_pts)
    for (x, y) in grown:
        r, g, b, a = px[x, y]
        if a < 8:
            continue
        h, s, v = colorsys.rgb_to_hsv(r / 255.0, g / 255.0, b / 255.0)
        if v < 0.32:                      # schwarze Comic-Kontur
            delete.add((x, y))
    print("[D1][%s] loesche %d px (mit Kontur)" % (tier, len(delete)))

    # Spitzen-Textur: nur die Strahlen (Farbe + Kontur), gleiche Leinwand
    spikes = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    sp = spikes.load()
    for (x, y) in delete:
        sp[x, y] = px[x, y]
    # offene Kiste: Spitzen weg
    cleaned = im.copy()
    cp = cleaned.load()
    for (x, y) in delete:
        cp[x, y] = (0, 0, 0, 0)

    cleaned.save(path)
    out_spikes = os.path.join(BASE, "spikes_%s.png" % tier)
    spikes.save(out_spikes)
    print("[D1][%s] geschrieben: open_%s.png (ohne Spitzen), spikes_%s.png" % (tier, tier, tier))
    return cleaned, spikes, len(delete)


def sheet(results):
    cell = 256
    tiles = []
    for tier, (cleaned, spikes, n) in results.items():
        orig = Image.open(os.path.join(BASE, "chest_%s.png" % tier)).convert("RGBA")
        before = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
        tiles.append((tier, orig, cleaned, spikes))
    out = Image.new("RGBA", (cell * 4 + 60, cell * len(tiles) + 40), (18, 20, 26, 255))
    from PIL import ImageDraw
    d = ImageDraw.Draw(out)
    cols = ["geschlossen", "offen vorher (aus Git-Sicherung fehlt)", "offen nachher", "spikes_*.png"]
    for i, c in enumerate(cols):
        d.text((20 + i * (cell + 10), 8), c, fill=(255, 255, 255, 255))
    for r, (tier, orig, cleaned, spikes) in enumerate(tiles):
        for i, img in enumerate([orig, None, cleaned, spikes]):
            if img is None:
                continue
            bg = Image.new("RGBA", (512, 512), (20, 170, 60, 255))
            bg.alpha_composite(img)
            out.alpha_composite(bg.resize((cell, cell), Image.LANCZOS),
                                (20 + i * (cell + 10), 26 + r * (cell + 8)))
        d.text((22, 26 + r * (cell + 8) + 4), tier, fill=(255, 255, 0, 255))
    os.makedirs(SHOTS, exist_ok=True)
    p = os.path.join(SHOTS, "210-kisten-spitzen.png")
    out.save(p)
    print("[D1][SHEET] %s" % p)


if __name__ == "__main__":
    tiers = sys.argv[1:] or ["premium", "standard", "silver"]
    res = {}
    for t in tiers:
        c, s, n = process(t)
        if c is not None:
            res[t] = (c, s, n)
    if res:
        sheet(res)
