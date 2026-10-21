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

    // Ride mode and readiness.
    RowLayout {
        id: modeRow
        anchors.horizontalCenter: wings.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 24
        spacing: 18

        Rectangle {
            implicitWidth: modeLabel.implicitWidth + 44
            implicitHeight: 44
            radius: 22
            color: Style.alpha(page.modeColor, 0.14)
            border.color: page.modeColor
            border.width: 2
            Behavior on color { ColorAnimation { duration: Style.motion.normal } }

            RowLayout {
                anchors.centerIn: parent
                spacing: 10
                Rectangle {
                    implicitWidth: 12
                    implicitHeight: 12
                    radius: 6
                    color: page.modeColor
                }
                PrefsLabel {
                    id: modeLabel
                    font.pixelSize: Style.h2
                    isBold: true
                    color: page.modeColor
                    text: dashboardData.rideModeName.toUpperCase()
                }
            }

            TapHandler { onTapped: dashboardData.cycleRideMode() }
        }

        PrefsLabel {
            font.pixelSize: Style.h4
            isBold: true
            color: dashboardData.ready ? Style.success : Style.textMuted
            text: dashboardData.charging ? qsTr("CHARGING")
                                         : dashboardData.ready ? qsTr("READY") : qsTr("SELF CHECK")
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

    // Power and regen: regen fills to the left of centre, drive to the right.
    Item {
        id: powerMeter
        anchors.horizontalCenter: wings.horizontalCenter
        anchors.top: gears.bottom
        anchors.topMargin: 16
        width: 360
        height: 30

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 8
            radius: 4
            color: Style.surfaceSunken
        }
        Rectangle {
            readonly property real share: Math.max(-1, Math.min(1, power.value / 6.0))
            anchors.verticalCenter: parent.verticalCenter
            x: share >= 0 ? parent.width / 2 : parent.width / 2 + share * parent.width / 2
            width: Math.abs(share) * parent.width / 2
            height: 8
            radius: 4
            color: share >= 0 ? page.modeColor : Style.success
            Behavior on x { NumberAnimation { duration: Style.motion.normal } }
            Behavior on width { NumberAnimation { duration: Style.motion.normal } }
        }
        Rectangle {
            anchors.centerIn: parent
            width: 2
            height: 20
            color: Style.textMuted
        }
        DigitText {
            anchors.left: parent.right
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            pixelSize: Style.h6
            color: Style.textMuted
            text: power.value < -0.05 ? qsTr("Regen %1 kW").arg((-power.value).toFixed(1))
                                      : qsTr("%1 kW").arg(Math.max(0, power.value).toFixed(1))
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
                font.pixelSize: Style.h4
                isBold: true
                text: phone.trackTitle
            }
            PrefsLabel {
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: Style.h6
                color: Style.textMuted
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
            DigitText {
                pixelSize: Style.h5
                color: parent.valueColor
                text: parent.value
            }
        }
        component Separator: Image {
            Layout.preferredWidth: 170
            source: "qrc:/Icons/seprator.png"
        }

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

    Rectangle {
        visible: dashboardData.navigating
        anchors.left: parent.left
        anchors.leftMargin: 40
        anchors.top: parent.top
        anchors.topMargin: 24
        width: 360
        height: 150
        radius: Style.metrics.radiusLg
        color: Style.surface
        border.color: Style.border
        opacity: 0.96

        RowLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 16

            Rectangle {
                Layout.preferredWidth: 96
                Layout.preferredHeight: 96
                radius: Style.metrics.radiusMd
                color: page.modeColor
                ManeuverIcon {
                    anchors.centerIn: parent
                    width: 72
                    height: 72
                    maneuver: dashboardData.maneuver
                    color: Style.textOnAccent
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
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
                    text: dashboardData.street
                }
                DigitText {
                    pixelSize: Style.h6
                    color: Style.textMuted
                    text: qsTr("%1 min · %2 km left").arg(dashboardData.arrivalMinutes)
                                                       .arg(dashboardData.distanceKm.toFixed(1))
                }
            }
        }
    }
}
