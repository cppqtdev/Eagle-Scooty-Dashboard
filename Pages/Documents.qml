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

    // A status pill: its width follows the text, up to what the row allows.
    component StatusTag: Control {
        id: tag
        property string text
        property color tone
        leftPadding: 16
        rightPadding: 16
        topPadding: 8
        bottomPadding: 8
        background: Rectangle {
            radius: height / 2
            color: Style.alpha(tag.tone, 0.14)
            border.color: Style.alpha(tag.tone, 0.5)
        }
        contentItem: PrefsLabel {
            font.pixelSize: Style.h6
            isBold: true
            color: tag.tone
            elide: Text.ElideRight
            wrapMode: Text.NoWrap
            horizontalAlignment: Text.AlignHCenter
            text: tag.text
        }
    }

    Flickable {
        anchors.fill: parent
        anchors.leftMargin: 40
        anchors.rightMargin: 40
        anchors.topMargin: 24
        anchors.bottomMargin: 16
        contentHeight: column.implicitHeight + 40
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        ColumnLayout {
            id: column
            width: parent.width
            spacing: 22

            RowLayout {
                Layout.fillWidth: true
                spacing: 16
                PrefsLabel {
                    Layout.fillWidth: true
                    font.pixelSize: Style.h1
                    isBold: true
                    elide: Text.ElideRight
                    wrapMode: Text.NoWrap
                    text: qsTr("Documents")
                }
                StatusTag {
                    visible: vehicleDocuments.attentionCount > 0
                    Layout.maximumWidth: column.width / 2
                    tone: Style.warning
                    text: qsTr("%n need attention", "", vehicleDocuments.attentionCount)
                }
            }

            PrefsLabel { font.pixelSize: Style.h4; color: Style.textMuted; text: qsTr("Rider") }

            // The cards scroll sideways when the page is narrower than all of them.
            ListView {
                id: cards
                Layout.fillWidth: true
                Layout.preferredHeight: 330
                orientation: ListView.Horizontal
                spacing: 24
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                snapMode: ListView.SnapToItem
                model: vehicleDocuments.documents.filter(d => d.group === "rider")

                delegate: AbstractButton {
                    id: card
                    required property var modelData
                    width: 360
                    height: ListView.view.height
                    padding: 18
                    scale: pressed ? 0.97 : 1
                    Behavior on scale { NumberAnimation { duration: Style.motion.fast } }
                    onClicked: root.shown = modelData

                    background: Rectangle {
                        radius: Style.metrics.radiusLg
                        color: Style.surface
                        border.color: Style.border
                    }
                    contentItem: ColumnLayout {
                        spacing: 8
                        Image {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            fillMode: Image.PreserveAspectFit
                            source: card.modelData.image
                        }
                        PrefsLabel { Layout.fillWidth: true; font.pixelSize: Style.h4; isBold: true; elide: Text.ElideRight; wrapMode: Text.NoWrap; text: card.modelData.title }
                        PrefsLabel { Layout.fillWidth: true; font.pixelSize: Style.h6; color: Style.textMuted; elide: Text.ElideRight; wrapMode: Text.NoWrap; text: card.modelData.number }
                        PrefsLabel {
                            Layout.fillWidth: true
                            font.pixelSize: Style.h6
                            color: root.statusColor(card.modelData.status)
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                            text: root.statusText(card.modelData)
                        }
                    }
                }

                ScrollBar.horizontal: ScrollBar { policy: cards.contentWidth > cards.width ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff }
            }

            PrefsLabel { Layout.topMargin: 10; font.pixelSize: Style.h4; color: Style.textMuted; text: qsTr("Vehicle") }
            Repeater {
                model: vehicleDocuments.documents.filter(d => d.group === "vehicle")
                Control {
                    id: paper
                    required property var modelData
                    Layout.fillWidth: true
                    leftPadding: 24
                    rightPadding: 24
                    topPadding: 18
                    bottomPadding: 18

                    background: Rectangle {
                        radius: Style.metrics.radiusMd
                        color: Style.alpha(Style.textPrimary, Style.isDark ? 0.045 : 0.035)
                    }
                    contentItem: RowLayout {
                        spacing: 20
                        Rectangle {
                            Layout.preferredWidth: 10
                            Layout.fillHeight: true
                            radius: 5
                            color: root.statusColor(paper.modelData.status)
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            PrefsLabel { Layout.fillWidth: true; font.pixelSize: Style.h4; isBold: true; elide: Text.ElideRight; wrapMode: Text.NoWrap; text: paper.modelData.title }
                            PrefsLabel { Layout.fillWidth: true; font.pixelSize: Style.h6; color: Style.textMuted; elide: Text.ElideRight; wrapMode: Text.NoWrap; text: qsTr("%1 · %2").arg(paper.modelData.number).arg(paper.modelData.issuer) }
                        }
                        // A fixed column on the right, so every tag ends on the same edge.
                        Item {
                            Layout.preferredWidth: Math.min(330, paper.availableWidth * 0.42)
                            Layout.fillHeight: true
                            StatusTag {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: Math.min(implicitWidth, parent.width)
                                tone: root.statusColor(paper.modelData.status)
                                text: root.statusText(paper.modelData)
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
        radius: Style.metrics.radiusLg
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
