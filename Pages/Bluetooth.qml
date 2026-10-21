import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Style 1.0
import "../Component"

// Bluetooth: the radio, paired devices and devices in range. On the board this is
// the real adapter (BlueZ); on the desk a simulated radio.
EaglePage {
    id: root

    background: null

    function kindLabel(kind) {
        return kind === "phone" ? qsTr("Phone") : kind === "headset" ? qsTr("Headset") : qsTr("Device")
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 28
        spacing: 14

        ToggleRow {
            Layout.fillWidth: true
            title: qsTr("Bluetooth")
            subtitle: bluetooth.status + (bluetooth.real ? "" : qsTr(" · simulated on this computer"))
            checked: bluetooth.powered
            onToggled: bluetooth.powered = checked
        }

        // The companion app's own link, when this build listens for it.
        InfoRow {
            visible: phone.linked
            Layout.fillWidth: true
            glyph: "phone"
            title: qsTr("Ride app")
            subtitle: phone.connected ? qsTr("Linked · calls, music, navigation and messages")
                                      : qsTr("Waiting · open the app and tap Find my bike")
            tone: phone.connected ? Style.success : Style.warning
            value: phone.connected ? qsTr("%1% battery").arg(phone.phoneBattery) : ""
            valueColor: Style.textMuted
        }

        Caption { Layout.topMargin: 10; text: qsTr("Paired devices") }
        Repeater {
            model: bluetooth.devices.filter(d => d.paired)
            InfoRow {
                required property var modelData
                Layout.fillWidth: true
                glyph: modelData.kind === "headset" ? "headset" : "phone"
                title: modelData.name
                subtitle: root.kindLabel(modelData.kind) + " · " + modelData.address
                tone: modelData.connected ? Style.success : Style.textMuted
                value: modelData.connected ? qsTr("Connected") : qsTr("Forget")
                valueColor: modelData.connected ? Style.success : Style.danger
                onClicked: if (!modelData.connected) bluetooth.forget(modelData.address)
            }
        }

        RowLayout {
            Layout.topMargin: 10
            Caption { text: qsTr("Devices in range") }
            Item { Layout.fillWidth: true }
            OutlineButton {
                enabled: bluetooth.powered && !bluetooth.scanning
                opacity: enabled ? 1 : 0.5
                text: bluetooth.scanning ? qsTr("Searching…") : qsTr("Search")
                onClicked: bluetooth.scan()
            }
        }
        Repeater {
            model: bluetooth.devices.filter(d => !d.paired)
            InfoRow {
                required property var modelData
                Layout.fillWidth: true
                glyph: modelData.kind === "headset" ? "headset" : "phone"
                title: modelData.name
                subtitle: root.kindLabel(modelData.kind) + qsTr(" · signal %1 dBm").arg(modelData.rssi)
                tone: Style.accent
                value: qsTr("Pair")
                onClicked: bluetooth.pair(modelData.address)
            }
        }
        PrefsLabel {
            visible: bluetooth.devices.filter(d => !d.paired).length === 0
            font.pixelSize: Style.typography.caption
            color: Style.textMuted
            text: qsTr("Tap Search to find phones and headsets nearby.")
        }
        Item { Layout.fillHeight: true }
    }
}
