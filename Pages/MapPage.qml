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
    readonly property bool phoneRoute: phone.linked && phone.connected && dashboardData.navigating
    Sampled { id: turnDistance; source: dashboardData.maneuverDistanceM; interval: 500 }
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
                anchors.bottomMargin: 150
                maneuver: dashboardData.maneuver
                arrowColor: root.modeColor
            }

            // What to do and where.
            ColumnLayout {
                anchors.left: parent.left
                anchors.right: distanceRow.left
                anchors.top: parent.top
                anchors.margins: 32
                spacing: 6
                Caption { accent: true; text: root.instruction(dashboardData.maneuver) }
                // A long road name takes a second line, then elides.
                PrefsLabel {
                    Layout.fillWidth: true
                    font.pixelSize: Style.typography.display + 6
                    isBold: true
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    text: dashboardData.street
                }
            }

            // Distance to the manoeuvre.
            Row {
                id: distanceRow
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 28
                spacing: 8
                DigitText {
                    id: distanceValue
                    pixelSize: 72
                    text: turnDistance.value >= 1000
                          ? (turnDistance.value / 1000).toFixed(1)
                          : Math.round(turnDistance.value / 10) * 10
                }
                PrefsLabel {
                    anchors.baseline: distanceValue.baseline
                    font.pixelSize: Style.h1
                    color: Style.textMuted
                    text: turnDistance.value >= 1000 ? qsTr("km") : qsTr("m")
                }
            }

            // The trip: how far along the route the rider is, then what is left,
            // how long it takes and when they arrive, as three figures.
            ColumnLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: 32
                anchors.rightMargin: 32
                anchors.bottomMargin: 24
                spacing: 18

                Item {
                    id: track
                    readonly property real progress: 1 - Math.min(1, dashboardData.distanceKm / 8.4)
                    Layout.fillWidth: true
                    implicitHeight: 16
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: 4
                        radius: 2
                        color: Style.border
                    }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width * track.progress
                        height: 4
                        radius: 2
                        color: root.modeColor
                        Behavior on width { NumberAnimation { duration: Style.motion.theme } }
                    }
                    Rectangle {   // the rider
                        anchors.verticalCenter: parent.verticalCenter
                        x: parent.width * track.progress - width / 2
                        width: 16
                        height: 16
                        radius: 8
                        color: Style.surface
                        border.color: root.modeColor
                        border.width: 4
                        Behavior on x { NumberAnimation { duration: Style.motion.theme } }
                    }
                    Rectangle {   // the destination
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        width: 12
                        height: 12
                        radius: 3
                        rotation: 45
                        color: Style.textPrimary
                    }
                }

                // Three equal cells, so the figures sit at the same place whatever they read.
                Row {
                    id: figures
                    Layout.fillWidth: true

                    component TripFigure: Item {
                        id: cell
                        property string label
                        property string value
                        property string unit
                        property bool strong: false
                        property bool divider: true
                        width: figures.width / 3
                        implicitHeight: cellColumn.implicitHeight

                        Rectangle {
                            visible: cell.divider
                            y: 4
                            width: 1
                            height: cellColumn.height - 8
                            color: Style.border
                        }
                        Column {
                            id: cellColumn
                            x: cell.divider ? 28 : 0
                            spacing: 4
                            Caption { text: cell.label }
                            Row {
                                spacing: 8
                                DigitText {
                                    id: figure
                                    pixelSize: Style.typography.display
                                    isBold: cell.strong
                                    text: cell.value
                                }
                                PrefsLabel {
                                    anchors.baseline: figure.baseline
                                    font.pixelSize: Style.h5
                                    color: Style.textMuted
                                    text: cell.unit
                                }
                            }
                        }
                    }

                    TripFigure {
                        divider: false
                        label: qsTr("Remaining")
                        value: dashboardData.distanceKm.toFixed(1)
                        unit: qsTr("km")
                    }
                    TripFigure {
                        label: qsTr("Time")
                        value: dashboardData.arrivalMinutes
                        unit: qsTr("min")
                    }
                    TripFigure {
                        label: qsTr("Arrival")
                        value: Qt.formatTime(new Date(Date.now() + dashboardData.arrivalMinutes * 60000), "hh:mm")
                        strong: true
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
                        text: root.phoneRoute ? qsTr("Route from the Ride app") : qsTr("To %1").arg(root.destination)
                    }
                }
            }

            // With the app guiding, the destination is chosen on the phone.
            Panel {
                visible: root.phoneRoute
                Layout.fillWidth: true
                Layout.preferredHeight: 150
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 8
                    Caption { accent: true; text: qsTr("Guided by your phone") }
                    PrefsLabel {
                        Layout.fillWidth: true
                        font.pixelSize: Style.h4
                        text: qsTr("Pick or change the destination in the Ride app; turns follow here live.")
                    }
                }
            }

            Caption { visible: !root.phoneRoute; text: qsTr("Where to?") }
            Repeater {
                model: root.phoneRoute ? [] : root.places
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
