import io, re, subprocess, os

ROOT = r'C:\Users\vince\Games\comic-shooter'
P = ROOT + r'\project\scripts\game_manager.gd'
s = io.open(P, encoding='utf-8').read()

HOOK = "\n".join([
"func _audit80() -> void:",
"\tvar a = load(\"res://scripts/audit_tmp.gd\").new()",
"\tadd_child(a)",
"\ta.start(self, ui_manager)",
"",
])

s = s.replace("func _ready():\n\t_load_high_score()", HOOK + "func _ready():\n\tif OS.get_environment(\"COMIC_AUDIT80\") != \"\":\n\t\t_audit80()\n\t_load_high_score()", 1)
io.open(P, 'w', encoding='utf-8').write(s)

env = dict(os.environ); env["COMIC_AUDIT80"] = "1"
try:
    r = subprocess.run(["./Godot.exe", "--path", "project", "--resolution", "1920x1080"],
                       capture_output=True, text=True, timeout=240, env=env, cwd=ROOT)
    for l in ((r.stdout or "") + "\n" + (r.stderr or "")).splitlines():
        if "AUDIT" in l or "SCRIPT ERROR" in l:
            print(l[:180])
except subprocess.TimeoutExpired as e:
    out = e.stdout or b""
    if isinstance(out, bytes):
        out = out.decode("utf-8", "ignore")
    for l in out.splitlines():
        if "AUDIT" in l:
            print(l[:180])
    print("AUDIT TIMEOUT")

s = io.open(P, encoding='utf-8').read()
while ("func _audit80(") in s:
    a = s.index("func _audit80(")
    z = s.find("\nfunc ", a + 10)
    if z == -1:
        z = s.find("\n# ", a + 10)
    s = s[:a] + s[z + 1:]
m = re.search(r'func _ready\(\):\n(?:.*\n)*?\t_load_high_score\(\)', s)
if m:
    s = s[:m.start()] + 'func _ready():\n\t_load_high_score()' + s[m.end():]
io.open(P, 'w', encoding='utf-8').write(s)
print("hook entfernt:", s.count("_audit80"))
