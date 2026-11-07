#!/usr/bin/env sh
# Install or upgrade both widgets for the current user (Plasma 6).
set -e
cd "$(dirname "$0")"
for w in weather launcher; do
  kpackagetool6 -t Plasma/Applet -u "$w" 2>/dev/null || kpackagetool6 -t Plasma/Applet -i "$w"
done
echo "Done. Right-click the panel > Add Widgets > search 'Dara Weather' or 'Dara Launcher'."
