import QtQuick
import org.kde.kirigami as Kirigami

// Animated sky: gradient + sun/moon, stars, drifting clouds, rain, snow, fog, lightning. Pure QML, no shaders.
Item {
    id: s
    property string kind: "clear"   // clear | cloudy | rain | snow | storm | fog
    property bool isDay: true
    property int clouds: 0          // 0..5
    property bool animate: true
    property real moonPhase: 0.5
    property bool moonMirror: false
    property int moonIllum: 100
    property real heroH: height      // sky elements live in the top part; rain/snow fall through everything

    readonly property bool run: animate && visible && Kirigami.Units.longDuration > 0
    readonly property bool sunVisible: kind === "clear" || (kind === "cloudy" && clouds < 5)
    readonly property var palette: ({
        clear:  isDay ? ["#1f6fc4", "#5db0ea"] : ["#0b1530", "#27406b"],
        cloudy: isDay ? ["#4d6a88", "#8fa8bd"] : ["#1a2233", "#3a4659"],
        rain:   isDay ? ["#34475c", "#63788c"] : ["#141b27", "#2f3b4c"],
        snow:   isDay ? ["#74869a", "#b9c8d6"] : ["#2b3647", "#566478"],
        storm:  isDay ? ["#232c3a", "#475366"] : ["#0d1119", "#2a3240"],
        fog:    isDay ? ["#6a7884", "#97a5b0"] : ["#262e38", "#4a5560"]
    })[kind]
    clip: true

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: s.palette[0]; Behavior on color { ColorAnimation { duration: 900 } } }
            GradientStop { position: 1; color: s.palette[1]; Behavior on color { ColorAnimation { duration: 900 } } }
        }
    }

    // stars
    Repeater {
        model: !s.isDay && s.sunVisible ? 28 : 0
        Rectangle {
            required property int index
            x: ((index * 7919) % 97) / 97 * s.width
            y: ((index * 104729) % 89) / 89 * 0.8 * s.heroH
            width: 1 + index % 3; height: width; radius: width / 2
            color: "white"
            opacity: 0.3
            SequentialAnimation on opacity {
                running: s.run; loops: Animation.Infinite
                PauseAnimation { duration: (index * 131) % 1500 }
                NumberAnimation { to: 1; duration: 900 + (index % 4) * 300; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.2; duration: 900 + (index % 3) * 300; easing.type: Easing.InOutSine }
            }
        }
    }

    // sun / moon
    Item {
        id: orb
        x: s.width * 0.6; y: s.heroH * 0.16
        width: 56; height: 56
        opacity: s.sunVisible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 700 } }
        Rectangle {   // glow
            anchors.centerIn: parent
            width: 110; height: 110; radius: 55
            color: s.isDay ? "#ffe9a0" : "#cfd9ff"
            opacity: s.isDay ? 0.18 : 0.04 + 0.14 * s.moonIllum / 100
            SequentialAnimation on scale {
                running: s.run && orb.visible; loops: Animation.Infinite
                NumberAnimation { to: 1.18; duration: 2600; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.92; duration: 2600; easing.type: Easing.InOutSine }
            }
        }
        Item {        // rays
            anchors.fill: parent
            visible: s.isDay
            RotationAnimation on rotation { running: s.run && orb.visible && s.isDay; from: 0; to: 360; duration: 60000; loops: Animation.Infinite }
            Repeater {
                model: 12
                Rectangle {
                    required property int index
                    width: 3; height: 14; radius: 1.5
                    color: "#ffe28a"; opacity: 0.55
                    x: orb.width / 2 - width / 2; y: -16
                    transform: Rotation { origin.x: 1.5; origin.y: 44; angle: index * 30 }
                }
            }
        }
        Rectangle { anchors.fill: parent; radius: width / 2; color: "#ffd75a"; visible: s.isDay }
        MoonDisc { anchors.fill: parent; visible: !s.isDay; phase: s.moonPhase; mirror: s.moonMirror }
    }

    // clouds
    Repeater {
        model: s.clouds
        Item {
            id: cloud
            required property int index
            readonly property real sz: 0.8 + (index % 3) * 0.3
            y: s.heroH * (0.05 + ((index * 29) % 55) / 100)
            width: 120 * sz; height: 44 * sz
            opacity: s.kind === "clear" ? 0.5 : (s.kind === "cloudy" ? 0.8 : 0.55)
            Repeater {
                model: [[0, 14, 70, 30], [26, 0, 56, 44], [62, 12, 58, 30]]
                Rectangle {
                    required property var modelData
                    x: modelData[0] * cloud.sz; y: modelData[1] * cloud.sz
                    width: modelData[2] * cloud.sz; height: modelData[3] * cloud.sz
                    radius: height / 2
                    color: s.isDay ? (s.kind === "storm" || s.kind === "rain" ? "#aab6c3" : "white") : "#7d8aa0"
                }
            }
            SequentialAnimation on x {
                running: s.run; loops: Animation.Infinite
                NumberAnimation { from: -cloud.width - (cloud.index * 90) % 200; to: s.width; duration: 45000 + cloud.index * 13000 }
            }
        }
    }

    // fog bands
    Repeater {
        model: s.kind === "fog" ? 4 : 0
        Rectangle {
            required property int index
            y: s.heroH * (0.25 + index * 0.17); height: 26; radius: 13
            width: s.width * 1.4; color: "white"; opacity: 0.18
            SequentialAnimation on x {
                running: s.run; loops: Animation.Infinite
                NumberAnimation { to: -s.width * 0.4; duration: 9000 + index * 2500; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0; duration: 9000 + index * 2500; easing.type: Easing.InOutSine }
            }
        }
    }

    // rain
    Repeater {
        model: s.kind === "rain" || s.kind === "storm" ? 50 : 0
        Rectangle {
            id: drop
            required property int index
            x: ((index * 37) % 100) / 100 * s.width
            width: 1.5; height: 12 + index % 8; radius: 1
            color: "#d4e8ff"; opacity: 0.55; rotation: 10
            SequentialAnimation on y {
                running: s.run; loops: Animation.Infinite
                PauseAnimation { duration: (drop.index * 97) % 900 }
                NumberAnimation { from: -20; to: s.height; duration: 550 + (drop.index % 5) * 110 }
            }
        }
    }

    // snow
    Repeater {
        model: s.kind === "snow" ? 40 : 0
        Rectangle {
            id: flake
            required property int index
            property real baseX: ((index * 61) % 100) / 100 * s.width
            width: 3 + index % 4; height: width; radius: width / 2
            color: "white"; opacity: 0.85
            x: baseX
            SequentialAnimation on y {
                running: s.run; loops: Animation.Infinite
                PauseAnimation { duration: (flake.index * 173) % 3000 }
                NumberAnimation { from: -10; to: s.height; duration: 4500 + (flake.index % 5) * 900 }
            }
            SequentialAnimation on x {
                running: s.run; loops: Animation.Infinite
                NumberAnimation { to: flake.baseX + 16; duration: 1400 + (flake.index % 3) * 400; easing.type: Easing.InOutSine }
                NumberAnimation { to: flake.baseX - 16; duration: 1400 + (flake.index % 3) * 400; easing.type: Easing.InOutSine }
            }
        }
    }

    // lightning flash
    Rectangle {
        anchors.fill: parent; color: "white"; opacity: 0
        visible: s.kind === "storm"
        SequentialAnimation on opacity {
            running: s.run && s.kind === "storm"; loops: Animation.Infinite
            PauseAnimation { duration: 3800 }
            NumberAnimation { to: 0.7; duration: 50 }
            NumberAnimation { to: 0.05; duration: 90 }
            NumberAnimation { to: 0.55; duration: 40 }
            NumberAnimation { to: 0; duration: 500 }
            PauseAnimation { duration: 2500 }
        }
    }

    // keep text legible over bright skies
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: "#22000000" }
            GradientStop { position: 1; color: "#44000000" }
        }
    }
}
