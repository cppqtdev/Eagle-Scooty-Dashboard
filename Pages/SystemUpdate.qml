import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Style 1.0
import "../Component"

// Software version and updates, which download over Wi-Fi.
EaglePage {
    id: root

    property bool checking: false
    property bool checked: false

    background: null

    Timer {
        id: check
        interval: 2200
        onTriggered: { root.checking = false; root.checked = true }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 28
        spacing: 16

        Caption { text: qsTr("Installed") }
        PrefsLabel { font.pixelSize: 64; isBold: true; text: qsTr("v%1").arg(Qt.application.version) }
        PrefsLabel {
            font.pixelSize: Style.h5
            color: root.checked ? Style.success : Style.textMuted
            text: root.checking ? qsTr("Checking for updates…")
                  : root.checked ? qsTr("Eagle Dashboard is up to date")
                  : qsTr("Updates download over Wi-Fi and install when the scooter is switched off")
        }
        RowLayout {
            spacing: 14
            OutlineButton {
                text: root.checking ? qsTr("Checking…") : qsTr("Check now")
                highlighted: true
                enabled: !root.checking && wifi.connectedSsid.length > 0
                opacity: enabled ? 1 : 0.5
                onClicked: { root.checking = true; root.checked = false; check.start() }
            }
            PrefsLabel {
                visible: wifi.connectedSsid.length === 0
                font.pixelSize: Style.typography.caption
                color: Style.warning
                text: qsTr("Connect to Wi-Fi first")
            }
        }

        Caption { Layout.topMargin: 20; text: qsTr("Details") }
        InfoRow { Layout.fillWidth: true; showEdge: false; title: qsTr("Channel"); value: qsTr("Stable"); valueColor: Style.textMuted }
        InfoRow { Layout.fillWidth: true; showEdge: false; title: qsTr("Wi-Fi"); value: wifi.connectedSsid || qsTr("Not connected"); valueColor: Style.textMuted }
        InfoRow { Layout.fillWidth: true; showEdge: false; title: qsTr("Install"); value: qsTr("At switch-off"); valueColor: Style.textMuted }
        Item { Layout.fillHeight: true }
    }
}
