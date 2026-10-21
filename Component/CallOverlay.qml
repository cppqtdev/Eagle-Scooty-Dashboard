import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Style 1.0

// Calls over any page: an incoming call slides up with answer and decline; a call
// in progress shrinks to a pill with the timer, unless the phone page is open.
// Both are Controls: padding and background follow the caller's name, which
// elides rather than pushing the buttons off the card.
Item {
    id: root

    property bool phonePageOpen: false
    signal openPhone()

    readonly property bool incoming: phone.callState === 1
    readonly property bool inCall: phone.callState === 2 || phone.callState === 3

    component RoundAction: AbstractButton {
        id: action
        focusPolicy: Qt.StrongFocus
        property color tone
        property real iconRotation: 0
        implicitWidth: 96
        implicitHeight: 96
        scale: pressed ? 0.98 : 1
        Behavior on scale { NumberAnimation { duration: Style.motion.fast } }
        background: Rectangle { radius: width / 2; color: action.tone }
        contentItem: Item {
            Image {
                anchors.centerIn: parent
                rotation: action.iconRotation
                source: "qrc:/Icons/call.svg"
            }
        }
    }

    // Incoming call.
    Control {
        id: ringCard
        anchors.horizontalCenter: parent.horizontalCenter
        width: 900
        y: root.incoming ? parent.height - height - 170 : parent.height + 40
        leftPadding: 27
        rightPadding: 27
        topPadding: 27
        bottomPadding: 27
        Behavior on y { NumberAnimation { duration: Style.motion.theme; easing.type: Easing.OutBack } }

        background: Rectangle {
            radius: height / 2
            color: Style.surface
            border.color: Style.success
            border.width: 3
        }

        contentItem: RowLayout {
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
                    text: (phone.callerName || "?").charAt(0).toUpperCase()
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
                    Layout.fillWidth: true
                    font.pixelSize: Style.h1
                    isBold: true
                    elide: Text.ElideRight
                    wrapMode: Text.NoWrap
                    text: phone.callerName
                }
                PrefsLabel {
                    Layout.fillWidth: true
                    font.pixelSize: Style.h5
                    color: Style.textMuted
                    elide: Text.ElideRight
                    wrapMode: Text.NoWrap
                    text: phone.callerNumber.length > 0 ? qsTr("Incoming call · %1").arg(phone.callerNumber)
                                                        : qsTr("Incoming call")
                }
            }
            RoundAction { tone: Style.danger; iconRotation: 135; onClicked: phone.decline() }
            RoundAction { tone: Style.success; onClicked: phone.answer() }
        }
    }

    // Call in progress, away from the phone page: name (elided past 420 px) and timer.
    AbstractButton {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 150
        implicitWidth: implicitContentWidth + leftPadding + rightPadding
        implicitHeight: 60
        leftPadding: 24
        rightPadding: 28
        opacity: root.inCall && !root.phonePageOpen ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Style.motion.normal } }
        onClicked: root.openPhone()

        background: Rectangle { radius: height / 2; color: Style.success }

        contentItem: RowLayout {
            spacing: 14
            Image { source: "qrc:/Icons/call.svg" }
            PrefsLabel {
                Layout.maximumWidth: 420
                font.pixelSize: Style.h4
                isBold: true
                color: "#FFFFFF"
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
                text: phone.callState === 2 ? qsTr("Calling %1…").arg(phone.callerName) : phone.callerName
            }
            DigitText {
                visible: phone.callState === 3
                pixelSize: Style.h4
                isBold: true
                color: "#FFFFFF"
                text: "· " + phone.formatDuration(phone.callSeconds)
            }
        }
    }
}
