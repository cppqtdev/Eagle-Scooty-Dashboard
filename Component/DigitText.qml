import QtQuick
import Style 1.0

// A figure that never moves the layout: every digit sits in a cell as wide as the
// widest digit, the rest of the characters keep their own width. Orbitron's
// digits are proportional ("1" is narrow), so plain text would jump sideways each
// time a value changed.
Row {
    id: root

    property string text
    property int pixelSize: Style.h3
    property bool isBold: false
    property bool isStyle: false
    property color color: isStyle ? Style.accentStrong : Style.textPrimary
    // Align the figure's right edge (counters) or centre (big readouts) in a fixed box.
    property int digitAlign: Text.AlignHCenter

    readonly property bool largeFigure: pixelSize >= 48
    readonly property string family: !isBold ? Style.regularFontFamily
                                   : largeFigure ? Style.boldFontFamily : Style.mediumFontFamily
    readonly property int weight: !isBold ? Font.Normal : largeFigure ? Font.Bold : Font.Medium
    readonly property real digitWidth: {
        let widest = 0
        for (let d = 0; d <= 9; ++d)
            widest = Math.max(widest, metrics.advanceWidth(String(d)))
        return Math.ceil(widest)
    }

    baselineOffset: metrics.ascent
    spacing: 0

    FontMetrics {
        id: metrics
        font.family: root.family
        font.pixelSize: root.pixelSize
        font.weight: root.weight
    }

    Repeater {
        model: root.text.length
        Text {
            required property int index
            readonly property string glyph: root.text.charAt(index)
            readonly property bool digit: glyph >= "0" && glyph <= "9"
            width: digit ? root.digitWidth : implicitWidth
            horizontalAlignment: root.digitAlign
            text: glyph
            color: root.color
            font.family: root.family
            font.pixelSize: root.pixelSize
            font.weight: root.weight
            renderType: Text.QtRendering
            Behavior on color { ColorAnimation { duration: Style.motion.normal } }
        }
    }
}
