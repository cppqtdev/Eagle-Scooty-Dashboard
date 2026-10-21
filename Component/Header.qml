import QtQuick
import QtQuick.Layouts
import Style 1.0

// Date, the telltale strip and the phone status. Every lamp follows the vehicle;
// the indicators share one blink clock so left, right and hazard flash together.
Image {
    id: root

    property bool blinkPhase: true
    // At key-on every telltale lights for two seconds, so the rider can see that
    // none of the lamps is dead before relying on it (the usual bulb check).
    property bool lampCheck: false
    readonly property bool ready: dashboardData.ready
    onReadyChanged: if (ready) { lampCheck = true; lampCheckTimer.restart() }

    Timer {
        id: lampCheckTimer
        interval: 2000
        onTriggered: root.lampCheck = false
    }

    source: Style.isDark ? "qrc:/Icons/dark/top_dark.png" : "qrc:/Icons/topbar.svg"

    // 85 flashes a minute, inside the 60–120 the regulations allow.
    Timer {
        interval: 353
        repeat: true
        running: dashboardData.leftIndicator || dashboardData.rightIndicator
        onTriggered: root.blinkPhase = !root.blinkPhase
        onRunningChanged: root.blinkPhase = true
    }

    RowLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width * 0.85

        PrefsLabel {
            text: systemClock.dateText
        }

        Item { Layout.fillWidth: true }

        RowLayout {
            spacing: 22

            Telltale {
                lampCheck: root.lampCheck
                active: dashboardData.leftIndicator
                blinking: true
                blinkPhase: root.blinkPhase
                offSource: "qrc:/Icons/topIcons/icn_leftindicator.svg"
                onSource: "qrc:/Icons/topIcons/icn_leftindicator_glow.svg"
            }
            Telltale {
                lampCheck: root.lampCheck
                active: dashboardData.lowBeam && !dashboardData.highBeam
                offSource: "qrc:/Icons/topIcons/icn_lowbeam.svg"
                onSource: "qrc:/Icons/topIcons/icn_lowbeam_glow.svg"
            }
            Telltale {
                lampCheck: root.lampCheck
                active: dashboardData.sideStandDown
                iconSize: 65
                offSource: "qrc:/Icons/topIcons/icn_sidestandenabled.svg"
                onSource: "qrc:/Icons/topIcons/icn_sidestandenabled_glow.svg"
            }
            Telltale {
                lampCheck: root.lampCheck
                active: dashboardData.batteryTempC >= 55
                offSource: "qrc:/Icons/topIcons/icn_batterytemp.svg"
                onSource: "qrc:/Icons/topIcons/icn_batterytemp_glow.svg"
            }
            Telltale {
                lampCheck: root.lampCheck
                active: Math.min(dashboardData.tyreFrontBar, dashboardData.tyreRearBar) < 1.8
                offSource: "qrc:/Icons/topIcons/icn_tyrepressure.svg"
                onSource: "qrc:/Icons/topIcons/icn_tyrepressure_glow.svg"
            }
            Telltale {
                lampCheck: root.lampCheck
                active: dashboardData.highBeam
                offSource: "qrc:/Icons/topIcons/icn_highbeam.svg"
                onSource: "qrc:/Icons/topIcons/icn_highbeam_glow.svg"
            }
            Telltale {
                lampCheck: root.lampCheck
                active: dashboardData.rightIndicator
                blinking: true
                blinkPhase: root.blinkPhase
                offSource: "qrc:/Icons/topIcons/icn_rightindicator.svg"
                onSource: "qrc:/Icons/topIcons/icn_rightindicator _glow.svg"
            }
        }

        Item { Layout.fillWidth: true }

        RowLayout {
            spacing: 14

            Image {
                sourceSize: Qt.size(32, 32)
                opacity: phone.connected ? 1 : 0.35
                source: {
                    switch (phone.connected ? phone.signalBars : 0) {
                    case 1: return "qrc:/Icons/topIcons/wifi/network-cellular-signal-weak-svgrepo-com.svg"
                    case 2: return "qrc:/Icons/topIcons/wifi/network-cellular-signal-ok-svgrepo-com.svg"
                    case 3: return "qrc:/Icons/topIcons/wifi/network-cellular-signal-good-svgrepo-com.svg"
                    case 4: return "qrc:/Icons/topIcons/wifi/network-cellular-signal-excellent-svgrepo-com.svg"
                    default: return "qrc:/Icons/topIcons/wifi/network-cellular-signal-none-svgrepo-com.svg"
                    }
                }
            }
            Image {
                source: phone.connected ? "qrc:/Icons/topIcons/eva_bluetooth-fill -on.svg"
                                        : "qrc:/Icons/topIcons/eva_bluetooth-fill.svg"
            }
        }

        DigitText {
            text: systemClock.timeText
        }
    }
}
