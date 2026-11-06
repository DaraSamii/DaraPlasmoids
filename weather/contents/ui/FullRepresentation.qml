import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../code/weather.js" as W

Item {
    id: full
    required property QtObject weather
    readonly property var wx: weather.wx
    readonly property var now: wx ? wx.now : null
    readonly property string deg: "°"
    property bool adding: false

    Layout.preferredWidth: Kirigami.Units.gridUnit * 27
    Layout.preferredHeight: Kirigami.Units.gridUnit * 40
    Layout.minimumWidth: Kirigami.Units.gridUnit * 22
    Layout.minimumHeight: Kirigami.Units.gridUnit * 28

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ---------- hero ----------
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 12

            WeatherScene {
                anchors.fill: parent
                kind: full.now ? full.now.kind : "cloudy"
                isDay: full.now ? full.now.is_day === 1 : true
                clouds: full.now ? full.now.clouds : 3
                animate: Plasmoid.configuration.animations && Plasmoid.expanded
            }

            RowLayout {
                anchors { top: parent.top; left: parent.left; right: parent.right; margins: Kirigami.Units.largeSpacing }
                ColumnLayout {
                    spacing: 0
                    PlasmaComponents.Label {
                        text: weather.place ? weather.place.name : ""
                        color: "white"; font.pixelSize: Kirigami.Units.gridUnit * 1.4; font.bold: true
                    }
                    PlasmaComponents.Label {
                        text: weather.place ? [weather.place.admin1, weather.place.country].filter(Boolean).join(", ") : ""
                        color: "white"; opacity: 0.8; font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    }
                }
                Item { Layout.fillWidth: true }
                PlasmaComponents.ToolButton {
                    icon.name: "view-refresh"; icon.color: "white"
                    enabled: !weather.loading
                    opacity: weather.loading ? 0.5 : 1
                    onClicked: weather.load()
                    QQC2.ToolTip.text: weather.updated ? i18n("Updated %1", weather.updated) : i18n("Refresh")
                    QQC2.ToolTip.visible: hovered
                    RotationAnimator on rotation { running: weather.loading; from: 0; to: 360; duration: 900; loops: Animation.Infinite }
                }
                PlasmaComponents.ToolButton {
                    icon.name: "configure"; icon.color: "white"
                    onClicked: Plasmoid.internalAction("configure").trigger()
                }
            }

            RowLayout {
                anchors { bottom: parent.bottom; left: parent.left; right: parent.right; margins: Kirigami.Units.largeSpacing }
                spacing: Kirigami.Units.largeSpacing
                opacity: full.now ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 500 } }

                PlasmaComponents.Label {
                    id: bigTemp
                    property real shown: full.now ? full.now.temperature_2m : 0
                    Behavior on shown { NumberAnimation { duration: 1000; easing.type: Easing.OutCubic } }
                    text: Math.round(shown) + full.deg
                    color: "white"; font.pixelSize: Kirigami.Units.gridUnit * 4.6; font.weight: Font.Light
                }
                ColumnLayout {
                    spacing: 0
                    Layout.alignment: Qt.AlignVCenter
                    Kirigami.Icon { source: full.now ? full.now.icon : "weather-none-available"; Layout.preferredWidth: Kirigami.Units.iconSizes.medium; Layout.preferredHeight: width }
                    PlasmaComponents.Label { text: full.now ? full.now.text : ""; color: "white"; font.pixelSize: Kirigami.Units.gridUnit * 1.1; font.bold: true }
                    PlasmaComponents.Label {
                        text: full.now ? i18n("H %1°  L %2°  ·  Feels %3°", Math.round(wx.days[0].max), Math.round(wx.days[0].min), Math.round(full.now.apparent_temperature)) : ""
                        color: "white"; opacity: 0.9
                    }
                }
            }
        }

        // ---------- places ----------
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: Kirigami.Units.smallSpacing
            ListView {
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2.2
                orientation: ListView.Horizontal
                spacing: Kirigami.Units.smallSpacing
                clip: true
                model: weather.places
                delegate: PlasmaComponents.ToolButton {
                    required property var modelData
                    required property int index
                    text: modelData.name
                    checkable: true
                    checked: index === weather.placeIndex
                    onClicked: Plasmoid.configuration.placeIndex = index
                }
            }
            PlasmaComponents.ToolButton {
                icon.name: full.adding ? "dialog-close" : "list-add"
                checked: full.adding
                onClicked: { full.adding = !full.adding; if (full.adding) search.focusField(); }
                QQC2.ToolTip.text: i18n("Add a place"); QQC2.ToolTip.visible: hovered
            }
        }
        PlaceSearch {
            id: search
            visible: full.adding
            Layout.fillWidth: true
            Layout.margins: Kirigami.Units.smallSpacing
            onPicked: place => {
                const r = W.addPlace(Plasmoid.configuration.places, place);
                Plasmoid.configuration.places = r.json;
                Plasmoid.configuration.placeIndex = r.index;
                full.adding = false;
            }
        }

        // ---------- status ----------
        ColumnLayout {
            visible: !full.now
            Layout.fillWidth: true; Layout.fillHeight: true
            Item { Layout.fillHeight: true }
            QQC2.BusyIndicator { visible: weather.loading; running: visible; Layout.alignment: Qt.AlignHCenter }
            PlasmaComponents.Label { visible: weather.error !== ""; text: weather.error; Layout.alignment: Qt.AlignHCenter; wrapMode: Text.Wrap; horizontalAlignment: Text.AlignHCenter; Layout.fillWidth: true }
            PlasmaComponents.Button { visible: weather.error !== ""; text: i18n("Retry"); icon.name: "view-refresh"; onClicked: weather.load(); Layout.alignment: Qt.AlignHCenter }
            Item { Layout.fillHeight: true }
        }

        // ---------- content ----------
        PlasmaComponents.ScrollView {
            id: sv
            visible: full.now !== null
            Layout.fillWidth: true; Layout.fillHeight: true
            contentWidth: availableWidth

            ColumnLayout {
                width: sv.availableWidth
                spacing: Kirigami.Units.smallSpacing

                Card {
                    title: i18n("Next 24 hours"); order: 0
                    Layout.leftMargin: Kirigami.Units.smallSpacing; Layout.rightMargin: Kirigami.Units.smallSpacing
                    HourlyChart { Layout.fillWidth: true; hours: full.wx ? full.wx.hours : []; h24: Plasmoid.configuration.clock24 }
                }
                Card {
                    title: i18n("7-day forecast"); order: 1
                    Layout.leftMargin: Kirigami.Units.smallSpacing; Layout.rightMargin: Kirigami.Units.smallSpacing
                    Repeater {
                        model: full.wx ? full.wx.days : []
                        delegate: DayRow {
                            gmin: Math.min.apply(null, full.wx.days.map(d => d.min))
                            gmax: Math.max.apply(null, full.wx.days.map(d => d.max))
                        }
                    }
                }
                Card {
                    title: i18n("Sun"); order: 2
                    Layout.leftMargin: Kirigami.Units.smallSpacing; Layout.rightMargin: Kirigami.Units.smallSpacing
                    SunArc {
                        Layout.fillWidth: true
                        nowIso: full.now ? full.now.time : ""
                        sunrise: full.wx ? full.wx.days[0].sunrise : ""
                        sunset: full.wx ? full.wx.days[0].sunset : ""
                        h24: Plasmoid.configuration.clock24
                    }
                }
                Card {
                    title: i18n("Details"); order: 3
                    Layout.leftMargin: Kirigami.Units.smallSpacing; Layout.rightMargin: Kirigami.Units.smallSpacing
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: Kirigami.Units.smallSpacing; rowSpacing: Kirigami.Units.smallSpacing
                        readonly property bool imp: weather.imperial
                        Tile {
                            label: i18n("Wind")
                            value: full.now ? Math.round(full.now.wind_speed_10m) + " " + (parent.imp ? "mph" : "km/h") : ""
                            sub: full.now ? W.compass(full.now.wind_direction_10m) + " · " + i18n("gusts %1", Math.round(full.now.wind_gusts_10m)) : ""
                            Kirigami.Icon {
                                anchors.fill: parent; source: "go-up"
                                rotation: full.now ? full.now.wind_direction_10m + 180 : 0 // arrow points where the wind blows
                                Behavior on rotation { NumberAnimation { duration: 900; easing.type: Easing.OutBack } }
                            }
                        }
                        Tile { label: i18n("Humidity"); value: full.now ? full.now.relative_humidity_2m + "%" : ""; sub: i18n("Clouds %1%", full.now ? full.now.cloud_cover : 0) }
                        Tile { label: i18n("UV index"); value: full.now ? Math.round(full.now.uv) : ""; sub: full.now ? W.uvLabel(full.now.uv) : "" }
                        Tile {
                            label: i18n("Pressure")
                            value: full.now ? (parent.imp ? (full.now.pressure_msl * 0.02953).toFixed(2) + " inHg" : Math.round(full.now.pressure_msl) + " hPa") : ""
                        }
                        Tile {
                            label: i18n("Visibility")
                            value: full.now ? (parent.imp ? (full.now.visibility / 1609.34).toFixed(0) + " mi" : (full.now.visibility / 1000).toFixed(0) + " km") : ""
                        }
                        Tile {
                            label: i18n("Precipitation")
                            value: full.now ? full.now.precipitation + (parent.imp ? " in" : " mm") : ""
                            sub: wx ? i18n("Today %1", wx.days[0].precip + (parent.imp ? " in" : " mm")) : ""
                        }
                    }
                }
                PlasmaComponents.Label {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.bottomMargin: Kirigami.Units.smallSpacing
                    text: i18n("Weather data by <a href=\"https://open-meteo.com\">Open-Meteo.com</a>")
                    textFormat: Text.StyledText
                    opacity: 0.6; font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    onLinkActivated: link => Qt.openUrlExternally(link)
                }
            }
        }
    }
}
