import QtQuick
import org.kde.kirigami as Kirigami

// Panel button: shows the chosen icon, glows on hover, stays lit while the launcher is open.
MouseArea {
    id: area
    required property var launcher
    implicitWidth: Kirigami.Units.iconSizes.smallMedium
    implicitHeight: Kirigami.Units.iconSizes.smallMedium
    hoverEnabled: true
    activeFocusOnTab: true
    Accessible.name: i18n("Applications")
    Accessible.role: Accessible.Button
    onClicked: launcher.toggle()
    Keys.onSpacePressed: launcher.toggle()
    Keys.onReturnPressed: launcher.toggle()

    Rectangle {
        anchors.fill: parent
        anchors.margins: -2
        radius: Math.min(width, height) / 4
        color: Kirigami.Theme.highlightColor
        opacity: area.launcher.open ? 0.35 : area.containsMouse ? 0.18 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }
    }
    Kirigami.Icon {
        anchors.fill: parent
        source: area.launcher.cfg.icon
        active: area.containsMouse
        scale: area.pressed ? 0.88 : area.containsMouse ? 1.08 : 1
        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    }
}
