import QtQuick
import QtQuick.Layouts
import Style 1.0

// Key-on: the logo, then each system checks in, then the ride view fades in once
// the vehicle reports ready.
Rectangle {
    id: root

    readonly property var checks: [qsTr("Battery"), qsTr("Motor"), qsTr("Brakes"), qsTr("Lights"), qsTr("Tyres"), qsTr("Phone")]
    property int passed: 0

    color: Style.isDark ? "#05080A" : "#F3F7F7"
    opacity: dashboardData.ready ? 0 : 1
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.InOutCubic } }

    MouseArea { anchors.fill: parent }

    Timer {
        interval: 320
        repeat: true
        running: root.passed < root.checks.length
        onTriggered: root.passed++
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 40

        Image {
            id: logo
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 760
            Layout.preferredHeight: 404
            sourceSize: Qt.size(760, 404)
            source: Style.isDark ? "qrc:/Icons/Eagle/5.png" : "qrc:/Icons/Eagle/7.png"
            opacity: 0
            scale: 0.92
            Component.onCompleted: { opacity = 1; scale = 1 }
            Behavior on opacity { NumberAnimation { duration: 700 } }
            Behavior on scale { NumberAnimation { duration: 900; easing.type: Easing.OutCubic } }
        }

        PrefsLabel {
            Layout.alignment: Qt.AlignHCenter
            font.pixelSize: 44
            isBold: true
            text: qsTr("EAGLE")
            font.letterSpacing: 14
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 34
            Repeater {
                model: root.checks
                RowLayout {
                    required property int index
                    required property string modelData
                    spacing: 8
                    Rectangle {
                        implicitWidth: 14
                        implicitHeight: 14
                        radius: 7
                        color: index < root.passed ? Style.success : Style.border
                        Behavior on color { ColorAnimation { duration: Style.motion.fast } }
                    }
                    PrefsLabel {
                        font.pixelSize: Style.h5
                        color: index < root.passed ? Style.textPrimary : Style.textMuted
                        text: modelData
                    }
                }
            }
        }
    }
}
