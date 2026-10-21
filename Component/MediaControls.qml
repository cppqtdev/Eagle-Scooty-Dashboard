import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Style 1.0

// Previous, play or pause, next, and a level meter, driven by one value:
// phone.playerState. Each state below says everything the controls look like
// in it (the State pattern, as QML spells it), so the icon, the emphasis, what
// can be pressed and whether the meter moves always change together and never
// disagree, whatever order the phone's updates arrive in.
Control {
    id: root

    property color tone: Style.accent
    property int diameter: 84            // the middle key; the others are smaller
    property bool showMeter: true

    // The look of the current state; only the states below set these.
    property string playIcon: "play"
    property bool canSkip: false
    property bool meterRunning: false
    property real meterOpacity: 0.3

    state: phone.playerState === 2 ? "playing" : phone.playerState === 1 ? "paused" : "noSource"
    states: [
        State {
            name: "noSource"
            PropertyChanges { target: root; playIcon: "play"; canSkip: false; meterRunning: false; meterOpacity: 0.15 }
            PropertyChanges { target: playKey; enabled: false; highlighted: false }
        },
        State {
            name: "paused"
            PropertyChanges { target: root; playIcon: "play"; canSkip: true; meterRunning: false; meterOpacity: 0.35 }
            PropertyChanges { target: playKey; enabled: true; highlighted: true }
        },
        State {
            name: "playing"
            PropertyChanges { target: root; playIcon: "pause"; canSkip: true; meterRunning: true; meterOpacity: 1 }
            PropertyChanges { target: playKey; enabled: true; highlighted: true }
        }
    ]
    transitions: Transition {
        NumberAnimation { property: "meterOpacity"; duration: Style.motion.normal }
    }

    contentItem: ColumnLayout {
        spacing: 14

        // A level meter that moves while music plays.
        Row {
            visible: root.showMeter
            Layout.alignment: Qt.AlignHCenter
            spacing: 5
            opacity: root.meterOpacity
            Repeater {
                model: 15
                Rectangle {
                    id: bar
                    required property int index
                    readonly property real rest: 10 + 18 * Math.abs(Math.sin(index * 1.7))
                    anchors.verticalCenter: parent.verticalCenter
                    width: 4
                    height: rest
                    radius: 2
                    color: root.tone
                    SequentialAnimation on height {
                        running: root.meterRunning
                        loops: Animation.Infinite
                        NumberAnimation { to: bar.rest * 0.4; duration: 260 + (bar.index % 4) * 70; easing.type: Easing.InOutSine }
                        NumberAnimation { to: bar.rest * 1.4; duration: 300 + (bar.index % 3) * 60; easing.type: Easing.InOutSine }
                    }
                }
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 26
            RoundIconButton {
                diameter: Math.round(root.diameter * 0.72)
                iconName: "previous"
                enabled: root.canSkip
                opacity: enabled ? 1 : 0.35
                onClicked: phone.previous()
            }
            RoundIconButton {
                id: playKey
                diameter: root.diameter
                iconName: root.playIcon
                tone: root.tone
                opacity: enabled ? 1 : 0.35
                onClicked: phone.playPause()
            }
            RoundIconButton {
                diameter: Math.round(root.diameter * 0.72)
                iconName: "next"
                enabled: root.canSkip
                opacity: enabled ? 1 : 0.35
                onClicked: phone.next()
            }
        }
    }
}
