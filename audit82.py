import io, re, subprocess, os

ROOT = r'C:\Users\vince\Games\comic-shooter'
P = ROOT + r'\project\scripts\game_manager.gd'
A = ROOT + r'\project\scripts\audit_tmp.gd'

# Audit-Node: Ladescreen-Screenshot ergaenzen + frischen Pfad
a = io.open(A, encoding='utf-8').read()
a = a.replace('compare/v79/', 'compare/v82/')
# Ladescreen-Frames am Anfang aufnehmen
a = a.replace('''		0:
			um.show_start_screen()
			t_wait = 1.3
			step = 1''','''		0:
			_shot("00_ladescreen_a")
			t_wait = 1.1
			step = 100
		100:
			_shot("00_ladescreen_b")
			um.show_start_screen()
			t_wait = 1.3
			step = 1''')
io.open(A, 'w', encoding='utf-8').write(a)
print("audit-node angepasst")

s = io.open(P, encoding='utf-8').read()
HOOK = "\n".join([
"func _audit82() -> void:",
"\tvar a = load(\"res://scripts/audit_tmp.gd\").new()",
"\tadd_child(a)",
"\ta.start(self, ui_manager)",
"",
])
s = s.replace("func _ready():\n\t_load_high_score()", HOOK + "func _ready():\n\tif OS.get_environment(\"COMIC_AUDIT82\") != \"\":\n\t\t_audit82()\n\t_load_high_score()", 1)
io.open(P, 'w', encoding='utf-8').write(s)
print("hook gesetzt")
