import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

MouseArea {
    id: compact
    required property QtObject weather
    readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property var now: weather.wx ? weather.wx.now : null

    Layout.minimumWidth: grid.implicitWidth
    Layout.minimumHeight: grid.implicitHeight
    hoverEnabled: true
    onClicked: weather.expanded = !weather.expanded

    // soft hover highlight
    Rectangle {
        anchors.fill: parent
        radius: Kirigami.Units.cornerRadius
        color: Kirigami.Theme.highlightColor
        opacity: compact.containsMouse ? 0.18 : 0
        Behavior on opacity { NumberAnimation { duration: Kirigami.Units.shortDuration } }
    }

    GridLayout {
        id: grid
        anchors.centerIn: parent
        flow: compact.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
        columnSpacing: Kirigami.Units.smallSpacing
        rowSpacing: 0

        Kirigami.Icon {
            id: icon
            visible: weather.cfg.panelIcon || !weather.cfg.panelTemp
            source: Plasmoid.icon
            Layout.preferredWidth: Math.min(compact.height, compact.width, Kirigami.Units.iconSizes.large)
            Layout.preferredHeight: Layout.preferredWidth
            Layout.alignment: Qt.AlignCenter
            // little pop when the condition changes
            onSourceChanged: pop.restart()
            SequentialAnimation {
                id: pop
                NumberAnimation { target: icon; property: "scale"; to: 0.7; duration: 120 }
                NumberAnimation { target: icon; property: "scale"; to: 1; duration: 320; easing.type: Easing.OutBack }
            }
        }
        PlasmaComponents.Label {
            visible: compact.now !== null && weather.cfg.panelTemp
            text: compact.now ? Math.round(compact.now.temperature_2m) + (weather.cfg.panelUnitLetter ? weather.tempSym : "°") : ""
            font.bold: true
            font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, Math.min(compact.height * 0.5, Kirigami.Units.gridUnit * 1.4))
            Layout.alignment: Qt.AlignCenter
        }
        PlasmaComponents.Label {
            visible: weather.cfg.showCity && weather.place !== null
            text: weather.place ? weather.place.name : ""
            font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, Math.min(compact.height * 0.4, Kirigami.Units.gridUnit))
            opacity: 0.8
            Layout.alignment: Qt.AlignCenter
        }
    }
}
