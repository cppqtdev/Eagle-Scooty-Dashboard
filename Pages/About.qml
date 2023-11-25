import QtQuick 2.15
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3
import Style 1.0
import "../Component"

EaglePage {
    id:root
    width: parent.width
    leftPadding:100
    contentData: RowLayout{
        width: root.width
        spacing: 20
        Image{
            id:ebike
            source: "qrc:/Icons/scooty.png"
        }
        Pane{
            Layout.fillWidth: true
            Layout.fillHeight: true
            padding: 0
            leftPadding: 100
            background: Rectangle{
                anchors.fill: parent
                color: Style.background
            }

            ColumnLayout{
                width: parent.width
                spacing: 30
                PrefsLabel{
                    Layout.alignment: Qt.AlignLeft
                    font.pixelSize: Style.h1
                    text: qsTr("People E-bike")
                }

                PrefsLabel{
                    Layout.alignment: Qt.AlignLeft
                    font.pixelSize: Style.h2
                    text: qsTr("White")
                }

                RowLayout{
                    width: parent.width
                    ColumnLayout{
                        spacing: 30
                        ColumnLayout{
                            PrefsLabel{
                                Layout.alignment: Qt.AlignLeft
                                font.pixelSize: Style.h2
                                color: Style.grayColor
                                text: qsTr("Range")
                            }

                            PrefsLabel{
                                Layout.alignment: Qt.AlignLeft
                                font.pixelSize: Style.h3
                                text: qsTr("180")
                            }
                        }
                        ColumnLayout{
                            PrefsLabel{
                                Layout.alignment: Qt.AlignLeft
                                font.pixelSize: Style.h2
                                color: Style.grayColor
                                text: qsTr("Top Speed")
                            }

                            PrefsLabel{
                                Layout.alignment: Qt.AlignLeft
                                font.pixelSize: Style.h3
                                text: qsTr("110 KMPH")
                            }
                        }
                        ColumnLayout{
                            PrefsLabel{
                                Layout.alignment: Qt.AlignLeft
                                font.pixelSize: Style.h2
                                color: Style.grayColor
                                text: qsTr("0 to 100% Charging")
                            }

                            PrefsLabel{
                                Layout.alignment: Qt.AlignLeft
                                font.pixelSize: Style.h3
                                text: qsTr("3 Hrs")
                            }
                        }
                    }

                    Item{
                        Layout.fillWidth: true
                    }

                    ColumnLayout{
                        spacing: 30
                        ColumnLayout{
                            PrefsLabel{
                                Layout.alignment: Qt.AlignLeft
                                font.pixelSize: Style.h2
                                color: Style.grayColor
                                text: qsTr("Ride Modes")
                            }

                            PrefsLabel{
                                Layout.alignment: Qt.AlignLeft
                                font.pixelSize: Style.h3
                                text: qsTr("Economy,Regular,Sports")
                            }
                        }
                        ColumnLayout{
                            PrefsLabel{
                                Layout.alignment: Qt.AlignLeft
                                font.pixelSize: Style.h2
                                color: Style.grayColor
                                text: qsTr("0 to 60 KMPH")
                            }

                            PrefsLabel{
                                Layout.alignment: Qt.AlignLeft
                                font.pixelSize: Style.h3
                                text: qsTr("3.8 Sec")
                            }
                        }
                        ColumnLayout{
                            PrefsLabel{
                                Layout.alignment: Qt.AlignLeft
                                font.pixelSize: Style.h2
                                color: Style.grayColor
                                text: qsTr("Max Power")
                            }

                            PrefsLabel{
                                Layout.alignment: Qt.AlignLeft
                                font.pixelSize: Style.h3
                                text: qsTr("90 Hp")
                            }
                        }
                    }
                    Item{
                        Layout.preferredWidth: 200
                    }
                }
            }
        }
    }
}
