#!/usr/bin/env bash
# End-to-end test run for Dara Launcher.
#   - copies the package to a sandbox plugin id (your real widget and settings are untouched),
#   - stubs app launches and power actions, injects tests/Suite.qml,
#   - runs it in plasmawindowed with real synthetic mouse and keyboard events,
#   - prints every check and exits non-zero if anything failed.
# Usage: tests/run.sh [name-filter]   (a filter runs only the tests whose name contains it)
# Needs: Plasma 6, qml6 test module (QtTest), kpackagetool6, plasmawindowed, python3.
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
SRC="$(dirname "$HERE")"
ID=io.github.darasamii.launchertest
TMP=$(mktemp -d)
trap 'kpackagetool6 -t Plasma/Applet -r $ID >/dev/null 2>&1; rm -rf "$TMP"' EXIT

echo "== static checks"
fail=0
if command -v qmllint >/dev/null; then
  out=$(qmllint "$SRC"/contents/ui/*.qml 2>&1 | grep -i "error" || true)
  if [ -n "$out" ]; then echo "$out"; fail=1; echo "FAIL qmllint"; else echo "PASS qmllint: no errors"; fi
fi
python3 "$HERE/static.py" "$SRC" || fail=1

echo "== building sandbox"
cp -r "$SRC" "$TMP/pkg"; rm -rf "$TMP/pkg/tests"
sed -i "s/io.github.darasamii.launcher\"/$ID\"/" "$TMP/pkg/metadata.json"
python3 "$HERE/patch.py" "$TMP/pkg" "$HERE/Suite.qml" "${1:-}" || exit 2
kpackagetool6 -t Plasma/Applet -u "$TMP/pkg" >/dev/null 2>&1 || kpackagetool6 -t Plasma/Applet -i "$TMP/pkg" >/dev/null 2>&1 || { echo "cannot install sandbox"; exit 2; }
while pgrep -f "plasmawindowed $ID" >/dev/null; do sleep 1; done

echo "== running UI suite (about a minute)"
since=$(date +"%Y-%m-%d %H:%M:%S")
timeout 240 plasmawindowed $ID >/dev/null 2>&1 &
for _ in $(seq 1 240); do
  sleep 1
  journalctl --user --since "$since" -o cat 2>/dev/null | grep -q "SUITE DONE" && break
done
log=$(journalctl --user --since "$since" -o cat 2>/dev/null | grep -E "^(TEST|SUITE)|Error|TypeError|ReferenceError|Binding loop|recursive rearrange" | grep -v "weathertest\|HourlyChart\|qrc:/qt/qml/plasma/applet")   # ignore Plasma's own shell QML
pkill -f "plasmawindowed $ID" 2>/dev/null
echo "$log" | sed 's/^TEST PASS/  ok  /; s/^TEST FAIL/FAIL  /; s/^TEST ----/\n--/'
echo
echo "$log" | grep -E "SUITE DONE" || { echo "SUITE DID NOT FINISH"; fail=1; }
echo "$log" | grep -q "^TEST FAIL" && fail=1
echo "$log" | grep -E "TypeError|ReferenceError|Binding loop|recursive rearrange" >/dev/null && { echo "QML runtime errors / binding loops seen above"; fail=1; }
exit $fail
