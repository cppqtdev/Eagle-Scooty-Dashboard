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
        { icon: "about", title: qsTr("About"), value: "", page: aboutPage },
    ]

    Component { id: profilePage; Profile {} }
    Component { id: displayPage; Display {} }
    Component { id: bluetoothPage; Bluetooth {} }
    Component { id: wifiPage; Wifi {} }
    Component { id: mytripPage; MyTrips {} }
    Component { id: aboutPage; About {} }
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

                // The tabs: a rail down the left, and the chosen tab lit from it with
                // a glow that fades across the row; the light slides to a new tab.
                ListView {
                    id: tabs
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 4
                    currentIndex: root.current
                    model: root.entries.length
                    boundsBehavior: Flickable.StopAtBounds
                    highlightFollowsCurrentItem: true
                    highlightMoveDuration: Style.motion.normal
                    highlightMoveVelocity: -1
                    highlightResizeDuration: 0

                    Rectangle {   // the rail
                        x: 0
                        y: 0
                        width: 2
                        height: tabs.height
                        radius: 1
                        color: Style.border
                        z: -1
                    }

                    highlight: Item {
                        Rectangle {
                            anchors.fill: parent
                            radius: Style.metrics.radiusMd
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: Style.alpha(Style.accent, Style.isDark ? 0.42 : 0.24) }
                                GradientStop { position: 0.7; color: Style.alpha(Style.accent, 0.06) }
                                GradientStop { position: 1.0; color: Style.alpha(Style.accent, 0.0) }
                            }
                        }
                        // The lit edge, with a soft halo on the rail.
                        Rectangle {
                            x: 0
                            anchors.verticalCenter: parent.verticalCenter
                            width: 9
                            height: parent.height - 6
                            radius: 5
                            color: Style.alpha(Style.accentStrong, 0.25)
                        }
                        Rectangle {
                            x: 0
                            anchors.verticalCenter: parent.verticalCenter
                            width: 4
                            height: parent.height - 14
                            radius: 2
                            color: Style.isDark ? Style.accentStrong : Style.accent
                        }
                    }

                    delegate: AbstractButton {
                        id: tab
                        required property int index
                        readonly property bool current: ListView.isCurrentItem
                        width: ListView.view.width
                        implicitHeight: 56
                        leftPadding: 22
                        rightPadding: 16
                        onClicked: root.current = index

                        background: Rectangle {
                            radius: Style.metrics.radiusMd
                            color: tab.pressed && !tab.current ? Style.alpha(Style.textPrimary, 0.06) : "transparent"
                        }
                        contentItem: RowLayout {
                            spacing: 16
                            LineIcon {
                                name: root.entries[tab.index].icon
                                size: 26
                                color: tab.current ? (Style.isDark ? Style.accentStrong : Style.accent) : Style.textMuted
                            }
                            PrefsLabel {
                                Layout.fillWidth: true
                                font.pixelSize: Style.h4
                                isBold: tab.current
                                color: tab.current ? Style.textPrimary : Style.textSecondary
                                elide: Text.ElideRight
                                wrapMode: Text.NoWrap
                                text: root.entries[tab.index].title
                            }
                            PrefsLabel {
                                Layout.maximumWidth: tab.availableWidth * 0.45
                                font.pixelSize: Style.h6
                                color: Style.textMuted
                                elide: Text.ElideRight
                                wrapMode: Text.NoWrap
                                text: root.entries[tab.index].value
                            }
                        }
                    }
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
