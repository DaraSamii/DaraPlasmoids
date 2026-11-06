import QtQuick
import org.kde.plasma.plasmoid
import "../code/weather.js" as W

PlasmoidItem {
    id: root

    readonly property var cfg: Plasmoid.configuration
    readonly property var places: W.parsePlaces(cfg.places)
    readonly property int placeIndex: Math.max(0, Math.min(cfg.placeIndex, places.length - 1))
    readonly property var place: places.length ? places[placeIndex] : null
    readonly property bool imperial: cfg.units === 1

    property var wx: null      // normalized forecast, null until first success
    property bool loading: false
    property string error: ""
    property string updated: ""
    property int seq: 0

    function load() {
        if (!place) return;
        const my = ++seq;
        const xhr = new XMLHttpRequest();
        loading = true;
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE || my !== seq) return; // stale: place changed meanwhile
            loading = false;
            try {
                if (xhr.status !== 200) throw new Error("HTTP " + xhr.status);
                wx = W.normalize(JSON.parse(xhr.responseText));
                error = "";
                updated = Qt.formatTime(new Date(), Qt.locale().timeFormat(1));
            } catch (e) {
                error = i18n("Could not load weather (%1)", e.message);
            }
        };
        xhr.open("GET", W.forecastUrl(place, imperial, cfg.model));
        xhr.send();
    }

    // wipe stale data when switching place/units so we never show Tehran's weather under "Montreal"
    onPlaceChanged: { wx = null; load(); }
    onImperialChanged: { wx = null; load(); }
    Connections { target: root.cfg; function onModelChanged() { root.wx = null; root.load(); } }
    Component.onCompleted: load()

    Timer {
        interval: Math.max(5, root.cfg.refreshMin) * 60000
        running: true
        repeat: true
        onTriggered: root.load()
    }

    Plasmoid.icon: wx ? wx.now.icon : "weather-none-available"
    toolTipMainText: place ? place.name + (wx ? " · " + Math.round(wx.now.temperature_2m) + "°" : "") : ""
    toolTipSubText: wx ? wx.now.text + "\n" + i18n("H %1°  L %2°", Math.round(wx.days[0].max), Math.round(wx.days[0].min)) : error

    compactRepresentation: CompactRepresentation { weather: root }
    fullRepresentation: FullRepresentation { weather: root }
}
