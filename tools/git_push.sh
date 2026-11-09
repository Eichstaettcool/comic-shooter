#!/usr/bin/env bash
# Erstes Push-Setup fuer dieses Repo (comic-shooter).
#
#   tools/git_push.sh git@github.com:DEINNAME/comic-shooter.git
#   tools/git_push.sh https://github.com/DEINNAME/comic-shooter.git
#
# Voraussetzung: das Repo existiert schon auf GitHub (leer anlegen, ohne README).
# Alternativ mit GitHub CLI direkt aus diesem Ordner:
#   gh repo create comic-shooter --private --source . --push
set -euo pipefail
cd "$(dirname "$0")/.." || exit 2

URL="${1:-}"
if [ -z "$URL" ]; then
  echo "Aufruf: tools/git_push.sh git@github.com:DEINNAME/comic-shooter.git" >&2
  exit 2
fi

if [ ! -d .git ]; then
  echo "FEHLER: hier ist kein Git-Repo (cd in den Projektordner?)" >&2
  exit 3
fi

BRANCH="$(git rev-parse --abbrev-ref HEAD)"
echo "[PUSH] ordner=$(pwd) branch=$BRANCH dateien=$(git ls-files | wc -l)"

git remote remove origin 2>/dev/null || true
git remote add origin "$URL"
git push -u origin "$BRANCH"
echo "[PUSH] fertig: $URL ($BRANCH)"
