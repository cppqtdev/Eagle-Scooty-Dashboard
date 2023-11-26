import QtQuick 2.15
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3
import Style 1.0
import "../Component"

EaglePage {
    id:root
    width: parent.width
    leftPadding: 100

    Component{
        id:tripDetails
        TripDetails{

        }
    }

    contentData: ColumnLayout{
        width: root.width
        spacing: 20

        RowLayout{
            spacing: 10
            PrefsLabel{
                isStyle:true
                isBold: true
                font.pixelSize: Style.h2
                text: qsTr("Today")
            }
            PrefsButton{
                iconFactor: 0.5
                implicitWidth: 28
                implicitHeight: 28
                setIcon: "qrc:/Icons/Down.svg"
                backgroundColor:"#00000000"
            }
        }

        Image{
            width: parent.width
            Layout.alignment: Qt.AlignLeft
            source: "qrc:/Icons/HorizontalSeparator.png"
        }

        RowLayout{
            spacing: 30
            width: parent.width
            Layout.alignment: Qt.AlignLeft
            RowLayout{
                spacing: 10
                PrefsButton{
                    iconFactor: 0.6
                    implicitWidth: 36
                    implicitHeight: 36
                    setIcon: "qrc:/Icons/scooty.svg"
                    backgroundColor:"#00000000"
                }

                PrefsLabel{
                    isBold: true
                    isStyle: true
                    font.pixelSize: Style.h5
                    text: qsTr("13 km 30 min")
                }
            }

            RowLayout{
                spacing: 10
                PrefsButton{
                    iconFactor: 0.5
                    implicitWidth: 36
                    implicitHeight: 36
                    setIcon: "qrc:/Icons/location.svg"
                    backgroundColor:"#00000000"
                }

                PrefsLabel{
                    font.pixelSize: Style.h5
                    isBold: true
                    isStyle: true
                    text: qsTr("2 Visit")
                }
            }
        }

        Image{
            width: parent.width
            Layout.alignment: Qt.AlignLeft
            source: "qrc:/Icons/HorizontalSeparator.png"
        }
        ListView{
            id:tripView
            width: parent.width
            height: contentHeight
            model: 2
            spacing : 20
            clip: true
            delegate:RoundRectangle {
                clip: true
                width: tripView.width * 0.8;
                height: 220
                radius: 10
                radiusCorners: Qt.AlignLeft | Qt.AlignRight | Qt.AlignTop | Qt.AlignBottom
                color: Style.isDark ? palette.dark : palette.light
                Rectangle{
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    height: parent.height
                    width: 10
                    radius: 10
                    color: Style.styleColor
                }

                ColumnLayout{
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 20
                    spacing: 20

                    PrefsLabel{
                        Layout.fillWidth: true
                        Layout.leftMargin: 20
                        Layout.alignment: Qt.AlignLeft
                        font.pixelSize: Style.h5
                        text: qsTr("Sunday , June 18 ,08:22 AM")
                    }

                    PrefsTimeLine{
                        id:time_line
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignLeft
                        mode: Style.left
                        model:ListModel{
                            ListElement{
                                lable:"2017-07-01"
                                text:"HOME (26th Outlet, Near Showroom)"
                            }
                            ListElement{
                                lable:"2017-09-01"
                                text:"HOME (26th Outlet, Near Showroom)"
                            }
                        }
                    }
                }

                Image{
                    source: "qrc:/Icons/rightArrow.svg"
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.rightMargin: 30
                }

                MouseArea{
                    anchors.fill: parent
                    onClicked: {
                        gEagleStack.push(tripDetails)
                    }
                }
            }
        }
    }
}
