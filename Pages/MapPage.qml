import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Style 1.0
import "../Component"

// Navigation, after the ApexCluster design: the next manoeuvre drawn onto the
// road with its distance large, what to do and where above it, the remaining
// distance and arrival time below; the route and saved places on the right.
EaglePage {
    id: root

    readonly property color modeColor: Style.modeColor(dashboardData.rideMode)
    property string destination: qsTr("Office")
    readonly property var places: [
        { name: qsTr("Home"), detail: qsTr("8.4 km · about 15 min") },
        { name: qsTr("Office"), detail: qsTr("6.4 km · about 12 min") },
        { name: qsTr("Charger · Koramangala"), detail: qsTr("2.1 km · about 4 min") },
    ]

    function instruction(maneuver) {
        switch (maneuver) {
        case 1: return qsTr("Turn left onto")
        case 2: return qsTr("Turn right onto")
        case 3: return qsTr("Make a U-turn at")
        case 4: return qsTr("Arriving at")
        }
        return qsTr("Continue on")
    }

    leftPadding: Style.metrics.pageMargin
    rightPadding: Style.metrics.pageMargin
    topPadding: 24
    bottomPadding: 24

    contentItem: RowLayout {
        spacing: 28

        Panel {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            TurnView {
                anchors.fill: parent
                anchors.topMargin: 150
                anchors.bottomMargin: 70
                maneuver: dashboardData.maneuver
                arrowColor: root.modeColor
            }

            // What to do and where.
            ColumnLayout {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.margins: 32
                spacing: 6
                Caption { accent: true; text: root.instruction(dashboardData.maneuver) }
                PrefsLabel {
                    font.pixelSize: Style.typography.display + 6
                    isBold: true
                    text: dashboardData.street
                }
            }

            // Distance to the manoeuvre.
            Row {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 28
                spacing: 8
                PrefsLabel {
                    id: distanceValue
                    font.pixelSize: 72
                    text: dashboardData.maneuverDistanceM >= 1000
                          ? (dashboardData.maneuverDistanceM / 1000).toFixed(1)
                          : dashboardData.maneuverDistanceM
                }
                PrefsLabel {
                    anchors.baseline: distanceValue.baseline
                    font.pixelSize: Style.h1
                    color: Style.textMuted
                    text: dashboardData.maneuverDistanceM >= 1000 ? qsTr("km") : qsTr("m")
                }
            }

            // Remaining and arrival.
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 70
                color: Style.surfaceSunken
                radius: Style.metrics.radiusLg
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 32
                    anchors.rightMargin: 32
                    PrefsLabel {
                        font.pixelSize: Style.h4
                        text: qsTr("%1 km remaining").arg(dashboardData.distanceKm.toFixed(1))
                    }
                    Item { Layout.fillWidth: true }
                    PrefsLabel {
                        font.pixelSize: Style.h4
                        isBold: true
                        text: qsTr("ETA %1").arg(Qt.formatTime(new Date(Date.now() + dashboardData.arrivalMinutes * 60000), "hh:mm"))
                    }
                }
            }
        }

        ColumnLayout {
            Layout.preferredWidth: 600
            Layout.fillWidth: false   // a child filling would otherwise make the column grab the row
            Layout.fillHeight: true
            spacing: 18

            Panel {
                Layout.fillWidth: true
                Layout.preferredHeight: 330
                clip: true
                RouteMap {
                    anchors.fill: parent
                    anchors.margins: 2
                    progress: 1 - Math.min(1, dashboardData.distanceKm / 8.4)
                    routeColor: root.modeColor
                }
                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.margins: 14
                    width: routeLabel.implicitWidth + 28
                    height: 40
                    radius: 20
                    color: Style.surface
                    Caption {
                        id: routeLabel
                        anchors.centerIn: parent
                        text: qsTr("To %1").arg(root.destination)
                    }
                }
            }

            Caption { text: qsTr("Where to?") }
            Repeater {
                model: root.places
                InfoRow {
                    required property var modelData
                    Layout.fillWidth: true
                    title: modelData.name
                    subtitle: modelData.detail
                    selected: root.destination === modelData.name
                    tone: root.modeColor
                    value: selected ? qsTr("Active") : qsTr("Go")
                    valueColor: selected ? root.modeColor : Style.textMuted
                    onClicked: root.destination = modelData.name
                }
            }
            Item { Layout.fillHeight: true }
        }
    }
}
