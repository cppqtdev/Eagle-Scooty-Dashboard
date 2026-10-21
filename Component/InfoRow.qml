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
    property color tone: Style.accent
    property color valueColor: tone
    property bool selected: false
    property bool showEdge: true

    leftPadding: showEdge ? 32 : 22
    rightPadding: 24
    topPadding: 14
    bottomPadding: 14
    implicitWidth: implicitContentWidth + leftPadding + rightPadding
    implicitHeight: Math.max(subtitle.length > 0 ? 92 : 76, implicitContentHeight + topPadding + bottomPadding)

    background: Rectangle {
        radius: Style.metrics.radiusMd
        color: row.pressed ? Style.surfaceSunken : row.selected ? Style.alpha(Style.accent, 0.10) : Style.surface
        border.color: row.selected ? Style.accent : Style.border
        border.width: row.selected ? 2 : 1
        Behavior on color { ColorAnimation { duration: Style.motion.instant } }

        Rectangle {
            visible: row.showEdge
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            width: 5
            height: parent.height - 26
            radius: 3
            color: row.tone
        }
    }

    contentItem: RowLayout {
        spacing: 18

        Image {
            visible: row.iconSource.length > 0
            sourceSize: Qt.size(36, 36)
            source: row.iconSource
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
