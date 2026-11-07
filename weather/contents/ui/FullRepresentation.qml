import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Effects
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../code/weather.js" as W

Item {
    id: full
    required property QtObject weather
    readonly property var cfg: Plasmoid.configuration
    readonly property var wx: weather.wx
    readonly property var now: wx ? wx.now : null
    readonly property var days: wx ? wx.days.slice(0, cfg.daysCount) : []
    readonly property int bg: cfg.backgroundStyle          // 0 glass + blur, 1 glass, 2 plain theme
    readonly property real heroH: Kirigami.Units.gridUnit * 12
    readonly property real wu: [24, 27, 32][cfg.popupSize]  // popup width in grid units
    readonly property bool run: cfg.animations && weather.expanded
    readonly property string windLabel: W.UNITS.wind[cfg.windUnit][0]
    readonly property string precipLabel: W.UNITS.precip[cfg.precipUnit][0]
    readonly property bool miles: cfg.windUnit === 1
    readonly property var moonInfo: wx && weather.place ? W.moon(new Date(), weather.place.lat) : null  // re-evaluated on each data refresh
    property bool adding: false
    function openSite() { Qt.openUrlExternally(W.siteUrl(cfg.site, weather.place)); }

    Layout.preferredWidth: Kirigami.Units.gridUnit * wu
    Layout.preferredHeight: Kirigami.Units.gridUnit * wu * 1.48
    Layout.minimumWidth: Kirigami.Units.gridUnit * 22
    Layout.minimumHeight: Kirigami.Units.gridUnit * 28

    // Glass modes use a dark sky, so force light text regardless of the desktop theme.
    Kirigami.Theme.colorSet: Kirigami.Theme.Complementary
    Kirigami.Theme.inherit: bg === 2

    // plain mode: solid theme colour instead of the sky
    Rectangle { anchors.fill: parent; visible: full.bg === 2; color: Kirigami.Theme.backgroundColor }

    // ---------- glass background: sky, blurred under the content, plus a contrast scrim ----------
    WeatherScene {
        id: scene
        anchors.fill: parent
        visible: full.bg < 2
        heroH: full.heroH
        kind: full.now ? full.now.kind : "cloudy"
        isDay: full.now ? full.now.is_day === 1 : true
        clouds: full.now ? full.now.clouds : 3
        animate: full.run
        moonPhase: full.moonInfo ? full.moonInfo.phase : 0.5
        moonMirror: full.moonInfo ? full.moonInfo.mirror : false
        moonIllum: full.moonInfo ? full.moonInfo.illum : 100
    }
    ShaderEffectSource { id: sceneSrc; sourceItem: scene; live: true; visible: false }
    Item {
        id: fadeMask   // transparent over the hero (sharp sky), opaque below it (blurred)
        anchors.fill: parent; visible: false; layer.enabled: true
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: full.heroH * 0.8 / full.height; color: "transparent" }
                GradientStop { position: (full.heroH + Kirigami.Units.gridUnit * 3) / full.height; color: "black" }
                GradientStop { position: 1; color: "black" }
            }
        }
    }
    MultiEffect {
        anchors.fill: parent
        visible: full.bg === 0
        source: sceneSrc
        blurEnabled: true; blur: 1.0; blurMax: 48
        maskEnabled: true; maskSource: fadeMask
    }
    Rectangle {   // keeps text contrast (WCAG) on bright skies; stronger where cards sit
        anchors.fill: parent
        visible: full.bg < 2
        gradient: Gradient {
            GradientStop { position: full.heroH * 0.8 / full.height; color: "transparent" }
            GradientStop { position: (full.heroH + Kirigami.Units.gridUnit * 3) / full.height; color: "#44000000" }
            GradientStop { position: 1; color: "#55000000" }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ---------- hero ----------
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: full.heroH

            RowLayout {
                anchors { top: parent.top; left: parent.left; right: parent.right; margins: Kirigami.Units.largeSpacing }
                ColumnLayout {
                    spacing: 0
                    PlasmaComponents.Label {
                        text: weather.place ? weather.place.name : ""
                        color: "white"; font.pixelSize: Kirigami.Units.gridUnit * 1.7; font.bold: true
                    }
                    PlasmaComponents.Label {
                        text: weather.place ? [weather.place.admin1, weather.place.country].filter(Boolean).join(", ") : ""
                        color: "white"; font.bold: true; opacity: 0.9
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
                    icon.name: "internet-web-browser-symbolic"; icon.color: "white"
                    enabled: weather.place !== null
                    onClicked: full.openSite()
                    QQC2.ToolTip.text: i18n("Open on %1", W.siteLabel(full.cfg.site)); QQC2.ToolTip.visible: hovered
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
                    property real shown: full.now ? full.now.temperature_2m : 0
                    Behavior on shown { NumberAnimation { duration: 1000; easing.type: Easing.OutCubic } }
                    text: Math.round(shown) + "°"
                    color: "white"; font.pixelSize: Kirigami.Units.gridUnit * 4.6; font.weight: Font.Light
                }
                ColumnLayout {
                    spacing: 0
                    Layout.alignment: Qt.AlignVCenter
                    Kirigami.Icon { source: full.now ? (full.now.mono ? full.now.symbolic : full.now.icon) : "weather-none-available"; Layout.preferredWidth: Kirigami.Units.iconSizes.medium; Layout.preferredHeight: width }
                    PlasmaComponents.Label { text: full.now ? full.now.text : ""; color: "white"; font.pixelSize: Kirigami.Units.gridUnit * 1.4; font.bold: true }
                    PlasmaComponents.Label {
                        font.bold: true; font.pixelSize: Kirigami.Units.gridUnit * 1.05
                        textFormat: Text.StyledText
                        text: full.now ? i18n("<font color=\"#ffb84a\">↑</font> %1°   <font color=\"#6ec1ff\">↓</font> %2°   ·   Feels %3°", Math.round(wx.days[0].max), Math.round(wx.days[0].min), Math.round(full.now.apparent_temperature)) : ""
                        color: "white"; opacity: 0.95
                    }
                }
            }
        }

        // ---------- "what's next" summary + offline notice ----------
        PlasmaComponents.Label {
            visible: full.cfg.showSummary && full.now !== null
            Layout.fillWidth: true; Layout.margins: Kirigami.Units.largeSpacing
            text: full.now ? W.summary(wx, full.cfg.clock24, full.cfg.tempUnit === 1) : ""
            font.bold: true; font.pixelSize: Kirigami.Units.gridUnit * 1.1
            wrapMode: Text.Wrap
        }
        PlasmaComponents.Label {
            visible: full.now !== null && weather.error !== ""
            Layout.fillWidth: true; Layout.leftMargin: Kirigami.Units.largeSpacing; Layout.rightMargin: Kirigami.Units.largeSpacing
            text: i18n("Offline — showing data from %1", weather.updated)
            color: "#ffb84a"; font.bold: true
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
                delegate: Row {
                    required property var modelData
                    required property int index
                    spacing: 0
                    PlasmaComponents.ToolButton {
                        text: modelData.name
                        font.bold: true
                        checkable: true
                        checked: index === weather.placeIndex
                        onClicked: full.cfg.placeIndex = index
                    }
                    PlasmaComponents.ToolButton {   // only on the selected chip, never on the last place
                        visible: index === weather.placeIndex && weather.places.length > 1
                        icon.name: "edit-delete"
                        onClicked: {
                            full.cfg.places = W.removePlace(full.cfg.places, index);
                            full.cfg.placeIndex = Math.max(0, index - 1);
                        }
                        QQC2.ToolTip.text: i18n("Remove %1", modelData.name); QQC2.ToolTip.visible: hovered
                    }
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
                const r = W.addPlace(full.cfg.places, place);
                full.cfg.places = r.json;
                full.cfg.placeIndex = r.index;
                full.adding = false;
            }
        }

        // ---------- status ----------
        ColumnLayout {
            visible: !full.now
            Layout.fillWidth: true; Layout.fillHeight: true
            Item { Layout.fillHeight: true }
            QQC2.BusyIndicator { visible: weather.loading; running: visible; Layout.alignment: Qt.AlignHCenter }
            PlasmaComponents.Label { visible: weather.place === null; text: i18n("No place selected — click + to add a city."); Layout.alignment: Qt.AlignHCenter; font.bold: true }
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

            // The page grows as data/cards appear and the scroll area drifted down with it.
            // Hold the view at the top until the user scrolls themselves.
            property bool touched: false
            function toTop() { touched = false; if (contentItem) contentItem.contentY = 0; }
            Connections {
                target: sv.contentItem
                function onContentHeightChanged() { if (!sv.touched) sv.contentItem.contentY = 0; }
                function onMovingChanged() { if (sv.contentItem.moving && sv.contentItem.contentY > 0) sv.touched = true; }
            }
            Connections { target: full.weather; function onExpandedChanged() { if (full.weather.expanded) sv.toTop() } }
            Connections { target: full; function onNowChanged() { sv.toTop() } }

            ColumnLayout {
                width: sv.availableWidth
                spacing: Kirigami.Units.smallSpacing

                Card {
                    visible: full.cfg.showHourly
                    title: i18n("Next %1 hours", full.wx ? full.wx.hours.length : full.cfg.hoursCount); order: 0
                    Layout.leftMargin: Kirigami.Units.smallSpacing; Layout.rightMargin: Kirigami.Units.smallSpacing
                    RowLayout {
                        Layout.fillWidth: true
                        PlasmaComponents.Label { text: i18n("Blue bars: chance of rain"); opacity: 0.75; font.pixelSize: Kirigami.Theme.smallFont.pixelSize; Layout.fillWidth: true }
                        Repeater {
                            model: [-1, 1]
                            PlasmaComponents.ToolButton {
                                required property int modelData
                                enabled: modelData < 0 ? chart.contentX > 1 : chart.contentX < hourlyBox.maxX - 1
                                opacity: enabled ? 1 : 0.35
                                Behavior on opacity { NumberAnimation { duration: 200 } }
                                Layout.preferredWidth: Kirigami.Units.gridUnit * 1.9; Layout.preferredHeight: Layout.preferredWidth
                                icon.name: modelData < 0 ? "go-previous-symbolic" : "go-next-symbolic"
                                focusPolicy: Qt.NoFocus
                                background: Rectangle { radius: width / 2; color: Qt.rgba(1, 1, 1, parent.hovered ? 0.22 : 0.12); border.color: Qt.rgba(1, 1, 1, 0.3) }
                                onClicked: hourlyBox.slide(modelData)
                                QQC2.ToolTip.text: modelData < 0 ? i18n("Earlier hours") : i18n("Later hours"); QQC2.ToolTip.visible: hovered
                            }
                        }
                    }
                    Item {
                        id: hourlyBox
                        Layout.fillWidth: true
                        Layout.preferredHeight: chart.implicitHeight
                        readonly property real maxX: Math.max(0, chart.contentWidth - chart.width)
                        function slide(dir) {
                            slideAnim.stop();
                            slideAnim.from = chart.contentX;
                            slideAnim.to = Math.max(0, Math.min(maxX, chart.contentX + dir * chart.width * 0.7));
                            slideAnim.start();
                        }
                        NumberAnimation { id: slideAnim; target: chart; property: "contentX"; duration: 380; easing.type: Easing.OutCubic }
                        HourlyChart { id: chart; anchors.fill: parent; hours: full.wx ? full.wx.hours : []; h24: full.cfg.clock24 }
                    }
                }
                Card {
                    visible: full.cfg.showDaily
                    title: i18n("%1-day forecast", full.days.length); order: 1
                    Layout.leftMargin: Kirigami.Units.smallSpacing; Layout.rightMargin: Kirigami.Units.smallSpacing
                    Repeater {
                        model: full.days
                        delegate: DayRow {
                            gmin: Math.min.apply(null, full.days.map(d => d.min))
                            gmax: Math.max.apply(null, full.days.map(d => d.max))
                        }
                    }
                }
                Card {
                    visible: full.cfg.showSun
                    title: i18n("Sun"); order: 2
                    Layout.leftMargin: Kirigami.Units.smallSpacing; Layout.rightMargin: Kirigami.Units.smallSpacing
                    SunArc {
                        Layout.fillWidth: true
                        nowIso: full.now ? full.now.time : ""
                        sunrise: full.wx ? full.wx.days[0].sunrise : ""
                        sunset: full.wx ? full.wx.days[0].sunset : ""
                        h24: full.cfg.clock24
                    }
                }
                Card {
                    visible: full.cfg.showMoon && full.moonInfo !== null
                    title: i18n("Moon"); order: 3
                    Layout.leftMargin: Kirigami.Units.smallSpacing; Layout.rightMargin: Kirigami.Units.smallSpacing
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.largeSpacing
                        MoonDisc {
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 5; Layout.preferredHeight: Layout.preferredWidth
                            phase: full.moonInfo ? full.moonInfo.phase : 0.5
                            mirror: full.moonInfo ? full.moonInfo.mirror : false
                        }
                        ColumnLayout {
                            spacing: 0
                            PlasmaComponents.Label { text: full.moonInfo ? full.moonInfo.name : ""; font.bold: true; font.pixelSize: Kirigami.Units.gridUnit * 1.6 }
                            PlasmaComponents.Label { text: full.moonInfo ? i18n("%1% illuminated", full.moonInfo.illum) : ""; font.bold: true; color: "#cfd9ff"; font.pixelSize: Kirigami.Units.gridUnit * 1.1 }
                            PlasmaComponents.Label { text: full.moonInfo ? i18n("Day %1 of 29.5", Math.floor(full.moonInfo.age) + 1) : ""; opacity: 0.8; font.weight: Font.DemiBold }
                        }
                    }
                    Item {   // lunar cycle: marker sweeps from new → full → new
                        id: cycle
                        Layout.fillWidth: true
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 1.2
                        Rectangle {
                            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                            height: 8; radius: 4
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0; color: "#2b3550" }
                                GradientStop { position: 0.5; color: "#eef1fa" }
                                GradientStop { position: 1; color: "#2b3550" }
                            }
                            border.color: Qt.rgba(1, 1, 1, 0.25)
                        }
                        Rectangle {
                            property real f: full.moonInfo ? full.moonInfo.phase : 0
                            Behavior on f { NumberAnimation { duration: 1400; easing.type: Easing.OutBack } }
                            x: f * (cycle.width - width); anchors.verticalCenter: parent.verticalCenter
                            width: 16; height: 16; radius: 8; color: "#ffd75a"; border.color: "white"; border.width: 2
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Repeater {
                            model: [i18n("New"), i18n("Full"), i18n("New")]
                            PlasmaComponents.Label {
                                required property var modelData
                                required property int index
                                text: modelData; opacity: 0.7; font.bold: true; font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                Layout.fillWidth: true
                                horizontalAlignment: [Text.AlignLeft, Text.AlignHCenter, Text.AlignRight][index]
                            }
                        }
                    }
                    GridLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: Kirigami.Units.smallSpacing
                        columns: 2
                        columnSpacing: Kirigami.Units.largeSpacing * 2
                        Repeater {
                            model: full.moonInfo ? [[i18n("Next full moon"), full.moonInfo.nextFull, "#eef1fa"], [i18n("Next new moon"), full.moonInfo.nextNew, "#8fa0c8"]] : []
                            Rectangle {
                                required property var modelData
                                Layout.fillWidth: true; Layout.preferredWidth: 1   // equal-width tiles
                                implicitHeight: dateCol.implicitHeight + Kirigami.Units.largeSpacing * 2
                                radius: Kirigami.Units.largeSpacing
                                color: Qt.alpha(modelData[2], 0.12)
                                border.color: Qt.alpha(modelData[2], 0.4)
                                ColumnLayout {
                                    id: dateCol
                                    anchors { fill: parent; margins: Kirigami.Units.largeSpacing }
                                    spacing: 0
                                    PlasmaComponents.Label { text: modelData[0]; font.bold: true; opacity: 0.85 }
                                    PlasmaComponents.Label { text: modelData[1]; font.bold: true; font.pixelSize: Kirigami.Units.gridUnit * 1.5 }
                                }
                            }
                        }
                    }
                }
                Card {
                    visible: full.cfg.showWind || full.cfg.showHumidity || full.cfg.showUV || full.cfg.showPressure
                             || full.cfg.showVisibility || full.cfg.showPrecip || full.cfg.showClouds
                    title: i18n("Details"); order: 4
                    Layout.leftMargin: Kirigami.Units.smallSpacing; Layout.rightMargin: Kirigami.Units.smallSpacing
                    WindCard {
                        visible: full.cfg.showWind
                        run: full.run
                        speed: full.now ? full.now.wind_speed_10m : 0
                        gust: full.now && full.now.wind_gusts_10m !== null ? full.now.wind_gusts_10m : NaN
                        dir: full.now ? full.now.wind_direction_10m : 0
                        unit: full.windLabel
                        toKmh: W.UNITS.wind[full.cfg.windUnit][2]
                    }
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: Kirigami.Units.smallSpacing; rowSpacing: Kirigami.Units.smallSpacing
                        Tile {
                            visible: full.cfg.showHumidity
                            label: i18n("Humidity"); accent: "#4aa3ff"
                            value: full.now ? full.now.relative_humidity_2m + "%" : ""
                            sub: full.now ? (full.now.relative_humidity_2m < 30 ? i18n("Dry") : full.now.relative_humidity_2m < 60 ? i18n("Comfortable") : full.now.relative_humidity_2m < 80 ? i18n("Humid") : i18n("Very humid")) : ""
                            DropFill { anchors.centerIn: parent; level: full.now ? full.now.relative_humidity_2m / 100 : 0; run: full.run }
                        }
                        Tile {
                            visible: full.cfg.showUV
                            label: i18n("UV index"); accent: "#ff9a3d"
                            value: full.now ? W.num(full.now.uv) : ""
                            sub: full.now && full.now.uv !== null ? W.uvLabel(full.now.uv) : i18n("Not provided")
                            gauge: full.now && full.now.uv !== null ? Math.min(1, full.now.uv / 11) : -1
                            gaugeColors: ["#3fbf6f", "#b5d94a", "#ffd23d", "#ff9a3d", "#ff4d4d", "#a35bff"]
                        }
                        Tile {
                            visible: full.cfg.showPressure
                            label: i18n("Pressure"); accent: "#b48cff"
                            value: full.now ? W.pressureText(full.now.pressure_msl, full.cfg.pressureUnit) : ""
                            sub: full.now ? W.UNITS.pressure[full.cfg.pressureUnit][0] + " · " + (full.now.pressure_msl < 1009 ? i18n("Low") : full.now.pressure_msl > 1022 ? i18n("High") : i18n("Normal")) : ""
                            gauge: full.now ? Math.max(0, Math.min(1, (full.now.pressure_msl - 980) / 60)) : -1
                            gaugeColors: ["#5aa0ff", "#8ab4ff", "#b48cff", "#e08cff", "#ff8fb1"]
                        }
                        Tile {
                            visible: full.cfg.showVisibility
                            label: i18n("Visibility"); accent: "#4fd18b"
                            value: full.now && full.now.visibility !== null ? (full.miles ? (full.now.visibility / 1609.34).toFixed(0) : (full.now.visibility / 1000).toFixed(0)) : "–"
                            sub: full.miles ? "mi" : "km"
                            gauge: full.now && full.now.visibility !== null ? Math.min(1, full.now.visibility / 20000) : -1
                            gaugeColors: ["#ff6b6b", "#ffa94d", "#ffd23d", "#a4d86b", "#4fd18b"]
                        }
                        Tile {
                            visible: full.cfg.showPrecip
                            label: i18n("Rain & snow"); accent: "#5aa0ff"
                            value: full.now ? full.now.rainToday + " " + full.precipLabel : ""
                            sub: full.now ? i18n("Today so far · last 24 h %1 %2", full.now.rain24h, full.precipLabel) : ""
                            RainDrops { anchors.fill: parent; run: full.run }
                        }
                        Tile {
                            visible: full.cfg.showClouds
                            label: i18n("Clouds"); accent: "#9fb3c8"
                            value: full.now ? full.now.cloud_cover + "%" : ""
                            sub: full.now ? (full.now.cloud_cover < 20 ? i18n("Clear") : full.now.cloud_cover < 60 ? i18n("Partly cloudy") : i18n("Overcast")) : ""
                            gauge: full.now ? full.now.cloud_cover / 100 : -1
                            gaugeColors: ["#ffd23d", "#d9d9a8", "#b9c6d3", "#8fa3b8", "#6b7f95"]
                        }
                    }
                }
                PlasmaComponents.Button {
                    Layout.alignment: Qt.AlignHCenter
                    icon.name: "internet-web-browser-symbolic"
                    focusPolicy: Qt.NoFocus
                    text: i18n("Open full forecast on %1", W.siteLabel(full.cfg.site))
                    font.bold: true
                    onClicked: full.openSite()
                }
                PlasmaComponents.Label {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.bottomMargin: Kirigami.Units.smallSpacing
                    text: i18n("Data: <a href=\"https://open-meteo.com\">Open-Meteo.com</a> · model: %1", W.modelLabel(full.cfg.model))
                    textFormat: Text.StyledText
                    opacity: 0.8; font.bold: true; font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    onLinkActivated: link => Qt.openUrlExternally(link)
                }
            }
        }
    }
}
