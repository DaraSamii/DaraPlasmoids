import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../code/weather.js" as W

// Wind: compass with a swinging arrow, streaks that blow faster the stronger the wind.
Rectangle {
    id: card
    property real speed: 0
    property real gust: NaN
    property real dir: 0
    property string unit: "km/h"
    property bool run: true
    readonly property color accent: "#2fd3c4"
    readonly property real strength: Math.max(0.25, Math.min(3, speed / (unit === "mph" ? 12 : 20)))

    Layout.fillWidth: true
    Layout.preferredHeight: Kirigami.Units.gridUnit * 7.4
    radius: Kirigami.Units.largeSpacing
    color: Qt.alpha(accent, 0.12)
    border.color: Qt.alpha(accent, 0.35)
    clip: true

    Repeater {   // streaks
        model: 6
        Item {
            id: st
            required property int index
            y: 14 + index * (card.height - 28) / 5
            height: 3; width: 36 + (index % 3) * 22
            Rectangle { anchors.fill: parent; radius: 1.5; color: card.accent; opacity: 0.35 }
            SequentialAnimation on x {
                running: card.run && card.visible; loops: Animation.Infinite
                PauseAnimation { duration: (st.index * 410) % 1700 }
                NumberAnimation { from: -st.width; to: card.width; duration: 4200 / card.strength + (st.index % 3) * 500 }
            }
        }
    }

    RowLayout {
        anchors { fill: parent; margins: Kirigami.Units.largeSpacing }
        spacing: Kirigami.Units.largeSpacing
        Item {   // compass
            Layout.preferredWidth: Kirigami.Units.gridUnit * 5
            Layout.preferredHeight: Layout.preferredWidth
            Rectangle { anchors.fill: parent; radius: width / 2; color: Qt.alpha(Kirigami.Theme.backgroundColor, 0.7); border.width: 3; border.color: card.accent }
            Repeater {
                model: ["N", "E", "S", "W"]
                PlasmaComponents.Label {
                    required property var modelData
                    required property int index
                    text: modelData; font.bold: true; font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    color: index === 0 ? "#ff6b6b" : Kirigami.Theme.textColor; opacity: index === 0 ? 1 : 0.6
                    x: parent.width / 2 - width / 2 + [0, 1, 0, -1][index] * (parent.width / 2 - 11)
                    y: parent.height / 2 - height / 2 + [-1, 0, 1, 0][index] * (parent.height / 2 - 11)
                }
            }
            Kirigami.Icon {
                id: arrow
                anchors.centerIn: parent
                width: parent.width * 0.5; height: width; source: "go-up"
                color: card.accent
                rotation: card.dir + 180   // points where the wind blows to
                Behavior on rotation { NumberAnimation { duration: 1200; easing.type: Easing.OutElastic; easing.amplitude: 1.0; easing.period: 0.8 } }
                SequentialAnimation on scale {
                    running: card.run && card.visible; loops: Animation.Infinite
                    NumberAnimation { to: 1.08; duration: 1200; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0.94; duration: 1200; easing.type: Easing.InOutSine }
                }
            }
        }
        ColumnLayout {
            spacing: 0
            PlasmaComponents.Label { text: i18n("WIND"); font.bold: true; font.letterSpacing: 1; color: card.accent }
            PlasmaComponents.Label { text: Math.round(card.speed) + " " + card.unit; font.pixelSize: Kirigami.Units.gridUnit * 2.2; font.weight: Font.Bold }
            PlasmaComponents.Label { text: i18n("from %1 (%2°)", W.compass(card.dir), Math.round(card.dir)); font.bold: true; font.pixelSize: Kirigami.Units.gridUnit * 1.05 }
            PlasmaComponents.Label { text: isNaN(card.gust) ? "" : i18n("Gusts up to %1 %2", Math.round(card.gust), card.unit); opacity: 0.85; font.weight: Font.DemiBold }
        }
    }
}
