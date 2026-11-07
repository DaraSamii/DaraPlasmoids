import QtQuick
import QtQuick.Window
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.private.kicker as Kicker

PlasmoidItem {
    id: root

    readonly property var cfg: Plasmoid.configuration
    property string wallUrl: ""
    readonly property bool open: win.visible

    // The button IS the full representation and there is no compact one, like Pager or Show Desktop: Plasma draws it
    // straight into the panel, so there is no popup to open (an empty popup still showed as a box over the button).
    preferredRepresentation: fullRepresentation
    compactRepresentation: null
    fullRepresentation: CompactRepresentation { launcher: root }
    Plasmoid.icon: cfg.icon
    toolTipMainText: i18n("Applications")
    toolTipSubText: i18n("Open the application launcher")

    // --- models (shared with the window) ---------------------------------
    readonly property Kicker.RootModel rootModel: Kicker.RootModel {
        autoPopulate: false
        appletInterface: root
        flat: true
        sorted: true
        showSeparators: false
        showAllApps: true
        showAllAppsCategorized: false
        showRecentApps: false
        showRecentDocs: false
        showRecentFolders: false
        showPowerSession: false
        showFavoritesPlaceholder: false
        Component.onCompleted: {
            favoritesModel.initForClient("io.github.darasamii.launcher.favorites.instance-" + Plasmoid.id);
            if (!root.cfg.favoritesSeeded) {
                if (favoritesModel.count < 1)
                    favoritesModel.portOldFavorites(["preferred://browser", "org.kde.dolphin.desktop", "systemsettings.desktop", "org.kde.konsole.desktop", "org.kde.discover.desktop"]);
                root.cfg.favoritesSeeded = true;
            }
            refresh();
        }
    }
    readonly property Kicker.RunnerModel runnerModel: Kicker.RunnerModel {
        appletInterface: root
        mergeResults: true
        favoritesModel: root.rootModel.favoritesModel
    }
    readonly property Kicker.RecentUsageModel recentModel: Kicker.RecentUsageModel {
        shownItems: Kicker.RecentUsageModel.OnlyApps
        ordering: Kicker.RecentUsageModel.Recent
    }
    readonly property Kicker.RecentUsageModel frequentModel: Kicker.RecentUsageModel {
        shownItems: Kicker.RecentUsageModel.OnlyApps
        ordering: Kicker.RecentUsageModel.Popular
    }

    // --- helpers: run a shell command (wallpaper lookup, power actions) ----
    property int seq: 0
    property var pending: ({})
    P5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            disconnectSource(source);
            const cb = root.pending[source];
            delete root.pending[source];
            if (cb) cb((data["stdout"] || "").trim());
        }
    }
    function run(cmd, cb) {
        const key = cmd + " # " + (++seq); // unique so repeated calls are not deduplicated
        if (cb) pending[key] = cb;
        exec.connectSource(key);
    }
    function refreshWallpaper() {
        if (cfg.wallpaperMode !== 0) return;
        const py = Qt.resolvedUrl("../code/wallpaper.py").toString().replace("file://", "");
        run("python3 -I '" + py + "'", out => wallUrl = out);
    }
    Component.onCompleted: refreshWallpaper() // ready before the first open: no black flash
    function power(what) {
        const prompt = a => "dbus-send --session --type=method_call --dest=org.kde.LogoutPrompt /LogoutPrompt org.kde.LogoutPrompt." + a;
        run({ lock: "loginctl lock-session", sleep: "systemctl suspend", logout: prompt("promptLogout"),
              reboot: prompt("promptReboot"), shutdown: prompt("promptShutDown") }[what]);
    }

    LauncherWindow { id: win; launcher: root }

    property double lastActivation: 0
    Connections {
        target: Plasmoid
        function onActivated() {
            const now = Date.now();
            if (now - root.lastActivation < 150) return; // one Meta press can arrive twice (KWin's Meta + the widget's own shortcut)
            root.lastActivation = now;
            root.toggle();
        }
    }
    // The launcher always opens fullscreen on the primary screen, whichever screen has focus. A hidden window has no
    // screen of its own to follow, so Qt keeps it on the primary screen; the launcher window's visualParent sits in it.
    // Only fullscreen can choose its screen on Wayland (KWin places normal windows), so the taskbar is covered.
    // shortcut: changing the primary screen while Plasma runs needs a plasmashell restart to be picked up.
    readonly property Item primaryItem: primaryAnchorItem
    Window {
        visible: false
        transientParent: null
        Item { id: primaryAnchorItem; readonly property var scr: Screen }
    }
    function primaryRect() {
        const s = primaryAnchorItem.scr;
        return { x: s.virtualX, y: s.virtualY, w: s.width, h: s.height };
    }
    function toggle() {
        if (win.visible) { win.visible = false; return; }
        const r = primaryRect();
        win.x = r.x; win.y = r.y; win.width = r.w; win.height = r.h; // sized before it is shown: no wrong-size frame
        // not win.toggle(): that marks this widget "expanded", and Plasma then flashes an empty popup (the "big icon")
        win.visibility = Window.FullScreen;
        win.requestActivate();
    }

    function openSettings() { Plasmoid.internalAction("configure").trigger(); }
}
