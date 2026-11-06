import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import "../code/weather.js" as W

KCM.SimpleKCM {
    property int cfg_tempUnit
    property int cfg_tempUnitDefault
    property int cfg_windUnit
    property int cfg_windUnitDefault
    property int cfg_pressureUnit
    property int cfg_pressureUnitDefault
    property int cfg_precipUnit
    property int cfg_precipUnitDefault
    property bool cfg_clock24
    property bool cfg_clock24Default
    property int cfg_refreshMin
    property int cfg_refreshMinDefault
    Kirigami.FormLayout {
        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Measurements") }
        QQC2.ComboBox {
            Kirigami.FormData.label: i18n("Temperature:")
            model: [i18n("Celsius (°C)"), i18n("Fahrenheit (°F)")]
            currentIndex: cfg_tempUnit
            onActivated: cfg_tempUnit = currentIndex
        }
        QQC2.ComboBox {
            Kirigami.FormData.label: i18n("Wind speed:")
            model: [i18n("km/h"), i18n("mph"), i18n("m/s"), i18n("knots")]
            currentIndex: cfg_windUnit
            onActivated: cfg_windUnit = currentIndex
        }
        QQC2.ComboBox {
            Kirigami.FormData.label: i18n("Pressure:")
            model: [i18n("hPa"), i18n("inHg"), i18n("mmHg")]
            currentIndex: cfg_pressureUnit
            onActivated: cfg_pressureUnit = currentIndex
        }
        QQC2.ComboBox {
            Kirigami.FormData.label: i18n("Precipitation:")
            model: [i18n("Millimetres"), i18n("Inches")]
            currentIndex: cfg_precipUnit
            onActivated: cfg_precipUnit = currentIndex
        }
        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Time and updates") }
        QQC2.ComboBox {
            Kirigami.FormData.label: i18n("Clock:")
            readonly property var values: [0,1]
            model: [i18n("12-hour"), i18n("24-hour")]
            currentIndex: Math.max(0, values.indexOf(cfg_clock24 ? 1 : 0))
            onActivated: cfg_clock24 = !!values[currentIndex]
        }
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
