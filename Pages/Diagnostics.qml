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
        charge: qsTr("Plug in charger"), hazard: qsTr("Hazard lights"), reverse: qsTr("Reverse"),
        clear: qsTr("Clear all")
    })

    component Reading: Control {
        id: reading
        property string label
        property string value
        property bool warn: false
        Layout.fillWidth: true
        topPadding: 18
        bottomPadding: 18
        leftPadding: 12
        rightPadding: 12
        // The soft fill of every row, washed from the left: accent, or amber on a warning.
        background: Rectangle {
            id: readingBackground
            readonly property color tone: reading.warn ? Style.warning : Style.accent
            radius: Style.metrics.radiusMd
            color: Style.alpha(Style.textPrimary, Style.isDark ? 0.045 : 0.035)
            border.color: Style.alpha(tone, reading.warn ? 0.8 : 0.25)
            border.width: reading.warn ? 1.5 : 1
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Style.alpha(readingBackground.tone, Style.isDark ? 0.20 : 0.10) }
                    GradientStop { position: 1.0; color: Style.alpha(readingBackground.tone, 0.0) }
                }
            }
        }
        contentItem: ColumnLayout {
            spacing: 4
            PrefsLabel { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; font.pixelSize: Style.h6; color: Style.textMuted; elide: Text.ElideRight; wrapMode: Text.NoWrap; text: reading.label }
            PrefsLabel {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Style.h1
                isBold: true
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
                color: reading.warn ? Style.warning : Style.textPrimary
                text: reading.value
            }
        }
    }

    // A rounded action: the simulator's scenarios and the phone demos.
    component Pill: AbstractButton {
        id: pill
        focusPolicy: Qt.StrongFocus
        property bool primary: false
        Layout.fillWidth: true
        implicitHeight: 64
        leftPadding: 20
        rightPadding: 20
        scale: pressed ? 0.98 : 1
        Behavior on scale { NumberAnimation { duration: Style.motion.fast } }
        // A pill washed in the accent; the main action full strength.
        background: Rectangle {
            radius: height / 2
            color: Style.alpha(Style.textPrimary, Style.isDark ? 0.045 : 0.035)
            border.color: Style.alpha(Style.accent, pill.primary ? 0.9 : 0.35)
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Style.alpha(Style.accent, pill.primary ? 0.95 : (Style.isDark ? 0.24 : 0.14)) }
                GradientStop { position: 1.0; color: Style.alpha(Style.accent, pill.primary ? 0.65 : 0.02) }
            }
        }
        contentItem: PrefsLabel {
            font.pixelSize: Style.h5
            verticalAlignment: Text.AlignVCenter
            isBold: true
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            wrapMode: Text.NoWrap
            color: pill.primary ? Style.textOnAccent : Style.textPrimary
            text: pill.text
        }
    }

    // Scrolls when the page is shown in the narrower settings panel.
    Flickable {
        anchors.fill: parent
        anchors.leftMargin: 40
        anchors.rightMargin: 40
        anchors.topMargin: 24
        anchors.bottomMargin: 16
        contentHeight: page.implicitHeight + 24
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        ColumnLayout {
            id: page
            width: parent.width
            spacing: 22

            PrefsLabel { font.pixelSize: Style.h1; isBold: true; text: qsTr("Vehicle health") }

            GridLayout {
                Layout.fillWidth: true
                columns: width > 900 ? 4 : 2
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

            // Alerts and, on the desk, the scenarios: side by side when there is
            // room, one under the other in the settings panel.
            GridLayout {
                Layout.fillWidth: true
                columns: simulator.running && width > 1100 ? 2 : 1
                columnSpacing: 30
                rowSpacing: 22

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    spacing: 12
                    PrefsLabel { font.pixelSize: Style.h4; color: Style.textMuted; text: qsTr("Active alerts (%1)").arg(alertCenter.count) }
                    PrefsLabel {
                        Layout.fillWidth: true
                        visible: alertCenter.count === 0
                        font.pixelSize: Style.h4
                        color: Style.success
                        text: qsTr("No alerts. All systems normal.")
                    }
                    Repeater {
                        model: alertCenter
                        Control {
                            id: alertRow
                            required property string title
                            required property string message
                            required property int severity
                            required property string icon
                            Layout.fillWidth: true
                            padding: 14
                            background: Rectangle {
                                radius: Style.metrics.radiusMd
                                color: Style.surface
                                border.color: alertRow.severity === 2 ? Style.danger : alertRow.severity === 1 ? Style.warning : Style.accent
                            }
                            contentItem: RowLayout {
                                spacing: 16
                                AlertIcon { sourceSize: Qt.size(40, 40); key: alertRow.icon; severity: alertRow.severity }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    PrefsLabel { Layout.fillWidth: true; font.pixelSize: Style.h4; isBold: true; elide: Text.ElideRight; wrapMode: Text.NoWrap; text: alertRow.title }
                                    PrefsLabel { Layout.fillWidth: true; font.pixelSize: Style.h6; color: Style.textMuted; wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight; text: alertRow.message }
                                }
                            }
                        }
                    }
                }

                ColumnLayout {
                    visible: simulator.running
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    spacing: 12
                    PrefsLabel { font.pixelSize: Style.h4; color: Style.textMuted; text: qsTr("Simulator scenarios") }
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: 12
                        rowSpacing: 12
                        Repeater {
                            model: simulator.scenarios
                            Pill {
                                required property string modelData
                                primary: modelData === "clear"
                                text: root.scenarioLabels[modelData]
                                onClicked: simulator.trigger(modelData)
                            }
                        }
                        Pill { text: qsTr("Incoming call"); onClicked: phone.simulateIncomingCall() }
                        Pill { text: qsTr("Text message"); onClicked: phone.simulateMessage() }
                    }
                }
            }
        }
    }
}
