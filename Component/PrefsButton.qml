import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Style 1.0

Button {
    id: control

    property real radius: Style.metrics.radiusMd
    property color backgroundColor: Style.accent
    property string setIcon: ""
    property color textColor: Style.textOnAccent
    property real borderWidth: 0
    property color borderColor: Style.border
    property real iconFactor: 0.8
    property bool mirror: false

    implicitWidth: Style.metrics.touchTarget
    implicitHeight: Style.metrics.touchTarget
    hoverEnabled: true

    contentItem: RowLayout {
        spacing: Style.metrics.spacingSm

        Image {
            visible: control.setIcon.length > 0
            Layout.alignment: Qt.AlignCenter
            sourceSize: Qt.size(control.implicitWidth * control.iconFactor,
                                control.implicitHeight * control.iconFactor)
            source: control.setIcon
            mirror: control.mirror
            opacity: control.enabled ? 1 : 0.45
            scale: control.down ? 0.94 : 1

            Behavior on scale {
                NumberAnimation { duration: Style.motion.fast; easing.type: Style.motion.easeOut }
            }
        }

        PrefsLabel {
            visible: control.text.length > 0
            Layout.alignment: Qt.AlignCenter
            font.pixelSize: Style.h3
            text: control.text
            color: control.textColor
        }
    }

    background: Rectangle {
        radius: control.radius
        color: control.down ? Qt.darker(control.backgroundColor, 1.12)
                            : control.hovered ? Qt.lighter(control.backgroundColor, 1.06)
                                              : control.backgroundColor
        border.width: control.activeFocus ? Math.max(2, control.borderWidth) : control.borderWidth
        border.color: control.activeFocus ? Style.accentStrong : control.borderColor
        opacity: control.enabled ? 1 : 0.45

        Behavior on color {
            ColorAnimation { duration: Style.motion.fast }
        }
    }
}
