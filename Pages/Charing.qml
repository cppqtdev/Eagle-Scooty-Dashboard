import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Style 1.0
import "../Component"

// Charging: the live charge on the right, nearby charging stations on the left.
EaglePage {
    id: root

    readonly property color modeColor: Style.modeColor(dashboardData.rideMode)
    readonly property var stations: [
        { name: qsTr("EV Point, Koramangala"), detail: qsTr("1.2 km · 2 of 4 free · ₹18/kWh") },
        { name: qsTr("Charge Hub, HSR Layout"), detail: qsTr("2.8 km · 4 of 6 free · ₹16/kWh") },
        { name: qsTr("Swap Station, Silk Board"), detail: qsTr("3.5 km · battery swap · 3 min") },
    ]

    leftPadding: Style.metrics.pageMargin
    rightPadding: Style.metrics.pageMargin
    topPadding: 30
    bottomPadding: 30

    contentItem: RowLayout {
        spacing: 30

        // Stations.
        Rectangle {
            Layout.preferredWidth: root.availableWidth * 0.36
            Layout.fillHeight: true
            radius: Style.metrics.radiusLg
            color: Style.surface
            border.color: Style.border

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 28
                spacing: 20

                PrefsLabel {
                    font.pixelSize: Style.h1
                    isBold: true
                    text: qsTr("Charging stations")
                }
                PrefsLabel {
                    font.pixelSize: Style.h5
                    color: Style.textMuted
                    text: qsTr("Within your %1 km of range").arg(dashboardData.rangeKm)
                }
                Repeater {
                    model: root.stations
                    Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 110
                        radius: Style.metrics.radiusMd
                        color: Style.surfaceSunken
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 18
                            spacing: 16
                            Image {
                                sourceSize: Qt.size(40, 40)
                                source: "qrc:/Icons/MapIcons/charing.svg"
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                PrefsLabel { isBold: true; font.pixelSize: Style.h4; text: modelData.name }
                                PrefsLabel { font.pixelSize: Style.h6; color: Style.textMuted; text: modelData.detail }
                            }
                            Rectangle {
                                Layout.preferredWidth: 120
                                Layout.preferredHeight: 50
                                radius: 25
                                color: root.modeColor
                                PrefsLabel {
                                    anchors.centerIn: parent
                                    font.pixelSize: Style.h5
                                    isBold: true
                                    color: Style.textOnAccent
                                    text: qsTr("Go")
                                }
                            }
                        }
                    }
                }
                Item { Layout.fillHeight: true }
            }
        }

        // Live charge.
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Style.metrics.radiusLg
            color: Style.surface
            border.color: Style.border

            RowLayout {
                anchors.centerIn: parent
                spacing: 80

                // Charge ring.
                Item {
                    Layout.preferredWidth: 380
                    Layout.preferredHeight: 380

                    Canvas {
                        id: ring
                        anchors.fill: parent
                        property real value: dashboardData.batteryPercent
                        property color tone: dashboardData.batteryPercent < 15 ? Style.danger : root.modeColor
                        Behavior on value { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                        onValueChanged: requestPaint()
                        onToneChanged: requestPaint()
                        onPaint: {
                            const ctx = getContext("2d")
                            const r = width / 2 - 18
                            ctx.reset()
                            ctx.lineWidth = 26
                            ctx.lineCap = "round"
                            ctx.strokeStyle = Style.surfaceSunken
                            ctx.beginPath()
                            ctx.arc(width / 2, height / 2, r, 0, Math.PI * 2)
                            ctx.stroke()
                            ctx.strokeStyle = tone
                            ctx.beginPath()
                            ctx.arc(width / 2, height / 2, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * value / 100)
                            ctx.stroke()
                        }
                    }
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        PrefsLabel {
                            Layout.alignment: Qt.AlignHCenter
                            font.pixelSize: 96
                            isBold: true
                            text: qsTr("%1%").arg(dashboardData.batteryPercent)
                        }
                        PrefsLabel {
                            Layout.alignment: Qt.AlignHCenter
                            font.pixelSize: Style.h3
                            color: dashboardData.charging ? Style.success : Style.textMuted
                            text: !dashboardData.charging ? qsTr("Not plugged in")
                                  : dashboardData.chargePowerKw > 0 ? qsTr("⚡ Charging") : qsTr("Charge complete")
                        }
                    }
                }

                ColumnLayout {
                    spacing: 26

                    component Fact: ColumnLayout {
                        property string label
                        property string value
                        spacing: 2
                        PrefsLabel { font.pixelSize: Style.h5; color: Style.textMuted; text: parent.label }
                        PrefsLabel { font.pixelSize: Style.typography.display + 6; isBold: true; text: parent.value }
                    }

                    Fact {
                        label: qsTr("Range")
                        value: qsTr("%1 km").arg(dashboardData.rangeKm)
                    }
                    Fact {
                        label: qsTr("Charging power")
                        value: dashboardData.charging ? qsTr("%1 kW").arg(dashboardData.chargePowerKw.toFixed(1)) : "—"
                    }
                    Fact {
                        label: qsTr("Full in")
                        value: dashboardData.minutesToFull > 0
                               ? qsTr("%1 h %2 min").arg(Math.floor(dashboardData.minutesToFull / 60)).arg(dashboardData.minutesToFull % 60)
                               : "—"
                    }

                    PrefsLabel { font.pixelSize: Style.h5; color: Style.textMuted; text: qsTr("Charge limit") }
                    RowLayout {
                        spacing: 12
                        Repeater {
                            model: [80, 90, 100]
                            Rectangle {
                                required property int modelData
                                readonly property bool current: dashboardData.chargeLimitPercent === modelData
                                implicitWidth: 110
                                implicitHeight: 56
                                radius: 28
                                color: current ? root.modeColor : Style.surfaceSunken
                                Behavior on color { ColorAnimation { duration: Style.motion.fast } }
                                PrefsLabel {
                                    anchors.centerIn: parent
                                    isBold: true
                                    font.pixelSize: Style.h4
                                    color: parent.current ? Style.textOnAccent : Style.textPrimary
                                    text: qsTr("%1%").arg(modelData)
                                }
                                TapHandler { onTapped: dashboardData.chargeLimitPercent = modelData }
                            }
                        }
                    }

                    // The simulator stands in for plugging in the charger on the desk.
                    Rectangle {
                        visible: simulator.running
                        Layout.topMargin: 10
                        implicitWidth: 300
                        implicitHeight: 64
                        radius: 32
                        color: dashboardData.charging ? Style.danger : Style.success
                        PrefsLabel {
                            anchors.centerIn: parent
                            isBold: true
                            color: "#FFFFFF"
                            text: dashboardData.charging ? qsTr("Unplug charger") : qsTr("Plug in charger")
                        }
                        TapHandler { onTapped: simulator.toggleCharging() }
                    }
                }
            }
        }
    }
}
