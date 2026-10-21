import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Style 1.0
import "../Component"

// The software, what it is built with, and the open-source licences.
EaglePage {
    background: null

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 28
        spacing: 14

        Image {
            Layout.preferredWidth: 360
            Layout.preferredHeight: 190
            sourceSize: Qt.size(360, 190)
            source: Style.isDark ? "qrc:/Icons/Eagle/5.png" : "qrc:/Icons/Eagle/7.png"
        }
        PrefsLabel { font.pixelSize: Style.typography.display + 4; isBold: true; text: qsTr("Eagle Dashboard") }
        PrefsLabel { font.pixelSize: Style.h5; color: Style.textMuted; text: qsTr("Version %1 · TechCoderHub").arg(Qt.application.version) }

        Caption { Layout.topMargin: 18; text: qsTr("Built with") }
        InfoRow { Layout.fillWidth: true; showEdge: false; title: qsTr("Qt 6 · Qt Quick · C++20"); value: qsTr("LGPL v3"); valueColor: Style.textMuted }
        InfoRow { Layout.fillWidth: true; showEdge: false; title: qsTr("Orbitron typeface"); value: qsTr("SIL Open Font License"); valueColor: Style.textMuted }
        InfoRow { Layout.fillWidth: true; showEdge: false; title: qsTr("Target"); value: boardMode ? qsTr("HMI panel") : qsTr("Desktop preview"); valueColor: Style.textMuted }
        Item { Layout.fillHeight: true }
    }
}
