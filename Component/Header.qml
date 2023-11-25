import QtQuick 2.9
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3
import Style 1.0

Image{
    source: "qrc:/Icons/topbar.svg"
    RowLayout{
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width * 0.85
        PrefsLabel{
            text: qsTr("23rd January")
        }
        Item{
            Layout.fillWidth: true
        }

        RowLayout{
            Layout.preferredWidth: parent.width * 0.5
            IconButton{
                id:leftIndicator
                checkable: true
                setIcon: leftIndicator.checked ? "qrc:/Icons/topIcons/icn_leftindicator_glow.svg" : "qrc:/Icons/topIcons/icn_leftindicator.svg"
                SequentialAnimation {
                    running: leftIndicator.checked
                    loops: Animation.Infinite
                    OpacityAnimator {
                        target: leftIndicator.iconSource
                        from: 0;
                        to: 1;
                        duration: 500
                    }
                    OpacityAnimator {
                        target: leftIndicator.iconSource
                        from: 1;
                        to: 0;
                        duration: 500
                    }
                }
                onCheckedChanged: {
                    if(!checked){
                        leftIndicator.iconSource.opacity = 1
                    }
                }
            }
            IconButton{
                checkable: true
                setIcon:"qrc:/Icons/topIcons/icn_lowbeam.svg"
            }
            IconButton{
                checkable: true
                setIcon:"qrc:/Icons/topIcons/icn_sidestandenabled.svg"
            }
            IconButton{
                checkable: true
                setIcon:"qrc:/Icons/topIcons/icn_batterytemp.svg"
            }
            IconButton{
                checkable: true
                setIcon:"qrc:/Icons/topIcons/icn_tyrepressure.svg"
            }
            IconButton{
                checkable: true
                setIcon:"qrc:/Icons/topIcons/icn_highbeam.svg"
            }
            IconButton{
                id:rightIndicator
                checkable: true
                setIcon: rightIndicator.checked ? "qrc:/Icons/topIcons/icn_rightindicator _glow.svg" : "qrc:/Icons/topIcons/icn_rightindicator.svg"
                SequentialAnimation {
                    running: rightIndicator.checked
                    loops: Animation.Infinite
                    OpacityAnimator {
                        target: rightIndicator.iconSource
                        from: 0;
                        to: 1;
                        duration: 500
                    }
                    OpacityAnimator {
                        target: rightIndicator.iconSource
                        from: 1;
                        to: 0;
                        duration: 500
                    }
                }
                onCheckedChanged: {
                    if(!checked){
                        rightIndicator.iconSource.opacity = 1
                    }
                }
            }
        }

        Item{
            Layout.fillWidth: true
        }

        RowLayout{
            spacing: 10
            IconButton{
                checkable: true
                setIcon:"qrc:/Icons/topIcons/wifi.svg"
            }
            IconButton{
                checkable: true
                setIcon:"qrc:/Icons/topIcons/eva_bluetooth-fill.svg"
            }
        }
        PrefsLabel{
            text: qsTr("04:36 PM")
        }
    }
}
