import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../Component"
import Style 1.0

// The ride view: speed in the wings, mode and gear above it, power below it, the
// next turn on the left, the vehicle on the right and the phone's music beneath.
Page {
    id: page

    readonly property color modeColor: Style.modeColor(dashboardData.rideMode)

    // Figures are shown a few times a second, so they can be read at a glance.
    Sampled { id: speed; source: dashboardData.speed; interval: 250 }
    Sampled { id: power; source: dashboardData.powerKw; deadband: 0.05 }
    Sampled { id: turnDistance; source: dashboardData.maneuverDistanceM; interval: 500 }

    function distanceText(metres) {
        if (metres >= 1000)
            return qsTr("%1 km").arg((metres / 1000).toFixed(1))
        // Under a kilometre, steps of 10 m: the last digit would only flicker.
        return qsTr("%1 m").arg(Math.round(metres / 10) * 10)
    }

    padding: 0
    background: Rectangle { color: Style.background }

    // Ride mode and readiness: the three modes spaced out like a caption, the
    // current one lit in its colour with a bar under it that slides across when
    // the mode changes; then a status lamp. Tap a mode to select it.
    RowLayout {
        id: modeRow
        anchors.horizontalCenter: wings.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 28
        spacing: 36

        Item {
            implicitWidth: modes.implicitWidth
            implicitHeight: modes.implicitHeight + 14

            Row {
                id: modes
                spacing: 34
                Repeater {
                    id: modeRepeater
                    model: [qsTr("ECO"), qsTr("CITY"), qsTr("SPORT")]
                    PrefsLabel {
                        required property string modelData
                        required property int index
                        readonly property bool current: dashboardData.rideMode === index
                        font.pixelSize: Style.h4
                        font.letterSpacing: 4
                        isBold: current
                        color: current ? Style.modeColor(index) : Style.textMuted
                        opacity: current ? 1 : 0.7
                        text: modelData
                        TapHandler { onTapped: dashboardData.rideMode = index }
                    }
                }
            }

            Rectangle {
                readonly property Item target: modeRepeater.itemAt(dashboardData.rideMode)
                anchors.bottom: parent.bottom
                x: target ? target.x : 0
                width: target ? target.width - 4 : 0
                height: 3
                radius: 1.5
                color: page.modeColor
                Behavior on x { NumberAnimation { duration: Style.motion.normal; easing.type: Easing.OutCubic } }
                Behavior on width { NumberAnimation { duration: Style.motion.normal; easing.type: Easing.OutCubic } }
            }
        }

        Rectangle {
            Layout.preferredWidth: 1
            Layout.preferredHeight: 28
            color: Style.border
        }

        RowLayout {
            spacing: 10
            readonly property color tone: dashboardData.charging ? Style.accent
                                          : dashboardData.ready ? Style.success : Style.warning
            Rectangle {
                implicitWidth: 10
                implicitHeight: 10
                radius: 5
                color: parent.tone
            }
            Caption {
                color: parent.tone
                text: dashboardData.charging ? qsTr("Charging")
                                             : dashboardData.ready ? qsTr("Ready") : qsTr("Self check")
            }
        }
    }

    Image {
        id: wings
        width: 1120
        height: 596
        anchors.centerIn: parent
        sourceSize: Qt.size(1120, 596)
        source: Style.isDark ? "qrc:/Icons/Eagle/5.png" : "qrc:/Icons/Eagle/7.png"
    }

    // Speed.
    DigitText {
        id: speedLabel
        anchors.horizontalCenter: wings.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -150
        pixelSize: 140
        isBold: true
        text: Math.round(speed.value)
    }
    PrefsLabel {
        id: unitLabel
        anchors.horizontalCenter: wings.horizontalCenter
        anchors.top: speedLabel.bottom
        anchors.topMargin: -8
        font.pixelSize: Style.h2
        isBold: true
        color: Style.textMuted
        text: dashboardData.speedUnit
    }

    // Gear.
    RowLayout {
        id: gears
        anchors.horizontalCenter: wings.horizontalCenter
        anchors.top: unitLabel.bottom
        anchors.topMargin: 18
        spacing: 26
        Repeater {
            model: ["P", "R", "N", "D"]
            PrefsLabel {
                required property string modelData
                readonly property bool current: dashboardData.gear === modelData
                font.pixelSize: current ? Style.h1 : Style.h4
                isBold: current
                color: current ? page.modeColor : Style.textMuted
                text: modelData
                Behavior on font.pixelSize { NumberAnimation { duration: Style.motion.fast } }
            }
        }
    }

    // Now playing from the phone.
    ColumnLayout {
        anchors.horizontalCenter: wings.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 290
        spacing: 10
        visible: phone.connected

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 2
            PrefsLabel {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 520
                font.pixelSize: Style.h4
                isBold: true
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
                text: phone.trackTitle
            }
            PrefsLabel {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 520
                font.pixelSize: Style.h6
                color: Style.textMuted
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
                text: phone.trackArtist
            }
        }
        Image {
            Layout.alignment: Qt.AlignHCenter
            source: "qrc:/Icons/fooo.svg"
            opacity: phone.playing ? 1 : 0.35
            transformOrigin: Item.Center
            SequentialAnimation on scale {
                running: phone.playing
                loops: Animation.Infinite
                NumberAnimation { to: 1.06; duration: 420; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.96; duration: 420; easing.type: Easing.InOutSine }
            }
            Behavior on opacity { NumberAnimation { duration: Style.motion.normal } }
        }
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 20
            IconButton {
                setIcon: "qrc:/Icons/Music/first_page.svg"
                onClicked: phone.previous()
            }
            IconButton {
                roundIcon: true
                implicitHeight: 60
                implicitWidth: 60
                iconWidth: 24
                iconHeight: 28
                setIcon: phone.playing ? "qrc:/Icons/Music/pause_paly.svg" : "qrc:/Icons/Music/Play.svg"
                onClicked: phone.playPause()
            }
            IconButton {
                setIcon: "qrc:/Icons/Music/last_page.svg"
                onClicked: phone.next()
            }
        }
    }

    // Vehicle.
    ColumnLayout {
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: 48
        spacing: 18

        component Stat: ColumnLayout {
            property string title
            property string value
            property color valueColor: Style.textMuted
            spacing: 2
            PrefsLabel {
                isStyle: true
                text: parent.title
            }
            PrefsLabel {
                font.pixelSize: Style.h5
                color: parent.valueColor
                wrapMode: Text.NoWrap
                text: parent.value
            }
        }
        component Separator: Image {
            Layout.preferredWidth: 170
            source: "qrc:/Icons/seprator.png"
        }

        // Power and regen, off the wings so they stay clear: regen fills left of
        // the centre mark, drive to the right.
        ColumnLayout {
            spacing: 6
            PrefsLabel {
                isStyle: true
                text: power.value < -0.05 ? qsTr("Regen") : qsTr("Power")
            }
            DigitText {
                pixelSize: Style.h5
                color: Style.textMuted
                text: qsTr("%1 kW").arg(Math.abs(power.value).toFixed(1))
            }
            Item {
                implicitWidth: 220
                implicitHeight: 14
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 6
                    radius: 3
                    color: Style.surfaceSunken
                }
                Rectangle {
                    readonly property real share: Math.max(-1, Math.min(1, power.value / 6.0))
                    anchors.verticalCenter: parent.verticalCenter
                    x: share >= 0 ? parent.width / 2 : parent.width / 2 + share * parent.width / 2
                    width: Math.abs(share) * parent.width / 2
                    height: 6
                    radius: 3
                    color: share >= 0 ? page.modeColor : Style.success
                    Behavior on x { NumberAnimation { duration: Style.motion.normal } }
                    Behavior on width { NumberAnimation { duration: Style.motion.normal } }
                }
                Rectangle {
                    anchors.centerIn: parent
                    width: 2
                    height: 14
                    color: Style.textMuted
                }
            }
        }
        Separator {}
        Stat {
            title: qsTr("Trip A")
            value: qsTr("%1 km").arg(dashboardData.tripKm)
        }
        Separator {}
        Stat {
            title: qsTr("Odometer")
            value: qsTr("%L1 km").arg(dashboardData.odometerKm)
        }
        Separator {}
        Stat {
            title: qsTr("Temperature")
            value: qsTr("Outside %1 °C · Motor %2 °C").arg(dashboardData.temperatureC).arg(dashboardData.motorTempC)
            valueColor: dashboardData.motorTempC >= 90 ? Style.warning : Style.textMuted
        }
        Separator {}
        Stat {
            readonly property bool low: Math.min(dashboardData.tyreFrontBar, dashboardData.tyreRearBar) < 1.8
            title: qsTr("Tyres")
            value: qsTr("Front %1 · Rear %2 bar").arg(dashboardData.tyreFrontBar.toFixed(1))
                                                .arg(dashboardData.tyreRearBar.toFixed(1))
            valueColor: low ? Style.warning : Style.textMuted
        }
    }

    // Navigation: the next turn over the route map.
    Image {
        id: miniMap
        anchors.left: parent.left
        anchors.leftMargin: 20
        anchors.verticalCenter: parent.verticalCenter
        source: "qrc:/Icons/dummyMap.png"
        opacity: dashboardData.navigating ? 1 : 0.4
    }

    // The next turn: arrow, distance, street and what is left, no card behind it.
    RowLayout {
        visible: dashboardData.navigating
        anchors.left: parent.left
        anchors.leftMargin: 48
        anchors.top: parent.top
        anchors.topMargin: 28
        width: 380
        spacing: 18

        ManeuverIcon {
            Layout.preferredWidth: 72
            Layout.preferredHeight: 72
            Layout.alignment: Qt.AlignTop
            maneuver: dashboardData.maneuver
            color: page.modeColor
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            DigitText {
                pixelSize: Style.h1
                isBold: true
                text: page.distanceText(turnDistance.value)
            }
            PrefsLabel {
                Layout.fillWidth: true
                font.pixelSize: Style.h5
                color: Style.textSecondary
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
                maximumLineCount: 1
                text: dashboardData.street
            }
            PrefsLabel {
                Layout.fillWidth: true
                font.pixelSize: Style.h6
                color: Style.textMuted
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
                text: qsTr("%1 min · %2 km").arg(dashboardData.arrivalMinutes)
                                            .arg(dashboardData.distanceKm.toFixed(1))
            }
        }
    }
}
