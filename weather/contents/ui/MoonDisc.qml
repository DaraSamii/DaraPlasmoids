import QtQuick

// Moon drawn at a given phase: lit part = right half + terminator ellipse (mirrored when waning / southern hemisphere).
Canvas {
    id: m
    property real phase: 0.5          // 0 new … 0.5 full … 1 new
    property bool mirror: false
    property color lit: "#eef1fa"
    property color dark: "#2b3550"
    property real shown: phase
    Behavior on shown { NumberAnimation { duration: 1400; easing.type: Easing.OutCubic } }
    onShownChanged: requestPaint()
    onLitChanged: requestPaint()
    onDarkChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const r = Math.min(width, height) / 2 - 1.5, cx = width / 2, cy = height / 2;
        ctx.fillStyle = dark;
        ctx.beginPath(); ctx.arc(cx, cy, r, 0, 2 * Math.PI); ctx.fill();
        const p = shown <= 0.5 ? shown : 1 - shown;
        ctx.save();
        ctx.translate(cx, cy);
        if ((shown > 0.5) !== mirror) ctx.scale(-1, 1);
        ctx.beginPath();
        ctx.arc(0, 0, r, -Math.PI / 2, Math.PI / 2, false);          // lit limb (right)
        ctx.save();
        ctx.scale(Math.cos(2 * Math.PI * p), 1);                     // terminator: flat at quarter, bulges either way
        ctx.arc(0, 0, r, Math.PI / 2, -Math.PI / 2, true);
        ctx.restore();
        ctx.closePath();
        ctx.fillStyle = lit;
        ctx.fill();
        ctx.restore();
        ctx.lineWidth = 1.5;
        ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.25);
        ctx.beginPath(); ctx.arc(cx, cy, r, 0, 2 * Math.PI); ctx.stroke();
    }
}
