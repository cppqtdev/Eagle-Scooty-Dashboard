import QtQuick 2.15
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3
import Style 1.0
import "../Component"

EaglePage {
    id:root
    width: parent.width

    Component{
        id:keypad
        Keypad{

        }
    }

    contentItem: ColumnLayout{
        width: parent.width

        Image{
            Layout.alignment: Qt.AlignHCenter
            source: "qrc:/Icons/image.png"
        }
        PrefsLabel{
            Layout.alignment: Qt.AlignHCenter
            font.pixelSize: Style.h4
            color: Style.grayColor
            text: qsTr("Jonathan")
        }

        PrefsLabel{
            Layout.alignment: Qt.AlignHCenter
            font.pixelSize: Style.paragraph
            color: Style.grayColor
            text: qsTr("Calling")
        }

        RowLayout{
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: root.width * 0.5
            Layout.maximumWidth: root.width * 0.5

            ColumnLayout{
                spacing: 10
                IconButton{
                    Layout.alignment: Qt.AlignHCenter
                    setIcon: "qrc:/Icons/calling/eva_keypad-fill.svg"
                    onClicked: gEagleStack.push(keypad)
                }
                PrefsLabel{
                    Layout.alignment: Qt.AlignHCenter
                    font.pixelSize: Style.paragraph
                    color: Style.grayColor
                    text: qsTr("Keypad")
                }
            }

            Item{
                Layout.fillWidth: true
            }

            Image{
                source: "qrc:/Icons/verticalLine.png"
            }
            Item{
                Layout.fillWidth: true
            }
            ColumnLayout{
                spacing: 10
                IconButton{
                    Layout.alignment: Qt.AlignHCenter
                    setIcon: "qrc:/Icons/calling/fluent_call-add-20-filled.svg"
                }
                PrefsLabel{
                    Layout.alignment: Qt.AlignHCenter
                    font.pixelSize: Style.paragraph
                    color: Style.grayColor
                    text: qsTr("Add Call")
                }
            }
            Item{
                Layout.fillWidth: true
            }
            Image{
                source: "qrc:/Icons/verticalLine.png"
            }
            Item{
                Layout.fillWidth: true
            }

            ColumnLayout{
                spacing: 10
                IconButton{
                    Layout.alignment: Qt.AlignHCenter
                    setIcon: "qrc:/Icons/calling/bi_mic-mute-fill.svg"
                }
                PrefsLabel{
                    Layout.alignment: Qt.AlignHCenter
                    font.pixelSize: Style.paragraph
                    color: Style.grayColor
                    text: qsTr("Mute")
                }
            }
            Item{
                Layout.fillWidth: true
            }
            Image{
                source: "qrc:/Icons/verticalLine.png"
            }
            Item{
                Layout.fillWidth: true
            }
            Rectangle{
                width: 150
                height: 100
                color: "#FF0000"
                radius: 12
                ColumnLayout{
                    anchors.centerIn: parent
                    spacing: 10
                    Image{
                        Layout.alignment: Qt.AlignHCenter
                        source: "qrc:/Icons/calling/calling.svg"
                    }
                    PrefsLabel{
                        Layout.alignment: Qt.AlignHCenter
                        font.pixelSize: Style.paragraph
                        color: "#FFFFFF"
                        text: qsTr("End")
                    }
                }
            }
        }
    }
}

