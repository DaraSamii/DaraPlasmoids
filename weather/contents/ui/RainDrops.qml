import QtQuick

// Three staggered drops falling into a puddle line.
Item {
    id: r
    property bool run: true
    property color color: "#5aa0ff"
    Repeater {
        model: 3
        Rectangle {
            id: d
            required property int index
            x: 6 + index * 15; width: 8; height: 12; radius: 4; color: r.color
            SequentialAnimation on y {
                running: r.run && r.visible; loops: Animation.Infinite
                PauseAnimation { duration: d.index * 380 }
                NumberAnimation { from: -4; to: r.height - 16; duration: 1000; easing.type: Easing.InQuad }
                PauseAnimation { duration: 200 }
            }
            SequentialAnimation on opacity {
                running: r.run && r.visible; loops: Animation.Infinite
                PauseAnimation { duration: d.index * 380 }
                NumberAnimation { from: 1; to: 1; duration: 850 }
                NumberAnimation { to: 0; duration: 350 }
                PauseAnimation { duration: 0 }
            }
        }
    }
    Rectangle { anchors { bottom: parent.bottom; left: parent.left; right: parent.right } height: 3; radius: 1.5; color: r.color; opacity: 0.6 }
}
