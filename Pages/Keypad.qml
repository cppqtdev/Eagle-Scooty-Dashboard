import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Style 1.0
import "../Component"

// The dial pad: the number large, keys with their letters, call and backspace;
// contacts alongside to call by name.
EaglePage {
    id: root

    property string number: ""

    function press(key) {
        if (number.length < 16)
            number += key
    }
    function call(value) {
        phone.dial(value)
        if (phone.callState !== 0)
            root.gEagleStack.pop()
    }

    leftPadding: Style.metrics.pageMargin
    rightPadding: Style.metrics.pageMargin
    topPadding: 20
    bottomPadding: 24

    component Key: Rectangle {
        id: key
        property string digit
        property string letters
        signal pressed()
        implicitWidth: 200
        implicitHeight: 96
        radius: 18
        color: tap.pressed ? Style.accentSoft : Style.surfaceSunken
        border.color: tap.pressed ? Style.accent : "transparent"
        border.width: 2
        scale: tap.pressed ? 0.96 : 1
        Behavior on color { ColorAnimation { duration: Style.motion.instant } }
        Behavior on scale { NumberAnimation { duration: Style.motion.fast } }
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 2
            PrefsLabel { Layout.alignment: Qt.AlignHCenter; font.pixelSize: 40; isBold: true; text: key.digit }
            Caption { Layout.alignment: Qt.AlignHCenter; font.pixelSize: 13; text: key.letters; visible: key.letters.length > 0 }
        }
        TapHandler { id: tap; onTapped: key.pressed() }
    }

    contentItem: RowLayout {
        spacing: 28

        Panel {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 28
                spacing: 16

                RowLayout {
                    OutlineButton { text: qsTr("Back"); onClicked: root.gEagleStack.pop() }
                    Item { Layout.fillWidth: true }
                    Caption { text: phone.connected ? qsTr("Calling from %1").arg(phone.deviceName) : qsTr("No phone connected") }
                }

                // The number.
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 96
                    radius: 18
                    color: Style.background
                    border.color: Style.border
                    PrefsLabel {
                        anchors.centerIn: parent
                        font.pixelSize: root.number.length > 0 ? 50 : Style.h3
                        isBold: root.number.length > 0
                        color: root.number.length > 0 ? Style.textPrimary : Style.textMuted
                        text: root.number.length > 0 ? root.number : qsTr("Enter a number")
                    }
                }

                GridLayout {
                    Layout.alignment: Qt.AlignHCenter
                    columns: 3
                    columnSpacing: 16
                    rowSpacing: 12
                    Repeater {
                        model: [["1", ""], ["2", "ABC"], ["3", "DEF"], ["4", "GHI"], ["5", "JKL"], ["6", "MNO"],
                                ["7", "PQRS"], ["8", "TUV"], ["9", "WXYZ"], ["*", ""], ["0", "+"], ["#", ""]]
                        Key {
                            required property var modelData
                            digit: modelData[0]
                            letters: modelData[1]
                            onPressed: root.press(modelData[0])
                        }
                    }
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 16
                    OutlineButton {
                        implicitWidth: 200
                        implicitHeight: 80
                        text: "⌫"
                        enabled: root.number.length > 0
                        opacity: enabled ? 1 : 0.4
                        onClicked: root.number = root.number.slice(0, -1)
                    }
                    OutlineButton {
                        implicitWidth: 416
                        implicitHeight: 80
                        highlighted: true
                        tone: Style.success
                        text: qsTr("Call")
                        enabled: root.number.length > 0 && phone.connected
                        opacity: enabled ? 1 : 0.5
                        onClicked: root.call(root.number)
                    }
                }
            }
        }

        Panel {
            Layout.preferredWidth: 620
            Layout.fillHeight: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 28
                spacing: 12
                Caption { text: qsTr("Contacts") }
                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 8
                    model: phone.contacts.filter(c => root.number.length === 0
                                                 || c.number.replace(/\s/g, "").indexOf(root.number) >= 0)
                    delegate: InfoRow {
                        required property var modelData
                        width: ListView.view.width
                        title: modelData.name
                        subtitle: modelData.number
                        showEdge: false
                        value: qsTr("Call")
                        valueColor: Style.success
                        onClicked: root.call(modelData.number)
                    }
                }
            }
        }
    }
}
