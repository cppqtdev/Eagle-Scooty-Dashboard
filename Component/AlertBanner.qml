import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Style 1.0

// Warnings and information drop in under the telltales as a dark capsule, the
// same in both themes so it always stands apart from the page beneath: a badge
// in the alert's colour, the title and one line of detail, and a close button.
// Information also times out. Critical alerts use CriticalAlert instead.
Item {
    id: root

    readonly property var alert: alertCenter.banner
    readonly property bool shown: alert.id !== undefined
    readonly property color tone: shownAlert.severity === 1 ? Style.warning
                                  : shownAlert.icon === "charge" ? Style.success : Style.accentStrong
    readonly property bool telltale: ["tyre", "sideStand", "batteryTemp"].indexOf(shownAlert.icon) >= 0

    width: 900
    height: 100

    // Keep the last alert's text while sliding out.
    property var shownAlert: ({})
    onAlertChanged: if (alert.id !== undefined) shownAlert = alert

    Control {
        id: capsule
        width: parent.width
        height: parent.height
        y: root.shown ? 0 : -height - 40
        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : 0.96
        leftPadding: 16
        rightPadding: 20
        topPadding: 16
        bottomPadding: 16

        Behavior on y { NumberAnimation { duration: Style.motion.theme; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: Style.motion.normal } }
        Behavior on scale { NumberAnimation { duration: Style.motion.theme; easing.type: Easing.OutCubic } }

        background: Item {
            // A soft shadow from two offset layers (no effects module on the board's Qt).
            Rectangle {
                anchors.fill: parent
                anchors.margins: -6
                anchors.topMargin: 2
                radius: height / 2
                color: "#000000"
                opacity: 0.10
            }
            Rectangle {
                anchors.fill: parent
                anchors.margins: -2
                anchors.topMargin: 4
                radius: height / 2
                color: "#000000"
                opacity: 0.14
            }
            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: "#121A1D"
                border.color: Style.alpha(root.tone, 0.45)
                border.width: 1
                // A faint wash of the alert colour from the badge side.
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: Style.alpha(root.tone, 0.16) }
                        GradientStop { position: 0.45; color: "transparent" }
                    }
                }
            }
        }

        contentItem: RowLayout {
            spacing: 22

            // Badge.
            Rectangle {
                Layout.preferredWidth: 68
                Layout.preferredHeight: 68
                radius: 34
                color: Style.alpha(root.tone, 0.18)
                border.color: root.tone
                border.width: 2

                AlertIcon {
                    visible: root.telltale
                    anchors.centerIn: parent
                    sourceSize: Qt.size(40, 40)
                    key: root.shownAlert.icon || ""
                    severity: root.shownAlert.severity || 0
                }
                PrefsLabel {
                    visible: !root.telltale
                    anchors.centerIn: parent
                    font.pixelSize: 34
                    isBold: true
                    color: root.tone
                    text: root.shownAlert.icon === "charge" ? "✓"
                          : root.shownAlert.severity === 1 ? "!" : "i"
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                PrefsLabel {
                    Layout.fillWidth: true
                    font.pixelSize: Style.h3
                    isBold: true
                    color: "#F4FAFA"
                    elide: Text.ElideRight
                    wrapMode: Text.NoWrap
                    text: root.shownAlert.title || ""
                }
                PrefsLabel {
                    Layout.fillWidth: true
                    font.pixelSize: Style.h6
                    color: "#A9BABB"
                    elide: Text.ElideRight
                    wrapMode: Text.NoWrap
                    text: root.shownAlert.message || ""
                }
            }

            // Close.
            AbstractButton {
                implicitWidth: 60
                implicitHeight: 60
                scale: pressed ? 0.98 : 1
                onClicked: alertCenter.acknowledge(root.shownAlert.id)
                background: Rectangle {
                    radius: width / 2
                    color: Style.alpha("#FFFFFF", 0.08)
                    border.color: Style.alpha("#FFFFFF", 0.16)
                    Behavior on color { ColorAnimation { duration: Style.motion.instant } }
                }
                // An X from two bars, crisp at any scale.
                contentItem: Item {
                    Repeater {
                        model: [45, -45]
                        Rectangle {
                            required property int modelData
                            anchors.centerIn: parent
                            width: 22
                            height: 3
                            radius: 1.5
                            rotation: modelData
                            color: "#DCE6E6"
                        }
                    }
                }
            }
        }
    }
}
