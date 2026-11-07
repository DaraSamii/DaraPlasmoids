import QtQuick
import org.kde.kirigami as Kirigami

// One launcher entry. Deliberately light (no layouts, no per-tile animations or tooltip objects):
// the launcher can show hundreds of these and must scroll without a hitch.
Item {
    id: tile
    required property var ui          // the LauncherWindow (style + helpers)
    property string label
    property string subtitle
    property var icon
    property int iconSize: 48
    property bool listMode: false
    property bool current: false
    signal activated()
    signal contextRequested(real x, real y)
    readonly property bool hot: area.containsMouse || current

    Rectangle {
        visible: tile.hot
        anchors.fill: parent
        anchors.margins: ui.gap / 2
        radius: ui.radius
        color: Qt.alpha(ui.accent, area.pressed ? 0.4 : 0.26)
        border.width: tile.current ? 2 : 0
        border.color: ui.accent
    }
    Kirigami.Icon {
        source: tile.icon
        width: tile.iconSize
        height: tile.iconSize
        x: tile.listMode ? 12 : (tile.width - width) / 2
        y: tile.listMode ? (tile.height - height) / 2 : 8
    }
    Text {
        id: name
        text: tile.label
        font: ui.f(1)
        color: ui.text
        x: tile.listMode ? tile.iconSize + 26 : 6
        width: tile.listMode ? tile.width - x - 10 : tile.width - 12
        y: tile.listMode ? (tile.subtitle ? tile.height / 2 - implicitHeight : (tile.height - implicitHeight) / 2) : tile.iconSize + 12
        wrapMode: tile.listMode ? Text.NoWrap : Text.WrapAtWordBoundaryOrAnywhere   // names wrap, they are never cut
        elide: tile.listMode ? Text.ElideRight : Text.ElideNone
        horizontalAlignment: tile.listMode ? Text.AlignLeft : Text.AlignHCenter
    }
    Text {
        visible: tile.listMode && tile.subtitle.length > 0
        text: tile.subtitle
        font: ui.f(0.8)
        color: ui.text
        opacity: 0.6
        x: name.x
        y: tile.height / 2 + 1
        width: name.width
        elide: Text.ElideRight
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => mouse.button === Qt.RightButton ? tile.contextRequested(mouse.x, mouse.y) : tile.activated()
        onPressAndHold: mouse => tile.contextRequested(mouse.x, mouse.y)
        onContainsMouseChanged: ui.hoverTip(containsMouse ? tile : null, tile.listMode ? "" : tile.subtitle)
    }
    Accessible.name: tile.label
    Accessible.description: tile.subtitle
    Accessible.role: Accessible.Button
}
