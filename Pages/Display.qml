import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Style 1.0
import "../Component"

// Theme and brightness. Auto follows the time of day.
EaglePage {
    id: root

    background: null

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 28
        spacing: 16

        Caption { text: qsTr("Theme") }
        SegmentedControl {
            model: [{ icon: "auto", title: qsTr("Auto") }, { icon: "sun", title: qsTr("Light") }, { icon: "moon", title: qsTr("Dark") }]
            currentIndex: Style.themeMode
            onActivated: index => Style.setMode(index)
        }
        PrefsLabel {
            font.pixelSize: Style.typography.caption
            color: Style.textMuted
            text: qsTr("Auto uses the light theme by day and the dark theme from 6 pm to 6 am.")
        }

        Caption { Layout.topMargin: 24; text: qsTr("Navigation arrow") }
        SegmentedControl {
            // Display order; the stored values are solid 0, ribbon 1, chevrons 2, outline 3, sign 4.
            readonly property var styles: [4, 1, 0, 2, 3]
            model: [qsTr("Sign"), qsTr("Ribbon"), qsTr("Solid"), qsTr("Chevrons"), qsTr("Outline")]
            currentIndex: styles.indexOf(themeController.arrowStyle)
            onActivated: index => themeController.arrowStyle = styles[index]
        }

        Caption { Layout.topMargin: 24; text: qsTr("Brightness") }
        RowLayout {
            spacing: 18
            OutlineButton { symbol: "minus"; onClicked: themeController.brightness = Math.max(20, themeController.brightness - 10) }
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 18
                radius: 9
                color: Style.surfaceSunken
                Rectangle {
                    width: parent.width * themeController.brightness / 100
                    height: parent.height
                    radius: 9
                    color: Style.accent
                    Behavior on width { NumberAnimation { duration: Style.motion.fast } }
                }
            }
            OutlineButton { symbol: "plus"; onClicked: themeController.brightness = Math.min(100, themeController.brightness + 10) }
            DigitText { Layout.preferredWidth: 110; pixelSize: Style.h3; isBold: true; text: qsTr("%1%").arg(themeController.brightness) }
        }

        Caption { Layout.topMargin: 24; text: qsTr("Preview") }
        RowLayout {
            spacing: 18
            Repeater {
                model: [{ dark: false, label: qsTr("Day") }, { dark: true, label: qsTr("Night") }]
                Rectangle {
                    required property var modelData
                    implicitWidth: 300
                    implicitHeight: 170
                    radius: Style.metrics.radiusLg
                    color: modelData.dark ? "#101619" : "#F3F7F7"
                    border.color: Style.isDark === modelData.dark ? Style.accent : Style.border
                    border.width: Style.isDark === modelData.dark ? 3 : 1
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 2
                        PrefsLabel { Layout.alignment: Qt.AlignHCenter; font.pixelSize: 64; isBold: true; color: modelData.dark ? "#F4FAFA" : "#102526"; text: dashboardData.speed }
                        PrefsLabel { Layout.alignment: Qt.AlignHCenter; font.pixelSize: Style.typography.caption; color: modelData.dark ? "#829799" : "#6F8586"; text: modelData.label }
                    }
                }
            }
        }
        Item { Layout.fillHeight: true }
    }
}
