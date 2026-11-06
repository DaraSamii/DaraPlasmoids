import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import "../code/weather.js" as W

KCM.SimpleKCM {
    property string cfg_places
    property int cfg_placeIndex
    property int cfg_units
    property bool cfg_clock24
    property int cfg_refreshMin
    property bool cfg_animations
    property bool cfg_showCity
    // required by the config system; unused
    property string cfg_placesDefault
    property int cfg_placeIndexDefault
    property int cfg_unitsDefault
    property bool cfg_clock24Default
    property int cfg_refreshMinDefault
    property bool cfg_animationsDefault
    property bool cfg_showCityDefault

    readonly property var list: W.parsePlaces(cfg_places)

    Kirigami.FormLayout {
        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Places (this widget)") }
        Repeater {
            model: list
            delegate: RowLayout {
                required property var modelData
                required property int index
                Kirigami.FormData.label: index === 0 ? i18n("Saved:") : ""
                QQC2.RadioButton {
                    text: W.placeLabel(modelData)
                    checked: index === cfg_placeIndex
                    onClicked: cfg_placeIndex = index
                }
                QQC2.ToolButton {
                    icon.name: "edit-delete"; enabled: list.length > 1
                    onClicked: { cfg_places = W.removePlace(cfg_places, index); cfg_placeIndex = Math.min(cfg_placeIndex, list.length - 1); }
                }
            }
        }
        PlaceSearch {
            Kirigami.FormData.label: i18n("Add:")
            Layout.preferredWidth: Kirigami.Units.gridUnit * 18
            onPicked: place => { const r = W.addPlace(cfg_places, place); cfg_places = r.json; cfg_placeIndex = r.index; }
        }

        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Display") }
        QQC2.ComboBox {
            Kirigami.FormData.label: i18n("Units:")
            model: [i18n("Metric (°C, km/h)"), i18n("Imperial (°F, mph)")]
            currentIndex: cfg_units
            onActivated: cfg_units = currentIndex
        }
        QQC2.CheckBox { Kirigami.FormData.label: i18n("Clock:"); text: i18n("24-hour time"); checked: cfg_clock24; onToggled: cfg_clock24 = checked }
        QQC2.CheckBox { text: i18n("Show city name in the panel"); checked: cfg_showCity; onToggled: cfg_showCity = checked }
        QQC2.CheckBox { text: i18n("Animated weather scene"); checked: cfg_animations; onToggled: cfg_animations = checked }
        QQC2.SpinBox {
            Kirigami.FormData.label: i18n("Refresh every:")
            from: 5; to: 180; stepSize: 5
            value: cfg_refreshMin
            textFromValue: v => i18n("%1 min", v)
            valueFromText: t => parseInt(t)
            onValueModified: cfg_refreshMin = value
        }
    }
}
