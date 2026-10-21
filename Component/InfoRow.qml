import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Style 1.0

// One row of a list: an accent edge on the left, an optional icon, the title,
// and the value on the right in the row's tone. Selected rows are outlined.
// A button underneath, so padding, background and height follow the content.
AbstractButton {
    id: row

    property string title
    property string subtitle
    property string value
    property string iconSource
    property string glyph            // a LineIcon name for the avatar; else the title's initial
    property color tone: Style.accent
    property color valueColor: tone
    property bool selected: false
    property bool showEdge: true     // the leading avatar

    leftPadding: 16
    rightPadding: 20
    topPadding: 12
    bottomPadding: 12
    implicitWidth: implicitContentWidth + leftPadding + rightPadding
    implicitHeight: Math.max(subtitle.length > 0 ? 84 : 68, implicitContentHeight + topPadding + bottomPadding)

    // A soft filled row, no hard outline; the selected one is lit in its tone.
    background: Rectangle {
        radius: Style.metrics.radiusMd
        color: row.pressed ? Style.alpha(Style.textPrimary, 0.09) : Style.alpha(Style.textPrimary, Style.isDark ? 0.045 : 0.035)
        border.color: row.selected ? Style.alpha(row.tone, 0.7) : "transparent"
        border.width: row.selected ? 1.5 : 0
        Behavior on color { ColorAnimation { duration: Style.motion.instant } }

        Rectangle {
            visible: row.selected
            anchors.fill: parent
            radius: parent.radius
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Style.alpha(row.tone, Style.isDark ? 0.30 : 0.18) }
                GradientStop { position: 0.8; color: Style.alpha(row.tone, 0.0) }
            }
        }
    }

    contentItem: RowLayout {
        spacing: 18

        Image {
            visible: row.iconSource.length > 0
            sourceSize: Qt.size(36, 36)
            source: row.iconSource
        }
        Rectangle {
            visible: row.showEdge && row.iconSource.length === 0
            Layout.preferredWidth: 46
            Layout.preferredHeight: 46
            radius: 23
            color: Style.alpha(row.tone, 0.16)
            border.color: Style.alpha(row.tone, 0.45)
            LineIcon {
                visible: row.glyph.length > 0
                anchors.centerIn: parent
                name: row.glyph
                size: 24
                color: row.tone
            }
            PrefsLabel {
                visible: row.glyph.length === 0
                anchors.centerIn: parent
                font.pixelSize: Style.h5
                isBold: true
                color: row.tone
                text: (row.title || "?").charAt(0).toUpperCase()
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            PrefsLabel {
                Layout.fillWidth: true
                font.pixelSize: Style.h4
                isBold: row.selected
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
                text: row.title
            }
            PrefsLabel {
                Layout.fillWidth: true
                visible: row.subtitle.length > 0
                font.pixelSize: Style.typography.caption
                color: Style.textMuted
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
                text: row.subtitle
            }
        }
        PrefsLabel {
            visible: row.value.length > 0
            // The title gets the room first; a very long value elides past about half the row.
            Layout.maximumWidth: row.availableWidth * 0.55
            font.pixelSize: Style.h5
            isBold: true
            color: row.valueColor
            elide: Text.ElideRight
            wrapMode: Text.NoWrap
            text: row.value
        }
    }
}
