import QtQuick 2.15
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3
import Style 1.0
import "../Component"

EaglePage {
    id:root
    width: parent.width
    leftPadding: 100
    contentData: RowLayout{
        width: root.width
        spacing: 20
        Pane{
            Layout.fillWidth: true
            Layout.fillHeight: true
            padding: 0
            background: Rectangle{
                anchors.fill: parent
                color: Style.background
            }

            ColumnLayout{
                width: parent.width
                spacing: 30
                PrefsLabel{
                    Layout.alignment: Qt.AlignLeft
                    font.pixelSize: Style.h1
                    text: qsTr("Bluetooth")
                }

                SwitchDelegate{
                    Layout.preferredWidth: parent.width * 0.5
                    spacing : 20
                    background:Rectangle{
                        anchors.fill: parent
                        color: "#00B1B2"
                        radius: 7.9
                    }

                    contentItem: Item{
                        width: parent.width
                        RowLayout{
                            PrefsButton{
                                setIcon: "qrc:/Icons/bluetooth.svg"
                                backgroundColor:"#00000000"
                            }
                            PrefsLabel{
                                Layout.alignment: Qt.AlignLeft
                                text: qsTr("Bluetooth")
                            }
                        }
                    }
                    indicator : PrefsSwitch{
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                    }
                }

                ColumnLayout{
                    PrefsLabel{
                        Layout.alignment: Qt.AlignLeft
                        font.pixelSize: Style.h4
                        color: Style.grayColor
                        text: qsTr("Now Discover As \"People E-bike\"")
                    }
                    Item{
                        Layout.preferredHeight: 20
                        Layout.fillWidth: true
                    }

                    PrefsLabel{
                        Layout.alignment: Qt.AlignLeft
                        font.pixelSize: Style.h4
                        color: Style.grayColor
                        text: qsTr("On your bluetooth to connect with the device")
                    }
                }
            }
        }
        Image{
            id:ebike
            Layout.rightMargin: 250
            source: "qrc:/Icons/scooty.png"
        }
    }
}
