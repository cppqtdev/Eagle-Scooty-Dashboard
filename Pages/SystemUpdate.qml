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
    header:RowLayout{
        width: parent.width
        spacing: 5
        PrefsLabel{
            Layout.alignment: Qt.AlignLeft
            Layout.leftMargin: 100
            font.pixelSize: Style.h2
            isStyle: true
            isBold: true
            text: qsTr("Update")
        }

        PrefsButton{
            Layout.alignment: Qt.AlignRight
            Layout.rightMargin: 230
            implicitWidth: 300
            text: qsTr("Check For Update")
            borderWidth: 1
            borderColor: Style.styleColor
            textColor : borderColor
            backgroundColor: "transparent"
            onClicked: gEagleStack.pop()
        }
    }
    contentData: ColumnLayout{
        width: root.width
        spacing: 20
        Item{
            Layout.fillWidth: true
        }

        Image{
            width: parent.width
            Layout.alignment: Qt.AlignLeft
            source: "qrc:/Icons/HorizontalSeparator.png"
        }

        Rectangle{
            width: parent.width * 0.78
            height: 100
            radius: 10
            color : Style.isDark ? palette.dark : palette.light
            Rectangle{
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height
                width: 10
                radius: 10
                color: Style.styleColor
            }

            PrefsLabel{
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 20
                font.pixelSize: Style.h2
                isStyle: true
                isBold: true
                text: qsTr("Software")
            }

            ColumnLayout{
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                PrefsLabel{
                    Layout.alignment: Qt.AlignHCenter
                    font.pixelSize: Style.h5
                    isStyle: true
                    isBold: true
                    text: qsTr("Update Available 5.15.11")
                }
                PrefsLabel{
                    Layout.alignment: Qt.AlignHCenter
                    font.pixelSize: Style.paragraph
                    isStyle: true
                    isBold: true
                    text: qsTr("<a href='https://www.example.com'>Release Notes</a>")
                }
            }

            PrefsButton{
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 20
                implicitWidth: 150
                text: qsTr("Update")
                borderWidth: 1
                borderColor: Style.styleColor
                textColor : borderColor
                backgroundColor: "transparent"
                onClicked: gEagleStack.pop()
            }
        }
    }
}
