import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Style 1.0
import "../Component"

// Wi-Fi: on the board through NetworkManager, on the desk simulated. A secured
// network asks for its password before connecting.
EaglePage {
    id: root

    property string askingFor: ""

    background: null

    function bars(signal) {
        return signal >= 75 ? "▂▄▆█" : signal >= 50 ? "▂▄▆" : signal >= 25 ? "▂▄" : "▂"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 28
        spacing: 14

        ToggleRow {
            Layout.fillWidth: true
            title: qsTr("Wi-Fi")
            subtitle: wifi.status + (wifi.real ? "" : qsTr(" · simulated on this computer"))
            checked: wifi.enabled
            onToggled: checked => wifi.enabled = checked
        }

        RowLayout {
            Layout.topMargin: 10
            Caption { text: qsTr("Networks") }
            Item { Layout.fillWidth: true }
            OutlineButton {
                enabled: wifi.enabled && !wifi.busy
                opacity: enabled ? 1 : 0.5
                text: wifi.busy ? qsTr("Working…") : qsTr("Refresh")
                onClicked: wifi.scan()
            }
        }

        Repeater {
            model: wifi.networks
            InfoRow {
                required property var modelData
                Layout.fillWidth: true
                title: modelData.ssid
                subtitle: (modelData.secure ? qsTr("Secured") : qsTr("Open")) + "  " + root.bars(modelData.signal)
                tone: modelData.connected ? Style.success : Style.accent
                selected: modelData.connected
                value: modelData.connected ? qsTr("Disconnect") : qsTr("Connect")
                valueColor: modelData.connected ? Style.danger : Style.accent
                onClicked: {
                    if (modelData.connected)
                        wifi.disconnectNetwork()
                    else if (modelData.secure)
                        root.askingFor = modelData.ssid
                    else
                        wifi.connectTo(modelData.ssid, "")
                }
            }
        }
        Item { Layout.fillHeight: true }
    }

    // Password.
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.5)
        radius: Style.metrics.radiusLg
        visible: root.askingFor.length > 0
        TapHandler { onTapped: root.askingFor = "" }

        Panel {
            anchors.centerIn: parent
            width: 680
            height: 330
            TapHandler {}

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 28
                spacing: 18
                Caption { text: qsTr("Password for") }
                PrefsLabel { font.pixelSize: Style.h1; isBold: true; text: root.askingFor }
                TextFieldInput {
                    id: password
                    Layout.fillWidth: true
                    implicitHeight: 64
                    echoMode: TextInput.Password
                    placeholderText: qsTr("At least 8 characters")
                    radius: 10
                    borderColor: Style.accent
                    focus: root.askingFor.length > 0
                }
                RowLayout {
                    spacing: 14
                    Item { Layout.fillWidth: true }
                    OutlineButton { text: qsTr("Cancel"); onClicked: { password.text = ""; root.askingFor = "" } }
                    OutlineButton {
                        text: qsTr("Connect")
                        highlighted: true
                        onClicked: {
                            wifi.connectTo(root.askingFor, password.text)
                            password.text = ""
                            root.askingFor = ""
                        }
                    }
                }
            }
        }
    }
}
