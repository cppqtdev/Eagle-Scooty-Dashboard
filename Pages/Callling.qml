import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Style 1.0
import "../Component"

// The phone: its status and the tabs (recents, favourites, contacts, dial pad)
// on a rail at the left, the chosen list on the right; during a call the caller
// and timer large, with keypad, mute and end.
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

    property int tab: 0
    readonly property var tabs: [
        { icon: "recents", title: qsTr("Recents"), value: phone.recents.length > 0 ? String(phone.recents.length) : "" },
        { icon: "favourites", title: qsTr("Favourites"), value: String(phone.contacts.filter(c => c.favourite).length) },
        { icon: "contacts", title: qsTr("Contacts"), value: String(phone.contacts.length) },
        { icon: "dialpad", title: qsTr("Dial pad"), value: "" }
    ]
    readonly property var rows: tab === 0 ? phone.recents
                               : tab === 1 ? phone.contacts.filter(c => c.favourite)
                               : phone.contacts.slice().sort((a, b) => a.name.localeCompare(b.name))

    contentItem: Item {
    // No call: the phone and its tabs on the left, the chosen list on the right.
    RowLayout {
        anchors.fill: parent
        spacing: 28
        visible: !root.inCall

        Panel {
            Layout.preferredWidth: 480
            Layout.fillWidth: false
            Layout.fillHeight: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 18

                // The phone.
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16
                    Rectangle {
                        Layout.preferredWidth: 60
                        Layout.preferredHeight: 60
                        radius: 30
                        color: Style.alpha(phone.connected ? Style.success : Style.textMuted, 0.16)
                        border.color: Style.alpha(phone.connected ? Style.success : Style.textMuted, 0.5)
                        LineIcon {
                            anchors.centerIn: parent
                            name: "phone"
                            size: 28
                            color: phone.connected ? Style.success : Style.textMuted
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Caption { Layout.fillWidth: true; elide: Text.ElideRight; accent: phone.connected; text: phone.connected ? qsTr("Connected") : qsTr("No phone") }
                        PrefsLabel {
                            Layout.fillWidth: true
                            font.pixelSize: Style.h3
                            isBold: true
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                            text: phone.connected ? phone.deviceName : qsTr("Pair one in Settings")
                        }
                        PrefsLabel {
                            Layout.fillWidth: true
                            visible: phone.connected
                            font.pixelSize: Style.h6
                            color: Style.textMuted
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                            text: qsTr("Battery %1% · signal %2 of 4").arg(phone.phoneBattery).arg(phone.signalBars)
                        }
                    }
                }
                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Style.border }

                TabRail {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: root.tabs
                    currentIndex: root.tab
                    // The dial pad opens over the page; the others switch the list.
                    onActivated: index => index === 3 ? root.gEagleStack.push(keypad) : root.tab = index
                }
            }
        }

        Panel {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 28
                spacing: 14

                RowLayout {
                    Layout.fillWidth: true
                    PrefsLabel {
                        Layout.fillWidth: true
                        font.pixelSize: Style.h1
                        isBold: true
                        elide: Text.ElideRight
                        wrapMode: Text.NoWrap
                        text: root.tabs[root.tab].title
                    }
                    Caption { text: root.tab === 0 ? qsTr("Tap to call back") : qsTr("Tap to call") }
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 8
                    boundsBehavior: Flickable.StopAtBounds
                    model: root.rows
                    ScrollBar.vertical: ScrollBar {}
                    delegate: InfoRow {
                        required property var modelData
                        width: ListView.view.width
                        title: modelData.name
                        subtitle: root.tab === 0 ? root.kindText(modelData.kind) + (modelData.number ? " · " + modelData.number : "")
                                                 : modelData.number
                        tone: root.tab === 0 ? root.kindTone(modelData.kind) : Style.success
                        value: root.tab === 0 ? modelData.time : qsTr("Call")
                        valueColor: root.tab === 0 ? Style.textMuted : Style.success
                        onClicked: phone.dial(modelData.number || modelData.name)
                    }
                }
                PrefsLabel {
                    visible: root.rows.length === 0
                    Layout.fillWidth: true
                    font.pixelSize: Style.h5
                    color: Style.textMuted
                    wrapMode: Text.WordWrap
                    text: root.tab === 0 ? qsTr("No calls yet.") : qsTr("No contacts from the phone yet.")
                }
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
                spacing: 48
                component Action: ColumnLayout {
                    property alias iconName: button.iconName
                    property alias highlighted: button.highlighted
                    property alias tone: button.tone
                    property string label
                    signal clicked()
                    spacing: 10
                    RoundIconButton { id: button; Layout.alignment: Qt.AlignHCenter; diameter: 88; onClicked: parent.clicked() }
                    Caption { Layout.alignment: Qt.AlignHCenter; text: parent.label }
                }
                Action { iconName: "dialpad"; label: qsTr("Keypad"); onClicked: root.gEagleStack.push(keypad) }
                Action { iconName: phone.muted ? "mute" : "mic"; label: phone.muted ? qsTr("Unmute") : qsTr("Mute"); highlighted: phone.muted; onClicked: phone.toggleMute() }
                Action { iconName: "endcall"; label: qsTr("End"); highlighted: true; tone: Style.danger; onClicked: phone.hangUp() }
            }
        }
    }
}
