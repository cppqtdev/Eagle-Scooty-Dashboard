import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Style 1.0
import "../Component"

// What may interrupt a ride. Critical vehicle alerts always show.
EaglePage {
    background: null

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 28
        spacing: 14

        Caption { text: qsTr("From the phone") }
        ToggleRow { Layout.fillWidth: true; title: qsTr("Calls"); subtitle: qsTr("Show incoming calls with answer and decline"); checked: true }
        ToggleRow { Layout.fillWidth: true; title: qsTr("Messages"); subtitle: qsTr("Show the sender and the first line"); checked: true }
        ToggleRow { Layout.fillWidth: true; title: qsTr("Only when stopped"); subtitle: qsTr("Hold messages until the scooter is at a standstill"); checked: false }

        Caption { Layout.topMargin: 18; text: qsTr("From the scooter") }
        ToggleRow { Layout.fillWidth: true; title: qsTr("Service reminders"); subtitle: qsTr("Before the service and document expiry dates"); checked: true }
        ToggleRow { Layout.fillWidth: true; title: qsTr("Charging complete"); checked: true }
        InfoRow {
            Layout.fillWidth: true
            title: qsTr("Critical alerts")
            subtitle: qsTr("Motor, brake and battery faults cannot be switched off")
            value: qsTr("Always on")
            tone: Style.danger
            valueColor: Style.danger
        }
        Item { Layout.fillHeight: true }
    }
}
