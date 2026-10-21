import QtQuick
import QtQuick.Controls
import Style 1.0

// A round button with a line icon: the transport keys, call actions. The
// highlighted one is filled in its tone with a soft halo.
AbstractButton {
    id: button

    property string iconName
    property color tone: Style.accent
    property bool highlighted: false
    property int diameter: 76

    implicitWidth: diameter
    implicitHeight: diameter
    scale: pressed ? 0.94 : 1
    Behavior on scale { NumberAnimation { duration: Style.motion.fast } }

    background: Item {
        Rectangle {   // halo
            visible: button.highlighted
            anchors.centerIn: parent
            width: parent.width + 16
            height: width
            radius: width / 2
            color: Style.alpha(button.tone, 0.16)
        }
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: button.highlighted ? button.tone
                   : button.pressed ? Style.alpha(Style.textPrimary, 0.10) : Style.alpha(Style.textPrimary, 0.05)
            border.color: button.highlighted ? button.tone : Style.border
        }
    }

    contentItem: Item {
        LineIcon {
            anchors.centerIn: parent
            name: button.iconName
            size: Math.round(button.diameter * 0.4)
            strokeWidth: 2
            color: button.highlighted ? Style.textOnAccent : Style.textPrimary
        }
    }
}
