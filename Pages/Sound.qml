import QtQuick 2.15
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3
import Style 1.0
import "../Component"

EaglePage {
    id:root
    width: parent.width
    leftPadding: 100
    contentData: ColumnLayout{
        width: root.width
        spacing: 10
        SwitchDelegate{
            Layout.preferredWidth: parent.width * 0.75
            spacing : 20
            background:Rectangle{
                anchors.fill: parent
                color: "transparent"
                radius: 7.9
            }

            contentItem:  PrefsLabel{
                topPadding: 5
                text: qsTr("Turn indicator sounds")
            }
            indicator : PrefsSwitch{
                checked: true
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 10
            }
        }
        Image{
            width: parent.width
            Layout.alignment: Qt.AlignLeft
            source: "qrc:/Icons/HorizontalSeparator.png"
        }
        SwitchDelegate{
            Layout.preferredWidth: parent.width * 0.75
            spacing : 20
            background:Rectangle{
                anchors.fill: parent
                color: "transparent"
                radius: 7.9
            }

            contentItem: PrefsLabel{
                text: qsTr("Parking Assist sounds")
                topPadding: 5
            }
            indicator : PrefsSwitch{
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 10
            }
        }
        Image{
            width: parent.width
            Layout.alignment: Qt.AlignLeft
            source: "qrc:/Icons/HorizontalSeparator.png"
        }

    }
}
