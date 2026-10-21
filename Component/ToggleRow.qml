import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Style 1.0

// A setting that is on or off: title and explanation, with the switch on the
// right. A checkable button, so a tap anywhere on the row flips it and the row
// grows with a longer explanation (which wraps to two lines at most).
AbstractButton {
    id: row
    focusPolicy: Qt.StrongFocus

    property string title
    property string subtitle

    checkable: true
    scale: pressed ? 0.98 : 1
    Behavior on scale { NumberAnimation { duration: Style.motion.instant } }
    leftPadding: 24
    rightPadding: 24
    topPadding: 16
    bottomPadding: 16
    implicitWidth: implicitContentWidth + leftPadding + rightPadding
    implicitHeight: Math.max(72, implicitContentHeight + topPadding + bottomPadding)

    background: Rectangle {
        radius: Style.metrics.radiusMd
        color: Style.alpha(Style.textPrimary, Style.isDark ? 0.045 : 0.035)
    }

    contentItem: RowLayout {
        spacing: 18
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            PrefsLabel {
                Layout.fillWidth: true
                font.pixelSize: Style.h4
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
                text: row.title
            }
            PrefsLabel {
                Layout.fillWidth: true
                visible: row.subtitle.length > 0
                font.pixelSize: Style.typography.caption
                color: Style.textMuted
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
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
}
