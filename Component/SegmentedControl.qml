import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Style 1.0

// One choice out of a few, side by side in a track: the chosen segment is lit
// (glow and an underline in the accent) and the light slides between them.
// model: [{ icon, title }] or plain strings.
Control {
    id: control

    property var model: []
    property int currentIndex: 0
    signal activated(int index)

    padding: 4
    implicitWidth: implicitContentWidth + leftPadding + rightPadding
    implicitHeight: 64

    background: Rectangle {
        radius: Style.metrics.radiusMd
        color: Style.alpha(Style.textPrimary, Style.isDark ? 0.05 : 0.04)
        border.color: Style.border

        // The lit segment.
        Rectangle {
            readonly property Item target: segments.itemAt(control.currentIndex)
            x: target ? control.leftPadding + target.x : 0
            y: control.topPadding
            width: target ? target.width : 0
            height: parent.height - control.topPadding - control.bottomPadding
            radius: 2
            gradient: Gradient {
                GradientStop { position: 0.0; color: Style.alpha(Style.accent, Style.isDark ? 0.10 : 0.06) }
                GradientStop { position: 1.0; color: Style.alpha(Style.accent, Style.isDark ? 0.34 : 0.20) }
            }
            Behavior on x { NumberAnimation { duration: Style.motion.normal; easing.type: Easing.OutCubic } }
            Behavior on width { NumberAnimation { duration: Style.motion.normal; easing.type: Easing.OutCubic } }

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width * 0.6
                height: 3
                radius: 1.5
                color: Style.isDark ? Style.accentStrong : Style.accent
            }
        }
    }

    contentItem: RowLayout {
        spacing: 0
        Repeater {
            id: segments
            model: control.model
            AbstractButton {
                id: segment
                focusPolicy: Qt.StrongFocus
                required property int index
                required property var modelData
                readonly property bool current: control.currentIndex === index
                readonly property string title: typeof modelData === "string" ? modelData : modelData.title
                readonly property string iconName: typeof modelData === "string" ? "" : (modelData.icon || "")
                Layout.fillWidth: true
                Layout.fillHeight: true
                implicitWidth: implicitContentWidth + leftPadding + rightPadding
                leftPadding: 26
                rightPadding: 26
                onClicked: { control.currentIndex = index; control.activated(index) }

                contentItem: RowLayout {
                    spacing: 10
                    Item { Layout.fillWidth: true }
                    LineIcon {
                        visible: segment.iconName.length > 0
                        name: segment.iconName
                        size: 22
                        color: segment.current ? (Style.isDark ? Style.accentStrong : Style.accent) : Style.textMuted
                    }
                    PrefsLabel {
                        font.pixelSize: Style.h5
                        font.letterSpacing: 1.5
                        font.capitalization: Font.AllUppercase
                        isBold: segment.current
                        color: segment.current ? Style.textPrimary : Style.textSecondary
                        elide: Text.ElideRight
                        wrapMode: Text.NoWrap
                        text: segment.title
                    }
                    Item { Layout.fillWidth: true }
                }
            }
        }
    }
}
