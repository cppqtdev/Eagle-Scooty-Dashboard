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

        // The two themes as they look, picked by a tap; the one on screen is lit the way
        // a selected row is (a wash of the accent and an outline).
        Caption { Layout.topMargin: 24; text: qsTr("Preview") }
        RowLayout {
            spacing: 18
            Repeater {
                model: [{ dark: false, label: qsTr("Day"), image: "qrc:/Icons/theme_light.png", mode: 1 },
                        { dark: true, label: qsTr("Night"), image: "qrc:/Icons/theme_dark.png", mode: 2 }]
                AbstractButton {
                    id: themeCard
                    required property var modelData
                    readonly property bool current: Style.isDark === modelData.dark
                    focusPolicy: Qt.StrongFocus
                    padding: 10
                    scale: pressed ? 0.98 : 1
                    Behavior on scale { NumberAnimation { duration: Style.motion.instant } }
                    onClicked: Style.setMode(modelData.mode)

                    background: Rectangle {
                        radius: Style.metrics.radiusMd
                        color: Style.alpha(Style.textPrimary, Style.isDark ? 0.045 : 0.035)
                        border.color: themeCard.current ? Style.alpha(Style.accent, 0.8) : "transparent"
                        border.width: themeCard.current ? 1.5 : 0
                        Rectangle {
                            visible: themeCard.current
                            anchors.fill: parent
                            radius: parent.radius
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: Style.alpha(Style.accent, Style.isDark ? 0.30 : 0.18) }
                                GradientStop { position: 0.9; color: Style.alpha(Style.accent, 0.0) }
                            }
                        }
                    }
                    contentItem: ColumnLayout {
                        spacing: 10
                        Image {
                            Layout.preferredWidth: 288
                            Layout.preferredHeight: 162
                            sourceSize: Qt.size(288, 162)
                            fillMode: Image.PreserveAspectFit
                            source: themeCard.modelData.image
                        }
                        RowLayout {
                            Layout.leftMargin: 4
                            spacing: 10
                            LineIcon {
                                name: themeCard.modelData.dark ? "moon" : "sun"
                                size: 22
                                color: themeCard.current ? (Style.isDark ? Style.accentStrong : Style.accent) : Style.textMuted
                            }
                            PrefsLabel {
                                font.pixelSize: Style.h5
                                isBold: themeCard.current
                                color: themeCard.current ? Style.textPrimary : Style.textSecondary
                                text: themeCard.modelData.label
                            }
                        }
                    }
                }
            }
        }
        Item { Layout.fillHeight: true }
    }
}
