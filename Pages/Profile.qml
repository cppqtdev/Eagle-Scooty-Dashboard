import QtQuick 2.15
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3
import Style 1.0
import "../Component"

EaglePage {
    id:root
    contentData: ColumnLayout{
        width: root.width
        spacing: 20
        RowLayout{
            width: parent.width
            Layout.alignment: Qt.AlignHCenter
            spacing: 30

            Image{
                source: "qrc:/app.ico"
            }

            PrefsLabel{
                font.pixelSize: Style.h1
                text: qsTr("Mike")
            }
        }

        RowLayout{
            width: parent.width
            Layout.alignment: Qt.AlignHCenter
            spacing: 50
            RowLayout{
                spacing: 20
                PrefsLabel{
                    font.pixelSize: Style.h2
                    color: Style.grayColor
                    text: qsTr("Model Number")
                }
                PrefsLabel{
                    isBold: true
                    font.pixelSize: Style.h2
                    text: qsTr("RGEB001")
                }
            }

            Image{
                source: "qrc:/Icons/smallSeparator.png"
            }

            RowLayout{
                spacing: 20
                PrefsLabel{
                    font.pixelSize: Style.h2
                    color: Style.grayColor
                    text: qsTr("Registration Number")
                }
                PrefsLabel{
                    isBold: true
                    font.pixelSize: Style.h2
                    text: qsTr("AK15 1246")
                }
            }

            Image{
                source: "qrc:/Icons/smallSeparator.png"
            }

            RowLayout{
                spacing: 20
                PrefsLabel{
                    font.pixelSize: Style.h2
                    color: Style.grayColor
                    text: qsTr("Vin Number")
                }
                PrefsLabel{
                    isBold: true
                    font.pixelSize: Style.h2
                    text: qsTr("1516GH4516")
                }
            }
        }

        RowLayout{
            Layout.alignment: Qt.AlignLeft
            width: parent.width
            Item{
                Layout.preferredWidth: 180
            }

            PrefsLabel{
                isBold: true
                font.pixelSize: Style.h1
                text: qsTr("Documents")
            }
        }

        RowLayout{
            width: parent.width
            Layout.alignment: Qt.AlignHCenter
            spacing: 120
            RowLayout{
                ColumnLayout{
                    Image{
                        source: "qrc:/Icons/doc/driving.png"
                    }

                    PrefsLabel{
                        font.pixelSize: Style.h2
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("Driving License")
                    }
                }
            }

            RowLayout{
                ColumnLayout{
                    Image{
                        source: "qrc:/Icons/doc/pencard.png"
                    }

                    PrefsLabel{
                        font.pixelSize: Style.h2
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("Pan Card")
                    }
                }
            }

            RowLayout{
                ColumnLayout{
                    Image{
                        source: "qrc:/Icons/doc/Adhaar.png"
                    }

                    PrefsLabel{
                        font.pixelSize: Style.h2
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("Adhaar Card")
                    }
                }
            }
        }
    }
}
