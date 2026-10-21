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

    // The arrow, over the dashes, in one of four styles (Style.arrowStyle):
    //   solid     a bold line of even width with a head (the classic)
    //   ribbon    a translucent band lying on the road, wider near the rider,
    //             with a bright core, as AR navigation draws it
    //   chevrons  chevron marks along the path, growing towards the rider
    //   outline   the ribbon's shape drawn as an outline with a soft glow inside
    // The path is the same for all; only how it is drawn differs.
    Canvas {
        id: arrow
        anchors.fill: parent
        visible: !root.reverse
        readonly property var key: [root.maneuver, Math.round(root.joinY), root.arrowColor, root.drop > 0,
                                    Math.round(root.drop * 20), root.width, root.height, Style.arrowStyle, Style.isDark]
        onKeyChanged: requestPaint()

        // The arrow's centre line as points, near to far, and where its head goes.
        function route() {
            const w = width, h = height, cx = root.cx, joinY = root.joinY
            const startY = h * 0.96
            const bendY = joinY + h * 0.02
            const points = []
            if (root.hasSideRoad) {
                const side = root.turnSide
                points.push([cx, startY], [cx, bendY + h * 0.08])
                // The bend, a quadratic from straight up to across.
                const p0 = [cx, bendY + h * 0.08], c = [cx, bendY], p2 = [cx + side * w * 0.08, bendY]
                for (let i = 1; i <= 8; ++i) {
                    const t = i / 8
                    points.push([(1 - t) * (1 - t) * p0[0] + 2 * (1 - t) * t * c[0] + t * t * p2[0],
                                 (1 - t) * (1 - t) * p0[1] + 2 * (1 - t) * t * c[1] + t * t * p2[1]])
                }
                points.push([cx + side * w * 0.36, bendY])
                return { points: points, head: [cx + side * w * 0.4, bendY], angle: side < 0 ? Math.PI : 0 }
            }
            if (root.maneuver === 3) {
                const r = w * 0.06, ax = cx - w * 0.01, ay = bendY + h * 0.05
                points.push([cx + w * 0.05, startY], [cx + w * 0.05, ay])
                for (let i = 1; i <= 10; ++i) {
                    const t = -Math.PI * i / 10
                    points.push([ax + r * Math.cos(t), ay + r * Math.sin(t)])
                }
                points.push([cx - w * 0.07, bendY + h * 0.2])
                return { points: points, head: [cx - w * 0.07, bendY + h * 0.27], angle: Math.PI / 2 }
            }
            if (root.maneuver === 4) {
                points.push([cx, startY], [cx, bendY + h * 0.06])
                return { points: points, head: [cx, bendY - h * 0.02], angle: -1 }   // -1: a destination dot
            }
            points.push([cx, startY], [cx, root.horizon + h * 0.2])
            return { points: points, head: [cx, root.horizon + h * 0.12], angle: -Math.PI / 2 }
        }

        onPaint: {
            const ctx = getContext("2d")
            const w = width, h = height
            ctx.reset()
            ctx.globalAlpha = 1 - root.drop * 0.8
            ctx.lineCap = "round"
            ctx.lineJoin = "round"

            const color = root.arrowColor
            const soft = Qt.rgba(color.r, color.g, color.b, 0.28)
            const faint = Qt.rgba(color.r, color.g, color.b, 0.12)
            const { points, head, angle } = route()
            // Nearer is wider: 0.35 at the horizon, 1 at the bottom.
            const depth = y => 0.35 + 0.65 * Math.max(0, (y - root.horizon) / (h - root.horizon))

            function polyline() {
                ctx.beginPath()
                ctx.moveTo(points[0][0], points[0][1])
                for (let i = 1; i < points.length; ++i)
                    ctx.lineTo(points[i][0], points[i][1])
            }
            // The band either side of the centre line, half-width scaled by depth.
            function band(scale) {
                const left = [], right = []
                for (let i = 0; i < points.length; ++i) {
                    const a = points[Math.max(0, i - 1)], b = points[Math.min(points.length - 1, i + 1)]
                    const len = Math.hypot(b[0] - a[0], b[1] - a[1]) || 1
                    const nx = -(b[1] - a[1]) / len, ny = (b[0] - a[0]) / len
                    const half = w * scale * depth(points[i][1])
                    left.push([points[i][0] + nx * half, points[i][1] + ny * half])
                    right.push([points[i][0] - nx * half, points[i][1] - ny * half])
                }
                ctx.beginPath()
                ctx.moveTo(left[0][0], left[0][1])
                for (let i = 1; i < left.length; ++i)
                    ctx.lineTo(left[i][0], left[i][1])
                for (let i = right.length - 1; i >= 0; --i)
                    ctx.lineTo(right[i][0], right[i][1])
                ctx.closePath()
            }
            function headPath(size) {
                const len = w * size * depth(head[1])
                ctx.beginPath()
                ctx.moveTo(head[0] + Math.cos(angle) * len * 0.45, head[1] + Math.sin(angle) * len * 0.45)
                ctx.lineTo(head[0] - Math.cos(angle - 0.7) * len, head[1] - Math.sin(angle - 0.7) * len)
                ctx.lineTo(head[0] - Math.cos(angle) * len * 0.35, head[1] - Math.sin(angle) * len * 0.35)
                ctx.lineTo(head[0] - Math.cos(angle + 0.7) * len, head[1] - Math.sin(angle + 0.7) * len)
                ctx.closePath()
            }
            function dot(radius) {
                ctx.beginPath()
                ctx.arc(head[0], head[1], w * radius, 0, Math.PI * 2)
            }

            switch (Style.arrowStyle) {
            case "ribbon":
                ctx.fillStyle = soft
                band(0.05)
                ctx.fill()
                ctx.strokeStyle = color
                ctx.lineWidth = w * 0.008
                polyline()
                ctx.stroke()
                ctx.fillStyle = color
                if (angle === -1) { dot(0.03); ctx.fill() } else { headPath(0.075); ctx.fill() }
                break
            case "outline":
                ctx.fillStyle = faint
                band(0.04)
                ctx.fill()
                ctx.strokeStyle = color
                ctx.lineWidth = 4
                band(0.04)
                ctx.stroke()
                if (angle === -1) {
                    dot(0.03); ctx.fillStyle = faint; ctx.fill(); ctx.stroke()
                } else {
                    headPath(0.08); ctx.fillStyle = faint; ctx.fill(); ctx.stroke()
                }
                break
            case "chevrons": {
                // Marks every so far along the path, measured along it.
                let walked = 0
                const spacing = h * 0.075
                let next = spacing * 0.5
                for (let i = 1; i < points.length; ++i) {
                    const a = points[i - 1], b = points[i]
                    const segment = Math.hypot(b[0] - a[0], b[1] - a[1])
                    const dir = Math.atan2(b[1] - a[1], b[0] - a[0])
                    while (next <= walked + segment) {
                        const t = (next - walked) / segment
                        const x = a[0] + (b[0] - a[0]) * t, y = a[1] + (b[1] - a[1]) * t
                        const size = w * 0.032 * depth(y)
                        ctx.strokeStyle = color
                        ctx.globalAlpha = (1 - root.drop * 0.8) * (0.45 + 0.55 * depth(y))
                        ctx.lineWidth = Math.max(3, size * 0.45)
                        ctx.beginPath()
                        ctx.moveTo(x - Math.cos(dir - 0.8) * size, y - Math.sin(dir - 0.8) * size)
                        ctx.lineTo(x, y)
                        ctx.lineTo(x - Math.cos(dir + 0.8) * size, y - Math.sin(dir + 0.8) * size)
                        ctx.stroke()
                        next += spacing
                    }
                    walked += segment
                }
                ctx.globalAlpha = 1 - root.drop * 0.8
                ctx.fillStyle = color
                if (angle === -1) { dot(0.03); ctx.fill() } else { headPath(0.07); ctx.fill() }
                break
            }
            default:   // solid
                ctx.strokeStyle = color
                ctx.fillStyle = color
                ctx.lineWidth = w * 0.035
                polyline()
                ctx.stroke()
                if (angle === -1) { dot(0.035); ctx.fill() } else { headPath(0.06); ctx.fill() }
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
