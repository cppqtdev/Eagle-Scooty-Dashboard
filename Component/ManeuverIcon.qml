import QtQuick
import Style 1.0

// The next turn from the phone's navigation, drawn rather than loaded so it takes
// the theme colour and works on the software renderer.
// maneuver: 0 straight, 1 left, 2 right, 3 U-turn, 4 arrive.
Canvas {
    id: root

    property int maneuver: 0
    property color color: Style.textPrimary

    implicitWidth: 72
    implicitHeight: 72

    onManeuverChanged: requestPaint()
    onColorChanged: requestPaint()
    onWidthChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        const w = width, h = height, s = Math.min(w, h)
        ctx.reset()
        ctx.strokeStyle = root.color
        ctx.fillStyle = root.color
        ctx.lineWidth = s * 0.11
        ctx.lineCap = "round"
        ctx.lineJoin = "round"

        function head(x, y, angle) {
            const len = s * 0.2
            ctx.beginPath()
            ctx.moveTo(x + Math.cos(angle) * len * 0.2, y + Math.sin(angle) * len * 0.2)
            ctx.lineTo(x - Math.cos(angle - 0.6) * len, y - Math.sin(angle - 0.6) * len)
            ctx.lineTo(x - Math.cos(angle + 0.6) * len, y - Math.sin(angle + 0.6) * len)
            ctx.closePath()
            ctx.fill()
        }

        ctx.beginPath()
        switch (root.maneuver) {
        case 1: // left
            ctx.moveTo(w * 0.62, h * 0.92)
            ctx.lineTo(w * 0.62, h * 0.48)
            ctx.quadraticCurveTo(w * 0.62, h * 0.32, w * 0.46, h * 0.32)
            ctx.lineTo(w * 0.3, h * 0.32)
            ctx.stroke()
            head(w * 0.18, h * 0.32, Math.PI)
            break
        case 2: // right
            ctx.moveTo(w * 0.38, h * 0.92)
            ctx.lineTo(w * 0.38, h * 0.48)
            ctx.quadraticCurveTo(w * 0.38, h * 0.32, w * 0.54, h * 0.32)
            ctx.lineTo(w * 0.7, h * 0.32)
            ctx.stroke()
            head(w * 0.82, h * 0.32, 0)
            break
        case 3: // U-turn
            ctx.moveTo(w * 0.66, h * 0.92)
            ctx.lineTo(w * 0.66, h * 0.4)
            ctx.arc(w * 0.5, h * 0.4, w * 0.16, 0, Math.PI, true)
            ctx.lineTo(w * 0.34, h * 0.62)
            ctx.stroke()
            head(w * 0.34, h * 0.74, Math.PI / 2)
            break
        case 4: // arrive: a pin
            ctx.arc(w * 0.5, h * 0.4, s * 0.2, 0, Math.PI * 2)
            ctx.stroke()
            ctx.beginPath()
            ctx.moveTo(w * 0.5, h * 0.6)
            ctx.lineTo(w * 0.5, h * 0.9)
            ctx.stroke()
            break
        default: // straight
            ctx.moveTo(w * 0.5, h * 0.92)
            ctx.lineTo(w * 0.5, h * 0.3)
            ctx.stroke()
            head(w * 0.5, h * 0.16, -Math.PI / 2)
        }
    }
}
