import QtQuick

// Smooth, faster mouse-wheel scrolling for the Flickable it is declared in; touchpads scroll 1:1.
WheelHandler {
    id: h
    // children declared inside a Flickable live in its contentItem, so the view is the parent's parent
    readonly property Flickable view: (parent as Flickable) ?? (parent && parent.parent as Flickable)
    property real speed: 2.2        // pixels per wheel angle-delta unit (one notch = 120)
    property real goal: 0
    property NumberAnimation anim: NumberAnimation { target: h.view; property: "contentY"; duration: 260; easing.type: Easing.OutCubic }
    Component.onCompleted: if (view) { view.maximumFlickVelocity = 5000; view.flickDeceleration = 2500; } // touch / drag flicks: faster and longer glide
    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    onWheel: event => {
        const v = view;
        if (!v) { event.accepted = false; return; }
        const lo = v.originY - v.topMargin, hi = Math.max(lo, v.originY + v.contentHeight - v.height + v.bottomMargin);
        if (event.pixelDelta.y !== 0) { anim.stop(); v.contentY = Math.max(lo, Math.min(hi, v.contentY - event.pixelDelta.y)); return; }
        if (!anim.running) goal = v.contentY;
        goal = Math.max(lo, Math.min(hi, goal - event.angleDelta.y * speed));
        anim.to = goal;
        anim.restart();
    }
}
