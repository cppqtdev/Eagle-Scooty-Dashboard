import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Style 1.0
import "../Component"

// The language of the whole dashboard. It changes at once, without a restart,
// and the Ride app can set it too.
EaglePage {
    background: null

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 28
        spacing: 12

        Caption { text: qsTr("Language") }
        Repeater {
            model: language.languages
            InfoRow {
                required property var modelData
                required property int index
                Layout.fillWidth: true
                title: modelData.name
                subtitle: modelData.code.toUpperCase()
                selected: language.current === index
                value: selected ? qsTr("In use") : ""
                onClicked: language.current = index
            }
        }
        PrefsLabel {
            Layout.fillWidth: true
            Layout.topMargin: 8
            font.pixelSize: Style.typography.caption
            color: Style.textMuted
            wrapMode: Text.WordWrap
            text: qsTr("Names of roads, people and songs stay as the phone sends them.")
        }
        Item { Layout.fillHeight: true }
    }
}
