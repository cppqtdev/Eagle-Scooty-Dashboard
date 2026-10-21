import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Style 1.0

// A vertical list of tabs on a rail. Each tab is an icon, a title and an
// optional value on the right; the current one is lit from its edge with a glow
// that fades across the row, and the light slides when the tab changes. A tap
// draws nothing of its own, so the only colour that ever appears is the glow.
// model: [{ icon, title, value }]. Tapping a tab emits activated(index); the
// owner decides whether it becomes current (a tab may open something instead).
ListView {
    id: rail

    signal activated(int index)

    clip: true
    spacing: 4
    boundsBehavior: Flickable.StopAtBounds
    highlightFollowsCurrentItem: true
    highlightMoveDuration: Style.motion.fast
    highlightMoveVelocity: -1
    highlightResizeDuration: 0

    Rectangle {   // the rail
        width: 2
        height: rail.height
        radius: 1
        color: Style.border
        z: -1
    }

    // The lit tab: a glow fading across the row from a bar on the rail. Small
    // radius, one colour family, nothing else drawn on a tap.
    highlight: Item {
        Rectangle {
            anchors.fill: parent
            radius: 2
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Style.alpha(Style.accent, Style.isDark ? 0.30 : 0.16) }
                GradientStop { position: 0.75; color: Style.alpha(Style.accent, 0.03) }
                GradientStop { position: 1.0; color: Style.alpha(Style.accent, 0.0) }
            }
        }
        Rectangle {
            width: 3
            height: parent.height
            radius: 1
            color: Style.isDark ? Style.accentStrong : Style.accent
        }
    }

    delegate: AbstractButton {
        id: tab
        required property int index
        required property var modelData
        readonly property bool current: ListView.isCurrentItem
        width: ListView.view.width
        implicitHeight: 56
        leftPadding: 22
        rightPadding: 16
        onClicked: rail.activated(index)

        background: null
        contentItem: RowLayout {
            spacing: 16
            LineIcon {
                name: tab.modelData.icon || ""
                size: 26
                color: tab.current ? (Style.isDark ? Style.accentStrong : Style.accent) : Style.textMuted
            }
            PrefsLabel {
                Layout.fillWidth: true
                font.pixelSize: Style.h4
                isBold: tab.current
                color: tab.current ? Style.textPrimary : Style.textSecondary
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
                text: tab.modelData.title
            }
            PrefsLabel {
                visible: text.length > 0
                Layout.maximumWidth: tab.availableWidth * 0.45
                font.pixelSize: Style.h6
                color: Style.textMuted
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
                text: tab.modelData.value || ""
            }
        }
    }
}
