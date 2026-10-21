import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Style 1.0
import "../Component"

// What the phone is playing, in the SR Motard style: artwork tile, source, title
// and artist, progress, then PREV / PAUSE / NEXT and the volume.
EaglePage {
    id: root

    readonly property color modeColor: Style.modeColor(dashboardData.rideMode)

    leftPadding: Style.metrics.pageMargin
    rightPadding: Style.metrics.pageMargin
    topPadding: 24
    bottomPadding: 24

    contentItem: RowLayout {
        spacing: 28

        Panel {
            Layout.fillWidth: true
            Layout.fillHeight: true

            RowLayout {
                anchors.fill: parent
                anchors.margins: 48
                spacing: 56

                // Artwork.
                Rectangle {
                    Layout.preferredWidth: 400
                    Layout.preferredHeight: 400
                    Layout.alignment: Qt.AlignVCenter
                    radius: 24
                    gradient: Gradient {
                        GradientStop { position: 0; color: Qt.lighter(root.modeColor, 1.25) }
                        GradientStop { position: 1; color: Qt.darker(root.modeColor, 1.3) }
                    }
                    scale: phone.playing ? 1 : 0.95
                    Behavior on scale { NumberAnimation { duration: Style.motion.theme; easing.type: Easing.OutBack } }
                    PrefsLabel {
                        visible: cover.status !== Image.Ready
                        anchors.centerIn: parent
                        font.pixelSize: 170
                        color: "#FFFFFF"
                        text: "♫"
                    }
                    // The cover the phone sends with the track, when it sends one.
                    Image {
                        id: cover
                        anchors.fill: parent
                        source: phone.artworkUrl
                        sourceSize: Qt.size(400, 400)
                        fillMode: Image.PreserveAspectCrop
                        cache: false
                        visible: status === Image.Ready
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 14

                    Caption {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        accent: true
                        text: !phone.connected ? qsTr("No phone connected")
                              : phone.trackSource.length > 0 ? qsTr("%1 · %2").arg(phone.deviceName).arg(phone.trackSource)
                              : qsTr("Bluetooth · %1").arg(phone.deviceName)
                    }
                    PrefsLabel { Layout.fillWidth: true; font.pixelSize: 60; isBold: true; elide: Text.ElideRight; wrapMode: Text.NoWrap; text: phone.trackTitle }
                    PrefsLabel { Layout.fillWidth: true; font.pixelSize: Style.typography.display; color: Style.textSecondary; elide: Text.ElideRight; wrapMode: Text.NoWrap; text: phone.trackArtist }
                    PrefsLabel { Layout.fillWidth: true; visible: text.length > 0; font.pixelSize: Style.h5; color: Style.textMuted; elide: Text.ElideRight; wrapMode: Text.NoWrap; text: phone.trackAlbum }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.topMargin: 30
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
                        DigitText { pixelSize: Style.h5; color: Style.textMuted; text: phone.formatDuration(phone.positionSeconds) }
                        Item { Layout.fillWidth: true }
                        DigitText { pixelSize: Style.h5; color: Style.textMuted; text: phone.formatDuration(phone.durationSeconds) }
                    }

                    RowLayout {
                        Layout.topMargin: 24
                        spacing: 28
                        RoundIconButton { iconName: "previous"; onClicked: phone.previous() }
                        RoundIconButton {
                            diameter: 96
                            iconName: phone.playing ? "pause" : "play"
                            highlighted: true
                            tone: root.modeColor
                            onClicked: phone.playPause()
                        }
                        RoundIconButton { iconName: "next"; onClicked: phone.next() }
                    }
                }
            }
        }

        // Volume.
        Panel {
            Layout.preferredWidth: 220
            Layout.fillHeight: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 18

                Caption { Layout.alignment: Qt.AlignHCenter; text: qsTr("Volume") }
                DigitText { Layout.alignment: Qt.AlignHCenter; pixelSize: Style.typography.display + 8; isBold: true; text: phone.volume }
                OutlineButton { Layout.alignment: Qt.AlignHCenter; implicitWidth: 120; symbol: "plus"; onClicked: phone.volume = phone.volume + 10 }
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillHeight: true
                    Layout.preferredWidth: 22
                    radius: 11
                    color: Style.surfaceSunken
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: parent.height * phone.volume / 100
                        radius: 11
                        color: root.modeColor
                        Behavior on height { NumberAnimation { duration: Style.motion.fast } }
                    }
                }
                OutlineButton { Layout.alignment: Qt.AlignHCenter; implicitWidth: 120; symbol: "minus"; onClicked: phone.volume = phone.volume - 10 }
            }
        }
    }
}
