import QtQuick
import Style 1.0

// The battery bar in the footer. The fill follows the charge and its colour the
// state: the ride-mode colour normally, amber below 30 %, red below 15 %. While
// charging a light sweep runs along it. Plain QML, so it draws on any renderer.
Rectangle {
    id: root

    property int value: 0
    property bool charging: false
    property color fillColor: Style.accent

    readonly property color stateColor: value < 15 ? Style.danger : value < 30 ? Style.warning : fillColor

    implicitWidth: 200
    implicitHeight: 18
    radius: height / 2
    color: Style.surfaceSunken
    border.color: Style.border
    border.width: 1
    clip: true

    Rectangle {
        id: fill
        x: 2
        y: 2
        height: parent.height - 4
        radius: height / 2
        width: Math.max(height, (parent.width - 4) * root.value / 100)
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Qt.darker(root.stateColor, 1.25) }
            GradientStop { position: 1.0; color: root.stateColor }
        }
        Behavior on width { NumberAnimation { duration: Style.motion.theme; easing.type: Easing.OutCubic } }

        Rectangle {
            id: sweep
            visible: root.charging
            width: parent.height * 3
            height: parent.height
            radius: height / 2
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#00FFFFFF" }
                GradientStop { position: 0.5; color: "#88FFFFFF" }
                GradientStop { position: 1.0; color: "#00FFFFFF" }
            }
            NumberAnimation on x {
                running: root.charging
                loops: Animation.Infinite
                from: -sweep.width
                to: fill.width
                duration: 1600
            }
        }
    }
}
