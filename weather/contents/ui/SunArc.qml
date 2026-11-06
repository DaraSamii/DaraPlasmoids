import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../code/weather.js" as W

ColumnLayout {
    id: sun
    property string nowIso
    property string sunrise
    property string sunset
    property bool h24: true

    readonly property real frac: Math.max(0, Math.min(1, (W.mins(nowIso) - W.mins(sunrise)) / Math.max(1, W.mins(sunset) - W.mins(sunrise))))
    readonly property bool daytime: W.mins(nowIso) >= W.mins(sunrise) && W.mins(nowIso) <= W.mins(sunset)
    property real prog: 0

    spacing: 0
    Component.onCompleted: prog = frac
    onFracChanged: prog = frac
    Behavior on prog { NumberAnimation { duration: 1400; easing.type: Easing.OutCubic } }
    onProgChanged: arc.requestPaint()

    Canvas {
        id: arc
        Layout.fillWidth: true
        Layout.preferredHeight: Kirigami.Units.gridUnit * 5
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const pad = 14, cx = width / 2, cy = height - pad, r = Math.min(width / 2 - pad, height - 2 * pad);
            ctx.lineCap = "round";
            ctx.strokeStyle = Qt.alpha(Kirigami.Theme.textColor, 0.25);
            ctx.lineWidth = 1;
            ctx.beginPath(); ctx.moveTo(pad, cy); ctx.lineTo(width - pad, cy); ctx.stroke();
            ctx.setLineDash([4, 5]);
            ctx.beginPath(); ctx.arc(cx, cy, r, Math.PI, 2 * Math.PI); ctx.stroke();
            ctx.setLineDash([]);
            const a = Math.PI + Math.PI * sun.prog;
            ctx.strokeStyle = "#ffb84a";
            ctx.lineWidth = 3;
            ctx.beginPath(); ctx.arc(cx, cy, r, Math.PI, a); ctx.stroke();
            if (sun.daytime) {
                const x = cx + r * Math.cos(a), y = cy + r * Math.sin(a);
                ctx.fillStyle = Qt.alpha("#ffb84a", 0.3);
                ctx.beginPath(); ctx.arc(x, y, 11, 0, 2 * Math.PI); ctx.fill();
                ctx.fillStyle = "#ffd75a";
                ctx.beginPath(); ctx.arc(x, y, 6, 0, 2 * Math.PI); ctx.fill();
            }
        }
        PlasmaComponents.Label {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: Kirigami.Units.gridUnit
            text: i18n("Daylight %1", W.duration(sun.sunrise, sun.sunset))
            opacity: 0.7
            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
        }
    }
    RowLayout {
        Layout.fillWidth: true
        PlasmaComponents.Label { text: i18n("Sunrise %1", W.timeLabel(sun.sunrise, sun.h24)); Layout.fillWidth: true }
        PlasmaComponents.Label { text: i18n("Sunset %1", W.timeLabel(sun.sunset, sun.h24)) }
    }
}
