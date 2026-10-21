import QtQuick
import QtQuick.Controls
import Style 1.0

// Text in the dashboard's type: Orbitron Regular for reading, Medium for emphasis,
// and Bold only for large figures, where the heavier strokes still read cleanly.
Label {
    id: control

    property bool isBold: false
    property bool isStyle: false

    readonly property bool largeFigure: font.pixelSize >= 48

    color: isStyle ? Style.accentStrong : Style.textPrimary
    font.pixelSize: Style.h3
    font.family: !isBold ? Style.regularFontFamily : largeFigure ? Style.boldFontFamily : Style.mediumFontFamily
    font.weight: !isBold ? Font.Normal : largeFigure ? Font.Bold : Font.Medium
    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
    renderType: Text.NativeRendering

    Behavior on color {
        ColorAnimation { duration: Style.motion.normal }
    }
}
