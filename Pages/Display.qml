import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
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
            value: themeController.brightness
            width:  parent.width * 0.7
            onMoved: themeController.brightness = Math.round(value)
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
                    backgroundColor: Style.themeMode === Style.autoMode ? Style.accent : Style.surfaceRaised
                    textColor: Style.themeMode === Style.autoMode ? Style.textOnAccent : Style.textPrimary
                    borderWidth: Style.themeMode === Style.autoMode ? 0 : 1
                    borderColor: Style.border
                    text: qsTr("Auto")
                    onClicked: Style.setMode(Style.autoMode)
                }
                PrefsButton{
                    implicitWidth: 160
                    backgroundColor: Style.themeMode === Style.lightMode ? Style.accent : Style.surfaceRaised
                    textColor: Style.themeMode === Style.lightMode ? Style.textOnAccent : Style.textPrimary
                    borderWidth: Style.themeMode === Style.lightMode ? 0 : 1
                    borderColor: Style.border
                    text: qsTr("Light")
                    onClicked: Style.setMode(Style.lightMode)
                }
                PrefsButton{
                    implicitWidth: 160
                    backgroundColor: Style.themeMode === Style.darkMode ? Style.accent : Style.surfaceRaised
                    textColor: Style.themeMode === Style.darkMode ? Style.textOnAccent : Style.textPrimary
                    borderWidth: Style.themeMode === Style.darkMode ? 0 : 1
                    borderColor: Style.border
                    text: qsTr("Dark")
                    onClicked: Style.setMode(Style.darkMode)
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
