import QtQuick 2.9
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3
import Style 1.0

Image{
    source: Style.isDark ? "qrc:/Icons/dark/top_dark.png" : "qrc:/Icons/topbar.svg"
    RowLayout{
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width * 0.85
        PrefsLabel{
            text: new Date().toLocaleDateString()
        }
        Item{
            Layout.fillWidth: true //2BD150
        }

        RowLayout{
            Layout.preferredWidth: parent.width * 0.5
            IconButton{
                id:leftIndicator
                roundIcon: true
                iconWidth: 60
                iconHeight: 60
                checkable: true
                setIcon: leftIndicator.checked ? "qrc:/Icons/topIcons/icn_leftindicator_glow.svg" : "qrc:/Icons/topIcons/icn_leftindicator.svg"
                SequentialAnimation {
                    running: leftIndicator.checked
                    loops: Animation.Infinite
                    OpacityAnimator {
                        target: leftIndicator.roundIcon ? leftIndicator.roundIconSource : leftIndicator.iconSource
                        from: 0;
                        to: 1;
                        duration: 500
                    }
                    OpacityAnimator {
                        target: leftIndicator.roundIcon ? leftIndicator.roundIconSource : leftIndicator.iconSource
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
                roundIcon: true
                iconWidth: 60
                iconHeight: 60
                checkable: true
                setIcon: checked ? "qrc:/Icons/topIcons/icn_lowbeam_glow.svg" : "qrc:/Icons/topIcons/icn_lowbeam.svg"
            }
            IconButton{
                roundIcon: true
                iconWidth: 65
                iconHeight: 65
                checkable: true
                setIcon:checked ? "qrc:/Icons/topIcons/icn_sidestandenabled_glow.svg" : "qrc:/Icons/topIcons/icn_sidestandenabled.svg"
            }
            IconButton{
                roundIcon: true
                iconWidth: 60
                iconHeight: 60
                checkable: true
                setIcon: checked ? "qrc:/Icons/topIcons/icn_batterytemp_glow.svg" : "qrc:/Icons/topIcons/icn_batterytemp.svg"
            }
            IconButton{
                roundIcon: true
                iconWidth: 60
                iconHeight: 60
                checkable: true
                setIcon: checked ? "qrc:/Icons/topIcons/icn_tyrepressure_glow.svg" : "qrc:/Icons/topIcons/icn_tyrepressure.svg"
            }
            IconButton{
                roundIcon: true
                iconWidth: 60
                iconHeight: 60
                checkable: true
                setIcon:checked ? "qrc:/Icons/topIcons/icn_highbeam_glow.svg" : "qrc:/Icons/topIcons/icn_highbeam.svg"
            }
            IconButton{
                id:rightIndicator
                roundIcon: true
                iconWidth: 60
                iconHeight: 60
                checkable: true
                setIcon: rightIndicator.checked ? "qrc:/Icons/topIcons/icn_rightindicator _glow.svg" : "qrc:/Icons/topIcons/icn_rightindicator.svg"
                SequentialAnimation {
                    running: rightIndicator.checked
                    loops: Animation.Infinite
                    OpacityAnimator {
                        target: rightIndicator.roundIcon ? rightIndicator.roundIconSource : rightIndicator.iconSource
                        from: 0;
                        to: 1;
                        duration: 500
                    }
                    OpacityAnimator {
                        target: rightIndicator.roundIcon ? rightIndicator.roundIconSource : rightIndicator.iconSource
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
            IconButton{
                id:wifiIcon
                checkable: false
                roundIcon: true
                iconWidth: 32
                iconHeight: 32
                setIcon: getWifiIcon(3)
            }
            IconButton{
                checkable: true
                setIcon: checked ? "qrc:/Icons/topIcons/eva_bluetooth-fill -on.svg" : "qrc:/Icons/topIcons/eva_bluetooth-fill.svg"
            }
        }
        PrefsLabel{
            text: new Date().toLocaleTimeString(Qt.locale(), "hh:mm AP")
        }
    }

    function getWifiIcon(index){
        switch(index){
        case 1:
            return "qrc:/Icons/topIcons/wifi/network-cellular-signal-weak-svgrepo-com.svg"
        case 2:
            return "qrc:/Icons/topIcons/wifi/network-cellular-signal-ok-svgrepo-com.svg"
        case 3:
            return "qrc:/Icons/topIcons/wifi/network-cellular-signal-good-svgrepo-com.svg"
        case 4:
            return "qrc:/Icons/topIcons/wifi/network-cellular-signal-excellent-svgrepo-com.svg"
        default:
            return  "qrc:/Icons/topIcons/wifi/network-cellular-signal-none-svgrepo-com.svg"
        }
    }

    Timer{
        running: true
        repeat: true
        interval: 2500
        onTriggered: wifiIcon.setIcon = getWifiIcon(generateRandomNumber())
    }
    function generateRandomNumber() {
        return Math.floor(Math.random() * 5);
    }
}
