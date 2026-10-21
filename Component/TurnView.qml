import QtQuick
import Style 1.0
import Eagle.Blink 1.0

// The next manoeuvre drawn onto the road ahead, after the ApexCluster drive
// view: the road narrows to the horizon, its centre dashes run towards the
// rider at road speed (away from them in reverse), the side road comes down
// the road as the turn gets closer with a pulse where to turn, and an arrow in
// the ride-mode colour leads into it. Hazards light the edges green on the
// shared flasher; in reverse amber chevrons sweep towards the rider instead of
// the arrow; high beam tints the tarmac blue.
//
// The tarmac, side road and arrow are one Canvas painted only when they change;
// everything that moves every frame is a plain item, cheap on the board's
// software renderer.
// maneuver: 0 straight, 1 left, 2 right, 3 U-turn, 4 arrive.
Item {
    id: root

    property int maneuver: 0
    property color arrowColor: Style.accent
    property real distanceM: 300      // to the manoeuvre; brings the side road closer
    property real speed: 0            // km/h, runs the dashes
    property bool reverse: false
    property bool hazard: false
    property bool highBeam: false

    readonly property real horizon: height * 0.08
    readonly property real cx: width / 2
    readonly property int turnSide: maneuver === 1 || maneuver === 3 ? -1 : maneuver === 2 ? 1 : 0
    readonly property bool hasSideRoad: turnSide !== 0 && maneuver !== 3
    // 0 far off, 1 at the turn: the junction slides from near the horizon to the middle.
    readonly property real approach: Math.max(0, Math.min(1, 1 - distanceM / 500))
    property real drop: 0             // 0 settled, 1 at the horizon (a new manoeuvre drops in)
    readonly property real joinY: {
        const settled = horizon + (height * 0.55 - horizon) * (0.45 + 0.55 * approach)
        return settled + drop * (horizon - settled)
    }

    // x at height y for the road's left (side -1) or right (+1) edge.
    function edgeX(side, y) {
        const t = (y - horizon) / (height - horizon)
        return cx + side * (width * 0.012 + t * width * 0.34)
    }

    onManeuverChanged: { drop = 1; dropIn.restart() }

    NumberAnimation {
        id: dropIn
        target: root
        property: "drop"
        to: 0
        duration: 650
        easing.type: Easing.OutCubic
    }

    Canvas {
        id: road
        anchors.fill: parent

        // Repainted on what it draws, never per frame.
        readonly property var key: [root.maneuver, Math.round(root.joinY), root.highBeam, Style.isDark,
                                    root.width, root.height]
        onKeyChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d")
            const w = width, h = height
            const horizon = root.horizon, cx = root.cx
            const edge = root.edgeX
            ctx.reset()

            const tarmac = Style.isDark ? "#18231F" : "#E1E9EA"
            const line = Style.isDark ? "#3E5157" : "#AFC1C3"

            function surface() {
                ctx.beginPath()
                ctx.moveTo(edge(-1, horizon), horizon)
                ctx.lineTo(edge(1, horizon), horizon)
                ctx.lineTo(edge(1, h), h)
                ctx.lineTo(edge(-1, h), h)
                ctx.closePath()
            }
            ctx.fillStyle = tarmac
            surface()
            ctx.fill()

            // Side road for the turn, joining between joinTop and joinBottom.
            const joinY = root.joinY
            const joinTop = joinY - h * 0.05
            const joinBottom = joinY + h * 0.09
            const farX = root.turnSide < 0 ? 0 : w
            function sideRoad() {
                ctx.beginPath()
                ctx.moveTo(edge(root.turnSide, joinTop), joinTop)
                ctx.lineTo(farX, joinTop + h * 0.01)
                ctx.lineTo(farX, joinBottom + h * 0.02)
                ctx.lineTo(edge(root.turnSide, joinBottom), joinBottom)
                ctx.closePath()
            }
            if (root.hasSideRoad) {
                ctx.fillStyle = tarmac
                sideRoad()
                ctx.fill()
            }

            // High beam lights the tarmac ahead.
            if (root.highBeam) {
                const beam = ctx.createLinearGradient(0, h, 0, horizon)
                beam.addColorStop(0, "rgba(66, 133, 244, 0.30)")
                beam.addColorStop(1, "rgba(66, 133, 244, 0.04)")
                ctx.fillStyle = beam
                surface()
                ctx.fill()
            }

            // Edges, broken where the side road joins, and the side road's own edges.
            ctx.strokeStyle = line
            ctx.lineWidth = 3
            ctx.beginPath()
            for (const side of [-1, 1]) {
                ctx.moveTo(edge(side, horizon), horizon)
                if (root.hasSideRoad && side === root.turnSide) {
                    ctx.lineTo(edge(side, joinTop), joinTop)
                    ctx.lineTo(farX, joinTop + h * 0.01)
                    ctx.moveTo(farX, joinBottom + h * 0.02)
                    ctx.lineTo(edge(side, joinBottom), joinBottom)
                }
                ctx.lineTo(edge(side, h), h)
            }
            ctx.stroke()

        }
    }

    // Centre dashes running with the road. phase 0..1 is one dash period.
    property real phase: 0
    readonly property int dashCount: 9

    Timer {
        interval: 33
        repeat: true
        running: root.visible && root.speed > 0.5
        onTriggered: {
            // About two dashes a second at 40 km/h; backwards in reverse.
            const step = interval / 1000 * root.speed * 0.05 * (root.reverse ? -1 : 1)
            root.phase = ((root.phase + step) % 1 + 1) % 1
        }
    }

    Repeater {
        model: root.dashCount
        Rectangle {
            required property int index
            readonly property real t0: (index + root.phase) / root.dashCount
            readonly property real t1: Math.min(1, t0 + 0.45 / root.dashCount)
            readonly property real y0: root.horizon + (root.height - root.horizon) * Math.pow(t0, 1.6)
            readonly property real y1: root.horizon + (root.height - root.horizon) * Math.pow(t1, 1.6)
            x: root.cx - width / 2
            y: y0
            width: 2 + 6 * (y0 - root.horizon) / (root.height - root.horizon)
            height: Math.max(1, y1 - y0)
            radius: width / 2
            color: Style.isDark ? "#3E5157" : "#AFC1C3"
        }
    }

    // The arrow, over the dashes.
    Canvas {
        id: arrow
        anchors.fill: parent
        visible: !root.reverse
        readonly property var key: [root.maneuver, Math.round(root.joinY), root.arrowColor, root.drop > 0,
                                    Math.round(root.drop * 20), root.width, root.height]
        onKeyChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d")
            const w = width, h = height
            const horizon = root.horizon, cx = root.cx
            const joinY = root.joinY
            ctx.reset()

            // The arrow.
            ctx.globalAlpha = 1 - root.drop * 0.8
            ctx.strokeStyle = root.arrowColor
            ctx.fillStyle = root.arrowColor
            ctx.lineWidth = w * 0.035
            ctx.lineCap = "round"
            ctx.lineJoin = "round"
            const startY = h * 0.96
            const bendY = joinY + h * 0.02
            function head(x, y, angle) {
                const len = w * 0.05
                ctx.beginPath()
                ctx.moveTo(x + Math.cos(angle) * len * 0.35, y + Math.sin(angle) * len * 0.35)
                ctx.lineTo(x - Math.cos(angle - 0.62) * len, y - Math.sin(angle - 0.62) * len)
                ctx.lineTo(x - Math.cos(angle + 0.62) * len, y - Math.sin(angle + 0.62) * len)
                ctx.closePath()
                ctx.fill()
            }
            ctx.beginPath()
            if (root.hasSideRoad) {
                const endX = cx + root.turnSide * w * 0.4
                ctx.moveTo(cx, startY)
                ctx.lineTo(cx, bendY + h * 0.08)
                ctx.quadraticCurveTo(cx, bendY, cx + root.turnSide * w * 0.08, bendY)
                ctx.lineTo(endX - root.turnSide * w * 0.04, bendY)
                ctx.stroke()
                head(endX, bendY, root.turnSide < 0 ? Math.PI : 0)
            } else if (root.maneuver === 3) {
                ctx.moveTo(cx + w * 0.05, startY)
                ctx.lineTo(cx + w * 0.05, bendY + h * 0.05)
                ctx.arc(cx - w * 0.01, bendY + h * 0.05, w * 0.06, 0, Math.PI, true)
                ctx.lineTo(cx - w * 0.07, bendY + h * 0.2)
                ctx.stroke()
                head(cx - w * 0.07, bendY + h * 0.27, Math.PI / 2)
            } else if (root.maneuver === 4) {
                ctx.moveTo(cx, startY)
                ctx.lineTo(cx, bendY + h * 0.06)
                ctx.stroke()
                ctx.beginPath()
                ctx.arc(cx, bendY - h * 0.02, w * 0.035, 0, Math.PI * 2)
                ctx.fill()
            } else {
                ctx.moveTo(cx, startY)
                ctx.lineTo(cx, horizon + h * 0.2)
                ctx.stroke()
                head(cx, horizon + h * 0.12, -Math.PI / 2)
            }
            ctx.globalAlpha = 1
        }
    }

    // Hazards: both edges lit green, flashing with the telltales.
    Canvas {
        id: hazardEdges
        anchors.fill: parent
        visible: root.hazard && BlinkClock.on
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            ctx.strokeStyle = Style.success
            ctx.lineWidth = 6
            ctx.lineCap = "round"
            ctx.beginPath()
            for (const side of [-1, 1]) {
                ctx.moveTo(root.edgeX(side, root.horizon), root.horizon)
                ctx.lineTo(root.edgeX(side, height), height)
            }
            ctx.stroke()
        }
    }

    // Where to turn: a ring pulsing on the junction.
    Item {
        visible: root.hasSideRoad && !root.reverse && root.drop < 0.1
        x: root.cx + root.turnSide * root.width * 0.4 - width / 2
        y: root.joinY + root.height * 0.02 - height / 2
        width: root.width * 0.09
        height: width

        Rectangle {
            id: ring
            anchors.centerIn: parent
            width: parent.width
            height: width
            radius: width / 2
            color: "transparent"
            border.color: root.arrowColor
            border.width: 3
            SequentialAnimation on scale {
                running: ring.visible
                loops: Animation.Infinite
                NumberAnimation { from: 0.6; to: 1.5; duration: 1200; easing.type: Easing.OutCubic }
            }
            SequentialAnimation on opacity {
                running: ring.visible
                loops: Animation.Infinite
                NumberAnimation { from: 0.9; to: 0; duration: 1200; easing.type: Easing.OutCubic }
            }
        }
    }

    // Reverse: three amber chevrons down the road, lit one at a time towards the rider.
    property int sweep: 0
    Timer {
        running: root.reverse && root.visible
        interval: 300
        repeat: true
        triggeredOnStart: true
        onTriggered: root.sweep = (root.sweep + 1) % 3
    }
    Repeater {
        model: [0.40, 0.60, 0.82]
        LineIcon {
            required property int index
            required property real modelData
            visible: root.reverse
            size: Math.round(root.width * (0.08 + 0.05 * index))
            x: root.cx - size / 2
            y: root.height * modelData - size / 2
            name: "chevronDown"
            strokeWidth: 3
            color: Style.warning
            opacity: index === root.sweep ? 1 : 0.25
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }
    }
}
