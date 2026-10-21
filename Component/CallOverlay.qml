import QtQuick
import QtQuick.Layouts
import Style 1.0

// Calls over any page: an incoming call slides up with answer and decline; a call
// in progress shrinks to a pill with the timer, unless the phone page is open.
Item {
    id: root

    property bool phonePageOpen: false
    signal openPhone()

    readonly property bool incoming: phone.callState === 1
    readonly property bool inCall: phone.callState === 2 || phone.callState === 3

    // Incoming call.
    Rectangle {
        id: ringCard
        anchors.horizontalCenter: parent.horizontalCenter
        width: 900
        height: 150
        radius: 75
        y: root.incoming ? parent.height - height - 170 : parent.height + 40
        color: Style.surface
        border.color: Style.success
        border.width: 3
        Behavior on y { NumberAnimation { duration: Style.motion.theme; easing.type: Easing.OutBack } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 30
            anchors.rightMargin: 30
            spacing: 24

            Rectangle {
                Layout.preferredWidth: 96
                Layout.preferredHeight: 96
                radius: 48
                color: Style.accentSoft
                PrefsLabel {
                    anchors.centerIn: parent
                    font.pixelSize: Style.h1
                    isBold: true
                    color: Style.accentStrong
                    text: (phone.callerName || "?").charAt(0)
                }
                // Ringing pulse.
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                    radius: width / 2
                    color: "transparent"
                    border.color: Style.success
                    border.width: 3
                    SequentialAnimation on scale {
                        running: root.incoming
                        loops: Animation.Infinite
                        NumberAnimation { from: 1; to: 1.35; duration: 900 }
                    }
                    SequentialAnimation on opacity {
                        running: root.incoming
                        loops: Animation.Infinite
                        NumberAnimation { from: 0.9; to: 0; duration: 900 }
                    }
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                PrefsLabel {
                    font.pixelSize: Style.h1
                    isBold: true
                    text: phone.callerName
                }
                PrefsLabel {
                    font.pixelSize: Style.h5
                    color: Style.textMuted
                    text: qsTr("Incoming call · %1").arg(phone.callerNumber)
                }
            }
            Rectangle {
                Layout.preferredWidth: 96
                Layout.preferredHeight: 96
                radius: 48
                color: Style.danger
                Image {
                    anchors.centerIn: parent
                    rotation: 135
                    source: "qrc:/Icons/call.svg"
                }
                TapHandler { onTapped: phone.decline() }
            }
            Rectangle {
                Layout.preferredWidth: 96
                Layout.preferredHeight: 96
                radius: 48
                color: Style.success
                Image {
                    anchors.centerIn: parent
                    source: "qrc:/Icons/call.svg"
                }
                TapHandler { onTapped: phone.answer() }
            }
        }
    }

    // Call in progress, away from the phone page.
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 150
        width: pillRow.implicitWidth + 48
        height: 60
        radius: 30
        color: Style.success
        opacity: root.inCall && !root.phonePageOpen ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Style.motion.normal } }

        RowLayout {
            id: pillRow
            anchors.centerIn: parent
            spacing: 14
            Image { source: "qrc:/Icons/call.svg" }
            PrefsLabel {
                font.pixelSize: Style.h4
                isBold: true
                color: "#FFFFFF"
                text: phone.callState === 2 ? qsTr("Calling %1…").arg(phone.callerName)
                                            : qsTr("%1 · %2").arg(phone.callerName).arg(phone.formatDuration(phone.callSeconds))
            }
        }
        TapHandler { onTapped: root.openPhone() }
    }
}
