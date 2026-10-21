import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Style 1.0

Button {
    id: control

    property real radius: Style.metrics.radiusSm
    property color backgroundColor: Style.accent
    property color smallBackgroundColor: "transparent"
    property string setIcon: ""
    property color textColor: Style.textOnAccent
    property real borderWidth: 0
    property color borderColor: Style.border
    property real iconWidth: 18
    property real iconHeight: 18

    implicitHeight: 45
    implicitWidth: 120
    hoverEnabled: true

    contentItem: RowLayout {
        spacing: Style.metrics.spacingSm

        Image {
            Layout.preferredWidth: control.iconWidth
            Layout.preferredHeight: control.iconHeight
            Layout.alignment: Qt.AlignVCenter
            sourceSize: Qt.size(control.iconWidth, control.iconHeight)
            source: control.setIcon
        }

        PrefsLabel {
            Layout.alignment: Qt.AlignVCenter
            color: control.textColor
            font.pixelSize: Style.paragraph
            text: control.text
        }
    }

    background: Rectangle {
        radius: control.radius
        color: control.down ? Qt.darker(control.backgroundColor, 1.12)
                            : control.hovered ? Qt.lighter(control.backgroundColor, 1.06)
                                              : control.backgroundColor
        border.width: control.activeFocus ? Math.max(2, control.borderWidth) : control.borderWidth
        border.color: control.activeFocus ? Style.accentStrong : control.borderColor
        Behavior on color { ColorAnimation { duration: Style.motion.fast } }
    }
}
