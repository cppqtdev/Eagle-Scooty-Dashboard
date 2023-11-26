import QtQuick 2.15
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3
import QtLocation 5.15
import QtPositioning 5.6
import Style 1.0
import "../Component"

EaglePage {
    id:root
    width: parent.width
    leftPadding: 100
    contentData: ColumnLayout{
        width: root.width
        spacing: 20

        RowLayout{
            spacing: 5
            PrefsButton{
                mirror:true
                iconFactor: 0.8
                implicitWidth: 48
                implicitHeight: 48
                setIcon: "qrc:/Icons/topIcons/icn_rightindicator.svg"
                backgroundColor:"#00000000"
                onClicked: gEagleStack.pop()
            }
            PrefsLabel{
                isStyle: true
                font.pixelSize: Style.h2
                text: qsTr("Back")
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
                    isStyle: true
                    isBold: true
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
                    isStyle: true
                    isBold: true
                    font.pixelSize: Style.h5
                    text: qsTr("2 Visit")
                }
            }
        }

        Image{
            width: parent.width
            Layout.alignment: Qt.AlignLeft
            source: "qrc:/Icons/HorizontalSeparator.png"
        }

        RoundRectangle {
            clip: true
            width: tripView.width * 0.8;
            height: 610.5
            radius: 15
            radiusCorners: Qt.AlignLeft | Qt.AlignRight | Qt.AlignTop | Qt.AlignBottom
            color : Style.isDark ? palette.dark : palette.light
            PrefsLabel{
                id:dateLabel
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.leftMargin: 70
                anchors.topMargin: 30
                font.pixelSize: Style.h4
                text: qsTr("Sunday , June 18 ,08:22 AM")
            }

            PrefsTimeLine{
                id:time_line
                anchors.top: dateLabel.bottom
                anchors.topMargin: 20
                anchors.left: parent.left
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
                    ListElement{
                        lable:"2017-07-01"
                        text:"HOME (26th Outlet, Near Showroom)"
                    }
                }
            }

            RoundRectangle{
                radius: 15
                width: parent.width - time_line.width * 1.1
                height: parent.height * 0.9
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: time_line.right
                anchors.leftMargin: 20
                radiusCorners: Qt.AlignLeft | Qt.AlignRight | Qt.AlignTop | Qt.AlignBottom
                color : Style.isDark ? palette.dark : palette.light
                MapDetails{
                    id:mapview
                }
            }
        }
    }
}
