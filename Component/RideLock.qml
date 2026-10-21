import QtQuick
import QtQuick.Layouts
import Style 1.0

// Covers screens that need more than a glance (settings, documents, dialling)
// while the scooter is moving, as driver-distraction guidelines ask: the rider
// can still see where they are, but not operate them until they stop. It locks
// above 5 km/h and only unlocks below 2 km/h, so it does not flicker at walking
// pace.
Rectangle {
    id: root

    property bool armed: true
    property bool screenNeedsStop: false
    property bool moving: false

    readonly property int speed: dashboardData.speed
    onSpeedChanged: {
        if (speed > 5)
            moving = true
        else if (speed < 2)
            moving = false
    }

    readonly property bool locked: armed && screenNeedsStop && moving

    color: Style.alpha(Style.background, 0.9)
    opacity: locked ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: Style.motion.normal } }

    // Swallows touches while it is shown.
    MouseArea { anchors.fill: parent }

    Panel {
        anchors.centerIn: parent
        width: 720
        height: 300

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 18

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 72
                implicitHeight: 72
                radius: 36
                color: Style.alpha(Style.warning, 0.16)
                border.color: Style.warning
                border.width: 2
                // A pause sign: two bars.
                Row {
                    anchors.centerIn: parent
                    spacing: 10
                    Repeater {
                        model: 2
                        Rectangle { width: 9; height: 28; radius: 2; color: Style.warning }
                    }
                }
            }
            PrefsLabel {
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: Style.h2
                isBold: true
                text: qsTr("Available when stopped")
            }
            PrefsLabel {
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: Style.h5
                color: Style.textMuted
                text: simulator.running ? qsTr("Bench: press P to park and charge")
                                        : qsTr("Keep your eyes on the road")
            }
        }
    }
}
