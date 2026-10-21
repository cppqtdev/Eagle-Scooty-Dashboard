import QtQuick
import QtQuick.Layouts
import Style 1.0

// A text button with an outline; the highlighted one is filled. Used for the
// transport keys and dialog choices.
Rectangle {
    id: button

    property string text
    // "plus" or "minus": drawn as bars rather than a glyph, so it stays crisp and sized
    property string symbol: ""
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

    Item {
        visible: button.symbol.length > 0
        anchors.centerIn: parent
        width: 26
        height: 26
        Rectangle {
            anchors.centerIn: parent
            width: parent.width
            height: 4
            radius: 2
            color: button.highlighted ? Style.textOnAccent : button.tone
        }
        Rectangle {
            visible: button.symbol === "plus"
            anchors.centerIn: parent
            width: 4
            height: parent.height
            radius: 2
            color: button.highlighted ? Style.textOnAccent : button.tone
        }
    }

    PrefsLabel {
        id: label
        visible: button.symbol.length === 0
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
