import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

// Rounded section with a title; slides/fades in (staggered by `order`) each time the popup opens.
Rectangle {
    id: card
    property string title
    property int order: 0
    default property alias content: inner.data

    Layout.fillWidth: true
    implicitHeight: col.implicitHeight + Kirigami.Units.largeSpacing * 2
    radius: Kirigami.Units.largeSpacing
    color: Qt.alpha(Kirigami.Theme.textColor, 0.06)
    border.color: Qt.alpha(Kirigami.Theme.textColor, 0.08)

    opacity: 0
    transform: Translate { id: slide; y: 24 }

    ParallelAnimation {
        id: intro
        PauseAnimation { duration: 0 }
        SequentialAnimation {
            PauseAnimation { duration: 60 + card.order * 90 }
            ParallelAnimation {
                NumberAnimation { target: card; property: "opacity"; to: 1; duration: 380 }
                NumberAnimation { target: slide; property: "y"; to: 0; duration: 480; easing.type: Easing.OutCubic }
            }
        }
    }
    function replay() { opacity = 0; slide.y = 24; intro.restart(); }
    Component.onCompleted: replay()
    Connections {
        target: Plasmoid
        function onExpandedChanged() { if (Plasmoid.expanded) card.replay(); }
    }

    ColumnLayout {
        id: col
        anchors { fill: parent; margins: Kirigami.Units.largeSpacing }
        spacing: Kirigami.Units.smallSpacing
        PlasmaComponents.Label {
            text: card.title.toUpperCase()
            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
            font.letterSpacing: 1
            font.bold: true
            opacity: 0.6
        }
        ColumnLayout { id: inner; Layout.fillWidth: true; spacing: Kirigami.Units.smallSpacing }
    }
}
