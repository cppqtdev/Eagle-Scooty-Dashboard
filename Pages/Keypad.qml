import QtQuick 2.15
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3
import Style 1.0
import "../Component"

EaglePage {
    id:root
    width: parent.width
    header:RowLayout{
        Layout.alignment: Qt.AlignHCenter
        width: root.width * 0.8
        spacing: 5
        Item{
            Layout.preferredWidth: 10
        }
        RowLayout{
            spacing: 15
            IconButton{
                roundIcon: true
                iconWidth: 50
                iconHeight: 50
                setIcon: "qrc:/Icons/topIcons/icn_leftindicator.svg"
                onClicked: gEagleStack.pop()
            }

            PrefsLabel{
                Layout.alignment: Qt.AlignLeft
                font.pixelSize: Style.h2
                isStyle: true
                text: qsTr("Back")
            }
        }
    }
    contentItem: Item{
        anchors.fill: parent

        Rectangle{
            anchors.centerIn: parent
            width: 600
            height: 460
            radius: 12
            color: "#CDEAEA"
            TextFieldInput{
                id:inputField
                anchors.top: parent.top
                anchors.topMargin: 10
                anchors.horizontalCenter: parent.horizontalCenter
                implicitWidth: parent.width * 0.9
                implicitHeight: 55
                isBold:true
                placeholderText: qsTr("Primary")
                selectedTextColor: "#FFFFFF"
                selectionColor: "green"
                radius: 8
                borderColor : "#3B71CA"
            }
            ColumnLayout{
                anchors.top: inputField.bottom
                anchors.topMargin: 20
                anchors.horizontalCenter: inputField.horizontalCenter
                width: parent.width * 0.75
                RowLayout{
                    Layout.preferredWidth: parent.width
                    Layout.alignment: Qt.AlignHCenter
                    Image{
                        source: "qrc:/Icons/button.png"
                        PrefsLabel{
                            anchors.centerIn: parent
                            font.pixelSize: Style.h1
                            color: Style.grayColor
                            text: qsTr("1")
                        }
                        IconButton{
                            anchors.fill: parent
                        }
                    }
                    Image{
                        source: "qrc:/Icons/button.png"
                        PrefsLabel{
                            anchors.centerIn: parent
                            font.pixelSize: Style.h1
                            color: Style.grayColor
                            text: qsTr("2")
                        }
                        IconButton{
                            anchors.fill: parent
                        }
                    }
                    Image{
                        source: "qrc:/Icons/button.png"
                        PrefsLabel{
                            anchors.centerIn: parent
                            font.pixelSize: Style.h1
                            color: Style.grayColor
                            text: qsTr("3")
                        }
                        IconButton{
                            anchors.fill: parent
                        }
                    }
                }
                RowLayout{
                    Layout.preferredWidth: parent.width
                    Layout.alignment: Qt.AlignHCenter
                    Image{
                        source: "qrc:/Icons/button.png"
                        PrefsLabel{
                            anchors.centerIn: parent
                            font.pixelSize: Style.h1
                            color: Style.grayColor
                            text: qsTr("4")
                        }
                        IconButton{
                            anchors.fill: parent
                        }
                    }
                    Image{
                        source: "qrc:/Icons/button.png"
                        PrefsLabel{
                            anchors.centerIn: parent
                            font.pixelSize: Style.h1
                            color: Style.grayColor
                            text: qsTr("5")
                        }
                        IconButton{
                            anchors.fill: parent
                        }
                    }
                    Image{
                        source: "qrc:/Icons/button.png"
                        PrefsLabel{
                            anchors.centerIn: parent
                            font.pixelSize: Style.h1
                            color: Style.grayColor
                            text: qsTr("6")
                        }
                        IconButton{
                            anchors.fill: parent
                        }
                    }
                }
                RowLayout{
                    Layout.preferredWidth: parent.width
                    Layout.alignment: Qt.AlignHCenter
                    Image{
                        source: "qrc:/Icons/button.png"
                        PrefsLabel{
                            anchors.centerIn: parent
                            font.pixelSize: Style.h1
                            color: Style.grayColor
                            text: qsTr("7")
                        }
                        IconButton{
                            anchors.fill: parent
                        }
                    }
                    Image{
                        source: "qrc:/Icons/button.png"
                        PrefsLabel{
                            anchors.centerIn: parent
                            font.pixelSize: Style.h1
                            color: Style.grayColor
                            text: qsTr("8")
                        }
                        IconButton{
                            anchors.fill: parent
                        }
                    }
                    Image{
                        source: "qrc:/Icons/button.png"
                        PrefsLabel{
                            anchors.centerIn: parent
                            font.pixelSize: Style.h1
                            color: Style.grayColor
                            text: qsTr("9")
                        }
                        IconButton{
                            anchors.fill: parent
                        }
                    }
                }
                RowLayout{
                    Layout.preferredWidth: parent.width
                    Layout.alignment: Qt.AlignHCenter
                    Image{
                        source: "qrc:/Icons/button.png"
                        IconButton{
                            radius:19.33
                            setIcon: "qrc:/Icons/cross.svg"
                            anchors.fill: parent
                            iconBackground:"#FF0000"
                        }
                    }
                    Image{
                        source: "qrc:/Icons/button.png"
                        PrefsLabel{
                            anchors.centerIn: parent
                            font.pixelSize: Style.h1
                            color: Style.grayColor
                            text: qsTr("0")
                        }
                        IconButton{
                            anchors.fill: parent
                        }
                    }
                    Image{
                        source: "qrc:/Icons/button.png"
                        IconButton{
                            radius:19.33
                            setIcon: "qrc:/Icons/call.svg"
                            anchors.fill: parent
                            iconBackground:"#11B411"
                        }
                    }
                }
            }
        }
    }
}
