"""Turns a copy of the launcher package into a sandbox: stubs app launches and power actions, adds the test handles,
injects a driver component (tests/Suite.qml or tools/Demo.qml). Usage: patch.py <pkg> <driver.qml> [value for @ONLY@ / @OUT@]"""
import os, shutil, sys

pkg, driver = sys.argv[1], sys.argv[2]
arg = sys.argv[3] if len(sys.argv) > 3 else ""
name = os.path.splitext(os.path.basename(driver))[0]
ui = pkg + "/contents/ui/"
open(ui + name + ".qml", "w").write(open(driver).read().replace("@ONLY@", arg).replace("@OUT@", arg))

def patch(path, pairs):
    s = open(path).read()
    for a, b in pairs:
        assert a in s, "patch anchor not found: " + a[:60]
        s = s.replace(a, b, 1)
    open(path, "w").write(s)

patch(ui + "LauncherWindow.qml", [
    ("import QtQuick\n", "import QtQuick\nimport QtTest\n"),
    ("    property alias searchField: search\n",
     "    property alias searchField: search\n    property alias keys: ktc\n    property alias contextMenu: ctx\n    property alias panelItem: panel\n    property var lastLaunch: null\n"),
    ("    function launch(src, index, actionId, arg) {\n",
     "    function launch(src, index, actionId, arg) {\n"
     "        lastLaunch = { name: src.data(src.index(index, 0), 0), action: actionId || \"\" };\n"
     "        if (launcher.testMode) { if (cfg.closeOnLaunch && !actionId) win.visible = false; return; } // never start real apps in tests\n"),
    ("        QQC2.ToolTip { id: tip }", "        QQC2.ToolTip { id: tip }\n        TestCase { id: ktc; name: \"keys\"; when: false }"),
])
patch(ui + "main.qml", [
    ("    property string wallUrl: \"\"\n", "    property string wallUrl: \"\"\n    property bool testMode: true\n    property string lastPower: \"\"\n"),
    ("    function power(what) {\n", "    function power(what) {\n        lastPower = what;\n        if (testMode) return; // never log out / shut down in tests\n"),
    ("    LauncherWindow { id: win; launcher: root }", "    LauncherWindow { id: win; launcher: root }\n    " + name + " { root: root; win: win }"),
])
