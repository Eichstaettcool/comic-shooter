#!/usr/bin/env python3
"""hostify.py - UI-Funktionen in eine Seiten-Klasse verschieben (host-Muster).

Warum nicht `split_func.py`: UI-Code ist NICHT zustandslos. Er liest/schreibt
Mitglieder von ui_manager (`chest_page`, `shop_scroll`, ...) und ruft andere
Methoden. Beim Verschieben muss also jeder solche Zugriff ueber `host.` laufen
und die Fassade delegiert.

Was das Werkzeug macht (pro Funktion, eine nach der anderen):
  1. Parameter und lokale Variablen sammeln (die bleiben unqualifiziert)
  2. alle uebrigen ui_manager-Mitglieder/Methoden und Node-Grundmethoden
     (`add_child`, `get_tree`, ...) mit `host.` praefixen
  3. `self` -> `host`
  4. benutzte Konstanten in die Zieldatei kopieren (GDScript erreicht `const`
     nicht ueber eine Instanz)
  5. in der Quelle einen delegierenden Wrapper hinterlassen (Name bleibt)

    python tools/hostify.py project/scripts/ui_manager.gd \
        --class ShopPage --to project/scripts/ui/pages/shop_page.gd \
        --page-var shop_page_instance --funcs _on_gem_package,_on_quick_buy
"""
import argparse
import os
import re
import sys

NODE_API = [
    "add_child", "remove_child", "get_child", "get_children", "get_node", "has_node",
    "get_tree", "get_viewport", "is_inside_tree", "is_node_ready", "set_process",
    "set_process_input", "queue_free", "get_parent", "get_window",
]


def collect(src):
    members = set(re.findall(r"^(?:@onready\s+)?var\s+([A-Za-z0-9_]+)", src, re.M))
    consts = {}
    for m in re.finditer(r"^const\s+([A-Za-z0-9_]+)(?::[^=]+)?\s*=\s*(.+)$", src, re.M):
        consts[m.group(1)] = m.group(0)
    # mehrzeilige consts (Arrays/Dictionaries)
    for m in re.finditer(r"^const\s+([A-Za-z0-9_]+)[^\n]*=\s*[\{\[]", src, re.M):
        name = m.group(1)
        i = m.start()
        depth = 0
        j = i
        while j < len(src):
            ch = src[j]
            if ch in "[{":
                depth += 1
            elif ch in "]}":
                depth -= 1
                if depth == 0:
                    break
            j += 1
        text = src[i:j + 1]
        # bis Zeilenende ergaenzen
        while j + 1 < len(src) and src[j + 1] not in "\n":
            j += 1
        consts[name] = src[i:j + 1]
    methods = set(re.findall(r"^func\s+([A-Za-z0-9_]+)\s*\(", src, re.M))
    return members, consts, methods


def func_span(lines, name):
    pat = re.compile(r"^func\s+" + re.escape(name) + r"\s*\(")
    for i, ln in enumerate(lines):
        if pat.match(ln):
            start = i
            break
    else:
        return None
    end = len(lines)
    for j in range(start + 1, len(lines)):
        if lines[j].strip() == "":
            continue
        if not lines[j].startswith((" ", "\t")):
            end = j
            break
    while end > start and lines[end - 1].strip() == "":
        end -= 1
    return start, end


def head_lines(lines, start):
    depth = 0
    i = start
    while True:
        depth += lines[i].count("(") - lines[i].count(")")
        if depth <= 0 or i + 1 >= len(lines):
            return start, i
        i += 1


def split_sig(lines, start, hend):
    head_one = " ".join(l.strip() for l in lines[start:hend + 1])
    inner = head_one[head_one.index("(") + 1:head_one.rindex(")")]
    params, depth, cur = [], 0, ""
    for ch in inner:
        if ch in "([{":
            depth += 1
        elif ch in ")]}":
            depth -= 1
        if ch == "," and depth == 0:
            params.append(cur.strip())
            cur = ""
        else:
            cur += ch
    if cur.strip():
        params.append(cur.strip())
    names = [p.split(":")[0].split("=")[0].strip() for p in params if p]
    tail = head_one[head_one.rindex(")") + 1:]
    m = re.search(r"->\s*([A-Za-z0-9_\[\]]+)", tail)
    return head_one, names, (m.group(1) if m else "")


def locals_of(body):
    names = set(re.findall(r"\bvar\s+([A-Za-z0-9_]+)", body))
    names |= set(re.findall(r"\bconst\s+([A-Za-z0-9_]+)", body))
    names |= set(re.findall(r"\bfor\s+([A-Za-z0-9_]+)\s+in\b", body))
    return names


def qualify(body, names_to_prefix, locals_):
    """Qualifiziert Mitglieder mit `host.`, aber nie in Strings oder Kommentaren."""
    out_lines = []
    for line in body.replace("self.", "host.").split("\n"):
        # Kommentar abschneiden (einfache Naeherung; '#' in Strings ist selten)
        code, sep, comment = line, "", ""
        if "#" in line:
            idx = line.index("#")
            # '#' innerhalb eines Strings ignorieren
            if line[:idx].count('"') % 2 == 0:
                code, sep, comment = line[:idx], "#", line[idx + 1:]
        parts = code.split('"')
        for i in range(0, len(parts), 2):      # gerade Indizes = ausserhalb Strings
            seg = re.sub(r"(?<![.\w])self\b", "host", parts[i])
            for n in sorted(names_to_prefix, key=len, reverse=True):
                if n in locals_:
                    continue
                seg = re.sub(r"(?<![.\w])" + n + r"\b", "host." + n, seg)
            parts[i] = seg
        out_lines.append('"'.join(parts) + sep + comment)
    # `var x := host.y` kann den Typ nicht ableiten (Variant) -> `var x = host.y`
    fixed = []
    for ln in out_lines:
        if "host." in ln:
            ln = re.sub(r"\bvar\s+([A-Za-z0-9_]+)\s*:=", r"var \1 =", ln)
        fixed.append(ln)
    return "\n".join(fixed)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("--class", dest="cls", required=True)
    ap.add_argument("--to", required=True)
    ap.add_argument("--page-var", required=True)
    ap.add_argument("--funcs", required=True)
    ap.add_argument("--dry", action="store_true")
    a = ap.parse_args()

    src = open(a.src, encoding="utf-8").read()
    members, consts, methods = collect(src)
    lines = src.split("\n")
    names = [f for f in a.funcs.split(",") if f]

    prefix_set = (members | methods | set(NODE_API)) - set(names)
    moved, used_consts, wrappers = [], set(), []

    for n in names:
        span = func_span(lines, n)
        if not span:
            print("FEHLT: %s" % n)
            return 1
        start, end = span
        hend_start, hend = head_lines(lines, start)
        head_one, params, ret = split_sig(lines, start, hend)
        body = "\n".join(lines[hend + 1:end])
        local_names = set(params) | locals_of(body)
        q = qualify(body, prefix_set, local_names)
        for c in consts:
            if re.search(r"(?<![.\w])" + c + r"\b", q):
                used_consts.add(c)
        sig = head_one.replace("func " + n, "func " + n, 1)
        moved.append(sig + "\n" + q)
        args = ", ".join(params)
        if "await " in body:
            wrappers.append("%s await %s.%s(%s)" % (head_one, a.page_var + "_p()", n, args))
        elif ret == "void":
            wrappers.append("%s %s.%s(%s)" % (head_one, a.page_var + "_p()", n, args))
        else:
            wrappers.append("%s return %s.%s(%s)" % (head_one, a.page_var + "_p()", n, args))

    if a.dry:
        for m in moved:
            print("---- ZIEL ----")
            print(m[:1200])
        print("---- KONSTANTEN: %s" % ", ".join(sorted(used_consts)))
        for w in wrappers:
            print("---- WRAPPER ----")
            print(w)
        return 0

    # Zieldatei
    os.makedirs(os.path.dirname(a.to), exist_ok=True)
    try:
        dst = open(a.to, encoding="utf-8").read()
    except FileNotFoundError:
        dst = ""
    if not dst:
        dst = "class_name %s\nextends RefCounted\n\n# Runde 138: aus ui_manager.gd ausgelagert.\n# Zustand bleibt in der Fassade - jeder Zugriff laeuft ueber `host`.\nvar host: Node = null\n" % a.cls
    add = []
    for c in sorted(used_consts):
        if not re.search(r"^const\s+" + c + r"\b", dst, re.M):
            add.append(consts[c])
    if add:
        dst = dst.rstrip("\n") + "\n\n" + "\n".join(add) + "\n"
    dst = dst.rstrip("\n") + "\n\n\n" + "\n\n\n".join(moved) + "\n"

    # Fassade: Funktionen ersetzen + Seiten-Instanz anlegen
    helper = ("var %s: %s = null\n\nfunc %s_p() -> %s:\n\tif %s == null:\n"
              "\t\t%s = %s.new()\n\t\t%s.host = self\n\treturn %s\n"
              % (a.page_var, a.cls, a.page_var, a.cls, a.page_var, a.page_var, a.cls,
                 a.page_var, a.page_var))
    out = list(lines)
    for n, w in zip(names, wrappers):
        start, end = func_span(out, n)
        out[start:end] = [w]
    text = "\n".join(out)
    if "var %s: %s = null" % (a.page_var, a.cls) not in text:
        # Helfer direkt nach den ersten Member-Variablen einfuegen: ans Dateiende
        text = text.rstrip("\n") + "\n\n\n" + helper
    open(a.src, "w", encoding="utf-8").write(text)
    open(a.to, "w", encoding="utf-8").write(dst)
    print("%s: %d Funktionen -> %s (%d Zeilen)" % (a.cls, len(names), a.to, dst.count("\n")))
    return 0


if __name__ == "__main__":
    sys.exit(main())
