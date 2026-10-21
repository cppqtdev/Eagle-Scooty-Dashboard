import QtQuick
import QtQuick.Controls
import Style 1.0

// A section caption: small, upper case, spaced out, as on the SR Motard cluster.
Label {
    property bool accent: false

    font.family: Style.regularFontFamily
    font.pixelSize: 20
    font.letterSpacing: 2.5
    font.capitalization: Font.AllUppercase
    color: accent ? Style.accent : Style.textMuted
}
