import QtQuick 2.15
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3
import Style 1.0
import "../Component"

EaglePage {
    id:root
    width: parent.width
    leftPadding :100
    rightPadding:100
    contentItem: RowLayout{
        width: parent.width
        spacing: 20
        Pane{
            padding: 0
            Layout.preferredWidth: root.width * 0.3
            Layout.preferredHeight: root.height * 0.5
            background: Rectangle{
                color: palette.base
                anchors.fill: parent
                radius: 15
            }

            RoundRectangle{
                id:topLabel
                width: parent.width
                height: 80
                radius: 15
                radiusCorners: Qt.AlignLeft | Qt.AlignRight | Qt.AlignTop
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                color: palette.dark

                RowLayout{
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    IconButton{
                        setIcon: "qrc:/Icons/MapIcons/Search.svg"
                    }
                    PrefsLabel{
                        color: palette.light
                        text: qsTr("Search Here")
                    }
                }
            }

            RowLayout{
                anchors.top: topLabel.bottom
                anchors.topMargin: 20
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width * 0.9
                Image{
                    source: "qrc:/Icons/MapIcons/searchIcon.svg"
                }
                Item{
                    Layout.preferredWidth: 5
                }

                ColumnLayout{
                    width: parent.width
                    Layout.alignment: Qt.AlignHCenter
                    TextFieldInput{
                        placeholderText: qsTr("Choose Starting Point")
                        placeholderTextColor: palette.dark
                        implicitWidth: parent.width * 0.95
                        implicitHeight: 55
                        font.pixelSize: Style.paragraph
                        selectedTextColor: "#FFFFFF"
                        backgroundColor : Style.grayColor
                        selectionColor: Style.grayColor
                        radius: 8
                        borderColor : Style.grayColor
                        color: palette.windowText
                    }
                    Item{
                        Layout.fillHeight: true
                    }

                    TextFieldInput{
                        placeholderText: qsTr("Choose Destination")
                        placeholderTextColor: palette.dark
                        implicitWidth: parent.width * 0.95
                        implicitHeight: 55
                        font.pixelSize: Style.paragraph
                        backgroundColor : Style.grayColor
                        selectedTextColor: "#FFFFFF"
                        selectionColor: Style.grayColor
                        radius: 8
                        borderColor : Style.grayColor
                        color: palette.windowText
                    }
                }

                IconButton{
                    setIcon: "qrc:/Icons/MapIcons/switch.svg"
                }
            }

            RowLayout{
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 10
                IconButton{
                    roundIcon: true
                    iconWidth: 28
                    iconHeight: 28
                    setIcon: "qrc:/Icons/MapIcons/Add.svg"
                }
                PrefsLabel{
                    color: palette.dark
                    font.pixelSize: Style.h5
                    text: qsTr("Add destination")
                }
            }
        }
        Pane{
            padding: 0
            Layout.fillWidth: true
            Layout.preferredHeight: root.height * 0.9
            background: Rectangle{
                color: palette.base
                anchors.fill: parent
                radius: 15
            }
            RoundRectangle{
                z:3
                width: parent.width
                height: 80
                radius: 15
                radiusCorners: Qt.AlignLeft | Qt.AlignRight | Qt.AlignTop
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                color: palette.dark

                RowLayout{
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter

                    RowLayout{
                        IconButton{
                            roundIcon: true
                            iconWidth: 32
                            iconHeight: 32
                            setIcon: "qrc:/Icons/time.svg"
                        }
                        PrefsLabel{
                            Layout.alignment: Qt.AlignLeft
                            color: Style.grayColor
                            text: qsTr("23m Time")
                        }
                    }
                    RowLayout{
                        IconButton{
                            roundIcon: true
                            iconWidth: 32
                            iconHeight: 32
                            setIcon: "qrc:/Icons/entypo_arrow-left.svg"
                        }
                        PrefsLabel{
                            Layout.alignment: Qt.AlignLeft
                            color: Style.grayColor
                            text: qsTr("1.2km Distance")
                        }
                    }
                }

                RowLayout{
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    IconButton{
                        roundIcon: true
                        iconWidth: 32
                        iconHeight: 32
                        checkable: true
                        setIcon:"qrc:/Icons/bottomIcons/settings.svg"
                    }
                }
            }

            MapDetails{
                z:1
                anchors.fill: parent
                id:mapview
            }
        }
    }
}
