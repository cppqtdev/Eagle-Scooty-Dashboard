import QtQuick
import QtQuick.Layouts
import Style 1.0
import Eagle.Blink 1.0

// Date, the telltale strip and the phone status. The bulb check at key-on runs
// on the boot screen's own strip, before this one is shown.
Image {
    id: root


    // The light bar is the designer's SVG rendered once with its filters (the drop
    // and inner shadow); Qt's SVG renderer skips filters, which left it flat.
    source: Style.isDark ? "qrc:/Icons/dark/top_dark.png" : "qrc:/Icons/topbar.png"


    RowLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width * 0.85

        PrefsLabel {
            text: systemClock.dateText
        }

        Item { Layout.fillWidth: true }

        TelltaleStrip {}

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

        PrefsLabel {
            text: systemClock.timeText
        }
    }
}
