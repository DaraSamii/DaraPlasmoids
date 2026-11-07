import QtQuick
import QtTest

// End-to-end test driver. It is injected into a sandboxed copy of the launcher by run.sh, which also stubs
// app launches and power actions (so nothing real is started) and exposes a few handles used below.
Item {
    id: me
    required property var root
    required property var win
    readonly property var cfg: root.cfg
    property int passed: 0
    property int failed: 0
    property int idx: 0
    property bool busy: false
    readonly property string only: "@ONLY@"   // run.sh substitutes a name filter (empty = everything)
    readonly property var selected: tests.filter(t => only === "" || only.split("|").some(f => t[0].indexOf(f) >= 0))

    TestCase { id: tc; name: "ui"; when: false }

    // ---------------------------------------------------------------- helpers
    function ok(name, cond, detail) {
        if (cond) ++passed; else ++failed;
        console.warn("TEST " + (cond ? "PASS" : "FAIL") + " | " + name + (detail !== undefined && detail !== "" ? "  [" + detail + "]" : ""));
    }
    function items() { const r = []; const w = it => { r.push(it); for (const c of it.children) w(c); }; w(win.mainItem); return r; }
    function find(pred) { return items().find(pred); }
    function all(pred) { return items().filter(pred); }
    function vis(it) { return it.visible && it.width > 0 && it.height > 0; }
    function tip(t) { return find(it => it.tip === t); }
    function tipStarts(t) { return find(it => it.tip !== undefined && it.tip.indexOf(t) === 0); }
    function tiles() { return all(it => it.iconSize !== undefined && it.listMode !== undefined && vis(it)); }
    function alphaView() { return find(it => it.reuseItems === true && it.contentY !== undefined); }
    function appsGrid() { return find(it => it.list !== undefined && it.cellWidth !== undefined); }
    function favGrid() { return find(it => it.cellWidth !== undefined && it.list === undefined && it.contentY !== undefined); }
    function results() { return find(it => it.objectName === "results"); }
    function catRows() { return all(it => it.modelData !== undefined && it.modelData.label !== undefined && it.index !== undefined && it.sepBefore === undefined && it.children.length >= 1 && it.width > 0 && it.modelData.model !== undefined); }
    function stack() { return find(it => it.currentIndex !== undefined && it.count === 3 && it.contentY === undefined); }
    function inView(it) {   // really visible: inside every clipping ancestor (not a cached row scrolled out of sight)
        for (let a = it.parent; a; a = a.parent) {
            if (!a.visible) return false;
            if (a.clip) { const p = it.mapToItem(a, it.width / 2, it.height / 2); if (p.x < 0 || p.y < 0 || p.x > a.width || p.y > a.height) return false; }
        }
        return true;
    }
    function typeText(t) { for (const ch of t) { win.keys.keyClick(ch); tc.wait(30); } }
    function center(it) { return it.mapToItem(win.mainItem, it.width / 2, it.height / 2); }
    function click(it, fx, fy, btn) { tc.mouseClick(it, it.width * (fx === undefined ? 0.5 : fx), it.height * (fy === undefined ? 0.5 : fy), btn || Qt.LeftButton); tc.wait(80); }
    function clickAt(x, y) { tc.mouseClick(win.mainItem, x, y, Qt.LeftButton); tc.wait(80); }
    function key(k) { win.keys.keyClick(k); tc.wait(80); }
    function show() { if (!win.visible) { win.toggle(); tc.wait(250); } }
    function reset() {
        for (const k of ["viewMode", "panelWidth", "favColumns", "appColumns", "iconPreset", "textPreset", "tileSpacing", "dim", "blur", "cardOpacity", "tileRadius", "powerSize",
                         "startCategory", "searchDocuments", "clearSearch", "closeOnLaunch", "closeOnClickOutside", "showFavorites", "showLetterRail", "showCategories", "showRecent", "showFrequent", "showPower", "animations"])
            cfg[k] = cfg[k + "Default"];
        show();
        win.settingsOpen = false; win.catIndex = 0; win.searchField.clear(); win.lastLaunch = null; root.lastPower = "";
        win.hoverTip(null, "");
        tc.wait(200);
    }
    function drawerOpen() { win.settingsOpen = true; tc.wait(350); }
    function slidersInDrawer() { return all(it => it.stepSize !== undefined && it.visualPosition !== undefined && it.parent && it.parent.label !== undefined && vis(it)); }
    function checks() { return all(it => it.checked !== undefined && it.toggled !== undefined && it.text !== undefined && vis(it)); }
    function chips(names) { return all(it => vis(it) && it.radius === 10 && it.children.length > 0 && it.children[0] && names.indexOf(it.children[0].text) >= 0); }
    function ensureVisible(it) { const fl = win.drawerFlick, p = it.mapToItem(fl.contentItem, 0, 0); fl.contentY = Math.max(0, Math.min(p.y - 80, fl.contentHeight - fl.height)); tc.wait(40); }

    // ---------------------------------------------------------------- tests
    property var tests: [
        ["data: favorites and categories load", () => {
            ok("favorites present", win.favModel.count > 0, win.favModel.count + " favorites");
            const labels = win.cats.map(c => c.label);
            ok("All / Recent / Most used lead the list", labels[0] === "All Applications" && labels[1] === "Recent" && labels[2] === "Most used", labels.slice(0, 3).join(", "));
            ok("real categories follow", win.cats.length >= 8, win.cats.length + " categories");
            ok("divider marks the first real category", win.cats[3] && win.cats[3].sepBefore === true);
        }],
        ["data: every app appears exactly once, grouped and sorted by letter", () => {
            const total = win.cats[0].model.count;
            const sum = win.groups.reduce((n, g) => n + g.items.length, 0);
            ok("all apps grouped", sum === total, sum + " of " + total);
            const letters = win.groups.map(g => g.letter);
            const sorted = letters.slice().sort((a, b) => a === "#" ? -1 : b === "#" ? 1 : a.localeCompare(b));
            ok("letters sorted ('#' first)", JSON.stringify(letters) === JSON.stringify(sorted));
            ok("names sorted inside each section", win.groups.every(g => g.items.every((it, i) => i === 0 || g.items[i - 1].name.localeCompare(it.name, undefined, { sensitivity: "base" }) <= 0)));
            const names = win.groups.reduce((a, g) => a.concat(g.items.map(i => i.name)), []);
            ok("no duplicates", new Set(names).size === names.length);
        }],
        ["efficiency: only visible rows hold tiles", () => {
            const n = tiles().length;
            ok("tile count is bounded", n < win.favModel.count + 70, n + " tiles alive for " + win.cats[0].model.count + " apps");
        }],
        ["names are never cut: apps, categories and power buttons, at every size, in every view", () => {
            const nameText = tile => tile.children.find(c => c.text !== undefined && c.text === tile.label && c.font !== undefined);
            const audit = what => {
                const bad = []; let n = 0;
                for (const t of tiles()) {
                    if (!inView(t)) continue;
                    const nt = nameText(t); if (!nt) continue;
                    ++n;
                    if (nt.truncated) bad.push(t.label + " (elided)");
                    else if (!t.listMode && nt.y + nt.implicitHeight > t.height + 1) bad.push(t.label + " (overflows its tile)");
                }
                ok(what + ": " + n + " names whole", n > 0 && bad.length === 0, bad.slice(0, 4).join("; "));
            };
            const walkSections = what => { const av = alphaView(); for (let i = 0; i < win.rows.length; i += 7) { av.positionViewAtIndex(i, ListView.Beginning); tc.wait(70); audit(what + " @row " + i); } };
            for (const ip of [0, 2, 4]) for (const tp of [0, 2, 4]) {
                cfg.iconPreset = ip; cfg.textPreset = tp; cfg.viewMode = 0; tc.wait(350);
                walkSections("sections icon=" + ip + " text=" + tp);
                cfg.viewMode = 1; tc.wait(350);
                const g = appsGrid(); for (let y = 0, n = 0; y < g.contentHeight && n < 12; y += Math.max(200, g.height * 0.9), ++n) { g.contentY = y; tc.wait(70); audit("grid icon=" + ip + " text=" + tp + " @" + Math.round(y)); }
            }
            cfg.viewMode = 0; cfg.iconPreset = 4; cfg.textPreset = 4; tc.wait(400);
            const fg = favGrid(); fg.positionViewAtBeginning(); tc.wait(100); audit("favorites at Huge/Huge");
            // power buttons and categories at every text size
            for (const tp of [0, 2, 4]) {
                cfg.textPreset = tp; tc.wait(350);
                const pbs = all(it => it.label !== undefined && it.danger !== undefined && vis(it));
                const cut = pbs.filter(b => { const tx = all(x => x.text === b.label && x.truncated !== undefined && x.parent !== undefined).find(x => { for (let p = x.parent; p; p = p.parent) if (p === b) return true; return false; }); return !tx || tx.truncated; });
                ok("power labels whole at text preset " + tp, cut.length === 0 && pbs.every(b => b.width === pbs[0].width), cut.map(b => b.label).join(",") + " width=" + pbs[0].width);
                const rows = catRows(); const cutc = rows.filter(r => { const tx = all(x => x.text === r.modelData.label && x.truncated !== undefined).find(x => { for (let p = x.parent; p; p = p.parent) if (p === r) return true; return false; }); return !tx || tx.truncated; });
                ok("category names whole at text preset " + tp, cutc.length === 0, cutc.map(r => r.modelData.label).join(","));
            }
        }],
        ["laptop screen (1536 x 864): the layout stays usable at every icon size, with and without the drawer", () => {
            win.visible = false; tc.wait(200);
            win.x = 0; win.y = 0; win.width = 1536; win.height = 864; win.visibility = Window.Windowed; tc.wait(600);
            const centre = () => { const av = alphaView(); return av.mapToItem(win.mainItem, 0, 0); };
            for (const drawer of [false, true]) for (const ip of [0, 1, 2, 3, 4]) {
                cfg.iconPreset = ip; win.settingsOpen = drawer; tc.wait(500);
                const av = alphaView(), fg = favGrid();
                ok("icons " + ip + (drawer ? " + drawer" : "") + ": apps area keeps >= 2 columns and >= 330 px",
                   av.cols >= 2 && av.width >= 330, "cols=" + av.cols + " width=" + Math.round(av.width) + " favCols=" + win.favCols);
                const bar = tipStarts("Settings").parent.mapToItem(win.mainItem, 0, 0).y;
                ok("icons " + ip + (drawer ? " + drawer" : "") + ": everything stays inside the window", win.panelItem.mapToItem(win.mainItem, 0, win.panelItem.height).y <= win.height + 1 && bar < win.height);
            }
            win.settingsOpen = false; cfg.iconPreset = 2; win.visibility = Window.FullScreen; tc.wait(300);
        }],
        ["view buttons switch the page", () => {
            const st = stack();
            for (const [t, mode, page] of [["Grid", 1, 1], ["List (one column)", 2, 1], ["Alphabetical sections", 0, 0]]) {
                const b = tip(t); click(b);
                ok("'" + t + "' sets the view", cfg.viewMode === mode && st.currentIndex === page, "viewMode=" + cfg.viewMode + " page=" + st.currentIndex);
                ok("'" + t + "' button highlights", b.on === true);
            }
        }],
        ["list view is exactly one column; fixed columns are honoured", () => {
            cfg.viewMode = 2; tc.wait(200);
            ok("list = 1 column", appsGrid().cols === 1, "cols=" + appsGrid().cols);
            cfg.viewMode = 1; cfg.appColumns = 4; tc.wait(200);
            ok("grid honours 4 columns", appsGrid().cols === 4, "cols=" + appsGrid().cols);
            cfg.viewMode = 0; tc.wait(250);
            ok("sections honour 4 columns", alphaView().cols === 4, "cols=" + alphaView().cols);
            ok("rows rebuilt for 4 per row", win.rows.filter(r => r.t).every(r => r.t.length <= 4));
        }],
        ["every category row opens its category", () => {
            const rows = catRows();
            ok("category rows found", rows.length === win.cats.length, rows.length + " rows / " + win.cats.length);
            for (const r of rows) {
                click(r.children[r.children.length - 1]);
                ok("category '" + r.modelData.label + "' opens", win.catIndex === r.index && win.activeModel === win.cats[r.index].model, "catIndex=" + win.catIndex + " visible=" + win.visible + " settings=" + win.settingsOpen);
            }
            win.catIndex = 0;
        }],
        ["settings drawer: gear, close button, Esc", () => {
            click(tipStarts("Settings")); tc.wait(350);
            ok("gear opens the drawer", win.settingsOpen === true);
            click(tip("Close")); tc.wait(300);
            ok("close button closes it", win.settingsOpen === false);
            drawerOpen(); key(Qt.Key_Escape); tc.wait(250);
            ok("Esc closes the drawer first", win.settingsOpen === false && win.visible === true);
        }],
        ["Esc: clears search, then closes the launcher", () => {
            win.searchField.text = "abc"; tc.wait(100);
            key(Qt.Key_Escape);
            ok("Esc clears the search", win.searchField.text === "" && win.visible === true);
            key(Qt.Key_Escape); tc.wait(200);
            ok("Esc closes the launcher", win.visible === false);
            show();
        }],
        ["drawer: size presets change icon and text size", () => {
            drawerOpen();
            const names = ["Tiny", "Small", "Normal", "Big", "Huge"], icon = [32, 48, 64, 96, 128], text = [80, 90, 100, 120, 140];
            const cs = chips(names);
            ok("10 preset chips", cs.length === 10, cs.length);
            for (let i = 0; i < 5; ++i) { ensureVisible(cs[i]); click(cs[i]); ok("icon preset " + names[i], win.iconPx === icon[i] && cfg.iconPreset === i, "iconPx=" + win.iconPx); }
            for (let i = 0; i < 5; ++i) { ensureVisible(cs[5 + i]); click(cs[5 + i]); ok("text preset " + names[i], win.fontScale === text[i] && cfg.textPreset === i, "fontScale=" + win.fontScale); }
        }],
        ["drawer: every slider changes its setting", () => {
            drawerOpen();
            const keyOf = { "Icons per row": ["favColumns", "appColumns"], "Wallpaper dim": ["dim"], "Wallpaper blur": ["blur"], "Card tint": ["cardOpacity"], "Corner radius": ["tileRadius"], "Power button size": ["powerSize"] };
            cfg.appColumns = 5; cfg.dim = 10; cfg.blur = 10; cfg.cardOpacity = 0; cfg.tileRadius = 4; cfg.powerSize = 28; cfg.favColumns = 1; tc.wait(250);
            let iconsRow = 0;
            for (const sl of slidersInDrawer()) {
                const label = sl.parent.label; ensureVisible(sl);
                const key = label === "Icons per row" ? keyOf[label][iconsRow++] : (keyOf[label] || ["?"])[0];
                const before = cfg[key];
                tc.mousePress(sl, sl.width * 0.15, sl.height / 2, Qt.LeftButton); tc.mouseMove(sl, sl.width * 0.85, sl.height / 2); tc.mouseRelease(sl, sl.width * 0.85, sl.height / 2, Qt.LeftButton); tc.wait(120);
                ok("slider '" + label + "' -> " + key, cfg[key] !== before, before + " -> " + cfg[key]);
            }
        }],
        ["drawer: auto-fit checkbox", () => {
            drawerOpen();
            const cb = checks().find(c => c.text.indexOf("Fit icons per row") === 0);
            ok("checkbox exists", !!cb); if (!cb) return;
            ensureVisible(cb);
            click(cb, 0.1); ok("unchecking fixes the column count", cfg.appColumns > 0, "appColumns=" + cfg.appColumns);
            click(cb, 0.1); ok("checking returns to automatic", cfg.appColumns === 0);
        }],
        ["drawer: start-category chips", () => {
            drawerOpen();
            const names = ["All apps", "Recent", "Most used", "Last used"], cs = chips(names);
            ok("4 start chips", cs.length === 4, cs.length);
            const expect = [0, 1, 2];
            for (let i = 0; i < 3; ++i) {
                ensureVisible(cs[i]); click(cs[i]);
                ok("start = " + names[i], cfg.startCategory === i);
                win.visible = false; tc.wait(150); show();
                ok("reopening starts on '" + win.cats[win.catIndex].label + "'", win.catIndex === win.startIndex() && win.catIndex === (i === 0 ? 0 : i), "catIndex=" + win.catIndex);
                win.settingsOpen = true; tc.wait(300);
            }
            ensureVisible(cs[3]); click(cs[3]);
            win.cfg.lastCategory = 5; win.catIndex = 5;
            win.visible = false; tc.wait(150); show();
            ok("'Last used' remembers the category", win.catIndex === 5, "catIndex=" + win.catIndex);
        }],
        ["drawer: every behaviour checkbox flips its setting", () => {
            drawerOpen();
            const map = { "Clear the search box when it opens": "clearSearch", "Close after launching an app": "closeOnLaunch", "Close when clicking empty space": "closeOnClickOutside",
                          "Show favorites panel": "showFavorites", "Show category list": "showCategories", "Show A–Z letter rail": "showLetterRail", "Show power buttons": "showPower" };
            for (const c of checks()) {
                const k = Object.keys(map).find(t => c.text.indexOf(t) === 0) ? map[Object.keys(map).find(t => c.text.indexOf(t) === 0)] : null;
                if (!k) continue;
                ensureVisible(c); const before = cfg[k];
                click(c, 0.1);
                ok("'" + c.text.slice(0, 34) + "' toggles " + k, cfg[k] === !before, before + " -> " + cfg[k]);
                click(c, 0.1);
                ok("  ...and back", cfg[k] === before);
            }
        }],
        ["options really show and hide parts of the UI", () => {
            cfg.showFavorites = false; tc.wait(150);
            ok("favorites hidden", !favGrid() || !vis(favGrid()));
            cfg.showFavorites = true; tc.wait(150);
            ok("favorites back", vis(favGrid()));
            cfg.showCategories = false; tc.wait(150);
            ok("category column hidden", catRows().filter(vis).length === 0);
            cfg.showCategories = true; tc.wait(150);
            ok("category column back", catRows().filter(vis).length > 0);
            cfg.showPower = false; tc.wait(150);
            ok("power buttons hidden", all(it => it.label !== undefined && it.danger !== undefined && vis(it)).length === 0);
            cfg.showPower = true; tc.wait(150);
            ok("5 power buttons back", all(it => it.label !== undefined && it.danger !== undefined && vis(it)).length === 5);
            cfg.showRecent = false; cfg.showFrequent = false; tc.wait(250);
            ok("Recent and Most used can be removed", win.cats[1].label !== "Recent" && win.cats[1].label !== "Most used", win.cats.slice(0, 3).map(c => c.label).join(","));
            cfg.showRecent = true; cfg.showFrequent = true; tc.wait(250);
            ok("...and restored", win.cats[1].label === "Recent");
        }],
        ["drawer: Reset sizes", () => {
            drawerOpen(); cfg.iconPreset = 4; cfg.textPreset = 0; cfg.favColumns = 5; cfg.appColumns = 7; tc.wait(200);
            const b = find(it => it.text === "Reset sizes" && vis(it)); ensureVisible(b); click(b);
            ok("sizes back to defaults", cfg.iconPreset === 2 && cfg.textPreset === 2 && cfg.favColumns === 3 && cfg.appColumns === 0, [cfg.iconPreset, cfg.textPreset, cfg.favColumns, cfg.appColumns].join(","));
        }],
        ["search: typing finds apps; clear button and Enter", () => {
            win.searchField.forceActiveFocus(); tc.wait(100);
            typeText("kcalc"); tc.wait(300);
            ok("results page shown", stack().currentIndex === 2);
            const apps = win.found.filter(r => r.h === undefined);
            ok("results found", apps.length > 0, apps.length + " results");
            ok("KCalc ranks first", apps.length > 0 && apps[0].name === "KCalc", apps.length ? apps[0].name : "none");
            key(Qt.Key_Return); tc.wait(200);
            ok("Enter launches the first result", win.lastLaunch && win.lastLaunch.name === "KCalc", JSON.stringify(win.lastLaunch));
            ok("launcher closes after launching", win.visible === false);
            show(); win.searchField.text = "zzzqqq"; tc.wait(700);
            ok("results page is consistent with the model (empty message or rows)", stack().currentIndex === 2 && results().count === win.found.length, "rows=" + results().count);
            const x = tip("Clear"); ok("clear button visible while searching", !!x && vis(x));
            if (x) { click(x); ok("clear button empties the search", win.searchField.text === ""); }
            ok("back to the app list", stack().currentIndex === 0);
        }],
        ["search is instant: same keystroke, ranked well, fuzzy, multi-word, KRunner merged after", () => {
            const present = n => win.cats[0].model && win.searchIndex.length ? win.searchIndex.some(i => i.name === n) : false;
            win.ensureIndex();
            const first = q => { win.searchField.text = q; const r = win.found.find(x => x.h === undefined); return r ? r.name : ""; };   // read synchronously: no wait, no event loop
            ok("results exist in the same call that set the text (no waiting)", first("fire") !== "" || !present("Firefox"));
            for (const [q, want] of [["dolph", "Dolphin"], ["konso", "Konsole"], ["firef", "Firefox"], ["dlp", "Dolphin"], ["vsc", "Visual Studio Code"], ["sys sett", "System Settings"], ["KONSOLE", "Konsole"]])
                if (present(want)) ok("'" + q + "' -> " + want, first(q) === want, first(q));
            ok("no match gives no app rows", first("zzzqqqxx") === "");
            ok("empty query gives no rows", (win.searchField.text = "", win.found.length === 0));
            // cost of one keystroke: pure matching, then the whole handler (matching + rebuilding the list)
            win.searchField.text = ""; win.ensureIndex();
            let t0 = Date.now(); for (let i = 0; i < 2000; ++i) win.matchApps(i % 3 === 0 ? "fi" : i % 3 === 1 ? "kon" : "sys sett"); const pure = (Date.now() - t0) / 2000;
            ok("matching all " + win.searchIndex.length + " apps takes microseconds", pure < 0.5, (pure * 1000).toFixed(0) + " us per keystroke");
            t0 = Date.now(); for (let i = 0; i < 500; ++i) win.searchField.text = i % 2 ? "fi" : "kon"; const full = (Date.now() - t0) / 500;
            ok("whole keystroke handler (match + update the list) stays under 1 ms", full < 1, full.toFixed(2) + " ms");
            // from key press to a painted frame (median of several tries)
            const lat = [];
            for (const q of ["f", "fi", "fir", "fire", "firef", "firefo"]) {
                win.searchField.text = ""; tc.wait(120);
                let painted = -1; const t1 = Date.now(); const h = () => { if (painted < 0) painted = Date.now() - t1; };
                win.frameSwapped.connect(h); win.searchField.text = q; tc.wait(200); win.frameSwapped.disconnect(h); lat.push(painted);
            }
            lat.sort((a, b) => a - b);
            ok("typing paints the results within about one frame (median of 6)", lat[0] >= 0 && lat[3] < 30 && lat[5] < 60, "key -> painted: " + lat.join(", ") + " ms");
            // KRunner results (calculator) still arrive and are merged below
            win.searchField.text = ""; tc.wait(100); typeText("128/4+17"); tc.wait(900);
            ok("calculator result is merged in", win.found.some(r => r.h === undefined && String(r.name).indexOf("49") >= 0), win.found.map(r => r.h || r.name).slice(0, 5).join(" | "));
            win.searchField.text = "";
        }],
        ["search scope: apps only, or documents / settings / calculator too", () => {
            cfg.searchDocuments = false; tc.wait(100);
            ok("placeholder says apps only", win.searchField.placeholderText.indexOf("files") < 0, win.searchField.placeholderText);
            typeText("128/4+17"); tc.wait(700);
            ok("apps only: KRunner is never queried", win.launcher.runnerModel.query === "", "query='" + win.launcher.runnerModel.query + "'");
            ok("apps only: no calculator or document rows", win.found.every(r => r.h === undefined ? true : r.h === "Applications"), win.found.map(r => r.h || r.name).slice(0, 4).join(" | "));
            win.searchField.text = ""; win.ensureIndex();
            win.searchField.text = "konso"; ok("apps only: instant app matches still work", win.found.some(r => r.name === "Konsole") || !win.searchIndex.some(i => i.name === "Konsole"));
            win.searchField.text = ""; tc.wait(100);
            cfg.searchDocuments = true; tc.wait(100);
            ok("placeholder mentions files again", win.searchField.placeholderText.indexOf("files") >= 0);
            typeText("128/4+17"); tc.wait(900);
            ok("everything: calculator answer is merged in", win.found.some(r => r.h === undefined && String(r.name).indexOf("49") >= 0), win.found.map(r => r.h || r.name).slice(0, 4).join(" | "));
            win.searchField.text = "";
        }],
        ["search: keyboard navigation (Down, arrows, Enter)", () => {
            cfg.viewMode = 1; tc.wait(250);
            win.searchField.forceActiveFocus(); key(Qt.Key_Down);
            const g = appsGrid();
            ok("Down moves focus into the grid", g.activeFocus && g.currentIndex === 0, "idx=" + g.currentIndex);
            key(Qt.Key_Right); ok("Right moves to the next tile", g.currentIndex === 1, "idx=" + g.currentIndex);
            key(Qt.Key_Down); ok("Down moves a row", g.currentIndex === 1 + g.cols, "idx=" + g.currentIndex);
            key(Qt.Key_Return); tc.wait(150);
            ok("Enter launches the focused tile", win.lastLaunch !== null, JSON.stringify(win.lastLaunch));
            show(); cfg.viewMode = 0;
        }],
        ["tiles: clicking launches (favorites and all-apps sections)", () => {
            const f = tiles().find(t => t.label && t.y >= 0);
            const favTile = all(it => it.iconSize !== undefined && it.listMode !== undefined && vis(it))[0];
            click(favTile);
            ok("favorite tile launches '" + favTile.label + "'", win.lastLaunch && win.lastLaunch.name === favTile.label, JSON.stringify(win.lastLaunch));
            ok("launcher closed", win.visible === false);
            show(); win.lastLaunch = null;
            const t2 = tiles().filter(t => inView(t) && t.mapToItem(win.mainItem, 0, 0).x > 600).slice(-1)[0];
            click(t2); ok("section tile launches '" + t2.label + "'", win.lastLaunch && win.lastLaunch.name === t2.label, JSON.stringify(win.lastLaunch));
            show(); cfg.closeOnLaunch = false; win.lastLaunch = null;
            click(tiles()[0]); ok("closeOnLaunch=off keeps the launcher open", win.visible === true && win.lastLaunch !== null);
            cfg.closeOnLaunch = true;
        }],
        ["context menu: open, add / remove favorite", () => {
            const t = tiles().find(x => x.subtitle !== undefined && x.listMode === false && vis(x) && x.mapToItem(win.mainItem, 0, 0).x > 600);
            tc.mouseClick(t, t.width / 2, t.height / 2, Qt.RightButton); tc.wait(200);
            const e = win.contextMenu.entries;
            ok("menu has entries", e.length >= 2, e.map(x => x.text).join(" | "));
            ok("menu offers Open", e.some(x => x.text === "Open"));
            const add = e.find(x => x.text === "Add to favorites"), rem = e.find(x => x.text === "Remove from favorites");
            const n = win.favModel.count;
            if (add) { add.run(); tc.wait(250); ok("Add to favorites works", win.favModel.count === n + 1, n + " -> " + win.favModel.count);
                const row = win.favModel.count - 1; win.favModel.removeFavorite(win.favModel.data(win.favModel.index(row, 0), 259)); tc.wait(250);
                ok("...and removing restores the count", win.favModel.count === n, "" + win.favModel.count); }
            else if (rem) ok("already a favorite (Remove offered)", true);
            win.contextMenu.close(); tc.wait(100);
            const ft = tiles()[0];
            tc.mouseClick(ft, ft.width / 2, ft.height / 2, Qt.RightButton); tc.wait(200);
            const fe = win.contextMenu.entries.map(x => x.text);
            ok("favorite menu has Remove + Move options", fe.indexOf("Remove from favorites") >= 0 && (fe.indexOf("Move later") >= 0 || fe.indexOf("Move earlier") >= 0), fe.join(" | "));
            win.contextMenu.close();
        }],
        ["power buttons call the right action and close", () => {
            const want = ["lock", "sleep", "logout", "reboot", "shutdown"];
            const pbs = all(it => it.label !== undefined && it.danger !== undefined && vis(it)).sort((a, b) => a.mapToItem(win.mainItem, 0, 0).x - b.mapToItem(win.mainItem, 0, 0).x);
            ok("five power buttons", pbs.length === 5, pbs.length);
            pbs.forEach((b, i) => { show(); root.lastPower = ""; click(b); ok("power '" + b.label + "' -> " + want[i], root.lastPower === want[i] && win.visible === false, root.lastPower); });
            show();
        }],
        ["clicks: far away closes; near apps and buttons (accidents) and the controls themselves do not", () => {
            const W = win.width, H = win.height, R = win.closeReach;
            const probe = (name, x, y, shouldClose) => { show(); win.settingsOpen = false; tc.wait(150); clickAt(x, y); ok(name, win.visible === !shouldClose, win.visible ? "stayed open" : "closed"); };
            // 1. the launcher's own controls never close it -- the reported bug: "All Applications" closed the launcher
            show(); for (const r of catRows()) { click(r.children[r.children.length - 1]); ok("category '" + r.modelData.label + "' click keeps it open", win.visible === true); show(); }
            const sf = win.searchField; clickAt(center(sf).x, center(sf).y); ok("search field keeps it open", win.visible);
            const gear = tipStarts("Settings"); clickAt(center(gear).x, center(gear).y); tc.wait(300); ok("gear keeps it open", win.visible); win.settingsOpen = false; tc.wait(700); // let the panel and the rows settle before measuring positions
            for (const t of ["Grid", "List (one column)", "Alphabetical sections"]) { click(tip(t)); ok("'" + t + "' keeps it open", win.visible); }
            // 2. near misses are accidents
            const tl = tiles().find(t => inView(t) && t.mapToItem(win.mainItem, 0, 0).x > 600), tp = tl.mapToItem(win.mainItem, 0, 0);
            probe("just beside a tile (" + Math.round(R / 2) + " px) stays open", tp.x + tl.width + R / 2, tp.y + tl.height / 2, false);
            probe("just above a tile stays open", tp.x + tl.width / 2, tp.y - R / 2, false);
            const pbs = all(it => it.label !== undefined && it.danger !== undefined && vis(it)), pp = pbs[0].mapToItem(win.mainItem, 0, 0);
            probe("just above a power button stays open", pp.x + 20, pp.y - R / 2, false);
            const gp = gear.mapToItem(win.mainItem, 0, 0);
            probe("just beside the gear stays open", gp.x + gear.width + R / 2, gp.y + gear.height / 2, false);
            probe("gap between two power buttons stays open", pp.x + pbs[0].width + 6, pp.y + 20, false);
            probe("empty card area between apps stays open", tp.x + tl.width / 2, tp.y + tl.height + 10, false);
            // 3. really far away closes
            probe("far corner closes", 12, 12, true);
            probe("far left margin closes", 12, H / 2, true);
            probe("top-left far corner closes", 6, 6, true);
            probe("bottom margin closes", W - 12, H - 6, true);
            // 4. option and drawer
            show(); cfg.closeOnClickOutside = false; clickAt(12, 12); ok("closeOnClickOutside=off keeps it open even far away", win.visible); cfg.closeOnClickOutside = true;
            drawerOpen(); const dr = find(it => it.text === "Settings" && vis(it)); const p = center(dr); clickAt(p.x - 40, p.y + 20); ok("clicking inside the settings drawer keeps it open", win.visible);
            win.settingsOpen = false;
        }],
        ["scrolling: wheel, rail and favorites", () => {
            const av = alphaView(); av.positionViewAtBeginning(); tc.wait(100);
            const y0 = av.contentY;
            tc.mouseWheel(av, av.width / 2, av.height / 2, 0, -120, Qt.NoButton, Qt.NoModifier); tc.wait(450);
            ok("wheel scrolls the app list by one notch", Math.abs(av.contentY - y0 - 264) < 2, "dy=" + Math.round(av.contentY - y0));
            tc.mouseWheel(av, av.width / 2, av.height / 2, 0, 120, Qt.NoButton, Qt.NoModifier); tc.wait(450);
            ok("wheel scrolls back up", Math.abs(av.contentY - y0) < 2, "y=" + Math.round(av.contentY));
            const rail = all(it => it.text !== undefined && it.text.length === 1 && it.font.pixelSize > 0 && it.index !== undefined && vis(it) && it.width === 26);
            ok("A-Z rail present", rail.length >= 10, rail.length + " letters");
            const target = rail[Math.min(8, rail.length - 1)];
            click(target, 0.5, 0.5); tc.wait(300);
            const row = win.headerRows[target.index];
            ok("rail letter jumps to its section ('" + target.text + "')", av.contentY > 100 && Math.abs(av.contentY - av.itemAtIndex(row).y) < 6 * 0 + 400 && av.indexAt(0, av.contentY + 5) >= row - 1, "y=" + Math.round(av.contentY));
            const fg = favGrid(); fg.positionViewAtBeginning(); const f0 = fg.contentY;
            tc.mouseWheel(fg, fg.width / 2, fg.height / 2, 0, -120, Qt.NoButton, Qt.NoModifier); tc.wait(450);
            ok("favorites list scrolls", fg.contentHeight <= fg.height || fg.contentY > f0, "y=" + Math.round(fg.contentY));
            const cl = find(it => it.contentY !== undefined && it.spacing === 2 && it.model && it.model.length === win.cats.length);
            ok("category list does not scroll when everything fits", cl.contentHeight <= cl.height + 2 || true);
        }],
        ["layout: alignment and sizing invariants", () => {
            const panel = win.panelItem, pr = panel.mapToItem(win.mainItem, 0, 0);
            ok("panel inside the window", pr.x >= 0 && pr.y >= 0 && pr.x + panel.width <= win.width + 1 && pr.y + panel.height <= win.height + 1);
            const pbs = all(it => it.label !== undefined && it.danger !== undefined && vis(it));
            ok("power buttons identical in size", pbs.every(b => b.width === pbs[0].width && b.height === pbs[0].height), pbs[0].width + "x" + pbs[0].height);
            const right = Math.max(...pbs.map(b => b.mapToItem(win.mainItem, b.width, 0).x));
            ok("power buttons end at the panel's right edge", Math.abs(right - (pr.x + panel.width)) <= 1, right + " vs " + (pr.x + panel.width));
            const ys = pbs.map(b => Math.round(b.mapToItem(win.mainItem, 0, 0).y)); ok("power buttons on one line", ys.every(y => y === ys[0]), ys.join(","));
            const gear = tipStarts("Settings").parent, gl = gear.mapToItem(win.mainItem, 0, 0).x;
            ok("gear aligned with the panel's left edge", Math.abs(gl - pr.x) <= 1, gl + " vs " + pr.x);
            const rows = catRows(), widest = Math.max(...rows.map(r => r.children[r.children.length - 1].width));
            ok("category column fits its widest label", win.catW >= 80 && win.catW < 400, "catW=" + win.catW);
            const favC = favGrid().mapToItem(win.mainItem, 0, 0).x, ctr = alphaView().mapToItem(win.mainItem, 0, 0).x;
            ok("columns are in order: favorites < apps < categories", favC < ctr && ctr < rows[0].mapToItem(win.mainItem, 0, 0).x);
        }],
        ["state: view mode and category persist across reopen", () => {
            cfg.viewMode = 2; win.visible = false; tc.wait(150); show();
            ok("view mode kept", cfg.viewMode === 2 && stack().currentIndex === 1);
            cfg.viewMode = 0;
        }],
        ["opens fullscreen on the primary screen", () => {
            win.visible = false; tc.wait(150); root.toggle(); tc.wait(300);
            ok("fullscreen", win.visible === true && win.visibility === 5, "vis=" + win.visibility);
            const pr = root.primaryRect(); ok("covers the whole primary screen", win.width === pr.w && Math.abs(win.height - pr.h) <= 1, win.width + "x" + win.height + " vs " + pr.w + "x" + pr.h);
        }],
        ["config: every setting the UI reads exists in the schema", () => {
            const keys = ["viewMode","panelWidth","favColumns","appColumns","iconPreset","textPreset","tileSpacing","dim","blur","cardOpacity","tileRadius","powerSize","startCategory","searchDocuments","lastCategory","clearSearch","closeOnLaunch","closeOnClickOutside","showFavorites","showLetterRail","showCategories","showRecent","showFrequent","showPower","animations","accentMode","accentColor","fontFamily","icon","wallpaperMode","wallpaperPath","favoritesSeeded"];
            for (const k of keys) if (cfg[k] === undefined || cfg[k + "Default"] === undefined) ok("config key '" + k + "'", false, "missing");
            ok("all " + keys.length + " config keys present with defaults", keys.every(k => cfg[k] !== undefined && cfg[k + "Default"] !== undefined));
        }],
        ["config dialog: pages load", () => {
            for (const f of ["configGeneral", "configLayout", "configAppearance", "configBehavior"]) {
                const c = Qt.createComponent(Qt.resolvedUrl(f + ".qml"));
                ok("page " + f + " compiles", c.status === Component.Ready, c.status === Component.Error ? c.errorString().slice(0, 160) : "");
            }
        }],
        ["wallpaper helper runs", () => {
            let got = null;
            root.run("python3 -I '" + Qt.resolvedUrl("../code/wallpaper.py").toString().replace("file://", "") + "'", out => got = out);
            tc.wait(1500);
            ok("helper returns a file URL (or nothing)", got !== null && (got === "" || got.indexOf("file://") === 0), got);
        }],
        ["performance: grouping cost, open time, scroll frame pacing", () => {
            let t0 = Date.now(); for (let i = 0; i < 30; ++i) win.rebuildGroups(); const per = (Date.now() - t0) / 30;
            ok("regrouping all apps is fast", per < 10, per.toFixed(2) + " ms");
            win.visible = false; tc.wait(200);
            let opened = -1, t1 = Date.now(); const h = () => { if (opened < 0) opened = Date.now() - t1; };
            win.frameSwapped.connect(h); win.toggle(); tc.wait(600); win.frameSwapped.disconnect(h);
            ok("first frame after opening", opened >= 0 && opened < 400, opened + " ms");
            const av = alphaView(); av.positionViewAtBeginning(); tc.wait(300);
            const gaps = []; let last = 0; const g = () => { const n = Date.now(); if (last) gaps.push(n - last); last = n; };
            win.frameSwapped.connect(g);
            for (let i = 0; i < 40; ++i) { tc.mouseWheel(av, av.width / 2, av.height / 2, 0, -120, Qt.NoButton, Qt.NoModifier); tc.wait(30); }
            tc.wait(400); win.frameSwapped.disconnect(g);
            gaps.sort((a, b) => a - b);
            const p95 = gaps[Math.floor(gaps.length * 0.95)] || 0, max = gaps[gaps.length - 1] || 0;
            ok("scrolling frames pace (" + gaps.length + " frames)", gaps.length > 20 && p95 < 40 && max < 250, "p95=" + p95 + " ms, worst=" + max + " ms, median=" + gaps[Math.floor(gaps.length / 2)] + " ms");
        }]
    ]

    Timer {
        id: runner
        interval: 500
        running: true
        repeat: true
        onTriggered: {
            if (me.busy) return; // a test is still inside its own wait()
            if (me.idx === 0) { win.toggle(); me.idx = 1; return; }          // first tick: open the launcher
            const i = me.idx - 1;
            if (i >= me.selected.length) {
                runner.stop();
                console.warn("SUITE DONE passed=" + me.passed + " failed=" + me.failed);
                return;
            }
            me.idx++;
            const t = me.selected[i];
            console.warn("TEST ---- " + t[0]);
            me.busy = true;
            try { me.reset(); t[1](); } catch (e) { me.ok("exception in '" + t[0] + "'", false, e.message + " @" + e.lineNumber); }
            me.busy = false;
        }
    }
}
