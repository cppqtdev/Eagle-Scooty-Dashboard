import QtQuick
import QtQuick.Controls
import Style 1.0

Button {
    id: control

    property string setIcon: ""
    property string setIconText: ""
    property color setIconColor: Style.textPrimary
    property color iconBackground: "transparent"
    property real setIconSize: 25
    property real radius: height / 2
    property real iconWidth: 28
    property real iconHeight: 28
    property bool isMirror: false
    property bool isGlow: false
    property bool roundIcon: false
    property alias iconSource: iconSource
    property alias roundIconSource: roundIconSource

    implicitHeight: Style.metrics.touchTarget
    implicitWidth: Style.metrics.touchTarget
    hoverEnabled: true

    contentItem: Item {
        Image {
            id: iconSource
            visible: !control.roundIcon && control.setIconText.length === 0
            mirror: control.isMirror
            anchors.centerIn: parent
            source: control.setIcon
            opacity: control.enabled ? 1 : 0.4
            scale: control.down ? 0.9 : 1
            Behavior on scale { NumberAnimation { duration: Style.motion.fast } }
        }

        Image {
            id: roundIconSource
            visible: control.roundIcon && control.setIconText.length === 0
            mirror: control.isMirror
            sourceSize: Qt.size(control.iconWidth, control.iconHeight)
            anchors.centerIn: parent
            source: control.setIcon
            opacity: control.enabled ? 1 : 0.4
            scale: control.down ? 0.9 : 1
            Behavior on scale { NumberAnimation { duration: Style.motion.fast } }
        }

        PrefsLabel {
            visible: control.setIconText.length > 0
            anchors.centerIn: parent
            text: control.setIconText
            color: control.setIconColor
            font.pixelSize: control.setIconSize
            isBold: true
        }
    }

    background: Rectangle {
        radius: control.radius
        color: control.down ? Qt.darker(control.iconBackground, 1.12)
                            : control.hovered && control.iconBackground !== "transparent"
                              ? Qt.lighter(control.iconBackground, 1.08)
                              : control.iconBackground
        border.width: control.activeFocus ? 2 : 0
        border.color: Style.accentStrong
        Behavior on color { ColorAnimation { duration: Style.motion.fast } }
    }
}
