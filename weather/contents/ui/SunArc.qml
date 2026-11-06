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
    readonly property real pad: 14
    readonly property real r: Math.min(arc.width / 2 - pad, arc.height - 2 * pad)
    readonly property real dotX: arc.width / 2 + r * Math.cos(Math.PI + Math.PI * prog)
    readonly property real dotY: arc.height - pad + r * Math.sin(Math.PI + Math.PI * prog)

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
            const pad = sun.pad, cx = width / 2, cy = height - pad, r = sun.r;
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
            ctx.fillStyle = Qt.alpha("#ffb84a", 0.14); // warm fan under the travelled part
            ctx.beginPath(); ctx.moveTo(cx, cy); ctx.arc(cx, cy, r, Math.PI, a); ctx.closePath(); ctx.fill();
        }
        Item {   // sun marker with pulsing halo (QML so it can animate cheaply)
            visible: sun.daytime
            x: sun.dotX; y: sun.dotY
            Rectangle {
                id: halo
                anchors.centerIn: parent; width: 30; height: 30; radius: 15; color: "#ffb84a"; opacity: 0.35
                SequentialAnimation on scale { running: sun.visible; loops: Animation.Infinite
                    NumberAnimation { to: 1.5; duration: 1300; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0.8; duration: 1300; easing.type: Easing.InOutSine } }
            }
            Rectangle { anchors.centerIn: parent; width: 16; height: 16; radius: 8; color: "#ffd75a"; border.color: "#ff9d2e"; border.width: 2 }
        }
        PlasmaComponents.Label {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: Kirigami.Units.gridUnit
            text: i18n("Daylight %1", W.duration(sun.sunrise, sun.sunset))
            font.bold: true
            font.pixelSize: Kirigami.Units.gridUnit * 1.1
        }
    }
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Kirigami.Units.smallSpacing
        Repeater {
            model: [
                { label: i18n("Sunrise"), iso: sun.sunrise, color: "#ffb84a", icon: "weather-clear", left: true },
                { label: i18n("Sunset"), iso: sun.sunset, color: "#ff7a59", icon: "weather-clear-night", left: false }
            ]
            delegate: RowLayout {
                required property var modelData
                Layout.fillWidth: true
                layoutDirection: modelData.left ? Qt.LeftToRight : Qt.RightToLeft
                spacing: Kirigami.Units.smallSpacing
                Kirigami.Icon { source: modelData.icon; Layout.preferredWidth: Kirigami.Units.iconSizes.large; Layout.preferredHeight: Layout.preferredWidth }
                ColumnLayout {
                    spacing: 0
                    PlasmaComponents.Label { text: modelData.label.toUpperCase(); font.bold: true; font.letterSpacing: 1; color: modelData.color; Layout.alignment: modelData.left ? Qt.AlignLeft : Qt.AlignRight }
                    PlasmaComponents.Label { text: W.timeLabel(modelData.iso, sun.h24); font.bold: true; font.pixelSize: Kirigami.Units.gridUnit * 1.6; color: modelData.color; Layout.alignment: modelData.left ? Qt.AlignLeft : Qt.AlignRight }
                }
                Item { Layout.fillWidth: true }
            }
        }
    }
}
