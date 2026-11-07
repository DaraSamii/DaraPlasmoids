import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Effects
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.kicker as Kicker

Kicker.DashboardWindow {
    id: win
    required property var launcher
    readonly property var cfg: launcher.cfg
    readonly property var favModel: launcher.rootModel.favoritesModel
    readonly property var resultModel: launcher.runnerModel.count > 0 ? launcher.runnerModel.modelForRow(0) : null
    readonly property bool searching: search.text.length > 0
    property alias searchField: search
    property alias drawerFlick: drawerScroll
    property bool settingsOpen: false
    readonly property int settingsW: 400

    backgroundColor: "black"
    visualParent: launcher.primaryItem // Plasma moves and sizes the window to this item's screen: the primary one
    keyEventProxy: search
    onKeyEscapePressed: { if (search.text) search.clear(); else if (settingsOpen) settingsOpen = false; else win.visible = false; }

    // --- style helpers used by AppTile and the inline components ---------
    readonly property int gap: cfg.tileSpacing
    readonly property int radius: cfg.tileRadius
    readonly property bool anim: cfg.animations
    readonly property color text: Qt.rgba(1, 1, 1, 0.94)
    readonly property color accent: cfg.accentMode === 0 ? scene.Kirigami.Theme.highlightColor : cfg.accentColor
    // one shared icon size and one text size, picked from named presets
    readonly property var presetNames: [i18n("Tiny"), i18n("Small"), i18n("Normal"), i18n("Big"), i18n("Huge")]
    readonly property int iconPx: [32, 48, 64, 96, 128][cfg.iconPreset]
    readonly property int fontScale: [80, 90, 100, 120, 140][cfg.textPreset]
    readonly property int favTileW: iconPx + 48
    readonly property int appTileW: iconPx + 64
    property var fontCache: ({})
    readonly property string fontKey: (cfg.fontFamily || "") + "|" + fontScale
    onFontKeyChanged: { fontCache = ({}); textCache = ({}); groupTimer.restart(); }
    onIconPxChanged: groupTimer.restart()
    onFavTileWChanged: groupTimer.restart()
    function f(mult) {
        fontCache; // dependency: bindings re-evaluate when the cache is reset
        return fontCache[mult] || (fontCache[mult] = Qt.font({ family: cfg.fontFamily || Qt.application.font.family, pixelSize: Math.round(15 * fontScale / 100 * mult) }));
    }
    readonly property int headerH: Math.round(f(2.4).pixelSize * 1.6)
    readonly property string wallSrc: cfg.wallpaperMode === 0 ? launcher.wallUrl
        : cfg.wallpaperMode === 1 && cfg.wallpaperPath ? (cfg.wallpaperPath.indexOf("://") > 0 ? cfg.wallpaperPath : "file://" + cfg.wallpaperPath) : ""
    // categories column is exactly as wide as its longest label
    readonly property real catW: {
        const px = catFm.font.pixelSize; catFm.font.family;
        let w = 0;
        for (const c of cats) w = Math.max(w, catFm.advanceWidth(c.label));
        return Math.ceil(w) + 64; // = card margins (2 x 8) + text inset (2 x 16) + a little air
    }
    // what the app area really lays out (shown in the settings drawer)
    readonly property int appCols: alpha ? alphaView.cols : appsGrid.cols
    readonly property int appCellW: alpha ? Math.floor(alphaView.width / alphaView.cols) : appsGrid.cellWidth
    // --- tile geometry: an app's name is never cut or elided. It wraps (even inside a long word) and every row of tiles
    // is as tall as its longest wrapped name, measured with a hidden Text at the tile's real text width.
    property var textCache: ({})
    function nameH(name, w) {
        const k = name + "|" + w;
        textCache; // dependency: reset when the font changes
        let h = textCache[k];
        if (h === undefined) { probe.width = w; probe.text = name; probe.font = f(1); h = textCache[k] = Math.ceil(probe.implicitHeight); }
        return h;
    }
    function tileH(names, cellW) { let m = 0; for (const n of names) m = Math.max(m, nameH(n, cellW - 12)); return iconPx + 12 + m + 12; }
    function namesOf(src) { const r = []; if (src) for (let i = 0; i < src.count; ++i) r.push(src.data(src.index(i, 0), 0) || ""); return r; }
    // Measured imperatively (never inside a binding: reading the probe from bindings makes them re-trigger each other).
    // favorites never take more than ~30% of the width: big icons on a small screen drop a column instead of squeezing the apps
    readonly property int favCols: Math.max(1, Math.min(cfg.favColumns, Math.floor(panel.width * 0.30 / favTileW)))
    property int favCellH: 80
    property int gridCellH: 80
    function refreshMetrics() {
        favCellH = tileH(namesOf(favModel), favTileW);
        gridCellH = tileH(namesOf(activeModel), appsGrid.cellWidth);
    }
    // all five power buttons share one width, wide enough for the longest label
    readonly property int powerW: { let w = 0; for (const t of [i18n("Lock"), i18n("Sleep"), i18n("Log out"), i18n("Restart"), i18n("Shut down")]) w = Math.max(w, pwFm.advanceWidth(t)); return Math.max(104, cfg.powerSize + 56, Math.ceil(w) + 28); }

    // --- categories: All / Recent / Most used / the real menu categories --
    property var cats: []
    property int catIndex: 0
    readonly property var activeModel: cats.length ? cats[Math.min(catIndex, cats.length - 1)].model : null
    // 0 = alphabetical sections, 1 = grid, 2 = list. Recent/Most used are ordered by use, so they never get letter sections.
    readonly property bool alpha: cfg.viewMode === 0 && cats.length > 0 && !cats[Math.min(catIndex, cats.length - 1)].plain
    function rebuild() {
        const rm = launcher.rootModel, l = [];
        for (let i = 0; i < rm.count; ++i) if (rm.labelForRow(i) && rm.modelForRow(i)) l.push({ label: rm.labelForRow(i), model: rm.modelForRow(i) });
        const extra = [];
        if (cfg.showRecent) extra.push({ label: i18n("Recent"), model: launcher.recentModel, plain: true, kind: "recent" });
        if (cfg.showFrequent) extra.push({ label: i18n("Most used"), model: launcher.frequentModel, plain: true, kind: "frequent" });
        l.splice(1, 0, ...extra);
        if (l.length > 1 + extra.length) l[1 + extra.length].sepBefore = true; // divider between All/Recent/Most used and the real categories
        cats = l;
        indexCount = -1;
        if (catIndex >= l.length) catIndex = 0;
    }
    // which category to show when the launcher opens (0 all, 1 recent, 2 most used, 3 last used)
    function startIndex() {
        const sc = cfg.startCategory;
        if (sc === 3) return Math.min(cfg.lastCategory, cats.length - 1);
        const i = cats.findIndex(c => c.kind === (sc === 1 ? "recent" : "frequent"));
        return sc === 0 || i < 0 ? 0 : i;
    }
    onActiveModelChanged: groupTimer.restart()
    Component.onCompleted: rebuild()

    // --- grouping for the sections view (role ids come from the kicker models: 0 name, 1 icon, 257 description, 259 favoriteId, 265 actions)
    property var groups: []
    property var rows: []         // flattened for a virtualised list: {h: "title"} or {t: [tiles of one row]}
    property var headerRows: []   // row index of each heading (for the A-Z rail)
    function item(src, i) {
        const ix = src.index(i, 0);
        return { src: src, idx: i, name: src.data(ix, 0) || "", icon: src.data(ix, 1), desc: src.data(ix, 257) || "", fav: src.data(ix, 259) || "" };
    }
    function itemsOf(src) { const r = []; for (let i = 0; i < src.count; ++i) r.push(item(src, i)); return r; }
    function letterOf(name) {
        const L = name.normalize("NFD").charAt(0).toUpperCase();
        return L.toLowerCase() === L.toUpperCase() && L.charCodeAt(0) < 128 ? "#" : L; // digits and symbols
    }
    function rebuildGroups() {
        if (!activeModel) { groups = []; rebuildRows(); refreshMetrics(); return; }
        const by = {};
        for (const it of itemsOf(activeModel)) (by[letterOf(it.name)] = by[letterOf(it.name)] || []).push(it);
        groups = Object.keys(by).sort((a, b) => a === "#" ? -1 : b === "#" ? 1 : a.localeCompare(b)).map(L => ({ letter: L, items: by[L] }));
        rebuildRows();
        refreshMetrics();
    }
    function rebuildRows() {
        const cols = alphaView.cols, cw = Math.floor(alphaView.width / cols), out = [], heads = [];
        for (const g of groups) {
            heads.push(out.length);
            out.push({ h: g.letter });
            for (let i = 0; i < g.items.length; i += cols) { const t = g.items.slice(i, i + cols); out.push({ t: t, rowH: tileH(t.map(x => x.name), cw) }); }
        }
        rows = out;
        headerRows = heads;
    }
    // --- a click really far away from every app, button and field closes the launcher.
    // Clicks near them are accidents (a slightly missed tile, the gap between buttons) and are ignored.
    readonly property int closeReach: 64
    function interactive(it) {
        return it.clicked !== undefined || it.activated !== undefined || it.tip !== undefined || it.placeholderText !== undefined
            || it.visualPosition !== undefined || it.toggled !== undefined || (it.orientation !== undefined && it.size !== undefined);
    }
    function reachable(it) {   // is this control really on screen (not scrolled out of a clipping list)?
        for (let a = it.parent; a && a !== scene; a = a.parent) {
            if (!a.visible) return false;
            if (a.clip) { const p = it.mapToItem(a, it.width / 2, it.height / 2); if (p.x < 0 || p.y < 0 || p.x > a.width || p.y > a.height) return false; }
        }
        return true;
    }
    function nearControl(x, y) {
        let near = false;
        const walk = it => {
            if (near || !it.visible || it === tapLayer) return;
            if ((it === drawer || (interactive(it) && it.width > 0 && it.height > 0)) && (it !== drawer || settingsOpen) && reachable(it)) {
                const p = it.mapToItem(scene, 0, 0);
                if (Math.hypot(Math.max(p.x - x, 0, x - p.x - it.width), Math.max(p.y - y, 0, y - p.y - it.height)) < closeReach) { near = true; return; }
            }
            for (const c of it.children) walk(c);
        };
        walk(scene);
        return near;
    }
    function tapAt(x, y) {
        if (cfg.closeOnClickOutside && visible && !nearControl(x, y)) visible = false;
    }
    // --- instant search ---------------------------------------------------------------
    // Apps are matched in memory, synchronously, on every keystroke (microseconds): the list updates in the same frame
    // the key is pressed. KRunner (calculator, settings, files, ...) is merged in below as its results arrive.
    property var found: []            // rows of the results list: {h: "Heading"} or {src, idx, name, icon, desc}
    property var searchIndex: []
    property int indexCount: -1
    function ensureIndex() {
        const all = cats.length ? cats[0].model : null;
        if (!all) { searchIndex = []; indexCount = -1; return; }
        if (all.count === indexCount) return;
        indexCount = all.count;
        searchIndex = itemsOf(all).map(it => { it.nl = it.name.toLowerCase(); it.dl = it.desc.toLowerCase(); it.ini = it.nl.split(/[\s\-_.]+/).map(w => w.charAt(0)).join(""); return it; });
    }
    function tokenScore(it, q) {      // lower is better, -1 = no match
        const n = it.nl;
        if (n === q) return 0;
        if (n.startsWith(q)) return 1;
        const i = n.indexOf(q);
        if (i > 0 && /[\s\-_.]/.test(n.charAt(i - 1))) return 2 + i / 1000;   // start of a later word
        if (it.ini.startsWith(q)) return 2.5;                                   // initials: "vsc" -> Visual Studio Code
        if (i >= 0) return 3 + i / 1000;                                        // anywhere in the name
        if (q.length >= 3) {                                                    // letters in order: "dlp" -> Dolphin
            let p = 0;
            for (let k = 0; k < q.length && p >= 0; ++k) { p = n.indexOf(q.charAt(k), p); if (p >= 0) ++p; }
            if (p >= 0) return 5 + (p - q.length) / 100;
        }
        return it.dl.indexOf(q) >= 0 ? 6 : -1;                                  // description / generic name
    }
    function matchApps(q) {           // pure and allocation-light: the part that runs on every keystroke
        ensureIndex();
        const tokens = q.split(/\s+/), hits = [], idx = searchIndex;
        for (let i = 0; i < idx.length; ++i) {
            const it = idx[i];
            let sc = 0;
            for (let k = 0; k < tokens.length; ++k) { const ts = tokenScore(it, tokens[k]); if (ts < 0) { sc = -1; break; } sc += ts; }
            if (sc >= 0) hits.push({ it: it, s: sc });
        }
        return hits.sort((a, b) => a.s - b.s || (a.it.nl < b.it.nl ? -1 : 1));
    }
    function updateSearch() {
        const q = search.text.trim().toLowerCase();
        if (!q) { if (found.length) { found = []; foundModel.clear(); } if (runnerRows.length) runnerRows = []; return; }
        const hits = matchApps(q);
        const out = [], seen = {};
        if (hits.length) out.push({ h: i18n("Applications") });
        for (const h of hits.slice(0, 14)) { out.push({ src: h.it.src, idx: h.it.idx, name: h.it.name, icon: h.it.icon, desc: h.it.desc }); seen[h.it.name] = true; }
        let group = null;
        for (const r of runnerRows) {                                            // KRunner rows, converted once when they arrive
            if (seen[r.name] || r.group === "Applications") continue;            // already listed (instantly) above
            if (r.group !== group) { out.push({ h: r.group }); group = r.group; }
            out.push(r);
        }
        found = out;
        // rows keep their delegates and just re-bind to `found`: only the row COUNT changes in the model
        if (foundModel.count < out.length) { for (let n = out.length - foundModel.count; n > 0; --n) foundModel.append({ k: 0 }); }
        else if (foundModel.count > out.length) foundModel.remove(out.length, foundModel.count - out.length);
    }
    property var runnerRows: []
    function refreshRunnerRows() {
        const m = resultModel, rows = [];
        if (m && cfg.searchDocuments && search.text.trim().length >= 2) for (let i = 0; i < m.count; ++i) {
            const ix = m.index(i, 0);
            rows.push({ src: m, idx: i, name: m.data(ix, 0) || "", icon: m.data(ix, 1), desc: m.data(ix, 257) || "", group: m.data(ix, 258) || "" });
        }
        runnerRows = rows;
        updateSearch();
    }
    function rowInfo(src, i) { const ix = src.index(i, 0); return { favoriteId: src.data(ix, 259), actionList: src.data(ix, 265) }; }
    // one shared tooltip for every tile (a tooltip object per tile would be hundreds of objects)
    property Item tipTarget: null
    property string tipText
    function hoverTip(tile, text) {
        tipTimer.stop();
        tip.close();
        tipTarget = tile;
        tipText = text || "";
        if (tile && tipText) tipTimer.restart();
    }

    // --- actions ----------------------------------------------------------
    function launch(src, index, actionId, arg) {
        const close = src.trigger(index, actionId || "", arg === undefined ? null : arg);
        if (cfg.closeOnLaunch && (!actionId || close)) win.visible = false;
    }
    function openMenu(item, x, y, src, index, m, isFav) {
        const e = [{ text: i18n("Open"), icon: "document-open", run: () => win.launch(src, index) }];
        if (m.favoriteId) {
            const fav = isFav || win.favModel.isFavorite(m.favoriteId);
            e.push(fav ? { text: i18n("Remove from favorites"), icon: "bookmark-remove", run: () => win.favModel.removeFavorite(m.favoriteId) }
                       : { text: i18n("Add to favorites"), icon: "bookmark-new", run: () => win.favModel.addFavorite(m.favoriteId) });
        }
        if (isFav) {
            if (index > 0) e.push({ text: i18n("Move earlier"), icon: "go-previous", run: () => win.favModel.moveRow(index, index - 1) });
            if (index < win.favModel.count - 1) e.push({ text: i18n("Move later"), icon: "go-next", run: () => win.favModel.moveRow(index, index + 1) });
        }
        for (const a of (m.actionList || []))
            if (a.actionId && a.text) e.push({ text: a.text, icon: a.icon || "", run: () => win.launch(src, index, a.actionId, a.actionArgument) });
        ctx.entries = e;
        ctx.popup(item, x, y);
    }

    onVisibleChanged: {
        if (visible) {
            launcher.refreshWallpaper();
            settingsOpen = false;
            if (cfg.clearSearch) search.clear();
            catIndex = startIndex();
            alphaView.positionViewAtBeginning();
            appsGrid.positionViewAtBeginning();
            favGrid.positionViewAtBeginning();
            search.forceActiveFocus();
            panel.opacity = 1;   // appears instantly: no fade, no animation
        } else hoverTip(null, "");
    }

    // ---------------------------------------------------------------------
    component Card: Rectangle {
        radius: 22
        color: Qt.rgba(1, 1, 1, win.cfg.cardOpacity / 100)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.14)
    }
    component Btn: Rectangle {
        id: btn
        property string icon
        property string tip
        property bool on: false
        property int size: 40
        property int glyph: 24
        signal clicked()
        implicitWidth: size; implicitHeight: size; radius: 12
        color: on ? Qt.alpha(win.accent, 0.55) : ma.containsMouse ? Qt.rgba(1, 1, 1, ma.pressed ? 0.28 : 0.18) : "transparent"
        Behavior on color { enabled: win.anim; ColorAnimation { duration: 100 } }
        Kirigami.Icon { anchors.centerIn: parent; width: btn.glyph; height: btn.glyph; source: btn.icon; color: win.text; isMask: true }
        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: btn.clicked() }
        QQC2.ToolTip.visible: ma.containsMouse
        QQC2.ToolTip.delay: 500
        QQC2.ToolTip.text: btn.tip
        Accessible.name: btn.tip
        Accessible.role: Accessible.Button
    }
    // big labelled session button
    component PowerBtn: Rectangle {
        id: pb
        property string icon
        property string label
        property bool danger: false
        signal clicked()
        Layout.preferredWidth: win.powerW
        Layout.preferredHeight: win.cfg.powerSize + 48
        implicitWidth: Layout.preferredWidth
        implicitHeight: Layout.preferredHeight
        radius: win.radius + 4
        color: ma.containsMouse ? (danger ? Qt.rgba(0.85, 0.2, 0.2, ma.pressed ? 0.75 : 0.55) : Qt.alpha(win.accent, ma.pressed ? 0.6 : 0.4)) : Qt.rgba(1, 1, 1, 0.1)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.14)
        Behavior on color { enabled: win.anim; ColorAnimation { duration: 120 } }
        ColumnLayout {
            anchors.fill: parent
            anchors.topMargin: 10
            anchors.bottomMargin: 8
            spacing: 4
            Item { Layout.fillHeight: true }
            Kirigami.Icon { Layout.alignment: Qt.AlignHCenter; Layout.preferredWidth: win.cfg.powerSize; Layout.preferredHeight: win.cfg.powerSize; source: pb.icon; color: win.text; isMask: true
                scale: ma.containsMouse && win.anim ? 1.1 : 1; Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } } }
            Text { Layout.alignment: Qt.AlignHCenter; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; text: pb.label; font: win.f(0.95); color: win.text }
            Item { Layout.fillHeight: true }
        }
        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: pb.clicked() }
        Accessible.name: pb.label
        Accessible.role: Accessible.Button
    }

    mainItem: Item {
        id: scene
        width: win.width
        height: win.height

        Connections { target: win.launcher.rootModel; function onRefreshed() { rebuildTimer.restart(); } function onCountChanged() { rebuildTimer.restart(); } }
        Connections { target: win.cfg; function onSearchDocumentsChanged() { if (!win.cfg.searchDocuments) win.launcher.runnerModel.query = ""; win.refreshRunnerRows(); } function onShowRecentChanged() { rebuildTimer.restart(); } function onShowFrequentChanged() { rebuildTimer.restart(); } }
        Connections { target: win.activeModel; function onCountChanged() { groupTimer.restart(); } function onModelReset() { groupTimer.restart(); } function onLayoutChanged() { groupTimer.restart(); } }
        FontMetrics { id: catFm; font: win.f(1.1) }
        FontMetrics { id: pwFm; font: win.f(0.95) }
        Text { id: probe; visible: false; wrapMode: Text.WrapAtWordBoundaryOrAnywhere; horizontalAlignment: Text.AlignHCenter }
        Connections { target: alphaView; function onColsChanged() { groupTimer.restart(); } }
        Connections { target: appsGrid; function onCellWidthChanged() { groupTimer.restart(); } }
        Connections { target: win.favModel; function onCountChanged() { groupTimer.restart(); } }
        Timer { id: groupTimer; interval: 50; onTriggered: win.rebuildGroups() }
        Timer { id: rebuildTimer; interval: 30; onTriggered: win.rebuild() }
        Timer { id: tipTimer; interval: 700; onTriggered: { if (win.tipTarget) { tip.parent = win.tipTarget; tip.text = win.tipText; tip.open(); } } }
        Timer { id: queryTimer; interval: 20; onTriggered: win.launcher.runnerModel.query = search.text }
        Connections {
            target: win.launcher.runnerModel
            function onCountChanged() { Qt.callLater(win.refreshRunnerRows); }
            function onQueryingChanged() { Qt.callLater(win.refreshRunnerRows); }
        }
        Connections {
            target: win.resultModel
            function onCountChanged() { Qt.callLater(win.refreshRunnerRows); }
            function onRowsInserted() { Qt.callLater(win.refreshRunnerRows); }
            function onModelReset() { Qt.callLater(win.refreshRunnerRows); }
            function onDataChanged() { Qt.callLater(win.refreshRunnerRows); }
        }
        // load KRunner's plugins once, in the background, so the first real search is not the slow one
        Timer { interval: 3500; running: true; onTriggered: if (win.cfg.searchDocuments && !win.visible) { win.launcher.runnerModel.query = "ab"; warmOff.start(); } }
        Timer { id: warmOff; interval: 1500; onTriggered: if (!win.searching) win.launcher.runnerModel.query = "" }
        QQC2.ToolTip { id: tip }
        ListModel { id: foundModel }
        QQC2.Menu {
            id: ctx
            property var entries: []
            Instantiator {
                model: ctx.entries
                delegate: QQC2.MenuItem {
                    required property var modelData
                    text: modelData.text
                    icon.name: modelData.icon
                    onTriggered: modelData.run()
                }
                onObjectAdded: (i, o) => ctx.insertItem(i, o)
                onObjectRemoved: (i, o) => ctx.removeItem(o)
            }
        }

        Rectangle { anchors.fill: parent; color: "#0d1117" }
        Item {
            anchors.fill: parent
            layer.enabled: true // the blur is rendered once and cached as a texture instead of being recomputed every frame
            Image {
                id: wall
                anchors.fill: parent
                source: win.wallSrc
                sourceSize.width: win.cfg.blur > 0 ? 1600 : 0 // a blurred picture does not need full resolution
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                visible: false
            }
            MultiEffect {
                anchors.fill: parent
                source: wall
                opacity: wall.status === Image.Ready ? 1 : 0
                blurEnabled: win.cfg.blur > 0
                blur: win.cfg.blur / 100
                blurMax: 48
                autoPaddingEnabled: false
                Behavior on opacity { enabled: win.anim; NumberAnimation { duration: 250 } }
            }
        }
        Rectangle { anchors.fill: parent; color: "black"; opacity: win.cfg.dim / 100 }

        Item {
            id: panel
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: win.settingsOpen ? -(win.settingsW + 16) / 2 : 0
            width: Math.min(parent.width - 48 - (win.settingsOpen ? win.settingsW + 16 : 0), 2200, Math.max(win.settingsOpen ? 760 : 960, parent.width * win.cfg.panelWidth / 100))
            height: parent.height - 2 * Math.max(28, parent.height * 0.05)


            ColumnLayout {
                anchors.fill: parent
                spacing: 16

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 20

                    // ---- left: favorites (scrollable, any number) -------------
                    Card {
                        visible: win.cfg.showFavorites
                        Layout.preferredWidth: win.favCols * win.favTileW + 40 + 14
                        Layout.fillHeight: true
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 8
                            RowLayout {
                                Layout.leftMargin: 6
                                Text { text: i18n("Favorites"); font: win.f(1.25); color: win.text; Layout.fillWidth: true }
                                Text { text: win.favModel.count; font: win.f(0.9); color: win.text; opacity: 0.55 }
                            }
                            GridView {
                                id: favGrid
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                model: win.cfg.showFavorites ? win.favModel : null
                                cellWidth: win.favTileW
                                cellHeight: win.favCellH
                                keyNavigationEnabled: true
                                boundsBehavior: Flickable.StopAtBounds
                                SmoothScroll {}
                                QQC2.ScrollBar.vertical: QQC2.ScrollBar { policy: QQC2.ScrollBar.AsNeeded }
                                Keys.onReturnPressed: if (currentIndex >= 0) win.launch(win.favModel, currentIndex)
                                Keys.onUpPressed: event => { if (currentIndex < win.favCols) search.forceActiveFocus(); else event.accepted = false; }
                                Keys.onRightPressed: event => { if (currentIndex % win.favCols === win.favCols - 1 && !win.alpha) { appsGrid.forceActiveFocus(); if (appsGrid.currentIndex < 0) appsGrid.currentIndex = 0; } else event.accepted = false; }
                                delegate: AppTile {
                                    required property var model
                                    required property int index
                                    ui: win
                                    width: GridView.view.cellWidth
                                    height: GridView.view.cellHeight
                                    label: model.display
                                    subtitle: model.description || ""
                                    icon: model.decoration
                                    iconSize: win.iconPx
                                    current: GridView.isCurrentItem && GridView.view.activeFocus
                                    onActivated: win.launch(win.favModel, index)
                                    onContextRequested: (x, y) => win.openMenu(this, x, y, win.favModel, index, model, true)
                                }
                                Text {
                                    anchors.centerIn: parent
                                    width: parent.width - 40
                                    visible: favGrid.count === 0
                                    text: i18n("No favorites yet.\nRight-click any app and choose “Add to favorites”.")
                                    font: win.f(0.95); color: win.text; opacity: 0.6
                                    horizontalAlignment: Text.AlignHCenter
                                    wrapMode: Text.Wrap
                                }
                            }
                        }
                    }

                    // ---- center: search + apps / results ------------------------
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 14

                        QQC2.TextField {
                            id: search
                            Layout.fillWidth: true
                            Layout.preferredHeight: 54
                            placeholderText: win.cfg.searchDocuments ? i18n("Search apps, files, settings, calculator…") : i18n("Search apps…")
                            placeholderTextColor: Qt.rgba(1, 1, 1, 0.5)
                            color: win.text
                            font: win.f(1.2)
                            leftPadding: 54
                            rightPadding: 48
                            selectByMouse: true
                            onTextChanged: {
                                win.updateSearch();   // instant: apps are matched right now, in this keystroke
                                if (win.cfg.searchDocuments && text.trim().length >= 2) queryTimer.restart(); else { queryTimer.stop(); win.launcher.runnerModel.query = ""; }
                            }
                            Keys.onDownPressed: {
                                if (win.searching) { results.forceActiveFocus(); results.currentIndex = Math.max(0, win.found.findIndex(r => r.h === undefined)); }
                                else if (!win.alpha) { appsGrid.forceActiveFocus(); appsGrid.currentIndex = 0; }
                            }
                            Keys.onLeftPressed: event => { if (cursorPosition === 0 && !win.searching) { favGrid.forceActiveFocus(); if (favGrid.currentIndex < 0) favGrid.currentIndex = 0; } else event.accepted = false; }
                            Keys.onReturnPressed: {
                                if (win.searching) { const r = win.found.find(x => x.h === undefined); if (r) win.launch(r.src, r.idx); }
                                else if (!win.searching && win.alpha && win.groups.length) win.launch(win.groups[0].items[0].src, win.groups[0].items[0].idx);
                                else if (!win.searching && !win.alpha && appsGrid.count > 0) win.launch(win.activeModel, 0);
                            }
                            Keys.onEnterPressed: Keys.returnPressed(event)
                            background: Rectangle {
                                radius: height / 2
                                color: Qt.rgba(1, 1, 1, search.activeFocus ? 0.2 : 0.13)
                                border.width: search.activeFocus ? 2 : 1
                                border.color: search.activeFocus ? win.accent : Qt.rgba(1, 1, 1, 0.16)
                                Behavior on color { enabled: win.anim; ColorAnimation { duration: 120 } }
                                Kirigami.Icon { x: 18; anchors.verticalCenter: parent.verticalCenter; width: 22; height: 22; source: "search"; color: win.text; isMask: true }
                            }
                            Btn {
                                anchors.right: parent.right; anchors.rightMargin: 8; anchors.verticalCenter: parent.verticalCenter
                                visible: win.searching; icon: "edit-clear"; tip: i18n("Clear")
                                onClicked: { search.clear(); search.forceActiveFocus(); }
                            }
                        }

                        Card {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            StackLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                currentIndex: win.searching ? 2 : win.alpha ? 0 : 1

                                // sections: one row per heading / per line of tiles, so only the visible rows exist
                                RowLayout {
                                    spacing: 6
                                    ListView {
                                        id: alphaView
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        clip: true
                                        model: win.alpha && !win.searching ? win.rows : []   // hidden pages hold no tiles
                                        reuseItems: true
                                        cacheBuffer: 500
                                        boundsBehavior: Flickable.StopAtBounds
                                        readonly property int cols: win.cfg.appColumns > 0 ? win.cfg.appColumns : Math.max(1, Math.floor(width / win.appTileW))
                                        SmoothScroll {}
                                        onWidthChanged: groupTimer.restart()
                                        QQC2.ScrollBar.vertical: QQC2.ScrollBar { policy: QQC2.ScrollBar.AsNeeded }
                                        delegate: Item {
                                            id: rowItem
                                            required property var modelData
                                            readonly property bool isHead: modelData.h !== undefined
                                            width: alphaView.width
                                            height: isHead ? win.headerH : rowItem.modelData.rowH
                                            Text { id: headText; visible: rowItem.isHead; x: 12; height: parent.height; verticalAlignment: Text.AlignVCenter; text: rowItem.isHead ? rowItem.modelData.h : ""; font: win.f(2.4); color: Qt.lighter(win.accent, 1.7) }
                                            Rectangle { visible: rowItem.isHead; x: headText.width + 24; width: Math.max(0, parent.width - x - 10); y: parent.height / 2; height: 1; color: Qt.rgba(1, 1, 1, 0.16) }
                                            Repeater {
                                                model: rowItem.isHead ? [] : rowItem.modelData.t
                                                delegate: AppTile {
                                                    required property var modelData
                                                    required property int index
                                                    ui: win
                                                    x: index * width
                                                    width: Math.floor(alphaView.width / alphaView.cols)
                                                    height: rowItem.height
                                                    label: modelData.name
                                                    subtitle: modelData.desc
                                                    icon: modelData.icon
                                                    iconSize: win.iconPx
                                                    onActivated: win.launch(modelData.src, modelData.idx)
                                                    onContextRequested: (x, y) => win.openMenu(this, x, y, modelData.src, modelData.idx, win.rowInfo(modelData.src, modelData.idx), false)
                                                }
                                            }
                                        }
                                    }
                                    Column {
                                        visible: win.cfg.showLetterRail
                                        Layout.alignment: Qt.AlignVCenter
                                        Layout.rightMargin: 2
                                        Repeater {
                                            model: win.groups
                                            delegate: Text {
                                                required property var modelData
                                                required property int index
                                                text: modelData.letter
                                                font: win.f(1.0)
                                                color: win.text
                                                opacity: railMa.containsMouse ? 1 : 0.6
                                                width: 26; height: Math.min(28, (alphaView.height - 10) / Math.max(1, win.groups.length))
                                                horizontalAlignment: Text.AlignHCenter
                                                verticalAlignment: Text.AlignVCenter
                                                MouseArea { id: railMa; anchors.fill: parent; hoverEnabled: true; onClicked: alphaView.positionViewAtIndex(win.headerRows[index], ListView.Beginning) }
                                            }
                                        }
                                    }
                                }

                                // plain grid or list
                                GridView {
                                    id: appsGrid
                                    readonly property bool list: win.cfg.viewMode === 2
                                    readonly property int cols: list ? 1
                                        : (win.cfg.appColumns > 0 ? win.cfg.appColumns : Math.max(1, Math.floor(width / win.appTileW)))
                                    clip: true
                                    model: !win.alpha && !win.searching ? win.activeModel : null
                                    cellWidth: Math.floor(width / cols)
                                    cellHeight: list ? win.iconPx + 24 : win.gridCellH
                                    keyNavigationEnabled: true
                                    boundsBehavior: Flickable.StopAtBounds
                                    SmoothScroll {}
                                    QQC2.ScrollBar.vertical: QQC2.ScrollBar { policy: QQC2.ScrollBar.AsNeeded }
                                    Keys.onReturnPressed: if (currentItem) currentItem.activated()
                                    Keys.onUpPressed: event => { if (currentIndex < cols) search.forceActiveFocus(); else event.accepted = false; }
                                    Keys.onLeftPressed: event => { if (currentIndex % cols === 0 && favGrid.count > 0) favGrid.forceActiveFocus(); else event.accepted = false; }
                                    delegate: AppTile {
                                        required property var model
                                        required property int index
                                        ui: win
                                        width: GridView.view.cellWidth
                                        height: GridView.view.cellHeight
                                        label: model.display
                                        subtitle: model.description || ""
                                        icon: model.decoration
                                        iconSize: win.iconPx
                                        listMode: appsGrid.list
                                        current: GridView.isCurrentItem && GridView.view.activeFocus
                                        onActivated: win.launch(win.activeModel, index)
                                        onContextRequested: (x, y) => win.openMenu(this, x, y, win.activeModel, index, model, false)
                                    }
                                    Text {
                                        anchors.centerIn: parent
                                        visible: appsGrid.count === 0
                                        text: i18n("Nothing here yet")
                                        font: win.f(1); color: win.text; opacity: 0.6
                                    }
                                }

                                // search results: instant app matches first, then KRunner's (calculator, settings, files, ...)
                                ListView {
                                    id: results
                                    objectName: "results"
                                    clip: true
                                    model: win.searching ? foundModel : null
                                    reuseItems: true
                                    boundsBehavior: Flickable.StopAtBounds
                                    SmoothScroll {}
                                    QQC2.ScrollBar.vertical: QQC2.ScrollBar { policy: QQC2.ScrollBar.AsNeeded }
                                    function step(dir) { let i = currentIndex + dir; while (i >= 0 && i < count && win.found[i].h !== undefined) i += dir; return i; }
                                    Keys.onDownPressed: { const i = step(1); if (i < count) currentIndex = i; }
                                    Keys.onUpPressed: { const i = step(-1); if (i >= 0) currentIndex = i; else search.forceActiveFocus(); }
                                    Keys.onReturnPressed: { const r = win.found[currentIndex]; if (r && r.h === undefined) win.launch(r.src, r.idx); }
                                    delegate: Item {
                                        id: rowRoot
                                        required property int index
                                        readonly property var row: win.found[index] || ({ h: "" })   // bound to the live results: re-binds in place
                                        readonly property bool isHead: row.h !== undefined
                                        width: ListView.view.width
                                        height: isHead ? 34 : Math.max(56, win.iconPx * 0.8 + 16)
                                        Text { visible: rowRoot.isHead; x: 10; anchors.bottom: parent.bottom; bottomPadding: 4; text: rowRoot.isHead ? rowRoot.row.h : ""; font: win.f(0.9); color: win.text; opacity: 0.6 }
                                        AppTile {
                                            visible: !rowRoot.isHead
                                            anchors.fill: parent
                                            ui: win
                                            listMode: true
                                            label: rowRoot.isHead ? "" : rowRoot.row.name
                                            subtitle: rowRoot.isHead ? "" : rowRoot.row.desc
                                            icon: rowRoot.isHead ? "" : rowRoot.row.icon
                                            iconSize: Math.round(win.iconPx * 0.8)
                                            current: rowRoot.ListView.isCurrentItem && rowRoot.ListView.view.activeFocus
                                            onActivated: if (!rowRoot.isHead) win.launch(rowRoot.row.src, rowRoot.row.idx)
                                            onContextRequested: (x, y) => { if (!rowRoot.isHead) win.openMenu(this, x, y, rowRoot.row.src, rowRoot.row.idx, win.rowInfo(rowRoot.row.src, rowRoot.row.idx), false); }
                                        }
                                    }
                                    Text {
                                        anchors.centerIn: parent
                                        visible: results.count === 0
                                        text: win.launcher.runnerModel.querying ? i18n("Searching…") : i18n("No results for “%1”", search.text)
                                        font: win.f(1); color: win.text; opacity: 0.6
                                    }
                                }
                            }
                        }
                    }

                    // ---- right: categories + virtual desktops --------------------
                    ColumnLayout {
                        Layout.fillWidth: false // nested layouts stretch by default
                        Layout.preferredWidth: win.catW
                        Layout.maximumWidth: win.catW
                        Layout.fillHeight: true
                        visible: win.cfg.showCategories
                        spacing: 14

                        Card {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            ListView {
                                id: catList
                                anchors.fill: parent
                                anchors.margins: 8
                                clip: true
                                spacing: 2
                                model: win.cats
                                boundsBehavior: Flickable.StopAtBounds
                                SmoothScroll {}
                                QQC2.ScrollBar.vertical: QQC2.ScrollBar { policy: QQC2.ScrollBar.AsNeeded }
                                delegate: Column {
                                    id: row
                                    required property var modelData
                                    required property int index
                                    readonly property bool active: index === win.catIndex
                                    width: ListView.view.width
                                    Item {
                                        visible: row.modelData.sepBefore === true
                                        width: parent.width
                                        height: visible ? 21 : 0
                                        Rectangle { anchors.centerIn: parent; width: parent.width - 32; height: 1; color: Qt.rgba(1, 1, 1, 0.25) }
                                    }
                                    Rectangle {
                                        width: parent.width
                                        height: Math.round(win.f(1.1).pixelSize * 2.3)
                                        radius: win.radius
                                        color: row.active ? win.accent : catMa.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : "transparent"
                                        Behavior on color { enabled: win.anim; ColorAnimation { duration: 120 } }
                                        Text { anchors.verticalCenter: parent.verticalCenter; x: 16; width: parent.width - 32; text: row.modelData.label; font: win.f(1.1); color: win.text; elide: Text.ElideRight }
                                        MouseArea {
                                            id: catMa; anchors.fill: parent; hoverEnabled: true
                                            onClicked: { win.catIndex = row.index; win.cfg.lastCategory = row.index; alphaView.positionViewAtBeginning(); appsGrid.positionViewAtBeginning(); }
                                        }
                                        Accessible.name: row.modelData.label
                                        Accessible.role: Accessible.Button
                                    }
                                }
                            }
                        }
                    }
                }

                // ---- bottom bar: settings (isolated) | view mode | big power buttons ----
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 14
                    component Pill: Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredHeight: 64
                        radius: 16
                        color: Qt.rgba(1, 1, 1, 0.1)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.14)
                    }
                    Pill {
                        Layout.preferredWidth: 64
                        Btn { anchors.centerIn: parent; size: 52; glyph: 30; on: win.settingsOpen; icon: "configure"; tip: i18n("Settings (live preview)"); onClicked: win.settingsOpen = !win.settingsOpen }
                    }
                    Rectangle { Layout.alignment: Qt.AlignVCenter; Layout.preferredWidth: 1; Layout.preferredHeight: 36; color: Qt.rgba(1, 1, 1, 0.25) }
                    Pill {
                        Layout.preferredWidth: 3 * 56 + 2 * 4 + 12
                        Row {
                            anchors.centerIn: parent
                            spacing: 4
                            Btn { size: 56; glyph: 32; icon: "view-sort-ascending"; tip: i18n("Alphabetical sections"); on: win.cfg.viewMode === 0; onClicked: win.cfg.viewMode = 0 }
                            Btn { size: 56; glyph: 32; icon: "view-grid"; tip: i18n("Grid"); on: win.cfg.viewMode === 1; onClicked: win.cfg.viewMode = 1 }
                            Btn { size: 56; glyph: 32; icon: "view-list-details"; tip: i18n("List (one column)"); on: win.cfg.viewMode === 2; onClicked: win.cfg.viewMode = 2 }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Repeater {
                        model: win.cfg.showPower ? [["system-lock-screen", i18n("Lock"), "lock", false], ["system-suspend", i18n("Sleep"), "sleep", false], ["system-log-out", i18n("Log out"), "logout", false], ["system-reboot", i18n("Restart"), "reboot", true], ["system-shutdown", i18n("Shut down"), "shutdown", true]] : []
                        delegate: PowerBtn {
                            required property var modelData
                            Layout.alignment: Qt.AlignVCenter
                            icon: modelData[0]; label: modelData[1]; danger: modelData[3]
                            onClicked: { win.visible = false; win.launcher.power(modelData[2]); }
                        }
                    }
                }
            }
        }

        // ---- live settings drawer: the launcher stays visible and updates as you drag --------
        Card {
            id: drawer
            width: win.settingsW
            y: panel.y
            height: panel.height
            x: win.settingsOpen ? parent.width - width - 24 : parent.width + 20
            visible: x < parent.width
            Behavior on x { enabled: win.anim; NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
            Kirigami.Theme.inherit: false
            Kirigami.Theme.colorSet: Kirigami.Theme.Complementary
            color: Qt.rgba(0.08, 0.09, 0.12, 0.82)
            MouseArea { anchors.fill: parent }

            component Slide: ColumnLayout {
                id: sl
                property string label
                property real value
                property real from
                property real to
                property real step: 1
                property string suffix
                signal moved(int v)
                Layout.fillWidth: true
                spacing: 0
                RowLayout {
                    Text { Layout.fillWidth: true; text: sl.label; font: win.f(0.95); color: win.text }
                    Text { text: Math.round(sl.value) + sl.suffix; font: win.f(0.95); color: win.accent }
                }
                QQC2.Slider {
                    id: sld
                    Layout.fillWidth: true
                    implicitHeight: 28
                    from: sl.from; to: sl.to; stepSize: sl.step; value: sl.value
                    onMoved: sl.moved(Math.round(value))
                    background: Rectangle {
                        x: sld.leftPadding; y: sld.topPadding + sld.availableHeight / 2 - height / 2
                        width: sld.availableWidth; height: 6; radius: 3; color: Qt.rgba(1, 1, 1, 0.2)
                        Rectangle { width: sld.visualPosition * parent.width; height: parent.height; radius: 3; color: win.accent }
                    }
                    handle: Rectangle {
                        x: sld.leftPadding + sld.visualPosition * (sld.availableWidth - width)
                        y: sld.topPadding + sld.availableHeight / 2 - height / 2
                        width: 20; height: 20; radius: 10
                        color: sld.pressed ? win.accent : "white"
                        border.width: 2; border.color: win.accent
                    }
                }
            }
            component Heading: Text { Layout.topMargin: 10; font: win.f(1.15); color: win.text }
            // preset picker: five named sizes
            component Presets: ColumnLayout {
                id: pr
                property string label
                property int current
                property var names: win.presetNames
                signal picked(int i)
                Layout.fillWidth: true
                spacing: 4
                Text { text: pr.label; font: win.f(0.95); color: win.text }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Repeater {
                        model: pr.names
                        delegate: Rectangle {
                            required property string modelData
                            required property int index
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            implicitHeight: 34
                            radius: 10
                            color: index === pr.current ? win.accent : pma.containsMouse ? Qt.rgba(1, 1, 1, 0.2) : Qt.rgba(1, 1, 1, 0.1)
                            Text { anchors.centerIn: parent; text: parent.modelData; font: win.f(0.8); color: win.text }
                            MouseArea { id: pma; anchors.fill: parent; hoverEnabled: true; onClicked: pr.picked(parent.index) }
                        }
                    }
                }
            }
            component Check: QQC2.CheckBox {
                id: ck
                Layout.fillWidth: true
                contentItem: Text { leftPadding: ck.indicator.width + 8; text: ck.text; font: win.f(0.95); color: win.text; verticalAlignment: Text.AlignVCenter; wrapMode: Text.Wrap }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 8
                RowLayout {
                    Text { Layout.fillWidth: true; text: i18n("Settings"); font: win.f(1.4); color: win.text }
                    Btn { icon: "window-close"; tip: i18n("Close"); onClicked: win.settingsOpen = false }
                }
                Flickable {
                    id: drawerScroll
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentWidth: width
                    contentHeight: dcol.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds
                    SmoothScroll {}
                    QQC2.ScrollBar.vertical: QQC2.ScrollBar { policy: QQC2.ScrollBar.AsNeeded }
                    ColumnLayout {
                        id: dcol
                        width: drawerScroll.width - 22
                        spacing: 6

                        Heading { text: i18n("Sizes") }
                        Presets { label: i18n("Icons (favorites and all apps)"); current: win.cfg.iconPreset; onPicked: i => win.cfg.iconPreset = i }
                        Presets { label: i18n("Text"); current: win.cfg.textPreset; onPicked: i => win.cfg.textPreset = i }

                        Heading { text: i18n("Favorites") }
                        Slide { label: i18n("Icons per row"); value: win.cfg.favColumns; from: 1; to: 6; suffix: ""; onMoved: v => win.cfg.favColumns = v }

                        Heading { text: i18n("All apps") }
                        Check { text: win.cfg.appColumns === 0 ? i18n("Fit icons per row automatically (now %1)", win.appCols) : i18n("Fit icons per row automatically"); checked: win.cfg.appColumns === 0; onToggled: win.cfg.appColumns = checked ? 0 : Math.max(1, win.appCols) }
                        Slide { visible: win.cfg.appColumns > 0 && win.cfg.viewMode !== 2; label: i18n("Icons per row"); value: win.cfg.appColumns; from: 1; to: 14; onMoved: v => win.cfg.appColumns = v }

                        Heading { text: i18n("Behavior") }
                        Presets { label: i18n("When it opens, show"); names: [i18n("All apps"), i18n("Recent"), i18n("Most used"), i18n("Last used")]; current: win.cfg.startCategory; onPicked: i => win.cfg.startCategory = i }
                        Check { text: i18n("Search documents, files, settings and the calculator too (off = apps only)"); checked: win.cfg.searchDocuments; onToggled: win.cfg.searchDocuments = checked }
                        Check { text: i18n("Clear the search box when it opens"); checked: win.cfg.clearSearch; onToggled: win.cfg.clearSearch = checked }
                        Check { text: i18n("Close after launching an app"); checked: win.cfg.closeOnLaunch; onToggled: win.cfg.closeOnLaunch = checked }
                        Check { text: i18n("Close when clicking empty space"); checked: win.cfg.closeOnClickOutside; onToggled: win.cfg.closeOnClickOutside = checked }
                        Check { text: i18n("Show favorites panel"); checked: win.cfg.showFavorites; onToggled: win.cfg.showFavorites = checked }
                        Check { text: i18n("Show category list"); checked: win.cfg.showCategories; onToggled: win.cfg.showCategories = checked }
                        Check { text: i18n("Show A–Z letter rail"); checked: win.cfg.showLetterRail; onToggled: win.cfg.showLetterRail = checked }
                        Check { text: i18n("Show power buttons"); checked: win.cfg.showPower; onToggled: win.cfg.showPower = checked }

                        Heading { text: i18n("Look") }
                        Slide { label: i18n("Wallpaper dim"); value: win.cfg.dim; from: 0; to: 95; step: 5; suffix: "%"; onMoved: v => win.cfg.dim = v }
                        Slide { label: i18n("Wallpaper blur"); value: win.cfg.blur; from: 0; to: 100; step: 5; suffix: "%"; onMoved: v => win.cfg.blur = v }
                        Slide { label: i18n("Card tint"); value: win.cfg.cardOpacity; from: 0; to: 40; step: 2; suffix: "%"; onMoved: v => win.cfg.cardOpacity = v }
                        Slide { label: i18n("Corner radius"); value: win.cfg.tileRadius; from: 0; to: 32; step: 2; suffix: " px"; onMoved: v => win.cfg.tileRadius = v }
                        Slide { label: i18n("Power button size"); value: win.cfg.powerSize; from: 24; to: 72; step: 4; suffix: " px"; onMoved: v => win.cfg.powerSize = v }

                        RowLayout {
                            Layout.topMargin: 14
                            Layout.fillWidth: true
                            QQC2.Button { text: i18n("Reset sizes"); icon.name: "edit-undo"; onClicked: { for (const k of ["favColumns", "appColumns", "iconPreset", "textPreset", "tileRadius", "powerSize"]) win.cfg[k] = win.cfg[k + "Default"]; } }
                            Item { Layout.fillWidth: true }
                            QQC2.Button { text: i18n("More options…"); icon.name: "configure"; onClicked: { win.visible = false; win.launcher.openSettings(); } }
                        }
                        Item { Layout.preferredHeight: 6 }
                    }
                }
            }
        }

        // Passive observer of every left click (it never takes the click, so tiles and buttons keep working);
        // a press-and-release that did not move and hit empty space closes the launcher.
        Item {
            id: tapLayer
            anchors.fill: parent
            z: 1000
            PointHandler {
                acceptedButtons: Qt.LeftButton
                onActiveChanged: {
                    if (active) return;
                    const d = Math.hypot(point.scenePosition.x - point.scenePressPosition.x, point.scenePosition.y - point.scenePressPosition.y);
                    if (d < 12) win.tapAt(point.scenePosition.x, point.scenePosition.y);
                }
            }
        }
    }
}
