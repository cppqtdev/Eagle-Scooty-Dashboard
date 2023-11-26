import QtQuick 2.9
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3
import Style 1.0
Image{
    id:root
    width: parent.width
    source: Style.isDark ? "qrc:/Icons/dark/bottom_dark.png" : "qrc:/Icons/green.png"
    sourceSize: Qt.size(root.width , Style.isDark ? 150 : 134)
    signal settingsClicked()
    signal musicClicked()
    signal callingClicked()
    signal homeClicked()
    signal mapClicked()
    signal chargeClicked()
    Image{
        visible: !Style.isDark
        source: Style.isDark ? "qrc:/Icons/dark/bottom_dark2.png" : "qrc:/Icons/white.png"
        sourceSize.height: 116
        width: parent.width
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
    }
    RowLayout{
        width: parent.width * 0.35
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
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
        anchors.verticalCenterOffset: 12
        width: parent.width * 0.9
        Item{
            Layout.preferredWidth: 75
        }
        RowLayout{
            Layout.preferredWidth: parent.width /4.5
            IconButton{
                roundIcon: true
                iconWidth: 55
                iconHeight: 55
                checkable: true
                setIcon:"qrc:/Icons/bottomIcons/home.svg"
                onClicked: homeClicked()
            }
            IconButton{
                roundIcon: true
                iconWidth: 55
                iconHeight: 55
                checkable: true
                setIcon:"qrc:/Icons/bottomIcons/map.svg"
                onClicked: mapClicked()
            }
            IconButton{
                roundIcon: true
                iconWidth: 55
                iconHeight: 55
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
                roundIcon: true
                iconWidth: 55
                iconHeight: 55
                checkable: true
                setIcon:"qrc:/Icons/bottomIcons/Music.svg"
                onClicked: musicClicked()
            }
            IconButton{
                roundIcon: true
                iconWidth: 55
                iconHeight: 55
                checkable: true
                setIcon:"qrc:/Icons/bottomIcons/petrol.svg"
                onClicked: chargeClicked()
            }
            IconButton{
                roundIcon: true
                iconWidth: 55
                iconHeight: 55
                checkable: true
                setIcon:"qrc:/Icons/bottomIcons/settings.svg"
                onClicked: settingsClicked()
            }
        }
    }

}

