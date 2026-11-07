# Prints file:// URL of the wallpaper currently set on the desktop (empty if unknown).
import glob, os, re
from urllib.parse import unquote

cfg = os.path.expanduser("~/.config/plasma-org.kde.plasma.desktop-appletsrc")
sec = ""
try:
    for line in open(cfg, errors="ignore"):
        line = line.strip()
        if line.startswith("["):
            sec = line
        elif line.startswith("Image=") and re.search(r"\[Wallpaper\]\[[^\]]+\]\[General\]$", sec):
            p = re.sub("^file://", "", unquote(line[6:]))
            if os.path.isdir(p):  # wallpaper package: take its largest image
                files = glob.glob(os.path.join(p, "contents/images/*"))
                if not files:
                    continue
                p = max(files, key=os.path.getsize)
            if os.path.isfile(p):
                print("file://" + p)
                break
except OSError:
    pass
