import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../code/weather.js" as W

RowLayout {
    id: row
    required property var modelData
    readonly property var day: modelData
    required property int index
    property real gmin: 0
    property real gmax: 1
    property real reveal: 0

    spacing: Kirigami.Units.smallSpacing
    Layout.fillWidth: true
    Component.onCompleted: reveal = 1
    Behavior on reveal { NumberAnimation { duration: 900 + row.index * 120; easing.type: Easing.OutCubic } }

    PlasmaComponents.Label { text: W.dayName(day.date, index); Layout.preferredWidth: Kirigami.Units.gridUnit * 3.6; font.bold: true; font.pixelSize: Kirigami.Units.gridUnit * 1.05 }
    Kirigami.Icon { source: day.icon; Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium; Layout.preferredHeight: Layout.preferredWidth }
    PlasmaComponents.Label {
        text: day.pop >= 10 ? day.pop + "%" : ""
        color: "#4aa3ff"; font.bold: true
        Layout.preferredWidth: Kirigami.Units.gridUnit * 2
    }
    PlasmaComponents.Label { text: Math.round(day.min) + "°"; font.weight: Font.DemiBold; font.pixelSize: Kirigami.Units.gridUnit * 1.05; opacity: 0.8; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: Kirigami.Units.gridUnit * 1.8 }
    Item {
        id: track
        Layout.fillWidth: true
        Layout.preferredHeight: 8
        Rectangle { anchors.fill: parent; radius: height / 2; color: Qt.alpha(Kirigami.Theme.textColor, 0.12) }
        Rectangle {
            readonly property real span: Math.max(1, row.gmax - row.gmin)
            x: (day.min - row.gmin) / span * track.width
            width: Math.max(height, (day.max - day.min) / span * track.width * row.reveal)
            height: parent.height
            radius: height / 2
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "#4aa3ff" }
                GradientStop { position: 1; color: "#ffb84a" }
            }
        }
    }
    PlasmaComponents.Label { text: Math.round(day.max) + "°"; font.bold: true; font.pixelSize: Kirigami.Units.gridUnit * 1.15; Layout.preferredWidth: Kirigami.Units.gridUnit * 1.8 }
}
