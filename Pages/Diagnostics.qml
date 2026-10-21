import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Style 1.0
import "../Component"

// Vehicle health: live readings and every active alert. On the desk the
// simulator's scenarios sit here too, so each alert can be shown on demand.
EaglePage {
    id: root

    // Each scenario in the colour of what it raises.
    readonly property var scenarioTones: ({
        lowTyre: Style.warning, overheat: Style.warning, lowBattery: Style.warning, absFault: Style.warning,
        motorFault: Style.danger, sideStand: Style.danger,
        charge: Style.success, hazard: Style.success, reverse: "#F28C28", clear: Style.accent
    })

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
        property color hue: Style.accent   // the tile's own colour; amber replaces it on a warning
        Layout.fillWidth: true
        topPadding: 18
        bottomPadding: 18
        leftPadding: 12
        rightPadding: 12
        // The soft fill of every row, washed from the left: accent, or amber on a warning.
        background: Rectangle {
            id: readingBackground
            readonly property color tone: reading.warn ? Style.warning : reading.hue
            radius: Style.metrics.radiusMd
            color: Style.alpha(Style.textPrimary, Style.isDark ? 0.045 : 0.035)
            border.color: Style.alpha(tone, reading.warn ? 0.8 : 0.4)
            border.width: reading.warn ? 1.5 : 1
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Style.alpha(readingBackground.tone, Style.isDark ? 0.24 : 0.13) }
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
        property color tone: Style.accent   // the kind of action: critical, warning, phone…
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
            border.color: Style.alpha(pill.tone, pill.primary ? 0.9 : 0.5)
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Style.alpha(pill.tone, pill.primary ? 0.95 : (Style.isDark ? 0.28 : 0.16)) }
                GradientStop { position: 1.0; color: Style.alpha(pill.tone, pill.primary ? 0.65 : 0.02) }
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
                Reading { hue: "#2EBD59"; label: qsTr("Battery"); value: qsTr("%1%").arg(dashboardData.batteryPercent); warn: dashboardData.batteryPercent <= 15 }
                Reading { hue: "#F28C28"; label: qsTr("Battery temp"); value: qsTr("%1 °C").arg(dashboardData.batteryTempC); warn: dashboardData.batteryTempC >= 55 }
                Reading { hue: "#E8590C"; label: qsTr("Motor temp"); value: qsTr("%1 °C").arg(dashboardData.motorTempC); warn: dashboardData.motorTempC >= 90 }
                Reading { hue: "#3B82F6"; label: qsTr("Odometer"); value: qsTr("%L1 km").arg(dashboardData.odometerKm) }
                Reading { hue: "#14B8C4"; label: qsTr("Front tyre"); value: qsTr("%1 bar").arg(dashboardData.tyreFrontBar.toFixed(1)); warn: dashboardData.tyreFrontBar < 1.8 }
                Reading { hue: "#14B8C4"; label: qsTr("Rear tyre"); value: qsTr("%1 bar").arg(dashboardData.tyreRearBar.toFixed(1)); warn: dashboardData.tyreRearBar < 1.8 }
                Reading { hue: "#8B5CF6"; label: qsTr("Motor"); value: dashboardData.motorFault ? qsTr("Fault") : qsTr("OK"); warn: dashboardData.motorFault }
                Reading { hue: "#6366F1"; label: qsTr("ABS"); value: dashboardData.absFault ? qsTr("Fault") : qsTr("OK"); warn: dashboardData.absFault }
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
                            // The tiles' style, in the alert's colour.
                            background: Rectangle {
                                id: alertBackground
                                readonly property color tone: alertRow.severity === 2 ? Style.danger
                                                              : alertRow.severity === 1 ? Style.warning : Style.success
                                radius: Style.metrics.radiusMd
                                color: Style.alpha(Style.textPrimary, Style.isDark ? 0.045 : 0.035)
                                border.color: Style.alpha(tone, 0.5)
                                Rectangle {
                                    anchors.fill: parent
                                    radius: parent.radius
                                    gradient: Gradient {
                                        orientation: Gradient.Horizontal
                                        GradientStop { position: 0.0; color: Style.alpha(alertBackground.tone, Style.isDark ? 0.24 : 0.13) }
                                        GradientStop { position: 0.8; color: Style.alpha(alertBackground.tone, 0.0) }
                                    }
                                }
                            }
                            contentItem: RowLayout {
                                spacing: 16
                                // The telltale where there is one; otherwise a line icon in the alert's colour,
                                // which reads on both themes (the white symbol files do not on light).
                                readonly property bool telltale: ["tyre", "sideStand", "batteryTemp"].indexOf(alertRow.icon) >= 0
                                AlertIcon {
                                    visible: parent.telltale
                                    sourceSize: Qt.size(40, 40)
                                    key: alertRow.icon
                                    severity: alertRow.severity
                                }
                                LineIcon {
                                    visible: !parent.telltale
                                    size: 40
                                    strokeWidth: 2
                                    color: alertBackground.tone
                                    name: alertRow.severity === 2 ? "xCircle" : alertRow.severity === 1 ? "alertCircle" : "checkCircle"
                                }
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
                                tone: root.scenarioTones[modelData] || Style.accent
                                text: root.scenarioLabels[modelData]
                                onClicked: simulator.trigger(modelData)
                            }
                        }
                        Pill { tone: "#3B82F6"; text: qsTr("Incoming call"); onClicked: phone.simulateIncomingCall() }
                        Pill { tone: "#3B82F6"; text: qsTr("Text message"); onClicked: phone.simulateMessage() }
                    }
                }
            }
        }
    }
}
