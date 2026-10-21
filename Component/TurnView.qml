import QtQuick
import Style 1.0

// The next manoeuvre drawn onto the road ahead, after the ApexCluster navigation
// design: the road narrows to the horizon, the side road leaves where the turn is,
// and an arrow in the ride-mode colour runs from the rider into it. When the
// manoeuvre changes the arrow drops in from the horizon again.
// maneuver: 0 straight, 1 left, 2 right, 3 U-turn, 4 arrive.
Canvas {
    id: root

    property int maneuver: 0
    property color arrowColor: Style.accent
    property real drop: 0   // 0 settled, 1 at the horizon

    onManeuverChanged: { drop = 1; dropIn.restart() }
    onDropChanged: requestPaint()
    onArrowColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    Connections {
        target: Style
        function onIsDarkChanged() { root.requestPaint() }
    }

    NumberAnimation {
        id: dropIn
        target: root
        property: "drop"
        to: 0
        duration: 650
        easing.type: Easing.OutCubic
    }

    onPaint: {
        const ctx = getContext("2d")
        const w = width, h = height
        const horizon = h * 0.08
        const cx = w / 2
        // x at height y for the road's left (side -1) or right (+1) edge.
        function edge(side, y) {
            const t = (y - horizon) / (h - horizon)
            return cx + side * (w * 0.012 + t * w * 0.34)
        }
        ctx.reset()

        const road = Style.isDark ? "#1C272B" : "#E1E9EA"
        const line = Style.isDark ? "#3E5157" : "#AFC1C3"

        // Road surface.
        ctx.fillStyle = road
        ctx.beginPath()
        ctx.moveTo(edge(-1, horizon), horizon)
        ctx.lineTo(edge(1, horizon), horizon)
        ctx.lineTo(edge(1, h), h)
        ctx.lineTo(edge(-1, h), h)
        ctx.closePath()
        ctx.fill()

        // Side road for the turn.
        const turnSide = maneuver === 1 || maneuver === 3 ? -1 : maneuver === 2 ? 1 : 0
        const joinY = h * 0.5 + drop * (horizon - h * 0.5)
        if (turnSide !== 0 && maneuver !== 3) {
            const near = joinY + h * 0.09
            ctx.beginPath()
            ctx.moveTo(edge(turnSide, joinY - h * 0.05), joinY - h * 0.05)
            ctx.lineTo(turnSide < 0 ? 0 : w, joinY - h * 0.04)
            ctx.lineTo(turnSide < 0 ? 0 : w, near + h * 0.02)
            ctx.lineTo(edge(turnSide, near), near)
            ctx.closePath()
            ctx.fill()
        }

        // Road edges and the dashed centre line.
        ctx.strokeStyle = line
        ctx.lineWidth = 3
        ctx.beginPath()
        ctx.moveTo(edge(-1, horizon), horizon)
        ctx.lineTo(edge(-1, h), h)
        ctx.moveTo(edge(1, horizon), horizon)
        ctx.lineTo(edge(1, h), h)
        ctx.stroke()
        for (let i = 0; i < 9; ++i) {
            const y0 = horizon + (h - horizon) * Math.pow(i / 9, 1.6)
            const y1 = horizon + (h - horizon) * Math.pow((i + 0.45) / 9, 1.6)
            ctx.lineWidth = 2 + 6 * (y0 - horizon) / (h - horizon)
            ctx.beginPath()
            ctx.moveTo(cx, y0)
            ctx.lineTo(cx, y1)
            ctx.stroke()
        }

        // The arrow.
        ctx.globalAlpha = 1 - drop * 0.8
        ctx.strokeStyle = arrowColor
        ctx.fillStyle = arrowColor
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
        if (turnSide !== 0 && maneuver !== 3) {
            const endX = cx + turnSide * w * 0.4
            ctx.moveTo(cx, startY)
            ctx.lineTo(cx, bendY + h * 0.08)
            ctx.quadraticCurveTo(cx, bendY, cx + turnSide * w * 0.08, bendY)
            ctx.lineTo(endX - turnSide * w * 0.04, bendY)
            ctx.stroke()
            head(endX, bendY, turnSide < 0 ? Math.PI : 0)
        } else if (maneuver === 3) {
            ctx.moveTo(cx + w * 0.05, startY)
            ctx.lineTo(cx + w * 0.05, bendY + h * 0.05)
            ctx.arc(cx - w * 0.01, bendY + h * 0.05, w * 0.06, 0, Math.PI, true)
            ctx.lineTo(cx - w * 0.07, bendY + h * 0.2)
            ctx.stroke()
            head(cx - w * 0.07, bendY + h * 0.27, Math.PI / 2)
        } else if (maneuver === 4) {
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
