#!/usr/bin/env python3
"""postfix_pages.py - Nachbesserung nach dem Auslagern von Code in Module.

Drei Fehlerklassen, die beim ersten Durchlauf aufgefallen sind:
  1. `const X := Color(...)` wurde nicht erkannt (Regex kannte nur `=`), also
     fehlten benutzte Konstanten in der Zieldatei ("Identifier not declared").
  2. Node-Grundmethoden (`create_tween()`, `multiplayer`, ...) fehlten in der
     host-Liste ("Function create_tween() not found in base self").
  3. `enum GameState` ist nicht ueber eine Instanz erreichbar und muss gespiegelt
     werden (Reihenfolge identisch halten!).

    python tools/postfix_pages.py project/scripts/ui/overlays/*.gd
    python tools/postfix_pages.py --facade project/scripts/game_manager.gd project/scripts/core/*.gd
"""
import re
import sys

NL = chr(10)
FACADE = "project/scripts/ui_manager.gd"
EXTRA_API = ["create_tween", "get_node_or_null", "is_queued_for_deletion", "move_child",
             "is_multiplayer_authority", "set_multiplayer_authority"]
EXTRA_PROPS = ["multiplayer", "velocity", "global_position"]
ENUM_MIRROR = ("var host: Node = null" + NL + NL
               + "# Spiegel von game_manager.gd - Enum ist nicht ueber host erreichbar," + NL
               + "# Reihenfolge muss identisch bleiben." + NL
               + "enum GameState { MENU, LOBBY, PLAYING, DEAD }")


def const_map(src):
    out = {}
    for m in re.finditer(r"^const\s+([A-Za-z0-9_]+)\s*(?::\s*[^=\n]+)?:?=\s*(.+)$", src, re.M):
        out[m.group(1)] = m.group(0)
    for m in re.finditer(r"^const\s+([A-Za-z0-9_]+)[^\n]*=\s*[\{\[]", src, re.M):
        name, i = m.group(1), m.start()
        depth, j = 0, i
        while j < len(src):
            if src[j] in "[{":
                depth += 1
            elif src[j] in "]}":
                depth -= 1
                if depth == 0:
                    break
            j += 1
        while j + 1 < len(src) and src[j + 1] != NL:
            j += 1
        out[name] = src[i:j + 1]
    return out


def main():
    args = list(sys.argv[1:])
    facade = FACADE
    if "--facade" in args:
        i = args.index("--facade")
        facade = args[i + 1]
        del args[i:i + 2]
    consts = const_map(open(facade, encoding="utf-8").read())

    for path in args:
        text = open(path, encoding="utf-8").read()
        orig = text
        fixes = []

        # 1) fehlende Konstanten ergaenzen
        add = []
        for name, definition in consts.items():
            if re.search(r"^const\s+" + name + r"\b", text, re.M):
                continue
            if re.search(r"(?<![.\w])" + name + r"\b", text):
                add.append(definition)
        if add:
            text = (text.rstrip(NL) + NL + NL
                    + "# Konstanten aus " + facade.split("/")[-1] + NL
                    + NL.join(add) + NL)
            fixes.append("%d consts" % len(add))

        # 2) Node-Grundmethoden qualifizieren
        n_api = 0
        for fn in EXTRA_API:
            new = re.sub(r"(?<![.\w])" + fn + r"\s*\(", "host." + fn + "(", text)
            if new != text:
                n_api += 1
                text = new
        if n_api:
            fixes.append("%d API" % n_api)

        # 2b) Enum spiegeln, wenn benutzt aber nicht deklariert
        if "GameState" in text and "enum GameState" not in text:
            text = text.replace("var host: Node = null", ENUM_MIRROR, 1)
            fixes.append("enum")

        # 3) Typinferenz und Eigenschaften
        for prop in EXTRA_PROPS:
            new = re.sub(r"(?<![.\w])" + prop + r"\b", "host." + prop, text)
            if new != text:
                text = new
                fixes.append(prop)
        text = re.sub(r"\bvar\s+([A-Za-z0-9_]+)\s*:=\s*(host\.)", r"var \1 = \2", text)

        if text != orig:
            open(path, "w", encoding="utf-8").write(text)
            print("%-34s %s" % (path.split("/")[-1], ", ".join(fixes)))
        else:
            print("%-34s unveraendert" % path.split("/")[-1])


if __name__ == "__main__":
    main()
