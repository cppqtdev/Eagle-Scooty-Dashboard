import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Style 1.0
import "../Component"

// Charging, in the SR Motard style: the charge as a large number, the power, time
// left and range beneath, the charge limit, and nearby stations alongside.
EaglePage {
    id: root

    Sampled { id: chargePower; source: dashboardData.chargePowerKw; interval: 1000; deadband: 0.05 }
    readonly property color tone: dashboardData.batteryPercent < 15 ? Style.danger
                                 : dashboardData.charging ? Style.success
                                 : Style.modeColor(dashboardData.rideMode)
    readonly property var stations: [
        { name: qsTr("EV Point, Koramangala"), detail: qsTr("1.2 km · 2 of 4 free · ₹18/kWh"), value: qsTr("4 min") },
        { name: qsTr("Charge Hub, HSR Layout"), detail: qsTr("2.8 km · 4 of 6 free · ₹16/kWh"), value: qsTr("9 min") },
        { name: qsTr("Swap Station, Silk Board"), detail: qsTr("3.5 km · battery swap in 3 min"), value: qsTr("11 min") },
    ]

    leftPadding: Style.metrics.pageMargin
    rightPadding: Style.metrics.pageMargin
    topPadding: 24
    bottomPadding: 24

    component Fact: ColumnLayout {
        property string label
        property string value
        spacing: 6
        // Filling, so the column can grow to its share of the row.
        Caption { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: parent.label }
        PrefsLabel { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; font.pixelSize: Style.typography.display + 4; isBold: true; elide: Text.ElideRight; wrapMode: Text.NoWrap; text: parent.value }
    }

    contentItem: RowLayout {
        spacing: 28

        Panel {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 32
                spacing: 10

                RowLayout {
                    spacing: 16
                    Image { sourceSize: Qt.size(36, 36); source: "qrc:/Icons/MapIcons/charing.svg" }
                    PrefsLabel {
                        font.pixelSize: Style.h1
                        isBold: true
                        font.letterSpacing: 2
                        text: dashboardData.charging ? qsTr("CHARGING") : qsTr("BATTERY")
                    }
                    Item { Layout.fillWidth: true }
                    Caption {
                        accent: dashboardData.charging
                        text: !dashboardData.charging ? qsTr("Not plugged in")
                              : dashboardData.chargePowerKw > 0 ? qsTr("Charging") : qsTr("Charge complete")
                    }
                }

                // The figure in the bar's own gradient, so the two read as one.
                GradientText {
                    Layout.alignment: Qt.AlignHCenter
                    pixelSize: 230
                    color: root.tone
                    widestText: "100%"
                    text: dashboardData.batteryPercent + "%"
                }

                ProgressRunning {
                    Layout.fillWidth: true
                    Layout.leftMargin: 60
                    Layout.rightMargin: 60
                    implicitHeight: 22
                    value: dashboardData.batteryPercent
                    charging: dashboardData.charging
                    fillColor: root.tone
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 24
                    Fact { Layout.fillWidth: true; label: qsTr("Power"); value: dashboardData.charging ? qsTr("%1 kW").arg(chargePower.value.toFixed(1)) : "—" }
                    Fact {
                        Layout.fillWidth: true
                        label: qsTr("Full in")
                        value: dashboardData.minutesToFull > 0
                               ? qsTr("%1:%2").arg(Math.floor(dashboardData.minutesToFull / 60)).arg(String(dashboardData.minutesToFull % 60).padStart(2, "0"))
                               : "—"
                    }
                    Fact { Layout.fillWidth: true; label: qsTr("Range"); value: qsTr("%1 km").arg(dashboardData.rangeKm) }
                }

                Item { Layout.fillHeight: true }
                Caption {
                    Layout.alignment: Qt.AlignHCenter
                    visible: dashboardData.charging
                    text: qsTr("Vehicle locked while charging")
                }
            }
        }

        ColumnLayout {
            Layout.preferredWidth: 640
            Layout.fillWidth: false   // a child filling would otherwise make the column grab the row
            Layout.fillHeight: true
            spacing: 16

            Caption { text: qsTr("Charge limit") }
            SegmentedControl {
                readonly property var limits: [80, 90, 100]
                Layout.fillWidth: true
                model: limits.map(l => qsTr("%1%").arg(l))
                currentIndex: limits.indexOf(dashboardData.chargeLimitPercent)
                onActivated: index => dashboardData.chargeLimitPercent = limits[index]
            }

            Caption { Layout.topMargin: 14; text: qsTr("Nearby stations") }
            Repeater {
                model: root.stations
                InfoRow {
                    required property var modelData
                    Layout.fillWidth: true
                    iconSource: "qrc:/Icons/MapIcons/charing.svg"
                    title: modelData.name
                    subtitle: modelData.detail
                    value: modelData.value
                    tone: Style.modeColor(dashboardData.rideMode)
                }
            }

            Item { Layout.fillHeight: true }

            // The simulator stands in for plugging in the charger on the desk.
            OutlineButton {
                visible: simulator.running
                Layout.fillWidth: true
                highlighted: true
                tone: dashboardData.charging ? Style.danger : Style.success
                text: dashboardData.charging ? qsTr("Unplug charger") : qsTr("Plug in charger")
                onClicked: simulator.toggleCharging()
            }
        }
    }
}
