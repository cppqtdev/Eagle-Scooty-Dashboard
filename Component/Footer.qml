import QtQuick 2.9
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3
import Style 1.0
Image{
    source: "qrc:/Icons/green.png"
    signal settingsClicked()
    signal musicClicked()
    signal callingClicked()
    Image{
        source: "qrc:/Icons/white.png"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom

        RowLayout{
            width: parent.width * 0.35
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 40
            spacing: 10
            ColumnLayout{
                PrefsLabel{
                    isStyle: true
                    text: qsTr("72%")
                }
                PrefsLabel{
                    isStyle: true
                    text: qsTr("Battery")
                }
            }
            ProgressRunning{
                height: 24
                Layout.fillWidth: true
            }
            ColumnLayout{
                PrefsLabel{
                    isStyle: true
                    text: qsTr("136KM")
                }
                PrefsLabel{
                    isStyle: true
                    text: qsTr("Range")
                }
            }
        }
        RowLayout{
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width * 0.9
            Item{
                Layout.preferredWidth: 75
            }
            RowLayout{
                Layout.preferredWidth: parent.width /4.5
                IconButton{
                    checkable: true
                    setIcon:"qrc:/Icons/bottomIcons/home.svg"
                }
                IconButton{
                    checkable: true
                    setIcon:"qrc:/Icons/bottomIcons/map.svg"
                }
                IconButton{
                    checkable: true
                    setIcon:"qrc:/Icons/bottomIcons/phone.svg"
                    onClicked: callingClicked()
                }
            }
            Item{
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            RowLayout{
                Layout.preferredWidth: parent.width /4.5
                IconButton{
                    checkable: true
                    setIcon:"qrc:/Icons/bottomIcons/Music.svg"
                    onClicked: musicClicked()
                }
                IconButton{
                    checkable: true
                    setIcon:"qrc:/Icons/bottomIcons/petrol.svg"
                }
                IconButton{
                    checkable: true
                    setIcon:"qrc:/Icons/bottomIcons/settings.svg"
                    onClicked: settingsClicked()
                }
            }
        }
    }
}

