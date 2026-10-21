import QtQuick
import QtQuick.Controls
import Style 1.0

// A section caption: small, upper case, spaced out, as on the SR Motard cluster.
Label {
    property bool accent: false

    font.family: Style.mediumFontFamily
    font.pixelSize: 17
    font.letterSpacing: 3
    font.capitalization: Font.AllUppercase
    color: accent ? Style.accent : Style.textMuted
}
