import io, re, subprocess, os

ROOT = r'C:\Users\vince\Games\comic-shooter'
P = ROOT + r'\project\scripts\game_manager.gd'
A = ROOT + r'\project\scripts\audit_tmp.gd'

a = io.open(A, encoding='utf-8').read()
a = a.replace('compare/v79/', 'compare/v81/')
io.open(A, 'w', encoding='utf-8').write(a)

s = io.open(P, encoding='utf-8').read()
HOOK = "\n".join([
"func _audit81() -> void:",
"\tvar a = load(\"res://scripts/audit_tmp.gd\").new()",
"\tadd_child(a)",
"\ta.start(self, ui_manager)",
"",
])
s = s.replace("func _ready():\n\t_load_high_score()", HOOK + "func _ready():\n\tif OS.get_environment(\"COMIC_AUDIT81\") != \"\":\n\t\t_audit81()\n\t_load_high_score()", 1)
io.open(P, 'w', encoding='utf-8').write(s)
print("hook gesetzt")
