import QtQuick
import Style 1.0

// A telltale drawn rather than loaded: a line icon, or a short label in a
// rounded frame ("ABS"), in its ISO 2575 colour when lit and grey when not.
Item {
    id: root

    property string glyph           // a LineIcon name
    property string label           // used when there is no glyph
    property color tone: Style.warning
    property bool active: false
    property bool lampCheck: false
    property real iconSize: 52

    readonly property bool lit: active || lampCheck
    readonly property color shade: lit ? tone : Style.textMuted

    implicitWidth: iconSize + 12
    implicitHeight: iconSize + 12
    opacity: lit ? 1 : 0.55

    LineIcon {
        visible: root.glyph.length > 0
        anchors.centerIn: parent
        name: root.glyph
        size: root.iconSize
        strokeWidth: 2
        color: root.shade
    }

    Rectangle {
        visible: root.glyph.length === 0
        anchors.centerIn: parent
        width: root.iconSize
        height: root.iconSize * 0.7
        radius: height / 2
        color: "transparent"
        border.color: root.shade
        border.width: 2.5
        PrefsLabel {
            anchors.centerIn: parent
            font.pixelSize: root.iconSize * 0.3
            isBold: true
            color: root.shade
            text: root.label
        }
    }
}
