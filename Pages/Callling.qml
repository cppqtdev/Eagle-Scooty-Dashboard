import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Style 1.0
import "../Component"

// The phone, in the SR Motard style: recent calls as a list with each row's kind
// and time on the right, the phone and favourites beside it; during a call the
// caller and timer large, with keypad, mute and end.
EaglePage {
    id: root

    readonly property bool inCall: phone.callState === 2 || phone.callState === 3

    Component {
        id: keypad
        Keypad {}
    }

    function kindText(kind) {
        return kind === "missed" ? qsTr("Missed") : kind === "outgoing" ? qsTr("Outgoing") : qsTr("Incoming")
    }
    function kindTone(kind) {
        return kind === "missed" ? Style.danger : kind === "outgoing" ? Style.textSecondary : Style.success
    }

    leftPadding: Style.metrics.pageMargin
    rightPadding: Style.metrics.pageMargin
    topPadding: 24
    bottomPadding: 24

    contentItem: Item {
    // No call: recent calls, the phone and favourites.
    RowLayout {
        anchors.fill: parent
        spacing: 28
        visible: !root.inCall

        Panel {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 28
                spacing: 16

                RowLayout {
                    spacing: 16
                    Image { sourceSize: Qt.size(34, 34); source: "qrc:/Icons/bottomIcons/phone.svg" }
                    PrefsLabel {
                        font.pixelSize: Style.h1
                        isBold: true
                        font.letterSpacing: 2
                        text: qsTr("RECENT CALLS")
                    }
                }
                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 2; color: Style.accent }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 10
                    model: phone.recents
                    add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Style.motion.normal } }
                    delegate: InfoRow {
                        required property var modelData
                        required property int index
                        width: ListView.view.width
                        title: modelData.name
                        tone: root.kindTone(modelData.kind)
                        value: qsTr("%1 %2").arg(root.kindText(modelData.kind)).arg(modelData.time)
                        selected: index === 0
                        onClicked: phone.dial(modelData.number || modelData.name)
                    }
                }
                Caption {
                    Layout.alignment: Qt.AlignHCenter
                    font.pixelSize: 14
                    text: qsTr("Tap a call to call back")
                }
            }
        }

        ColumnLayout {
            Layout.preferredWidth: 620
            Layout.fillWidth: false   // a child filling would otherwise make the column grab the row
            Layout.fillHeight: true
            spacing: 18

            Panel {
                Layout.fillWidth: true
                Layout.preferredHeight: 150
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 6
                    Caption { accent: phone.connected; text: phone.connected ? qsTr("Bluetooth · connected") : qsTr("Bluetooth · no phone") }
                    PrefsLabel { font.pixelSize: Style.typography.display; isBold: true; text: phone.connected ? phone.deviceName : qsTr("Pair a phone in Settings") }
                    PrefsLabel {
                        visible: phone.connected
                        font.pixelSize: Style.h5
                        color: Style.textMuted
                        text: qsTr("Battery %1% · signal %2 of 4").arg(phone.phoneBattery).arg(phone.signalBars)
                    }
                }
            }

            Caption { text: qsTr("Favourites") }
            Repeater {
                model: phone.contacts.filter(c => c.favourite)
                InfoRow {
                    required property var modelData
                    Layout.fillWidth: true
                    title: modelData.name
                    subtitle: modelData.number
                    showEdge: false
                    value: qsTr("Call")
                    valueColor: Style.success
                    onClicked: phone.dial(modelData.number || modelData.name)
                }
            }
            Item { Layout.fillHeight: true }
            OutlineButton {
                Layout.fillWidth: true
                highlighted: true
                text: qsTr("Dial pad")
                onClicked: root.gEagleStack.push(keypad)
            }
        }
    }

        // The call in progress.
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 22
            visible: opacity > 0
            opacity: root.inCall ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Style.motion.normal } }

            Caption {
                Layout.alignment: Qt.AlignHCenter
                accent: true
                text: phone.callState === 2 ? qsTr("Calling") : phone.muted ? qsTr("On call · muted") : qsTr("On call")
            }
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 170
                Layout.preferredHeight: 170
                radius: 85
                color: Style.alpha(Style.success, 0.14)
                border.color: Style.success
                border.width: 3
                PrefsLabel {
                    anchors.centerIn: parent
                    font.pixelSize: 72
                    isBold: true
                    color: Style.success
                    text: (phone.callerName || "?").charAt(0).toUpperCase()
                }
            }
            PrefsLabel {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 640
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 54
                isBold: true
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
                text: phone.callerName
            }
            DigitText {
                Layout.alignment: Qt.AlignHCenter
                pixelSize: 44
                isBold: true
                color: phone.callState === 3 ? Style.success : Style.textMuted
                text: phone.callState === 2 ? qsTr("…") : phone.formatDuration(phone.callSeconds)
            }
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 16
                spacing: 24
                OutlineButton { text: qsTr("Keypad"); onClicked: root.gEagleStack.push(keypad) }
                OutlineButton { text: phone.muted ? qsTr("Unmute") : qsTr("Mute"); highlighted: phone.muted; onClicked: phone.toggleMute() }
                OutlineButton { text: qsTr("End"); highlighted: true; tone: Style.danger; onClicked: phone.hangUp() }
            }
        }
    }
}
