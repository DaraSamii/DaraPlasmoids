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
    readonly property bool glass: Plasmoid.configuration.backgroundStyle < 2
    readonly property real a: Plasmoid.configuration.glassOpacity / 100
    radius: Kirigami.Units.largeSpacing * 1.5
    readonly property color fg: Kirigami.Theme.textColor
    color: glass ? Qt.rgba(1, 1, 1, a) : Qt.rgba(fg.r, fg.g, fg.b, 0.07)
    border.color: glass ? Qt.rgba(1, 1, 1, 0.25) : Qt.rgba(fg.r, fg.g, fg.b, 0.12)
    border.width: 1

    Rectangle {   // glass sheen: bright top edge fading out
        visible: card.glass
        anchors.fill: parent; radius: card.radius
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.16) }
            GradientStop { position: 0.45; color: Qt.rgba(1, 1, 1, 0) }
        }
    }

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
    onVisibleChanged: if (visible) replay() // popup opened

    ColumnLayout {
        id: col
        anchors { fill: parent; margins: Kirigami.Units.largeSpacing }
        spacing: Kirigami.Units.smallSpacing
        PlasmaComponents.Label {
            text: card.title.toUpperCase()
            font.pixelSize: Kirigami.Units.gridUnit * 0.95
            font.letterSpacing: 1.5
            font.bold: true
            color: Qt.lighter(Kirigami.Theme.highlightColor, 1.6)
        }
        ColumnLayout { id: inner; Layout.fillWidth: true; spacing: Kirigami.Units.smallSpacing }
    }
}
