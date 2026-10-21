import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Style 1.0
import "../Component"

// The phone: the call in progress when there is one, otherwise favourites and the
// recent calls, with the dial pad one tap away.
EaglePage {
    id: root

    readonly property bool inCall: phone.callState === 2 || phone.callState === 3

    Component {
        id: keypad
        Keypad {}
    }

    component RoundAction: ColumnLayout {
        id: action
        property string icon
        property string label
        property color tone: Style.surfaceRaised
        property color iconTone: "transparent"
        property bool checked: false
        signal clicked()
        spacing: 10
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 110
            Layout.preferredHeight: 110
            radius: 55
            color: action.checked ? Style.accent : action.tone
            border.color: Style.border
            Behavior on color { ColorAnimation { duration: Style.motion.fast } }
            Image {
                anchors.centerIn: parent
                source: action.icon
            }
            TapHandler { onTapped: action.clicked() }
        }
        PrefsLabel {
            Layout.alignment: Qt.AlignHCenter
            font.pixelSize: Style.h5
            color: Style.textMuted
            text: action.label
        }
    }

    // The call in progress.
    ColumnLayout {
        anchors.centerIn: parent
        spacing: 28
        visible: root.inCall
        opacity: root.inCall ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Style.motion.normal } }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 180
            Layout.preferredHeight: 180
            radius: 90
            color: Style.accentSoft
            PrefsLabel {
                anchors.centerIn: parent
                font.pixelSize: 80
                isBold: true
                color: Style.accentStrong
                text: (phone.callerName || "?").charAt(0)
            }
        }
        PrefsLabel {
            Layout.alignment: Qt.AlignHCenter
            font.pixelSize: 44
            isBold: true
            text: phone.callerName
        }
        PrefsLabel {
            Layout.alignment: Qt.AlignHCenter
            font.pixelSize: Style.h2
            color: phone.callState === 3 ? Style.success : Style.textMuted
            text: phone.callState === 2 ? qsTr("Calling…") : phone.formatDuration(phone.callSeconds)
        }
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 20
            spacing: 70
            RoundAction {
                icon: "qrc:/Icons/calling/eva_keypad-fill.svg"
                label: qsTr("Keypad")
                onClicked: root.gEagleStack.push(keypad)
            }
            RoundAction {
                icon: "qrc:/Icons/calling/bi_mic-mute-fill.svg"
                label: phone.muted ? qsTr("Muted") : qsTr("Mute")
                checked: phone.muted
                onClicked: phone.toggleMute()
            }
            RoundAction {
                icon: "qrc:/Icons/calling/calling.svg"
                label: qsTr("End")
                tone: Style.danger
                onClicked: phone.hangUp()
            }
        }
    }

    // No call: favourites and recents.
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Style.metrics.pageMargin
        anchors.rightMargin: Style.metrics.pageMargin
        anchors.topMargin: 40
        anchors.bottomMargin: 30
        spacing: 60
        visible: !root.inCall

        ColumnLayout {
            Layout.preferredWidth: parent.width * 0.42
            Layout.fillHeight: true
            spacing: 20

            RowLayout {
                PrefsLabel {
                    font.pixelSize: Style.h1
                    isBold: true
                    text: qsTr("Favourites")
                }
                Item { Layout.fillWidth: true }
                PrefsLabel {
                    font.pixelSize: Style.h5
                    color: phone.connected ? Style.success : Style.textMuted
                    text: phone.connected ? qsTr("%1 · %2% battery").arg(phone.deviceName).arg(phone.phoneBattery)
                                          : qsTr("No phone connected")
                }
            }
            GridLayout {
                columns: 2
                columnSpacing: 20
                rowSpacing: 20
                Repeater {
                    model: phone.contacts.filter(c => c.favourite)
                    Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 110
                        radius: Style.metrics.radiusLg
                        color: Style.surface
                        border.color: Style.border
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 18
                            spacing: 16
                            Rectangle {
                                Layout.preferredWidth: 70
                                Layout.preferredHeight: 70
                                radius: 35
                                color: Style.accentSoft
                                PrefsLabel {
                                    anchors.centerIn: parent
                                    isBold: true
                                    color: Style.accentStrong
                                    text: modelData.name.charAt(0)
                                }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                PrefsLabel { isBold: true; text: modelData.name }
                                PrefsLabel { font.pixelSize: Style.h6; color: Style.textMuted; text: modelData.number }
                            }
                        }
                        TapHandler { onTapped: phone.dial(modelData.number) }
                    }
                }
            }
            Item { Layout.fillHeight: true }
            Rectangle {
                Layout.preferredWidth: 280
                Layout.preferredHeight: 70
                radius: 35
                color: Style.accent
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 12
                    Image { source: "qrc:/Icons/calling/eva_keypad-fill.svg" }
                    PrefsLabel { isBold: true; color: Style.textOnAccent; text: qsTr("Dial pad") }
                }
                TapHandler { onTapped: root.gEagleStack.push(keypad) }
            }
        }

        Rectangle {
            Layout.preferredWidth: 2
            Layout.fillHeight: true
            color: Style.border
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 16

            PrefsLabel {
                font.pixelSize: Style.h1
                isBold: true
                text: qsTr("Recent calls")
            }
            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 6
                model: phone.recents
                add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Style.motion.normal } }
                delegate: Rectangle {
                    required property var modelData
                    width: ListView.view.width
                    height: 84
                    radius: Style.metrics.radiusMd
                    color: Style.surface
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 20
                        anchors.rightMargin: 20
                        spacing: 16
                        PrefsLabel {
                            Layout.preferredWidth: 40
                            font.pixelSize: Style.h2
                            color: modelData.kind === "missed" ? Style.danger : Style.textMuted
                            text: modelData.kind === "outgoing" ? "↗" : modelData.kind === "missed" ? "↙" : "↙"
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            PrefsLabel {
                                isBold: true
                                color: modelData.kind === "missed" ? Style.danger : Style.textPrimary
                                text: modelData.name
                            }
                            PrefsLabel {
                                font.pixelSize: Style.h6
                                color: Style.textMuted
                                text: modelData.kind === "missed" ? qsTr("Missed") : modelData.kind === "outgoing" ? qsTr("Outgoing") : qsTr("Incoming")
                            }
                        }
                        PrefsLabel { font.pixelSize: Style.h5; color: Style.textMuted; text: modelData.time }
                    }
                    TapHandler { onTapped: phone.dial(modelData.number) }
                }
            }
        }
    }
}
