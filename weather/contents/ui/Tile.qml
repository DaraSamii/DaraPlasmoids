import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

// Metric tile: bold colored value, optional segmented gauge with a sliding marker, optional visual on the right.
Rectangle {
    id: tile
    property string label
    property string value
    property string sub
    property color accent: Kirigami.Theme.highlightColor
    property real gauge: -1                 // 0..1, or -1 to hide
    property var gaugeColors: []
    default property alias extra: extraSlot.data

    Layout.fillWidth: true
    Layout.preferredHeight: Kirigami.Units.gridUnit * 6.6
    radius: Kirigami.Units.largeSpacing
    color: Qt.alpha(tile.accent, 0.2)
    border.color: Qt.alpha(tile.accent, 0.5)

    Item { id: extraSlot; anchors { top: parent.top; right: parent.right; margins: Kirigami.Units.largeSpacing } width: Kirigami.Units.gridUnit * 3; height: Kirigami.Units.gridUnit * 3.6 }

    ColumnLayout {
        anchors { fill: parent; margins: Kirigami.Units.largeSpacing }
        spacing: 0
        PlasmaComponents.Label { text: tile.label.toUpperCase(); font.bold: true; font.letterSpacing: 1; color: tile.accent }
        PlasmaComponents.Label { text: tile.value; font.pixelSize: Kirigami.Units.gridUnit * 1.9; font.weight: Font.Bold }
        PlasmaComponents.Label { text: tile.sub; font.weight: Font.DemiBold; opacity: 0.85; elide: Text.ElideRight; Layout.fillWidth: true }
        Item { Layout.fillHeight: true }
        Item {
            id: bar
            visible: tile.gauge >= 0
            Layout.fillWidth: true
            Layout.preferredHeight: 14
            Row {
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: 2
                Repeater {
                    model: tile.gaugeColors
                    Rectangle {
                        required property var modelData
                        width: (bar.width - 2 * (tile.gaugeColors.length - 1)) / tile.gaugeColors.length
                        height: 6; radius: 3; color: modelData
                    }
                }
            }
            Rectangle {
                id: marker
                property real f: tile.gauge
                Behavior on f { NumberAnimation { duration: 1100; easing.type: Easing.OutBack } }
                x: Math.max(0, Math.min(1, f)) * (bar.width - width)
                anchors.verticalCenter: parent.verticalCenter
                width: 8; height: 14; radius: 4; color: "white"; border.color: "#33000000"
            }
        }
    }
}
