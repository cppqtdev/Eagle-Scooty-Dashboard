import QtQuick
import Style 1.0

// Large text filled with a horizontal gradient, darker on the left, as the
// battery bar is filled, so a figure and its bar read as one. Drawn on a
// Canvas: the board's software renderer has no shader effects to mask a
// gradient with, but a canvas fills text with one directly.
Canvas {
    id: root

    property string text
    property int pixelSize: 120
    property color color: Style.accent
    property bool bold: true
    // The widest text it will show: the size is fixed to it, so a change of value
    // never resizes the canvas (a resize repaints blank for a frame and moves the
    // layout around it).
    property string widestText: text

    readonly property string family: bold ? Style.boldFontFamily : Style.regularFontFamily

    implicitWidth: Math.ceil(widest.advanceWidth) + 4
    implicitHeight: Math.ceil(metrics.height)

    TextMetrics {
        id: metrics
        font.family: root.family
        font.pixelSize: root.pixelSize
        font.weight: root.bold ? Font.Bold : Font.Normal
        text: root.text
    }
    TextMetrics {
        id: widest
        font: metrics.font
        text: root.widestText
    }

    readonly property var key: [text, color, width, height, pixelSize, family]
    renderStrategy: Canvas.Immediate
    onKeyChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        const fill = ctx.createLinearGradient(0, 0, width, 0)
        fill.addColorStop(0, Qt.darker(root.color, 1.35))
        fill.addColorStop(1, Qt.lighter(root.color, 1.08))
        ctx.fillStyle = fill
        ctx.font = (root.bold ? "bold " : "") + root.pixelSize + "px \"" + root.family + "\""
        ctx.textBaseline = "top"
        ctx.textAlign = "center"
        ctx.fillText(root.text, width / 2, (height - root.pixelSize) / 2)
    }
}
