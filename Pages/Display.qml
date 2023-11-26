import QtQuick 2.15
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3
import Style 1.0
import "../Component"

EaglePage {
    id:root
    width: parent.width
    leftPadding:100
    contentData: ColumnLayout{
        width: root.width
        spacing: 20
        RowLayout{
            spacing: 5
            PrefsButton{
                setIcon: "qrc:/Icons/brightness 2.svg"
                backgroundColor:"#00000000"
            }
            PrefsLabel{
                font.pixelSize: Style.h2
                text: qsTr("Display brightness")
            }
        }

        Item{
            Layout.preferredHeight: 15
        }
        Item{
            Layout.fillWidth: true
        }

        PrefsSlider{
            value: 76
            width:  parent.width * 0.7
        }

        Image{
            width: parent.width
            Layout.alignment: Qt.AlignLeft
            source: "qrc:/Icons/HorizontalSeparator.png"
        }

        ColumnLayout{
            spacing: 15
            PrefsLabel{
                font.pixelSize: Style.h2
                text: qsTr("Themes")
            }

            RowLayout{
                spacing: 30
                PrefsButton{
                    implicitWidth: 160
                    backgroundColor: "#FFFFFF"
                    textColor: "#000000"
                    text: qsTr("Light")
                    onClicked: Style.isDark = false
                }
                PrefsButton{
                    implicitWidth: 160
                    backgroundColor:"#000000"
                    text: qsTr("Dark")
                    onClicked: Style.isDark = true
                }
            }
        }

        Image{
            width: parent.width
            Layout.alignment: Qt.AlignLeft
            source: "qrc:/Icons/HorizontalSeparator.png"
        }

        PrefsSwitch{
            text: qsTr("Night Sight Headlight")
        }
    }
}
