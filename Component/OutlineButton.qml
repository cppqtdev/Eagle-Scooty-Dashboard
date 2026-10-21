import QtQuick
import QtQuick.Layouts
import Style 1.0

// A text button with an outline; the highlighted one is filled. Used for the
// transport keys and dialog choices.
Rectangle {
    id: button

    property string text
    property bool highlighted: false
    property color tone: Style.accent
    signal clicked()

    implicitWidth: Math.max(150, label.implicitWidth + 56)
    implicitHeight: 64
    radius: 14
    color: highlighted ? tone : tap.pressed ? Style.surfaceSunken : "transparent"
    border.color: highlighted ? tone : Style.borderStrong
    border.width: 2
    scale: tap.pressed ? 0.96 : 1
    Behavior on color { ColorAnimation { duration: Style.motion.instant } }
    Behavior on scale { NumberAnimation { duration: Style.motion.fast } }

    PrefsLabel {
        id: label
        anchors.centerIn: parent
        font.pixelSize: Style.h5
        font.letterSpacing: 2
        font.capitalization: Font.AllUppercase
        isBold: true
        color: button.highlighted ? Style.textOnAccent : Style.textPrimary
        text: button.text
    }

    TapHandler { id: tap; onTapped: button.clicked() }
}
