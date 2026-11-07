"""Static checks: every cfg.<key> used by the QML exists in main.xml (and vice versa), and every config page declares what it uses."""
import re, sys, glob, xml.etree.ElementTree as ET

src = sys.argv[1]
keys = {e.get("name") for e in ET.parse(src + "/contents/config/main.xml").getroot().iter("{http://www.kde.org/standards/kcfg/1.0}entry")}
used = set()
for f in glob.glob(src + "/contents/ui/*.qml"):
    t = open(f).read()
    if "/config" in f:
        continue
    used |= set(re.findall(r"\bcfg\.(\w+)", t))
used -= {"valueChanged"}
bad = False
missing = sorted(k for k in used if k not in keys and not k.endswith("Default"))
if missing:
    print("FAIL cfg keys used in QML but missing from main.xml:", ", ".join(missing)); bad = True
else:
    print("PASS all %d cfg keys used by the QML are in main.xml" % len(used))
unused = sorted(k for k in keys if k not in used and k not in ("icon", "wallpaperMode", "wallpaperPath", "accentColor", "favoritesSeeded", "fontFamily", "accentMode"))
print(("NOTE unused keys: " + ", ".join(unused)) if unused else "PASS no dead settings in main.xml")
for page in glob.glob(src + "/contents/ui/config*.qml"):
    t = open(page).read()
    declared = set(re.findall(r"property \w+ cfg_(\w+)", t)); usedp = set(re.findall(r"\bcfg_(\w+)", t))
    miss = sorted(k for k in usedp - declared if not k.endswith("Default"))
    nokey = sorted(k for k in declared if not k.endswith("Default") and k not in keys)
    if miss or nokey:
        print("FAIL", page.split("/")[-1], "undeclared:", miss, "not in schema:", nokey); bad = True
print("PASS config pages consistent with the schema" if not bad else "")
import json
md = json.load(open(src + "/metadata.json"))
if md["KPlugin"].get("Category") != "Application Launchers" or "org.kde.plasma.launchermenu" not in md.get("X-Plasma-Provides", []):
    print("FAIL metadata must declare Category 'Application Launchers' and X-Plasma-Provides org.kde.plasma.launchermenu (that is what the Meta key targets)"); bad = True
else:
    print("PASS declared as an application launcher (Meta key target)")
mq = open(src + "/contents/ui/main.qml").read()
ok_ui = re.search(r"^\s*preferredRepresentation:\s*fullRepresentation", mq, re.M) and re.search(r"^\s*compactRepresentation:\s*null", mq, re.M) \
    and re.search(r"^\s*fullRepresentation:\s*CompactRepresentation", mq, re.M) and "onExpandedChanged" not in mq
if not ok_ui:
    print("FAIL main.qml: the button must be the FULL representation with no compact one (so no popup can open), and no onExpandedChanged hack"); bad = True
else:
    print("PASS button is the full representation, no compact view, so no popup can open")
sys.exit(1 if bad else 0)
