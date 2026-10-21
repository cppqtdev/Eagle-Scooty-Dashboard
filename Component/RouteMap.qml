import QtQuick
import Style 1.0

// A drawn route map: city blocks, the route, the part already ridden in the mode
// colour and the scooter's position. Drawn rather than tiled, so it needs no map
// service and renders on the board's software scene graph.
Canvas {
    id: root

    // 0 at the start of the route, 1 at the destination.
    property real progress: 0
    property color routeColor: Style.accent

    // Route corners as fractions of the map.
    readonly property var route: [
        Qt.point(0.12, 0.88), Qt.point(0.12, 0.62), Qt.point(0.38, 0.62), Qt.point(0.38, 0.34),
        Qt.point(0.64, 0.34), Qt.point(0.64, 0.56), Qt.point(0.86, 0.56), Qt.point(0.86, 0.14)
    ]

    function lengths() {
        let total = 0
        const parts = []
        for (let i = 1; i < route.length; ++i) {
            const dx = (route[i].x - route[i - 1].x) * width
            const dy = (route[i].y - route[i - 1].y) * height
            const len = Math.sqrt(dx * dx + dy * dy)
            parts.push(len)
            total += len
        }
        return { parts: parts, total: total }
    }

    function pointAt(fraction) {
        const l = lengths()
        let remaining = Math.max(0, Math.min(1, fraction)) * l.total
        for (let i = 0; i < l.parts.length; ++i) {
            if (remaining <= l.parts[i]) {
                const t = l.parts[i] === 0 ? 0 : remaining / l.parts[i]
                return Qt.point(
                    (route[i].x + (route[i + 1].x - route[i].x) * t) * width,
                    (route[i].y + (route[i + 1].y - route[i].y) * t) * height)
            }
            remaining -= l.parts[i]
        }
        const last = route[route.length - 1]
        return Qt.point(last.x * width, last.y * height)
    }

    onProgressChanged: requestPaint()
    onRouteColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    Connections {
        target: Style
        function onIsDarkChanged() { root.requestPaint() }
    }

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        ctx.fillStyle = Style.isDark ? "#0E1518" : "#EEF3F3"
        ctx.fillRect(0, 0, width, height)

        // Blocks between the streets.
        ctx.fillStyle = Style.isDark ? "#172226" : "#FFFFFF"
        const cols = 9, rows = 6, gap = 18
        for (let c = 0; c < cols; ++c) {
            for (let r = 0; r < rows; ++r) {
                const x = c * width / cols + gap / 2
                const y = r * height / rows + gap / 2
                ctx.fillRect(x, y, width / cols - gap, height / rows - gap)
            }
        }
        // A park and a lake for orientation.
        ctx.fillStyle = Style.isDark ? "#14321F" : "#D7EFD9"
        ctx.fillRect(width * 0.45, height * 0.68, width * 0.18, height * 0.22)
        ctx.fillStyle = Style.isDark ? "#10283A" : "#D3E8F5"
        ctx.beginPath()
        ctx.ellipse(width * 0.72, height * 0.72, width * 0.16, height * 0.18)
        ctx.fill()

        function polyline(upTo) {
            ctx.beginPath()
            const l = lengths()
            let remaining = upTo * l.total
            ctx.moveTo(route[0].x * width, route[0].y * height)
            for (let i = 1; i < route.length; ++i) {
                if (remaining >= l.parts[i - 1]) {
                    ctx.lineTo(route[i].x * width, route[i].y * height)
                    remaining -= l.parts[i - 1]
                } else {
                    const p = root.pointAt(upTo)
                    ctx.lineTo(p.x, p.y)
                    break
                }
            }
            ctx.stroke()
        }

        ctx.lineCap = "round"
        ctx.lineJoin = "round"
        ctx.lineWidth = 16
        ctx.strokeStyle = Style.isDark ? "#2E4A52" : "#B9CCCF"
        polyline(1)
        ctx.lineWidth = 16
        ctx.strokeStyle = root.routeColor
        polyline(root.progress)

        // Destination.
        const end = route[route.length - 1]
        ctx.fillStyle = Style.danger
        ctx.beginPath()
        ctx.arc(end.x * width, end.y * height, 16, 0, Math.PI * 2)
        ctx.fill()
    }

    // The scooter.
    Rectangle {
        readonly property point at: root.pointAt(root.progress)
        x: at.x - width / 2
        y: at.y - height / 2
        width: 40
        height: 40
        radius: 20
        color: "#FFFFFF"
        border.color: root.routeColor
        border.width: 8
        Behavior on x { NumberAnimation { duration: 500 } }
        Behavior on y { NumberAnimation { duration: 500 } }

        Rectangle {
            anchors.centerIn: parent
            width: 40
            height: 40
            radius: 20
            color: "transparent"
            border.color: root.routeColor
            border.width: 3
            SequentialAnimation on scale {
                loops: Animation.Infinite
                NumberAnimation { from: 1; to: 2.2; duration: 1400 }
            }
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { from: 0.8; to: 0; duration: 1400 }
            }
        }
    }
}
