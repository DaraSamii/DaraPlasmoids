import QtQuick

// Water droplet that fills (with a moving wave) to `level` (0..1).
Canvas {
    id: c
    property real level: 0
    property real shown: 0
    property real phase: 0
    property bool run: true
    property color water: "#4aa3ff"
    width: 48; height: 60
    Behavior on shown { NumberAnimation { duration: 1400; easing.type: Easing.OutCubic } }
    onLevelChanged: shown = level
    Component.onCompleted: shown = level
    onShownChanged: requestPaint()
    onPhaseChanged: requestPaint()
    NumberAnimation on phase { running: c.run && c.visible; from: 0; to: 2 * Math.PI; duration: 2200; loops: Animation.Infinite }

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const cx = width / 2, r = width / 2 - 3, cy = height * 0.68;
        ctx.beginPath();
        ctx.moveTo(cx, 2);
        ctx.bezierCurveTo(cx + r * 0.2, height * 0.2, cx + r, height * 0.45, cx + r, cy);
        ctx.arc(cx, cy, r, 0, Math.PI, false);
        ctx.bezierCurveTo(cx - r, height * 0.45, cx - r * 0.2, height * 0.2, cx, 2);
        ctx.closePath();
        ctx.save();
        ctx.clip();
        ctx.fillStyle = Qt.alpha(water, 0.18);
        ctx.fillRect(0, 0, width, height);
        const y0 = height - 3 - shown * (height - 8);
        ctx.beginPath();
        ctx.moveTo(0, height);
        for (let x = 0; x <= width; x += 2) ctx.lineTo(x, y0 + 2.5 * Math.sin(phase + x / 6));
        ctx.lineTo(width, height);
        ctx.closePath();
        const g = ctx.createLinearGradient(0, y0, 0, height);
        g.addColorStop(0, "#7cc4ff");
        g.addColorStop(1, water);
        ctx.fillStyle = g;
        ctx.fill();
        ctx.restore();
        ctx.lineWidth = 2;
        ctx.strokeStyle = water;
        ctx.stroke();
    }
}
