import QtQuick
import QtQuick.Controls
import Style 1.0

Label {
    id: control

    property bool isBold: false
    property bool isStyle: false

    color: isStyle ? Style.accentStrong : Style.textPrimary
    font.pixelSize: Style.h3
    font.family: isBold ? Style.boldFontFamily : Style.mediumFontFamily
    font.weight: isBold ? Font.Bold : Font.Medium
    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
    renderType: Text.NativeRendering

    Behavior on color {
        ColorAnimation { duration: Style.motion.normal }
    }
}
