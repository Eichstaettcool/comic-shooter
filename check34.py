import io, re
S = r'C:\Users\vince\Games\comic-shooter\project\scripts\game_manager.gd'
s = io.open(S, encoding='utf-8').read()

# Preis-Komponenten ausgeben (vor dem Cleanup)
s = s.replace('''	print("V34 SHOP angebote=", shop_offers.size()''','''	print("V34 PREIS check: map=", active_map, " map_mult=", snappedf(shop_price_mult(), 0.01), " wave=", wave, " wave_mult=", snappedf(1.0 + 0.05 * float(maxi(0, wave - 1)), 0.01), " preis15=", shop_price(15))
	print("V34 SHOP angebote=", shop_offers.size()''', 1)

# Testhook entfernen
b = len(s)
for fn in ["_v34", "_fw34"]:
    while ("func " + fn + "(") in s:
        a = s.index("func " + fn + "(")
        z = s.find("\nfunc ", a + 10)
        if z == -1:
            z = s.find("\n# ", a + 10)
        s = s[:a] + s[z + 1:]
m = re.search(r'func _ready\(\):\n(?:.*\n)*?\t_load_high_score\(\)', s)
if m:
    s = s[:m.start()] + 'func _ready():\n\t_load_high_score()' + s[m.end():]
io.open(S, 'w', encoding='utf-8').write(s)
print("game_manager:", b, "->", len(s), "| Reste:", s.count("_v34"), s.count("COMIC_V34"))
