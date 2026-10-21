import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Style 1.0
import "../Component"

// The papers a rider is asked for at a check: identity cards as cards, the
// vehicle's papers as a list with their expiry status. Tap a card to show it large.
EaglePage {
    id: root

    property var shown: null

    function statusColor(status) {
        return status === "expired" ? Style.danger : status === "expiring" ? Style.warning : Style.success
    }
    function statusText(doc) {
        if (doc.status === "expired")
            return qsTr("Expired %1 days ago").arg(-doc.daysLeft)
        if (doc.status === "expiring")
            return qsTr("Expires in %1 days").arg(doc.daysLeft)
        return doc.daysLeft < 0 ? qsTr("Valid") : qsTr("Valid until %1").arg(doc.validUntil)
    }

    Flickable {
        anchors.fill: parent
        anchors.leftMargin: 40
        anchors.rightMargin: 40
        contentHeight: column.implicitHeight + 40
        clip: true

        ColumnLayout {
            id: column
            width: parent.width
            spacing: 22

            RowLayout {
                PrefsLabel {
                    font.pixelSize: Style.h1
                    isBold: true
                    text: qsTr("Documents")
                }
                Item { Layout.fillWidth: true }
                Rectangle {
                    visible: vehicleDocuments.attentionCount > 0
                    implicitWidth: attention.implicitWidth + 32
                    implicitHeight: 44
                    radius: 22
                    color: Qt.alpha(Style.warning, 0.15)
                    border.color: Style.warning
                    PrefsLabel {
                        id: attention
                        anchors.centerIn: parent
                        font.pixelSize: Style.h5
                        isBold: true
                        color: Style.warning
                        text: qsTr("%n need attention", "", vehicleDocuments.attentionCount)
                    }
                }
            }

            PrefsLabel { font.pixelSize: Style.h4; color: Style.textMuted; text: qsTr("Rider") }
            RowLayout {
                spacing: 24
                Repeater {
                    model: vehicleDocuments.documents.filter(d => d.group === "rider")
                    Rectangle {
                        required property var modelData
                        implicitWidth: 380
                        implicitHeight: 330
                        radius: Style.metrics.radiusLg
                        color: Style.surface
                        border.color: Style.border
                        scale: cardTap.pressed ? 0.97 : 1
                        Behavior on scale { NumberAnimation { duration: Style.motion.fast } }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 18
                            spacing: 8
                            Image {
                                Layout.alignment: Qt.AlignHCenter
                                Layout.preferredWidth: 340
                                Layout.preferredHeight: 200
                                fillMode: Image.PreserveAspectFit
                                source: modelData.image
                            }
                            PrefsLabel { font.pixelSize: Style.h4; isBold: true; text: modelData.title }
                            PrefsLabel { font.pixelSize: Style.h6; color: Style.textMuted; text: modelData.number }
                            PrefsLabel {
                                font.pixelSize: Style.h6
                                color: root.statusColor(modelData.status)
                                text: root.statusText(modelData)
                            }
                        }
                        TapHandler { id: cardTap; onTapped: root.shown = modelData }
                    }
                }
            }

            PrefsLabel { Layout.topMargin: 10; font.pixelSize: Style.h4; color: Style.textMuted; text: qsTr("Vehicle") }
            Repeater {
                model: vehicleDocuments.documents.filter(d => d.group === "vehicle")
                Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 100
                    radius: Style.metrics.radiusMd
                    color: Style.surface
                    border.color: Style.border
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 24
                        anchors.rightMargin: 24
                        spacing: 20
                        Rectangle {
                            Layout.preferredWidth: 12
                            Layout.preferredHeight: 60
                            radius: 6
                            color: root.statusColor(modelData.status)
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            PrefsLabel { font.pixelSize: Style.h4; isBold: true; text: modelData.title }
                            PrefsLabel { font.pixelSize: Style.h6; color: Style.textMuted; text: qsTr("%1 · %2").arg(modelData.number).arg(modelData.issuer) }
                        }
                        Rectangle {
                            implicitWidth: statusLabel.implicitWidth + 32
                            implicitHeight: 44
                            radius: 22
                            color: Qt.alpha(root.statusColor(modelData.status), 0.14)
                            PrefsLabel {
                                id: statusLabel
                                anchors.centerIn: parent
                                font.pixelSize: Style.h6
                                isBold: true
                                color: root.statusColor(modelData.status)
                                text: root.statusText(modelData)
                            }
                        }
                    }
                }
            }
        }
    }

    // A card shown large, for an officer to read.
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.6)
        opacity: root.shown ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Style.motion.normal } }
        TapHandler { onTapped: root.shown = null }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 18
            Image {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 900
                Layout.preferredHeight: 520
                fillMode: Image.PreserveAspectFit
                source: root.shown ? root.shown.image : ""
            }
            PrefsLabel {
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: Style.h2
                isBold: true
                color: "#FFFFFF"
                text: root.shown ? root.shown.title : ""
            }
            PrefsLabel {
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: Style.h5
                color: "#DDDDDD"
                text: qsTr("Tap anywhere to close")
            }
        }
    }
}
