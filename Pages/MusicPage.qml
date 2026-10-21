import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Style 1.0
import "../Component"

// What the phone is playing, with the controls that send commands back to it.
EaglePage {
    id: root

    readonly property color modeColor: Style.modeColor(dashboardData.rideMode)

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.6, 1100)
        spacing: 34

        RowLayout {
            Layout.fillWidth: true
            spacing: 48

            Image {
                id: art
                Layout.preferredWidth: 300
                Layout.preferredHeight: 300
                fillMode: Image.PreserveAspectCrop
                source: "qrc:/Icons/Music/codex-omega.png"
                scale: phone.playing ? 1 : 0.94
                Behavior on scale { NumberAnimation { duration: Style.motion.theme; easing.type: Easing.OutBack } }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                PrefsLabel {
                    font.pixelSize: Style.h5
                    color: Style.textMuted
                    text: phone.connected ? qsTr("Now playing on %1").arg(phone.deviceName) : qsTr("No phone connected")
                }
                PrefsLabel {
                    Layout.topMargin: 20
                    font.pixelSize: 52
                    isBold: true
                    text: phone.trackTitle
                }
                PrefsLabel {
                    font.pixelSize: Style.h1
                    color: Style.textSecondary
                    text: phone.trackArtist
                }
                PrefsLabel {
                    font.pixelSize: Style.h4
                    color: Style.textMuted
                    text: phone.trackAlbum
                }
            }
        }

        // Progress.
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 10
                radius: 5
                color: Style.surfaceSunken
                Rectangle {
                    width: parent.width * Math.min(1, phone.positionSeconds / Math.max(1, phone.durationSeconds))
                    height: parent.height
                    radius: 5
                    color: root.modeColor
                    Behavior on width { NumberAnimation { duration: 900 } }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                PrefsLabel { font.pixelSize: Style.h6; color: Style.textMuted; text: phone.formatDuration(phone.positionSeconds) }
                Item { Layout.fillWidth: true }
                PrefsLabel { font.pixelSize: Style.h6; color: Style.textMuted; text: phone.formatDuration(phone.durationSeconds) }
            }
        }

        // Transport.
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 40
            IconButton {
                roundIcon: true
                implicitWidth: 80
                implicitHeight: 80
                iconWidth: 22
                iconHeight: 26
                iconBackground: root.modeColor
                setIcon: "qrc:/Icons/Music/Left.svg"
                onClicked: phone.previous()
            }
            IconButton {
                roundIcon: true
                implicitWidth: 110
                implicitHeight: 110
                iconWidth: 30
                iconHeight: 34
                iconBackground: root.modeColor
                setIcon: phone.playing ? "qrc:/Icons/Music/pause_paly.svg" : "qrc:/Icons/Music/Play.svg"
                onClicked: phone.playPause()
            }
            IconButton {
                roundIcon: true
                implicitWidth: 80
                implicitHeight: 80
                iconWidth: 22
                iconHeight: 26
                iconBackground: root.modeColor
                setIcon: "qrc:/Icons/Music/right.svg"
                onClicked: phone.next()
            }
        }

        // Volume.
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 18
            IconButton {
                setIconText: "−"
                setIconSize: 34
                onClicked: phone.volume = phone.volume - 10
            }
            Rectangle {
                Layout.preferredWidth: 360
                Layout.preferredHeight: 8
                radius: 4
                color: Style.surfaceSunken
                Rectangle {
                    width: parent.width * phone.volume / 100
                    height: parent.height
                    radius: 4
                    color: root.modeColor
                    Behavior on width { NumberAnimation { duration: Style.motion.fast } }
                }
            }
            IconButton {
                setIconText: "+"
                setIconSize: 34
                onClicked: phone.volume = phone.volume + 10
            }
            PrefsLabel {
                Layout.preferredWidth: 70
                font.pixelSize: Style.h5
                color: Style.textMuted
                text: qsTr("%1%").arg(phone.volume)
            }
        }
    }
}
