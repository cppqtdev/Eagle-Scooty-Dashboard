import QtQuick
import QtQuick.Layouts
import Style 1.0

// Warnings and information slide down under the telltales; the rider dismisses
// them, information also times out. Critical alerts use CriticalAlert instead.
Item {
    id: root

    readonly property var alert: alertCenter.banner
    readonly property bool shown: alert.id !== undefined
    readonly property color tone: alert.severity === 1 ? Style.warning : Style.accent

    width: 980
    height: 104

    // Keep the last alert's text while sliding out.
    property var shownAlert: ({})
    onAlertChanged: if (shown) shownAlert = alert

    Rectangle {
        id: card
        width: parent.width
        height: parent.height
        y: root.shown ? 0 : -height - 40
        opacity: root.shown ? 1 : 0
        radius: Style.metrics.radiusLg
        color: Style.surface
        border.color: root.tone
        border.width: 2

        Behavior on y { NumberAnimation { duration: Style.motion.theme; easing.type: Easing.OutBack } }
        Behavior on opacity { NumberAnimation { duration: Style.motion.normal } }

        Rectangle {
            width: 10
            height: parent.height - 24
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            radius: 5
            color: root.tone
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 40
            anchors.rightMargin: 24
            spacing: 20

            AlertIcon {
                key: root.shownAlert.icon || ""
                severity: root.shownAlert.severity || 0
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                PrefsLabel {
                    font.pixelSize: Style.h2
                    isBold: true
                    text: root.shownAlert.title || ""
                }
                PrefsLabel {
                    Layout.fillWidth: true
                    font.pixelSize: Style.h5
                    color: Style.textSecondary
                    text: root.shownAlert.message || ""
                }
            }
            Rectangle {
                Layout.preferredWidth: 150
                Layout.preferredHeight: 56
                radius: 28
                color: Qt.alpha(root.tone, 0.14)
                border.color: root.tone
                PrefsLabel {
                    anchors.centerIn: parent
                    font.pixelSize: Style.h5
                    isBold: true
                    color: root.tone
                    text: qsTr("Dismiss")
                }
                TapHandler { onTapped: alertCenter.acknowledge(root.shownAlert.id) }
            }
        }
    }
}
