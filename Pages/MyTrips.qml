import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Style 1.0
import "../Component"

// Trip A, the odometer and the last rides; trip A resets after a confirmation.
EaglePage {
    id: root

    property bool confirmReset: false

    background: null

    component Figure: ColumnLayout {
        property string label
        property string value
        spacing: 4
        Caption { text: parent.label }
        DigitText { pixelSize: Style.typography.display + 8; isBold: true; text: parent.value }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 28
        spacing: 16

        RowLayout {
            Layout.fillWidth: true
            spacing: 40
            Figure { label: qsTr("Trip A"); value: qsTr("%1 km").arg(dashboardData.tripKm) }
            Figure { label: qsTr("Odometer"); value: qsTr("%L1 km").arg(dashboardData.odometerKm) }
            Figure { label: qsTr("Efficiency"); value: qsTr("%1 Wh/km").arg([24, 28, 35][dashboardData.rideMode]) }
            Item { Layout.fillWidth: true }
            OutlineButton {
                text: root.confirmReset ? qsTr("Reset trip A?") : qsTr("Reset")
                highlighted: root.confirmReset
                tone: Style.danger
                onClicked: {
                    if (root.confirmReset)
                        dashboardData.resetTrip()
                    root.confirmReset = !root.confirmReset
                }
            }
        }

        Caption { Layout.topMargin: 16; text: qsTr("Recent rides") }
        Repeater {
            model: [
                { title: qsTr("Home → Office"), detail: qsTr("Today · 8.4 km · 22 min"), value: qsTr("27 Wh/km") },
                { title: qsTr("Office → Charger, Koramangala"), detail: qsTr("Yesterday · 2.1 km · 7 min"), value: qsTr("24 Wh/km") },
                { title: qsTr("Weekend ride, Nandi Hills"), detail: qsTr("Sunday · 61 km · 1 h 48 min"), value: qsTr("33 Wh/km") },
                { title: qsTr("Office → Home"), detail: qsTr("Friday · 8.6 km · 25 min"), value: qsTr("26 Wh/km") },
            ]
            InfoRow {
                required property var modelData
                Layout.fillWidth: true
                title: modelData.title
                subtitle: modelData.detail
                value: modelData.value
                valueColor: Style.textMuted
                tone: Style.modeColor(dashboardData.rideMode)
            }
        }
        Item { Layout.fillHeight: true }
    }
}
