import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Style 1.0

// A text button with an outline; the highlighted one is filled. Used for the
// transport keys and dialog choices. Its width follows the label plus padding.
AbstractButton {
    id: button

    // "plus" or "minus": drawn as bars rather than a glyph, so it stays crisp and sized
    property string symbol: ""
    property bool highlighted: false
    property color tone: Style.accent

    leftPadding: 28
    rightPadding: 28
    implicitWidth: symbol.length > 0 ? 90 : Math.max(150, implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: 64
    scale: pressed ? 0.96 : 1
    Behavior on scale { NumberAnimation { duration: Style.motion.fast } }

    background: Rectangle {
        radius: 14
        color: button.highlighted ? button.tone : button.pressed ? Style.surfaceSunken : "transparent"
        border.color: button.highlighted ? button.tone : Style.borderStrong
        border.width: 2
        Behavior on color { ColorAnimation { duration: Style.motion.instant } }
    }

    contentItem: Item {
        implicitWidth: button.symbol.length > 0 ? 26 : label.implicitWidth
        implicitHeight: label.implicitHeight

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
            width: parent.width
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: Style.h5
            font.letterSpacing: 2
            font.capitalization: Font.AllUppercase
            isBold: true
            elide: Text.ElideRight
            wrapMode: Text.NoWrap
            color: button.highlighted ? Style.textOnAccent : Style.textPrimary
            text: button.text
        }
    }
}
