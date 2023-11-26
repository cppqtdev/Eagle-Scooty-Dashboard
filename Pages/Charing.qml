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
            Layout.preferredHeight: root.height * 0.9
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
                    anchors.leftMargin: 15
                    PrefsLabel{
                        color: palette.light
                        text: qsTr("Charing Point")
                    }
                }
            }


            ColumnLayout{
                anchors.top: topLabel.bottom
                anchors.topMargin: 20
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width * 0.9
                clip: true
                spacing: 20
                TextFieldInput{
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: parent.width * 0.95
                    implicitHeight: 56
                    font.pixelSize: Style.h6
                    selectedTextColor: "#FFFFFF"
                    backgroundColor : Style.grayColor
                    selectionColor: Style.grayColor
                    radius: 6
                    borderColor : Style.grayColor
                    color: "#FFFFFF"
                    leftPadding: 50

                    IconButton{
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        roundIcon: true
                        iconWidth: 28
                        iconHeight: 28
                        implicitWidth: 30
                        implicitHeight: 30
                        setIcon: "qrc:/Icons/MapIcons/Search.svg"
                    }
                }

                RowLayout{
                    width: parent.width
                    Layout.alignment: Qt.AlignHCenter
                    Rectangle{
                        width: 250
                        height: 120
                        radius: 12
                        color: palette.light
                        ColumnLayout{
                            anchors.centerIn: parent
                            IconButton{
                                roundIcon: true
                                iconWidth: 28
                                iconHeight: 36
                                Layout.alignment: Qt.AlignHCenter
                                setIcon: "qrc:/Icons/MapIcons/save.svg"
                            }
                            PrefsLabel{
                                Layout.alignment: Qt.AlignHCenter
                                color: palette.dark
                                text: qsTr("Save Places")
                            }
                        }
                    }

                    Rectangle{
                        width: 250
                        height: 120
                        radius: 12
                        color: palette.light
                        ColumnLayout{
                            anchors.centerIn: parent
                            IconButton{
                                roundIcon: true
                                iconWidth: 36
                                iconHeight: 36
                                Layout.alignment: Qt.AlignHCenter
                                setIcon: "qrc:/Icons/MapIcons/charing.svg"
                            }
                            PrefsLabel{
                                Layout.alignment: Qt.AlignHCenter
                                color: palette.dark
                                text: qsTr("Charing Stations")
                            }
                        }
                    }
                }
                ColumnLayout{
                    width: parent.width
                    Layout.alignment: Qt.AlignHCenter
                    PrefsLabel{
                        Layout.alignment: Qt.AlignLeft
                        color: palette.dark
                        font.pixelSize: Style.h5
                        text: qsTr("Recent Places")
                    }
                    Image{
                        Layout.alignment: Qt.AlignLeft
                        source: "qrc:/Icons/MapIcons/Line.png"
                    }
                }

                ListView{
                    id:recentView
                    width: parent.width
                    height: contentHeight * 1
                    Layout.fillHeight: true
                    model:1
                    spacing: 10
                    delegate: ItemDelegate{
                        width: recentView.width
                        background:Rectangle{
                            anchors.fill: parent
                            color: "transparent"
                        }

                        contentItem: ColumnLayout{
                            spacing: 20
                            width: recentView.width
                            RowLayout{
                                Layout.preferredWidth: recentView.width * 0.95
                                Layout.maximumWidth: recentView.width * 0.95
                                Layout.alignment: Qt.AlignHCenter
                                ColumnLayout{
                                    Layout.alignment: Qt.AlignLeft
                                    PrefsLabel{
                                        Layout.alignment: Qt.AlignLeft
                                        color: palette.dark
                                        font.pixelSize: Style.h5
                                        text: qsTr("Madeline India")
                                    }
                                    PrefsLabel{
                                        Layout.alignment: Qt.AlignLeft
                                        color: palette.dark
                                        font.pixelSize: Style.h5
                                        text: qsTr("Cafe. Rs. 400-500")
                                    }
                                }

                                Item{
                                    Layout.fillWidth: true
                                }

                                PrefsButton{
                                    implicitWidth: 150
                                    implicitHeight: 55
                                    text: qsTr("Start")
                                }
                            }

                            RowLayout{
                                Layout.preferredWidth: recentView.width * 0.95
                                Layout.maximumWidth: recentView.width * 0.95
                                Layout.alignment: Qt.AlignHCenter
                                IconWithLabel{
                                    implicitHeight: 35
                                    implicitWidth: 120
                                    text: qsTr("Direction")
                                    backgroundColor: palette.dark
                                    setIcon:"qrc:/Icons/MapIcons/direction.svg"
                                    smallBackgroundColor: palette.dark
                                }
                                Item{
                                    Layout.fillWidth: true
                                }
                                IconWithLabel{
                                    implicitHeight: 35
                                    implicitWidth: 120
                                    text: qsTr("Save")
                                    backgroundColor: palette.dark
                                    setIcon:"qrc:/Icons/MapIcons/saveLocation.svg"
                                    smallBackgroundColor: palette.dark
                                }
                                Item{
                                    Layout.fillWidth: true
                                }
                                IconWithLabel{
                                    implicitHeight: 35
                                    implicitWidth: 120
                                    text: qsTr("Add Stop")
                                    backgroundColor: palette.dark
                                    setIcon:"qrc:/Icons/MapIcons/Plus.svg"
                                    smallBackgroundColor: palette.dark
                                }
                            }
                        }
                    }
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

            }

            MapDetails{
                z:1
                anchors.fill: parent
                id:mapview
            }
        }
    }
}
