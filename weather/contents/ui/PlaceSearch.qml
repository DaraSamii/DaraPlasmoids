import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../code/weather.js" as W

// City search backed by the Open-Meteo geocoding API. Emits picked({name, admin1, country, lat, lon}).
ColumnLayout {
    id: ps
    signal picked(var place)
    property var results: []
    property string status: ""
    property int seq: 0
    spacing: Kirigami.Units.smallSpacing

    function focusField() { field.forceActiveFocus(); }

    function search(q) {
        const my = ++seq;
        results = [];
        if (q.trim().length < 2) { status = ""; return; }
        status = i18n("Searching…");
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE || my !== seq) return;
            try {
                if (xhr.status !== 200) throw new Error("HTTP " + xhr.status);
                const r = JSON.parse(xhr.responseText).results || [];
                results = r.map(x => ({ name: x.name, admin1: x.admin1, country: x.country, lat: x.latitude, lon: x.longitude }));
                status = r.length ? "" : i18n("No matches");
            } catch (e) {
                status = i18n("Search failed (%1)", e.message);
            }
        };
        xhr.open("GET", "https://geocoding-api.open-meteo.com/v1/search?count=6&language=" + W.searchLang(q) + "&name=" + encodeURIComponent(q.trim()));
        xhr.send();
    }

    Kirigami.SearchField {
        id: field
        Layout.fillWidth: true
        placeholderText: i18n("Search city…")
        onTextChanged: debounce.restart()
        onAccepted: ps.search(text)
    }
    Timer { id: debounce; interval: 400; onTriggered: ps.search(field.text) }

    Repeater {
        model: ps.results
        delegate: QQC2.ItemDelegate {
            required property var modelData
            Layout.fillWidth: true
            text: W.placeLabel(modelData)
            icon.name: "mark-location"
            onClicked: { ps.picked(modelData); field.text = ""; ps.results = []; }
        }
    }
    QQC2.Label { visible: ps.status !== ""; text: ps.status; opacity: 0.7; Layout.fillWidth: true }
}
