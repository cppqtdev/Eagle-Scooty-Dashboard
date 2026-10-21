import QtQuick
import QtQuick.Layouts
import Style 1.0

// One row of a list: an accent edge on the left, an optional icon, the title,
// and the value on the right in the row's tone. Selected rows are outlined.
Rectangle {
    id: row

    property string title
    property string subtitle
    property string value
    property string icon
    property color tone: Style.accent
    property color valueColor: tone
    property bool selected: false
    property bool showEdge: true
    signal clicked()

    implicitHeight: subtitle.length > 0 ? 92 : 76
    radius: Style.metrics.radiusMd
    color: tap.pressed ? Style.surfaceSunken : selected ? Qt.alpha(Style.accent, 0.10) : Style.surface
    border.color: selected ? Style.accent : Style.border
    border.width: selected ? 2 : 1
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

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: row.showEdge ? 32 : 22
        anchors.rightMargin: 24
        spacing: 18

        Image {
            visible: row.icon.length > 0
            sourceSize: Qt.size(36, 36)
            source: row.icon
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
            font.pixelSize: Style.h5
            isBold: true
            color: row.valueColor
            text: row.value
        }
    }

    TapHandler { id: tap; onTapped: row.clicked() }
}
