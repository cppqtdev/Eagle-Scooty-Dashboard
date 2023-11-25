import QtQuick 2.15
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3
import Style 1.0
import "../Component"

EaglePage {
    id:root
    width: parent.width
    contentItem: ColumnLayout{
        width: parent.width
        RowLayout{
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: root.width * 0.5
            Image{
                id:musicIcon
                source: "qrc:/Icons/Music/codex-omega.png"
            }
            ColumnLayout{
                Layout.preferredHeight: musicIcon.height
                PrefsLabel{
                    Layout.alignment: Qt.AlignLeft
                    font.pixelSize: Style.h6
                    color: Style.grayColor
                    text: qsTr("Now Playing")
                }
                Item{
                    Layout.preferredHeight: 50
                }
                ColumnLayout{
                    spacing: 5
                    PrefsLabel{
                        Layout.alignment: Qt.AlignLeft
                        color: Style.grayColor
                        text: qsTr("Purple Haze")
                    }

                    PrefsLabel{
                        Layout.alignment: Qt.AlignLeft
                        font.pixelSize: Style.h5
                        color: Style.grayColor
                        text: qsTr("Jonathan Wishperbrook")
                    }

                    PrefsLabel{
                        Layout.alignment: Qt.AlignLeft
                        font.pixelSize: Style.paragraph
                        color: Style.grayColor
                        text: qsTr("Woodstock")
                    }
                }
            }
            Item{
                Layout.preferredWidth: root.width * 0.1
            }

            ColumnLayout{
                Layout.preferredHeight: musicIcon.height
                IconButton{
                    iconBackground: "#FFFFFF"
                    setIcon: "qrc:/Icons/Music/Like.svg"
                }
                IconButton{
                    roundIcon: true
                    iconWidth: 36
                    iconHeight: 36
                    iconBackground: "#FFFFFF"
                    setIcon: "qrc:/Icons/Music/AddPlaylist.svg"
                }
                IconButton{
                    iconBackground: "#FFFFFF"
                    setIcon: "qrc:/Icons/Music/Share.svg"
                }
            }
        }

        PrefsSlider{
            tooltipVisible:false
            Layout.alignment: Qt.AlignHCenter
            value: 76
            checkedColor: Style.styleColor
            handlerColor:"#FFFFFF"
            width:  parent.width * 0.5
        }

        RowLayout{
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: root.width * 0.5
            PrefsLabel{
                Layout.alignment: Qt.AlignLeft
                font.pixelSize: Style.paragraph
                color: Style.grayColor
                text: qsTr("00:00")
            }

            PrefsLabel{
                Layout.alignment: Qt.AlignRight
                font.pixelSize: Style.paragraph
                color: Style.grayColor
                text: qsTr("04:00")
            }
        }

        RowLayout{
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: root.width * 0.5
            IconButton{
                setIcon: "qrc:/Icons/Music/Suffle.svg"
            }
            IconButton{
                setIcon: "qrc:/Icons/Music/Repeat.svg"
            }

            IconButton{
                iconWidth: 20
                iconHeight: 24
                roundIcon: true
                iconBackground: Style.styleColor
                setIcon: "qrc:/Icons/Music/Left.svg"
            }

            IconButton{
                roundIcon: true
                implicitHeight: 60
                implicitWidth: 60
                iconWidth: 24
                iconHeight: 28
                iconBackground: Style.styleColor
                setIcon: "qrc:/Icons/Music/Play.svg"
            }

            IconButton{
                iconWidth: 20
                iconHeight: 24
                roundIcon: true
                iconBackground: Style.styleColor
                setIcon: "qrc:/Icons/Music/right.svg"
            }

            IconButton{
                setIcon: "qrc:/Icons/Music/Repeat2.svg"
            }
            IconButton{
                setIcon: "qrc:/Icons/Music/Settings.svg"
            }
        }
    }
}
