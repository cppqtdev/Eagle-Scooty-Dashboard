import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Style 1.0

import "../Component"

// Settings as master and detail, after the ApexCluster design: each entry shows
// its current value in the list, and the chosen one opens on the right.
EaglePage {
    id: root

    property int current: 0

    readonly property var entries: [
        { icon: "display", title: qsTr("Display"), value: [qsTr("Auto"), qsTr("Light"), qsTr("Dark")][Style.themeMode], page: displayPage },
        { icon: "bluetooth", title: qsTr("Bluetooth"), value: bluetooth.powered ? (phone.connected ? phone.deviceName : qsTr("On")) : qsTr("Off"), page: bluetoothPage },
        { icon: "wifi", title: qsTr("Wi-Fi"), value: wifi.enabled ? (wifi.connectedSsid || qsTr("On")) : qsTr("Off"), page: wifiPage },
        { icon: "sound", title: qsTr("Sound"), value: qsTr("Volume %1%").arg(phone.volume), page: soundPage },
        { icon: "documents", title: qsTr("Documents"), value: vehicleDocuments.attentionCount > 0 ? qsTr("%1 due").arg(vehicleDocuments.attentionCount) : qsTr("All valid"), page: documentsPage },
        { icon: "diagnostics", title: qsTr("Diagnostics"), value: alertCenter.count === 0 ? qsTr("All OK") : alertCenter.count === 1 ? qsTr("1 alert") : qsTr("%1 alerts").arg(alertCenter.count), page: diagnosticsPage },
        { icon: "trips", title: qsTr("My Trips"), value: qsTr("%1 km").arg(dashboardData.tripKm), page: mytripPage },
        { icon: "notifications", title: qsTr("Notifications"), value: qsTr("On"), page: systemNotificationPage },
        { icon: "update", title: qsTr("System Update"), value: qsTr("v%1").arg(Qt.application.version), page: systemUpdatePage },
        { icon: "profile", title: qsTr("Profile"), value: qsTr("Rider"), page: profilePage },
        { icon: "language", title: qsTr("Language"), value: language.currentName, page: languagePage },
        { icon: "about", title: qsTr("About"), value: "", page: aboutPage },
    ]

    Component { id: profilePage; Profile {} }
    Component { id: displayPage; Display {} }
    Component { id: bluetoothPage; Bluetooth {} }
    Component { id: wifiPage; Wifi {} }
    Component { id: mytripPage; MyTrips {} }
    Component { id: aboutPage; About {} }
    Component { id: languagePage; Language {} }
    Component { id: soundPage; Sound {} }
    Component { id: systemNotificationPage; SystemNotification {} }
    Component { id: systemUpdatePage; SystemUpdate {} }
    Component { id: documentsPage; Documents {} }
    Component { id: diagnosticsPage; Diagnostics {} }

    leftPadding: Style.metrics.pageMargin
    rightPadding: Style.metrics.pageMargin
    topPadding: 24
    bottomPadding: 24

    contentItem: RowLayout {
        spacing: 28

        Panel {
            Layout.preferredWidth: 520
            Layout.fillHeight: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 8

                Caption { text: qsTr("Settings") }
                PrefsLabel {
                    Layout.bottomMargin: 10
                    font.pixelSize: Style.h1
                    isBold: true
                    text: root.entries[root.current].title
                }

                TabRail {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: root.entries
                    currentIndex: root.current
                    onActivated: index => root.current = index
                }
            }
        }

        Panel {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            StackView {
                id: detail
                anchors.fill: parent
                anchors.margins: 12
                initialItem: root.entries[0].page
                replaceEnter: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Style.motion.normal }
                        NumberAnimation { property: "x"; from: 40; to: 0; duration: Style.motion.normal; easing.type: Easing.OutCubic }
                    }
                }
                replaceExit: Transition {
                    NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Style.motion.fast }
                }
            }
        }
    }

    onCurrentChanged: detail.replace(null, entries[current].page)
}
