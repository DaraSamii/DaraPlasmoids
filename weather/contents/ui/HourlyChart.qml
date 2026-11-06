import QtQuick
import QtQuick.Controls as QQC2
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../code/weather.js" as W

// Scrollable 24h strip: time, icon, smooth temperature curve with labels, precipitation chance.
Flickable {
    id: fl
    property var hours: []
    property bool h24: true

    readonly property real colW: Kirigami.Units.gridUnit * 3.2
    readonly property real dayRowH: Kirigami.Units.gridUnit * 1.4   // header row that names each day
    readonly property real curveTop: dayRowH + Kirigami.Units.gridUnit * 3.2
    readonly property real curveH: Kirigami.Units.gridUnit * 4.2
    readonly property real tMin: hours.length ? Math.min.apply(null, hours.map(h => h.temp)) : 0
    readonly property real tMax: hours.length ? Math.max.apply(null, hours.map(h => h.temp)) : 1
    readonly property var pts: hours.map((h, i) => ({
        x: i * colW + colW / 2,
        y: curveH * 0.3 + (tMax - h.temp) / Math.max(1, tMax - tMin) * curveH * 0.5
    }))
    property real reveal: 0

    implicitHeight: curveTop + curveH + Kirigami.Units.gridUnit * 1.4
    contentWidth: hours.length * colW
    contentHeight: height
    flickableDirection: Flickable.HorizontalFlick
    boundsBehavior: Flickable.StopAtBounds
    clip: true

    onHoursChanged: replay()
    function replay() { reveal = 0; sweep.restart(); }
    NumberAnimation { id: sweep; target: fl; property: "reveal"; to: 1; duration: 1100; easing.type: Easing.OutCubic }
    onRevealChanged: curve.requestPaint()
    onPtsChanged: curve.requestPaint()

    // Shift + wheel scrolls sideways (plain wheel keeps scrolling the page)
    WheelHandler {
        acceptedModifiers: Qt.ShiftModifier
        onWheel: event => fl.contentX = Math.max(0, Math.min(fl.contentWidth - fl.width, fl.contentX - event.angleDelta.y))
    }

    Canvas {
        id: curve
        y: fl.curveTop
        width: fl.contentWidth
        height: fl.curveH
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const p = fl.pts;
            if (p.length < 2) return;
            const c = Kirigami.Theme.highlightColor;
            ctx.save();
            ctx.beginPath();
            ctx.rect(0, 0, width * fl.reveal, height);
            ctx.clip();
            ctx.beginPath();
            ctx.moveTo(p[0].x, p[0].y);
            for (let i = 1; i < p.length; i++)
                ctx.quadraticCurveTo(p[i - 1].x, p[i - 1].y, (p[i - 1].x + p[i].x) / 2, (p[i - 1].y + p[i].y) / 2);
            ctx.lineTo(p[p.length - 1].x, p[p.length - 1].y);
            ctx.lineWidth = 2.5;
            ctx.lineJoin = "round";
            ctx.strokeStyle = c;
            ctx.stroke();
            ctx.lineTo(p[p.length - 1].x, height);
            ctx.lineTo(p[0].x, height);
            ctx.closePath();
            const g = ctx.createLinearGradient(0, 0, 0, height);
            g.addColorStop(0, Qt.alpha(c, 0.35));
            g.addColorStop(1, Qt.alpha(c, 0));
            ctx.fillStyle = g;
            ctx.fill();
            ctx.fillStyle = c;
            for (let i = 0; i < p.length; i++) {
                ctx.beginPath();
                ctx.arc(p[i].x, p[i].y, i === 0 ? 4.5 : 3, 0, 2 * Math.PI);
                ctx.fill();
            }
            ctx.restore();
        }
    }

    Repeater {
        model: fl.hours
        delegate: Item {
            required property var modelData
            required property int index
            x: index * fl.colW
            width: fl.colW
            height: fl.height
            opacity: fl.reveal > (index + 1) / fl.hours.length ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 250 } }

            readonly property bool newDay: index === 0 || modelData.time.substr(0, 10) !== fl.hours[index - 1].time.substr(0, 10)

            Rectangle {   // day boundary: thin line from the header down through the whole column
                visible: index > 0 && parent.newDay
                x: 0; y: 4; width: 1.5; height: parent.height - 8; radius: 1
                color: Qt.lighter(Kirigami.Theme.highlightColor, 1.6); opacity: 0.6
            }
            Rectangle {   // day pill: "Today" / "Sat · Nov 7" (extends right over the empty header row)
                visible: parent.newDay
                x: index === 0 ? 4 : 5; y: 2
                width: pillText.implicitWidth + Kirigami.Units.largeSpacing; height: fl.dayRowH - 4
                radius: height / 2
                color: Qt.alpha(Kirigami.Theme.highlightColor, 0.35)
                PlasmaComponents.Label {
                    id: pillText
                    anchors.centerIn: parent
                    text: index === 0 ? i18n("Today") : W.dayName(modelData.time, index) + " · " + W.dateShort(modelData.time)
                    font.bold: true; font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                }
            }
            PlasmaComponents.Label {
                y: fl.dayRowH + Kirigami.Units.smallSpacing
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: index === 0 ? i18n("Now") : W.hourLabel(modelData.time, fl.h24)
                font.bold: true
                color: index === 0 ? Qt.lighter(Kirigami.Theme.highlightColor, 1.6) : Kirigami.Theme.textColor
                opacity: index === 0 ? 1 : 0.85
            }
            Kirigami.Icon {
                y: fl.dayRowH + Kirigami.Units.gridUnit * 1.4
                anchors.horizontalCenter: parent.horizontalCenter
                width: Kirigami.Units.iconSizes.smallMedium; height: width
                source: modelData.mono ? modelData.symbolic : modelData.icon
            }
            PlasmaComponents.Label {
                y: fl.curveTop + fl.pts[index].y - height - Kirigami.Units.smallSpacing
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: Math.round(modelData.temp) + "°"
                font.bold: true
                font.pixelSize: Kirigami.Units.gridUnit * 1.15
            }
            PlasmaComponents.Label {
                y: fl.curveTop + fl.curveH + Kirigami.Units.smallSpacing
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: modelData.pop >= 10 ? modelData.pop + "%" : "–"
                color: modelData.pop >= 10 ? "#4aa3ff" : Kirigami.Theme.textColor
                opacity: modelData.pop >= 10 ? 1 : 0.35
                font.bold: true
            }
        }
    }
}
