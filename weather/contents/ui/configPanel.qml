import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import "../code/weather.js" as W

KCM.SimpleKCM {
    property bool cfg_panelIcon
    property bool cfg_panelIconDefault
    property bool cfg_panelTemp
    property bool cfg_panelTempDefault
    property bool cfg_showCity
    property bool cfg_showCityDefault
    property bool cfg_panelUnitLetter
    property bool cfg_panelUnitLetterDefault
    Kirigami.FormLayout {
        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("What the panel shows") }
        QQC2.CheckBox { Kirigami.FormData.label: i18n("Show:"); text: i18n("Weather icon"); checked: cfg_panelIcon; onToggled: cfg_panelIcon = checked }
        QQC2.CheckBox { text: i18n("Temperature"); checked: cfg_panelTemp; onToggled: cfg_panelTemp = checked }
        QQC2.CheckBox { text: i18n("City name (useful with several widgets)"); checked: cfg_showCity; onToggled: cfg_showCity = checked }
        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Format") }
        QQC2.CheckBox { text: i18n("Add the unit letter (e.g. 12°C instead of 12°)"); checked: cfg_panelUnitLetter; onToggled: cfg_panelUnitLetter = checked }
        QQC2.Label { text: i18n("The tooltip always shows city, condition and high/low."); opacity: 0.7 }
    }
}
