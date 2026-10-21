import QtQuick
import Style 1.0

// The next manoeuvre as a road-sign arrow: a short bold stem, a rounded bend and
// a crisp head, drawn in a 100 x 100 box and scaled. It pops in when the
// manoeuvre changes, then drifts slowly and slightly the way it points, so the eye finds it
// without it ever moving far. The picture is painted once per manoeuvre; only
// the item moves.
// maneuver: 0 straight, 1 left, 2 right, 3 U-turn, 4 arrive.
Item {
    id: root

    property int maneuver: 0
    property color color: Style.accent
    property bool running: true

    // Unit vector of where the arrow points, for the nudge.
    readonly property var heading: maneuver === 1 ? [-1, 0] : maneuver === 2 ? [1, 0]
                                 : maneuver === 3 ? [0, 1] : [0, -1]
    property real nudge: 0

    onManeuverChanged: popIn.restart()

    SequentialAnimation on nudge {
        running: root.running && root.maneuver !== 4
        loops: Animation.Infinite
        NumberAnimation { to: 1; duration: 1600; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0; duration: 1600; easing.type: Easing.InOutSine }
    }

    ParallelAnimation {
        id: popIn
        NumberAnimation { target: glyph; property: "scale"; from: 0.6; to: 1; duration: 420; easing.type: Easing.OutBack }
        NumberAnimation { target: glyph; property: "opacity"; from: 0; to: 1; duration: 260 }
    }

    // A ring pulsing out from behind the arrow: here, now.
    Rectangle {
        id: pulse
        anchors.centerIn: parent
        width: parent.width * 0.9
        height: width
        radius: width / 2
        color: "transparent"
        border.color: root.color
        border.width: 3
        visible: root.running
        SequentialAnimation on scale {
            running: pulse.visible
            loops: Animation.Infinite
            NumberAnimation { from: 0.8; to: 1.25; duration: 2200; easing.type: Easing.OutCubic }
        }
        SequentialAnimation on opacity {
            running: pulse.visible
            loops: Animation.Infinite
            NumberAnimation { from: 0.5; to: 0; duration: 2200; easing.type: Easing.OutCubic }
        }
    }

    Canvas {
        id: glyph
        width: root.width
        height: root.height
        x: root.heading[0] * root.nudge * root.width * 0.04
        y: root.heading[1] * root.nudge * root.height * 0.04

        readonly property var key: [root.maneuver, root.color, width, height]
        onKeyChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const k = width / 100
            ctx.scale(k, height / 100)
            ctx.strokeStyle = root.color
            ctx.fillStyle = root.color
            ctx.lineWidth = 16
            ctx.lineCap = "butt"
            ctx.lineJoin = "round"

            function head(x, y, angle) {
                // A triangle whose tip is at (x, y), pointing along angle.
                const len = 30, half = 22
                const bx = x - Math.cos(angle) * len, by = y - Math.sin(angle) * len
                ctx.beginPath()
                ctx.moveTo(x, y)
                ctx.lineTo(bx + Math.sin(angle) * half, by - Math.cos(angle) * half)
                ctx.lineTo(bx - Math.sin(angle) * half, by + Math.cos(angle) * half)
                ctx.closePath()
                ctx.fill()
            }

            ctx.beginPath()
            switch (root.maneuver) {
            case 1:   // left: up, round the corner, then left
            case 2: { // right
                const s = root.maneuver === 2 ? 1 : -1
                const x0 = 50 - s * 20
                ctx.moveTo(x0, 96)
                ctx.lineTo(x0, 58)
                ctx.arcTo(x0, 38, x0 + s * 20, 38, 20)
                ctx.lineTo(50 + s * 20, 38)
                ctx.stroke()
                head(50 + s * 48, 38, s > 0 ? 0 : Math.PI)
                break
            }
            case 3:   // U-turn: up, over the top, back down
                ctx.moveTo(68, 96)
                ctx.lineTo(68, 44)
                ctx.arc(46, 44, 22, 0, Math.PI, true)
                ctx.lineTo(24, 58)
                ctx.stroke()
                head(24, 90, Math.PI / 2)
                break
            case 4:   // arrive: a pin
                ctx.beginPath()
                ctx.arc(50, 36, 24, Math.PI * 0.85, Math.PI * 0.15)
                ctx.lineTo(50, 92)
                ctx.closePath()
                ctx.fill()
                ctx.fillStyle = Style.isDark ? "#101817" : "#FFFFFF"
                ctx.beginPath()
                ctx.arc(50, 36, 9, 0, Math.PI * 2)
                ctx.fill()
                break
            default:  // straight on
                ctx.moveTo(50, 96)
                ctx.lineTo(50, 34)
                ctx.stroke()
                head(50, 4, -Math.PI / 2)
            }
        }
    }
}
