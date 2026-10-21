import QtQuick
import QtQuick.Layouts
import Style 1.0

// A setting that is on or off: title and explanation, with the switch on the right.
Rectangle {
    id: row

    property string title
    property string subtitle
    property bool checked: false
    signal toggled(bool checked)

    implicitHeight: subtitle.length > 0 ? 92 : 72
    radius: Style.metrics.radiusMd
    color: Style.surface
    border.color: Style.border

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        spacing: 18
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            PrefsLabel { Layout.fillWidth: true; font.pixelSize: Style.h4; text: row.title }
            PrefsLabel {
                Layout.fillWidth: true
                visible: row.subtitle.length > 0
                font.pixelSize: Style.typography.caption
                color: Style.textMuted
                text: row.subtitle
            }
        }
        Rectangle {
            implicitWidth: 76
            implicitHeight: 40
            radius: 20
            color: row.checked ? Style.accent : Style.surfaceSunken
            border.color: row.checked ? Style.accent : Style.borderStrong
            Behavior on color { ColorAnimation { duration: Style.motion.fast } }
            Rectangle {
                width: 30
                height: 30
                radius: 15
                y: 5
                x: row.checked ? parent.width - width - 5 : 5
                color: "#FFFFFF"
                Behavior on x { NumberAnimation { duration: Style.motion.fast; easing.type: Easing.OutCubic } }
            }
        }
    }
    TapHandler { onTapped: { row.checked = !row.checked; row.toggled(row.checked) } }
}
