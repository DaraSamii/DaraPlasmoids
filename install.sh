#!/usr/bin/env sh
# Install or upgrade the widget for the current user (Plasma 6).
set -e
cd "$(dirname "$0")"
kpackagetool6 -t Plasma/Applet -u weather 2>/dev/null || kpackagetool6 -t Plasma/Applet -i weather
echo "Done. Right-click the panel > Add Widgets > search 'Dara Weather'."
