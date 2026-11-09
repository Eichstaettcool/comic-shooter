"""Runde 49: Wiederverwendbarer Test-Runner.

Warum diese Datei existiert:
  Ein Test-Hook, dessen Anker nicht im Code steht, wird beim Einfuegen
  stillschweigend verworfen - der Test laeuft dann nie, ohne dass man
  es merkt. Deshalb prueft dieses Skript JEDEN Schritt und bricht mit
  einer klaren Meldung ab, statt "ok" zu melden.

Aufruf:  python test_runner.py COMIC_AUDIT49C
"""
import io
import os
import re
import subprocess
import sys

ROOT = r"C:\Users\vince\Games\comic-shooter"
SCRIPTS = os.path.join(ROOT, "project", "scripts")
GAME_MANAGER = os.path.join(SCRIPTS, "game_manager.gd")
AUDIT_NODE = os.path.join(SCRIPTS, "audit_tmp.gd")
LOG = os.path.join(ROOT, "test_out.log")

# Der Test-Hook wird VOR _ready() aufgerufen: die exportierten
# PackedScenes sind erst danach gesetzt. Der Knoten wartet darum
# selber auf Frames, bevor er den Run startet.
# Der Dateiname des Testknotens kommt aus der Env-Variable
# COMIC_TESTNODE (Standard: audit_tmp.gd) - so kann man mehrere
# Tests parallel liegen lassen, ohne den Hook umzubauen.
HOOK_TEMPLATE = '''func _audit_hook() -> void:
\tvar a = load("res://scripts/" + OS.get_environment("COMIC_TESTNODE")) .new()
\tadd_child(a)
\ta.start(self, ui_manager)


'''

def read(path):
    with io.open(path, encoding="utf-8") as f:
        return f.read()


def write(path, data):
    with io.open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(data)


def count_funcs(src, names):
    out = {}
    for n in names:
        out[n] = len(re.findall(r"^func %s\(" % re.escape(n), src, re.M))
    return out


def remove_hook(src):
    """Entfernt den Test-Hook restlos: Hook-Funktion, Env-Aufruf und
    den Aufruf in _ready().

    Reihenfolge ist wichtig: erst den Env-Aufruf, dann die Funktion.
    Sonst greift der Aufruf-Regex nicht mehr, weil die Funktion schon
    weg ist - und es bleibt eine halbe Zeile uebrig.
    """
    # 1) Den Env-Aufruf mit dem Aufruf dahinter entfernen.
    #    Der Aufruf kann JEDER _audit*-Name sein - nach einem Patch
    #    koennen mehrere Varianten nebeneinander stehen.
    src = re.sub(r"[ \t]*if OS\.get_environment\(\"COMIC_[A-Z0-9_]+\"\) != \"\":\n"
                 r"(?:[ \t]*_audit\w*\(\)\n)+", "", src)
    # 2) Eine alleinstehende Env-Zeile (ohne Aufruf) entfernen
    src = re.sub(r"[ \t]*if OS\.get_environment\(\"COMIC_[A-Z0-9_]+\"\) != \"\":\n",
                 "", src)
    # 3) Die Hook-Funktion + ihren Body (bis zur naechsten func).
    #    WICHTIG: die Schleife laeuft, bis KEINE Definition mehr da ist -
    #    ein einzelnes replace trifft bei zwei aufeinanderfolgenden
    #    Definitionen nur die erste.
    #    Es werden ALLE Audit-Hook-Namen entfernt (_audit_hook, _audit49c,
    #    _audit49v, ...), sonst sammeln sich ueber die Runden Reste an.
    hook_pat = r"^func _audit\w*\(\) -> void:\n(?:\t.*\n|\n)*?(?=^func |\Z)"
    while True:
        new = re.sub(hook_pat, "", src, flags=re.M)
        if new == src:
            break
        src = new
    return src


def install_hook(env_name):
    src = read(GAME_MANAGER)
    before = len(src)

    # HARTER Anker: "func _ready():" existiert genau einmal.
    if src.count("func _ready():") != 1:
        print("FEHLER: 'func _ready():' nicht genau einmal gefunden (%d)"
              % src.count("func _ready():"))
        return False

    src = remove_hook(src)
    src = src.replace("func _ready():", HOOK_TEMPLATE + "func _ready():", 1)

    # Den Env-Aufruf direkt an den Anfang von _ready() haengen
    lines = src.split("\n")
    for i, ln in enumerate(lines):
        if ln == "func _ready():":
            lines.insert(i + 1, '\tif OS.get_environment("%s") != "":' % env_name)
            lines.insert(i + 2, "\t\t_audit_hook()")
            break
    src = "\n".join(lines)
    write(GAME_MANAGER, src)

    # VERIFIKATION: der Hook muss jetzt WIRKLICH drin sein
    check = read(GAME_MANAGER)
    n_def = len(re.findall(r"^func _audit_hook\(", check, re.M))
    n_ready = check.count("func _ready():")
    # env_name kann schon mit "COMIC_" beginnen - dann nicht nochmal
    # davor setzen, sonst wird "COMIC_COMIC_AUDIT49C" gesucht.
    env_key = env_name if env_name.startswith("COMIC_") else "COMIC_%s" % env_name
    ok = (n_def == 1
          and n_ready == 1
          and env_key in check
          and "_audit_hook()" in check)
    print("Hook installiert: %d -> %d Bytes | _audit_hook-def=%d | _ready=%d | %s"
          % (before, len(check), n_def, n_ready, "OK" if ok else "FEHLER"))
    if not ok:
        return False
    return True


def compile_check():
    p = subprocess.run(
        [os.path.join(ROOT, "Godot.exe"), "--headless", "--path",
         os.path.join(ROOT, "project"), "--quit-after", "60"],
        capture_output=True, text=True, timeout=300)
    out = (p.stdout or "") + (p.stderr or "")
    bad = [ln for ln in out.split("\n")
           if ("SCRIPT ERROR" in ln or "Parse Error" in ln or "Parse error" in ln)
           and "leaked" not in ln]
    if bad:
        print("COMPILE-FEHLER:")
        for ln in bad[:6]:
            print("   ", ln.strip()[:150])
        return False
    print("COMPILE_OK")
    return True


def run_test(env_name, timeout_s=90, windowed=False):
    env = dict(os.environ)
    env[env_name] = "1"
    # Der Testknoten-Name kommt aus COMIC_TESTNODE (Standard audit_tmp.gd)
    env["COMIC_TESTNODE"] = os.environ.get("COMIC_TESTNODE", "audit_tmp.gd")
    # WICHTIG: capture_output lesen, nicht in eine Datei umleiten -
    # Godot puffert print() in die Pipe, eine umgeleitete Datei
    # bleibt bis zum Prozessende leer.
    # WINDOWED: mit Fenster - headless hat KEINE GPU, der Screenshot
    # waere dann schwarz. Fuer die visuelle Pruefung also offen.
    cmd = [os.path.join(ROOT, "Godot.exe")]
    if not windowed:
        cmd.append("--headless")
    cmd += ["--path", os.path.join(ROOT, "project")]
    if windowed:
        cmd += ["--resolution", "1920x1080", "--position", "40,40"]
    try:
        p = subprocess.run(
            cmd,
            capture_output=True, text=True, timeout=timeout_s,
            env=env, cwd=ROOT)
        # Godot dupliziert print() nach stdout UND stderr - deshalb
        # nur EINE Quelle verwenden, sonst erscheint jede Zeile
        # dreifach (stdout + stderr + die eigene Zeile).
        out = p.stdout or ""
        if "AUDIT" not in out:
            out = p.stderr or ""
    except subprocess.TimeoutExpired as e:
        out = (e.stdout or "") + "\n" + (e.stderr or "")
        if isinstance(out, bytes):
            out = out.decode("utf-8", "ignore")
        print("HINWEIS: Timeout nach %ds" % timeout_s)
    except Exception as e:
        print("START-FEHLER:", e)
        return None
    with io.open(LOG, "w", encoding="utf-8") as lf:
        lf.write(out)
    lines = [ln for ln in out.split("\n") if "AUDIT" in ln]
    for ln in lines:
        print("   ", ln.strip()[:160])
    if not lines:
        print("!! KEINE AUDIT-AUSGABE - der Hook lief nicht !!")
        print("   Log-Ende:", out.strip()[-400:])
    return lines


def cleanup():
    src = read(GAME_MANAGER)
    src = remove_hook(src)
    write(GAME_MANAGER, src)
    check = read(GAME_MANAGER)
    print("Cleanup: _audit_hook=%d | COMIC_=%d | _ready=%d"
          % (check.count("_audit_hook"), len(re.findall(r"COMIC_[A-Z0-9_]+", check)),
             check.count("func _ready():")))
    # Der Testknoten bleibt liegen - er wird bei jedem Lauf neu
    # geschrieben und ist harmlos, solange kein Hook aktiv ist.
    print("audit_tmp.gd bleibt (Hook ist entfernt)")


if __name__ == "__main__":
    env_name = sys.argv[1] if len(sys.argv) > 1 else "COMIC_AUDIT49C"
    # --window: MIT Fenster (fuer Screenshots - headless hat keine GPU)
    windowed = "--window" in sys.argv
    if not os.path.exists(AUDIT_NODE):
        print("FEHLER: %s fehlt - Testknoten nicht vorhanden" % AUDIT_NODE)
        sys.exit(1)
    if not install_hook(env_name):
        sys.exit(2)
    if not compile_check():
        sys.exit(3)
    res = run_test(env_name, windowed=windowed)
    cleanup()
    if not res:
        sys.exit(4)
    # Der Test meldet "AUDIT... FEHLER=N" - N=0 heisst PASS.
    fails = [ln for ln in res if "FEHLER=" in ln]
    if fails:
        # Die ZAHL auswerten, nicht nur das Vorhandensein
        last = fails[-1]
        try:
            n = int(last.split("FEHLER=")[1].split()[0].strip())
        except (ValueError, IndexError):
            n = -1
        if n > 0:
            print("=> TEST FEHLGESCHLAGEN: %d Fehler" % n)
            sys.exit(5)
        print("=> TEST OK (0 Fehler)")
    else:
        print("=> TEST OK (keine Fehlermeldung)")
