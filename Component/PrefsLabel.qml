import QtQuick 2.15
import QtQuick.Controls 2.5
import Style 1.0

Label {
    property bool isBold: false
    property bool isStyle: false
    clip: true
    color: isStyle ? Style.styleColor : Style.baseColor
    font.pixelSize: Style.h3
    font.capitalization: Font.Capitalize
    font.bold: isBold ? Font.Bold : Font.Normal
    font.weight: isBold ? Font.Bold : Font.Normal
    font.family: isBold ? Style.helveticaNeureBold.name : Style.helveticaNeureMedium.name
    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
}
