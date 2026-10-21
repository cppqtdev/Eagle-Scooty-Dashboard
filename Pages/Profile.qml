import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Style 1.0
import "../Component"

// The rider and the scooter.
EaglePage {
    background: null

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 28
        spacing: 14

        RowLayout {
            spacing: 24
            Rectangle {
                implicitWidth: 120
                implicitHeight: 120
                radius: 60
                color: Style.accentSoft
                PrefsLabel { anchors.centerIn: parent; font.pixelSize: 54; isBold: true; color: Style.accentStrong; text: "A" }
            }
            ColumnLayout {
                spacing: 4
                Caption { text: qsTr("Rider") }
                PrefsLabel { font.pixelSize: Style.typography.display + 4; isBold: true; text: qsTr("Aarav Mehta") }
                PrefsLabel { font.pixelSize: Style.h5; color: Style.textMuted; text: qsTr("Fingerprint and PIN set up") }
            }
        }

        Caption { Layout.topMargin: 18; text: qsTr("Scooter") }
        InfoRow { Layout.fillWidth: true; showEdge: false; title: qsTr("Model"); value: qsTr("Eagle EV 3.2"); valueColor: Style.textMuted }
        InfoRow { Layout.fillWidth: true; showEdge: false; title: qsTr("Registration"); value: "KA 05 •• ••42"; valueColor: Style.textMuted }
        InfoRow { Layout.fillWidth: true; showEdge: false; title: qsTr("Battery"); value: qsTr("3.2 kWh lithium-ion"); valueColor: Style.textMuted }
        InfoRow { Layout.fillWidth: true; showEdge: false; title: qsTr("Odometer"); value: qsTr("%L1 km").arg(dashboardData.odometerKm); valueColor: Style.textMuted }
        Item { Layout.fillHeight: true }
    }
}
