import QtQuick 2.15
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3
import Style 1.0

TextField {
    id:control
    property bool isBold: false
    property real radius: 12
    property color borderColor: palette.highlight
    property color backgroundColor: palette.base

    placeholderTextColor: "#FFFFFF"
    font.pixelSize: Style.h5
    font.bold: isBold ? Font.Bold : Font.Normal
    font.weight: isBold ? Font.Bold : Font.Normal
    color: palette.dark
    background:Rectangle{
        implicitHeight: control.implicitHeight
        implicitWidth: control.implicitWidth
        radius: control.radius
        color: control.backgroundColor
        border.width:  control.activeFocus ? 2 : 1
        border.color: control.borderColor
    }
}
