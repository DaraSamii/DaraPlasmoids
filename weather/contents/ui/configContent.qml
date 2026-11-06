import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import "../code/weather.js" as W

KCM.SimpleKCM {
    property bool cfg_showSummary
    property bool cfg_showSummaryDefault
    property bool cfg_showHourly
    property bool cfg_showHourlyDefault
    property int cfg_hoursCount
    property int cfg_hoursCountDefault
    property bool cfg_showDaily
    property bool cfg_showDailyDefault
    property int cfg_daysCount
    property int cfg_daysCountDefault
    property bool cfg_showSun
    property bool cfg_showSunDefault
    property bool cfg_showMoon
    property bool cfg_showMoonDefault
    property bool cfg_showWind
    property bool cfg_showWindDefault
    property bool cfg_showHumidity
    property bool cfg_showHumidityDefault
    property bool cfg_showUV
    property bool cfg_showUVDefault
    property bool cfg_showPressure
    property bool cfg_showPressureDefault
    property bool cfg_showVisibility
    property bool cfg_showVisibilityDefault
    property bool cfg_showPrecip
    property bool cfg_showPrecipDefault
    property bool cfg_showClouds
    property bool cfg_showCloudsDefault
    Kirigami.FormLayout {
        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Overview") }
        QQC2.CheckBox { Kirigami.FormData.label: i18n("Show:"); text: i18n("Plain-language summary (e.g. 'Rain expected around 3 p.m.')"); checked: cfg_showSummary; onToggled: cfg_showSummary = checked }
        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Forecasts") }
        QQC2.CheckBox { Kirigami.FormData.label: i18n("Show:"); text: i18n("Hourly forecast"); checked: cfg_showHourly; onToggled: cfg_showHourly = checked }
        QQC2.ComboBox {
            Kirigami.FormData.label: i18n("Hours to show:")
            readonly property var values: [12,24,48]
            model: [i18n("12 hours"), i18n("24 hours"), i18n("48 hours")]
            currentIndex: Math.max(0, values.indexOf(cfg_hoursCount))
            onActivated: cfg_hoursCount = values[currentIndex]
        }
        QQC2.CheckBox { text: i18n("Daily forecast"); checked: cfg_showDaily; onToggled: cfg_showDaily = checked }
        QQC2.SpinBox { Kirigami.FormData.label: i18n("Days to show:"); from: 3; to: 7; value: cfg_daysCount; onValueModified: cfg_daysCount = value }
        QQC2.CheckBox { text: i18n("Sunrise and sunset"); checked: cfg_showSun; onToggled: cfg_showSun = checked }
        QQC2.CheckBox { text: i18n("Moon phase"); checked: cfg_showMoon; onToggled: cfg_showMoon = checked }
        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Detail cards") }
        QQC2.CheckBox { Kirigami.FormData.label: i18n("Show:"); text: i18n("Wind"); checked: cfg_showWind; onToggled: cfg_showWind = checked }
        QQC2.CheckBox { text: i18n("Humidity"); checked: cfg_showHumidity; onToggled: cfg_showHumidity = checked }
        QQC2.CheckBox { text: i18n("UV index"); checked: cfg_showUV; onToggled: cfg_showUV = checked }
        QQC2.CheckBox { text: i18n("Pressure"); checked: cfg_showPressure; onToggled: cfg_showPressure = checked }
        QQC2.CheckBox { text: i18n("Visibility"); checked: cfg_showVisibility; onToggled: cfg_showVisibility = checked }
        QQC2.CheckBox { text: i18n("Rain & snow"); checked: cfg_showPrecip; onToggled: cfg_showPrecip = checked }
        QQC2.CheckBox { text: i18n("Clouds"); checked: cfg_showClouds; onToggled: cfg_showClouds = checked }
    }
}
