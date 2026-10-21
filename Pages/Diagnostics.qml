import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Style 1.0
import "../Component"

// Vehicle health: live readings and every active alert. On the desk the
// simulator's scenarios sit here too, so each alert can be shown on demand.
EaglePage {
    id: root

    readonly property var scenarioLabels: ({
        lowTyre: qsTr("Low tyre"), overheat: qsTr("Overheat"), motorFault: qsTr("Motor fault"),
        lowBattery: qsTr("Low battery"), sideStand: qsTr("Side stand"), absFault: qsTr("ABS fault"),
        charge: qsTr("Plug in charger"), clear: qsTr("Clear all")
    })

    component Reading: Rectangle {
        property string label
        property string value
        property bool warn: false
        Layout.fillWidth: true
        Layout.preferredHeight: 110
        radius: Style.metrics.radiusMd
        color: Style.surface
        border.color: warn ? Style.warning : Style.border
        border.width: warn ? 2 : 1
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 4
            PrefsLabel { Layout.alignment: Qt.AlignHCenter; font.pixelSize: Style.h6; color: Style.textMuted; text: parent.parent.label }
            PrefsLabel {
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: Style.h1
                isBold: true
                color: parent.parent.warn ? Style.warning : Style.textPrimary
                text: parent.parent.value
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 40
        anchors.rightMargin: 40
        anchors.topMargin: 24
        anchors.bottomMargin: 16
        spacing: 22

        PrefsLabel { font.pixelSize: Style.h1; isBold: true; text: qsTr("Vehicle health") }

        GridLayout {
            Layout.fillWidth: true
            columns: 4
            columnSpacing: 16
            rowSpacing: 16
            Reading { label: qsTr("Battery"); value: qsTr("%1%").arg(dashboardData.batteryPercent); warn: dashboardData.batteryPercent <= 15 }
            Reading { label: qsTr("Battery temp"); value: qsTr("%1 °C").arg(dashboardData.batteryTempC); warn: dashboardData.batteryTempC >= 55 }
            Reading { label: qsTr("Motor temp"); value: qsTr("%1 °C").arg(dashboardData.motorTempC); warn: dashboardData.motorTempC >= 90 }
            Reading { label: qsTr("Odometer"); value: qsTr("%L1 km").arg(dashboardData.odometerKm) }
            Reading { label: qsTr("Front tyre"); value: qsTr("%1 bar").arg(dashboardData.tyreFrontBar.toFixed(1)); warn: dashboardData.tyreFrontBar < 1.8 }
            Reading { label: qsTr("Rear tyre"); value: qsTr("%1 bar").arg(dashboardData.tyreRearBar.toFixed(1)); warn: dashboardData.tyreRearBar < 1.8 }
            Reading { label: qsTr("Motor"); value: dashboardData.motorFault ? qsTr("Fault") : qsTr("OK"); warn: dashboardData.motorFault }
            Reading { label: qsTr("ABS"); value: dashboardData.absFault ? qsTr("Fault") : qsTr("OK"); warn: dashboardData.absFault }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 30

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12
                PrefsLabel { font.pixelSize: Style.h4; color: Style.textMuted; text: qsTr("Active alerts (%1)").arg(alertCenter.count) }
                PrefsLabel {
                    visible: alertCenter.count === 0
                    font.pixelSize: Style.h4
                    color: Style.success
                    text: qsTr("No alerts. All systems normal.")
                }
                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 8
                    model: alertCenter
                    delegate: Rectangle {
                        required property string title
                        required property string message
                        required property int severity
                        required property string icon
                        width: ListView.view.width
                        height: 86
                        radius: Style.metrics.radiusMd
                        color: Style.surface
                        border.color: severity === 2 ? Style.danger : severity === 1 ? Style.warning : Style.accent
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 16
                            AlertIcon { sourceSize: Qt.size(40, 40); key: icon; severity: parent.parent.severity }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                PrefsLabel { font.pixelSize: Style.h4; isBold: true; text: title }
                                PrefsLabel { Layout.fillWidth: true; font.pixelSize: Style.h6; color: Style.textMuted; text: message }
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                visible: simulator.running
                Layout.preferredWidth: 520
                Layout.fillHeight: true
                spacing: 12
                PrefsLabel { font.pixelSize: Style.h4; color: Style.textMuted; text: qsTr("Simulator scenarios") }
                GridLayout {
                    columns: 2
                    columnSpacing: 12
                    rowSpacing: 12
                    Repeater {
                        model: simulator.scenarios
                        Rectangle {
                            required property string modelData
                            implicitWidth: 250
                            implicitHeight: 64
                            radius: 32
                            color: modelData === "clear" ? Style.accent : Style.surfaceRaised
                            border.color: Style.border
                            PrefsLabel {
                                anchors.centerIn: parent
                                font.pixelSize: Style.h5
                                isBold: true
                                color: modelData === "clear" ? Style.textOnAccent : Style.textPrimary
                                text: root.scenarioLabels[modelData]
                            }
                            TapHandler { onTapped: simulator.trigger(modelData) }
                        }
                    }
                    Rectangle {
                        implicitWidth: 250
                        implicitHeight: 64
                        radius: 32
                        color: Style.surfaceRaised
                        border.color: Style.border
                        PrefsLabel { anchors.centerIn: parent; font.pixelSize: Style.h5; isBold: true; text: qsTr("Incoming call") }
                        TapHandler { onTapped: phone.simulateIncomingCall() }
                    }
                    Rectangle {
                        implicitWidth: 250
                        implicitHeight: 64
                        radius: 32
                        color: Style.surfaceRaised
                        border.color: Style.border
                        PrefsLabel { anchors.centerIn: parent; font.pixelSize: Style.h5; isBold: true; text: qsTr("Text message") }
                        TapHandler { onTapped: phone.simulateMessage() }
                    }
                }
                Item { Layout.fillHeight: true }
            }
        }
    }
}
