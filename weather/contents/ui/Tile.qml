import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

Rectangle {
    property string label
    property string value
    property string sub
    default property alias extra: extraSlot.data

    Layout.fillWidth: true
    Layout.preferredHeight: Kirigami.Units.gridUnit * 4.4
    radius: Kirigami.Units.largeSpacing
    color: Qt.alpha(Kirigami.Theme.textColor, 0.05)

    Item { id: extraSlot; anchors { top: parent.top; right: parent.right; margins: Kirigami.Units.smallSpacing } width: Kirigami.Units.iconSizes.medium; height: width }

    ColumnLayout {
        anchors { fill: parent; margins: Kirigami.Units.largeSpacing }
        spacing: 0
        PlasmaComponents.Label { text: label; opacity: 0.6; font.pixelSize: Kirigami.Theme.smallFont.pixelSize }
        PlasmaComponents.Label { text: value; font.pixelSize: Kirigami.Units.gridUnit * 1.5; font.weight: Font.DemiBold }
        PlasmaComponents.Label { text: sub; opacity: 0.7; font.pixelSize: Kirigami.Theme.smallFont.pixelSize; elide: Text.ElideRight; Layout.fillWidth: true }
    }
}
