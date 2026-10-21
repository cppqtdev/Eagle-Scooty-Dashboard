import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Style 1.0
import "../Component"

// Dial pad: digits into the field, backspace on the red key, call on the green.
EaglePage {
    id: root

    header: RowLayout {
        width: root.width
        spacing: 15
        Item { Layout.preferredWidth: 40 }
        IconButton {
            roundIcon: true
            iconWidth: 50
            iconHeight: 50
            setIcon: "qrc:/Icons/topIcons/icn_leftindicator.svg"
            onClicked: root.gEagleStack.pop()
        }
        PrefsLabel {
            font.pixelSize: Style.h2
            isStyle: true
            text: qsTr("Back")
        }
        Item { Layout.fillWidth: true }
    }

    component Key: Rectangle {
        id: key
        property string label
        property string icon
        property color tone: Style.surface
        signal pressed()
        implicitWidth: 150
        implicitHeight: 96
        radius: 20
        color: tap.pressed ? Qt.darker(tone, 1.15) : tone
        border.color: Style.border
        Behavior on color { ColorAnimation { duration: Style.motion.instant } }
        PrefsLabel {
            anchors.centerIn: parent
            visible: key.label.length > 0
            font.pixelSize: Style.typography.display + 8
            isBold: true
            text: key.label
        }
        Image {
            anchors.centerIn: parent
            visible: key.icon.length > 0
            source: key.icon
        }
        TapHandler { id: tap; onTapped: key.pressed() }
    }

    Rectangle {
        anchors.centerIn: parent
        width: 620
        height: 640
        radius: 24
        color: Style.accentSoft

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 22

            TextFieldInput {
                id: inputField
                Layout.preferredWidth: 520
                implicitHeight: 64
                isBold: true
                readOnly: true
                horizontalAlignment: Text.AlignHCenter
                placeholderText: qsTr("Enter a number")
                radius: 10
                borderColor: Style.accent
            }

            GridLayout {
                Layout.alignment: Qt.AlignHCenter
                columns: 3
                columnSpacing: 18
                rowSpacing: 16
                Repeater {
                    model: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "+", "0", "#"]
                    Key {
                        required property string modelData
                        label: modelData
                        onPressed: if (inputField.text.length < 16) inputField.text += modelData
                    }
                }
                Key {
                    icon: "qrc:/Icons/cross.svg"
                    tone: Style.danger
                    onPressed: inputField.text = inputField.text.slice(0, -1)
                }
                Item { implicitWidth: 150; implicitHeight: 96 }
                Key {
                    icon: "qrc:/Icons/call.svg"
                    tone: Style.success
                    onPressed: {
                        phone.dial(inputField.text)
                        if (phone.callState !== 0)
                            root.gEagleStack.pop()
                    }
                }
            }
        }
    }
}
