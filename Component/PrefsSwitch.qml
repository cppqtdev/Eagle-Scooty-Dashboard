import QtQuick
import QtQuick.Controls
import Style 1.0

Switch {
    id: control

    property color backgroundColor: Style.accent

    spacing: Style.metrics.spacingMd
    hoverEnabled: true

    indicator: Rectangle {
        implicitHeight: 32
        implicitWidth: 56
        x: control.leftPadding
        y: parent.height / 2 - height / 2
        radius: width / 2
        color: control.checked ? control.backgroundColor : Style.surfaceSunken
        border.width: control.activeFocus ? 2 : 1
        border.color: control.activeFocus ? Style.accentStrong : Style.borderStrong

        Behavior on color { ColorAnimation { duration: Style.motion.fast } }

        Rectangle {
            x: control.checked ? parent.width - width - 2 : 2
            width: 28
            height: 28
            radius: height / 2
            color: control.checked ? Style.textOnAccent : Style.textMuted
            anchors.verticalCenter: parent.verticalCenter

            Behavior on x {
                NumberAnimation { duration: Style.motion.fast; easing.type: Style.motion.easeInOut }
            }
        }
    }

    contentItem: PrefsLabel {
        font.pixelSize: Style.h2
        text: control.text
        verticalAlignment: Text.AlignVCenter
        leftPadding: control.indicator.width + control.spacing
    }
}
