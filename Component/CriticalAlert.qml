import QtQuick
import QtQuick.Layouts
import Style 1.0

// A critical alert takes the whole screen in red: motor fault, battery empty or
// overheating, side stand down while moving. The rider confirms once it is safe;
// the telltale stays lit for as long as the condition lasts.
Rectangle {
    id: root

    readonly property var alert: alertCenter.critical
    readonly property bool shown: alert.id !== undefined
    property var shownAlert: ({})
    onAlertChanged: if (shown) shownAlert = alert

    color: Qt.rgba(0, 0, 0, 0.72)
    opacity: shown ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: Style.motion.normal } }

    // Swallow touches so nothing behind it is pressed by accident.
    MouseArea { anchors.fill: parent }

    Rectangle {
        id: panel
        anchors.centerIn: parent
        width: 1000
        height: 460
        radius: 28
        color: Style.isDark ? "#2A0E0E" : "#FFF1F0"
        border.color: Style.danger
        border.width: 4

        SequentialAnimation on border.width {
            running: root.shown
            loops: Animation.Infinite
            NumberAnimation { to: 10; duration: 500; easing.type: Easing.InOutSine }
            NumberAnimation { to: 4; duration: 500; easing.type: Easing.InOutSine }
        }

        ColumnLayout {
            anchors.centerIn: parent
            width: parent.width - 120
            spacing: 22

            AlertIcon {
                Layout.alignment: Qt.AlignHCenter
                sourceSize: Qt.size(110, 110)
                key: root.shownAlert.icon || ""
                severity: 2
            }
            PrefsLabel {
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: 54
                isBold: true
                color: Style.danger
                text: (root.shownAlert.title || "").toUpperCase()
            }
            PrefsLabel {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Style.h1
                color: Style.textPrimary
                text: root.shownAlert.message || ""
            }
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 10
                Layout.preferredWidth: 260
                Layout.preferredHeight: 70
                radius: 35
                color: Style.danger
                PrefsLabel {
                    anchors.centerIn: parent
                    font.pixelSize: Style.h2
                    isBold: true
                    color: "#FFFFFF"
                    text: qsTr("OK")
                }
                TapHandler { onTapped: alertCenter.acknowledge(root.shownAlert.id) }
            }
        }
    }
}
