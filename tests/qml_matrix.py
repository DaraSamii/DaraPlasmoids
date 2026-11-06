#!/usr/bin/env python3
"""QML smoke-test matrix for Dara Weather.

Installs throw-away copies of the widget under a TEST id (never touches the real
install), runs each variant in `plasmawindowed`, and fails a variant if QML prints
any error/warning. Each run also saves a picture of the widget's own contents
(rendered by Qt, so no other windows can end up in it).

    python3 tests/qml_matrix.py [outdir] [variant-name-filter]

Needs: KDE Plasma 6 (kpackagetool6, plasmawindowed) and internet access.
"""
import json, os, re, shutil, subprocess, sys, time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PKG = os.path.join(ROOT, "weather")
TEST_ID = "io.github.darasamii.weathertest"
OUT = sys.argv[1] if len(sys.argv) > 1 else "/tmp/dara-weather-matrix"
ONLY = sys.argv[2] if len(sys.argv) > 2 else ""
RUN_SECONDS = 17

MTL = {"name": "Montreal", "admin1": "Quebec", "country": "Canada", "lat": 45.5088, "lon": -73.5878}
THR = {"name": "Tehran", "admin1": "Tehran", "country": "Iran", "lat": 35.6892, "lon": 51.389}
SYD = {"name": "Sydney", "admin1": "New South Wales", "country": "Australia", "lat": -33.8688, "lon": 151.2093}
MANY = [MTL, THR, SYD] + [dict(MTL, name="City %d" % i, lat=10 + i, lon=10 + i) for i in range(1, 6)]
CARDS_OFF = {k: "false" for k in ["showSummary", "showHourly", "showDaily", "showSun", "showMoon", "showWind", "showHumidity",
                                  "showUV", "showPressure", "showVisibility", "showPrecip", "showClouds"]}

# name -> (config overrides, extra flags)   flags: compact, badurl
VARIANTS = {
    "defaults": ({}, {}),
    "imperial": ({"tempUnit": 1, "windUnit": 1, "pressureUnit": 1, "precipUnit": 1}, {}),
    "ms-mmhg-24h": ({"windUnit": 2, "pressureUnit": 2, "clock24": "true"}, {}),
    "knots": ({"windUnit": 3}, {}),
    "hours48-days3": ({"hoursCount": 48, "daysCount": 3}, {}),
    "hours12-days7": ({"hoursCount": 12, "daysCount": 7}, {}),
    "glass-no-blur": ({"backgroundStyle": 1}, {}),
    "plain-theme": ({"backgroundStyle": 2}, {}),
    "glass-tint-max": ({"glassOpacity": 40}, {}),
    "glass-tint-min": ({"glassOpacity": 4}, {}),
    "size-compact": ({"popupSize": 0}, {}),
    "size-large": ({"popupSize": 2}, {}),
    "animations-off": ({"animations": "false"}, {}),
    "all-cards-off": (CARDS_OFF, {}),
    "only-wind": (dict(CARDS_OFF, showWind="true"), {}),
    "only-hourly": (dict(CARDS_OFF, showHourly="true"), {}),
    "model-gem": ({"model": "gem_seamless"}, {}),
    "model-ecmwf": ({"model": "ecmwf_ifs025"}, {}),
    "model-gfs": ({"model": "gfs_seamless"}, {}),
    "model-icon": ({"model": "icon_seamless"}, {}),
    "model-meteofrance": ({"model": "meteofrance_seamless"}, {}),
    "model-jma": ({"model": "jma_seamless"}, {}),
    "place-sydney-south": ({"places": json.dumps([SYD])}, {}),
    "place-tehran": ({"places": json.dumps([THR])}, {}),
    "place-two-select-2nd": ({"places": json.dumps([MTL, THR]), "placeIndex": 1}, {}),
    "place-many": ({"places": json.dumps(MANY), "placeIndex": 4}, {}),
    "place-index-out-of-range": ({"places": json.dumps([MTL]), "placeIndex": 9}, {}),
    "place-corrupt-json": ({"places": "{not json"}, {}),
    "place-empty-list": ({"places": "[]"}, {}),
    "panel-default": ({}, {"compact": True}),
    "panel-city-unit": ({"showCity": "true", "panelUnitLetter": "true"}, {"compact": True}),
    "panel-icon-only": ({"panelTemp": "false"}, {"compact": True}),
    "panel-temp-only": ({"panelIcon": "false"}, {"compact": True}),
    "panel-nothing-selected": ({"panelIcon": "false", "panelTemp": "false"}, {"compact": True}),
    "error-no-network": ({}, {"badurl": True}),
}

BENIGN = re.compile(r"qt\.qpa|propagateSizeHints|Wayland|QStandardPaths|libEGL|Fontconfig|kf\.|org\.kde\.|QDBus|dbus|KLocalizedString|"
                    r"Could not (open|find) .*(icon|theme)|XDG_|plasmawindowed:|^\s*$", re.I)
BAD = re.compile(r"\.qml:\d+|TypeError|ReferenceError|SyntaxError|Binding loop|is not defined|Cannot (read|assign|call)|Unable to assign|"
                 r"Invalid property|non-existent property|Type .* unavailable|module .* is not installed|QML .*: ", re.I)


def run(*cmd, **kw):
    return subprocess.run(cmd, capture_output=True, text=True, **kw)


def build(name, cfg, flags, shot_path):
    dst = os.path.join(OUT, "pkg")
    shutil.rmtree(dst, ignore_errors=True)
    shutil.copytree(PKG, dst)
    meta = os.path.join(dst, "metadata.json")
    text = open(meta).read().replace("io.github.darasamii.weather\"", TEST_ID + "\"")
    open(meta, "w").write(text)
    xml_path = os.path.join(dst, "contents/config/main.xml")
    xml = open(xml_path).read()
    for key, val in cfg.items():
        val = str(val)
        xml, n = re.subn(r'(<entry name="%s" type="[A-Za-z]+">\s*<default>)(.*?)(</default>)' % key,
                         lambda m: m.group(1) + ("<![CDATA[%s]]>" % val if key == "places" else val) + m.group(3), xml, flags=re.S)
        if n == 0:
            raise SystemExit("config key not found in main.xml: " + key)
    open(xml_path, "w").write(xml)
    main_path = os.path.join(dst, "contents/ui/main.qml")
    main = open(main_path).read()
    if flags.get("badurl"):  # point the forecast at a closed local port to exercise the error UI
        wj = os.path.join(dst, "contents/code/weather.js")
        text = open(wj).read().replace("https://api.open-meteo.com", "http://127.0.0.1:9")
        open(wj, "w").write(text)
    grab_item = "root.fullRepresentationItem"
    if flags.get("compact"):
        # plasmawindowed never shows the compact view, so mount the real CompactRepresentation
        # at thin / normal / thick panel heights inside the window instead.
        main = main.replace("fullRepresentation: FullRepresentation { weather: root }", """fullRepresentation: Item {
        implicitWidth: 420; implicitHeight: 230
        Rectangle { anchors.fill: parent; color: "#2b303b" }
        Column { x: 12; y: 12; spacing: 14
            Repeater { model: [24, 40, 64]
                Rectangle { required property int modelData; width: 260; height: modelData; color: "#3b4252"
                    CompactRepresentation { weather: root; anchors.fill: parent } } } } }""")
    harness = '''
    Timer { interval: 6000; running: true; onTriggered: root.expanded = true }
    Timer { interval: 10500; running: true; onTriggered: { const it = %s; if (it) it.grabToImage(function(r) { r.saveToFile("%s"); }, Qt.size(it.width * 2, it.height * 2)); } }
''' % (grab_item, shot_path)
    main = main.replace("    compactRepresentation: CompactRepresentation", harness + "\n    compactRepresentation: CompactRepresentation", 1)
    open(main_path, "w").write(main)
    return dst


def main():
    os.makedirs(OUT, exist_ok=True)
    results = []
    names = [n for n in VARIANTS if ONLY in n]
    for name in names:
        cfg, flags = VARIANTS[name]
        shot = os.path.join(OUT, name + ".png")
        if os.path.exists(shot):
            os.remove(shot)
        pkg = build(name, cfg, flags, shot)
        for attempt in (1, 2):   # a render that produced no picture is retried once (timing under load)
            run("kpackagetool6", "-t", "Plasma/Applet", "-r", TEST_ID)
            inst = run("kpackagetool6", "-t", "Plasma/Applet", "-i", pkg)
            if inst.returncode != 0:
                problems = ["install failed: " + inst.stdout + inst.stderr]
                break
            run("pkill", "plasmawindowed")
            try:
                p = subprocess.run(["plasmawindowed", TEST_ID], capture_output=True, text=True, timeout=RUN_SECONDS)
                out = p.stdout + p.stderr
            except subprocess.TimeoutExpired as e:
                out = (e.stdout or b"").decode(errors="replace") + (e.stderr or b"").decode(errors="replace")
            run("pkill", "plasmawindowed")
            lines = [l for l in out.splitlines() if l.strip() and not BENIGN.search(l)]
            problems = [l for l in lines if BAD.search(l)]
            if "badurl" in flags:  # the error path is *expected* to log a failed request, nothing else
                problems = [l for l in problems if "127.0.0.1" not in l]
            has_shot = os.path.exists(shot) and os.path.getsize(shot) > 2000
            if not has_shot:
                problems.append("no picture was produced (widget did not render)")
            if problems != ["no picture was produced (widget did not render)"]:
                break
        results.append((name, not problems, problems))
        print(("PASS " if not problems else "FAIL ") + name, flush=True)
        for l in problems[:6]:
            print("     ", l[:220], flush=True)
    run("kpackagetool6", "-t", "Plasma/Applet", "-r", TEST_ID)
    shutil.rmtree(os.path.join(OUT, "pkg"), ignore_errors=True)
    failed = [r for r in results if not r[1]]
    print("\n%d/%d variants clean" % (len(results) - len(failed), len(results)))
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
