import QtQuick
import QtQuick.Controls
import Style 1.0

TextField {
    id: control

    property bool isBold: false
    property real radius: Style.metrics.radiusMd
    property color borderColor: Style.border
    property color backgroundColor: Style.surface

    leftPadding: Style.metrics.spacingMd
    rightPadding: Style.metrics.spacingMd
    placeholderTextColor: Style.textMuted
    font.pixelSize: Style.h5
    font.family: isBold ? Style.boldFontFamily : Style.regularFontFamily
    font.weight: isBold ? Font.Bold : Font.Normal
    color: Style.textPrimary
    selectionColor: Style.accent
    selectedTextColor: Style.textOnAccent

    background: Rectangle {
        implicitHeight: control.implicitHeight
        implicitWidth: control.implicitWidth
        radius: control.radius
        color: control.backgroundColor
        border.width: control.activeFocus ? 2 : 1
        border.color: control.activeFocus ? Style.accent : control.borderColor

        Behavior on color { ColorAnimation { duration: Style.motion.normal } }
        Behavior on border.color { ColorAnimation { duration: Style.motion.fast } }
    }
}
