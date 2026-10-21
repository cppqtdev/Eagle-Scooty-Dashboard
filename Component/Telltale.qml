import QtQuick
import Style 1.0

// One lamp in the telltale strip. It is driven by the vehicle, never pressed: the
// rider sees state, and the lit glow image replaces the outline when it is on.
Item {
    id: root

    property string offSource
    property string onSource
    property bool active: false
    property bool blinking: false   // indicators: follow the shared blink phase
    property bool blinkPhase: true
    property real iconSize: 60

    readonly property bool lit: active && (!blinking || blinkPhase)

    implicitWidth: iconSize + 12
    implicitHeight: iconSize + 12

    Image {
        anchors.centerIn: parent
        sourceSize: Qt.size(root.iconSize, root.iconSize)
        source: root.offSource
        opacity: root.lit ? 0 : 0.55
        Behavior on opacity { NumberAnimation { duration: Style.motion.instant } }
    }

    Image {
        anchors.centerIn: parent
        sourceSize: Qt.size(root.iconSize, root.iconSize)
        source: root.onSource
        opacity: root.lit ? 1 : 0
        scale: root.lit ? 1 : 0.92
        Behavior on opacity { NumberAnimation { duration: Style.motion.instant } }
        Behavior on scale { NumberAnimation { duration: Style.motion.fast; easing.type: Easing.OutBack } }
    }
}
