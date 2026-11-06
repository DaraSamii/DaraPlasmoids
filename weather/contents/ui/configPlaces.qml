import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import "../code/weather.js" as W

KCM.SimpleKCM {
    property string cfg_places
    property string cfg_placesDefault
    property int cfg_placeIndex
    property int cfg_placeIndexDefault
    Kirigami.FormLayout {
        readonly property var list: W.parsePlaces(cfg_places)
        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Saved places (this widget)") }
        Repeater {
            model: parent.list
            delegate: RowLayout {
                required property var modelData
                required property int index
                QQC2.RadioButton {
                    text: W.placeLabel(modelData)
                    checked: index === cfg_placeIndex
                    onClicked: cfg_placeIndex = index
                }
                QQC2.ToolButton {
                    icon.name: "edit-delete"; enabled: parent.parent.list.length > 1
                    QQC2.ToolTip.text: i18n("Remove"); QQC2.ToolTip.visible: hovered
                    onClicked: { cfg_places = W.removePlace(cfg_places, index); cfg_placeIndex = Math.min(cfg_placeIndex, parent.parent.list.length - 1); }
                }
            }
        }
        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Add a place") }
        PlaceSearch {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 20
            onPicked: place => { const r = W.addPlace(cfg_places, place); cfg_places = r.json; cfg_placeIndex = r.index; }
        }
    }
}
