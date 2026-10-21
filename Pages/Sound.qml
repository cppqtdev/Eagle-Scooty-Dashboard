import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Style 1.0
import "../Component"

// Media volume and the sounds the dashboard itself makes.
EaglePage {
    background: null

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 28
        spacing: 14

        Caption { text: qsTr("Media volume") }
        RowLayout {
            spacing: 18
            OutlineButton { symbol: "minus"; onClicked: phone.volume = phone.volume - 10 }
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 18
                radius: 9
                color: Style.surfaceSunken
                Rectangle {
                    width: parent.width * phone.volume / 100
                    height: parent.height
                    radius: 9
                    color: Style.accent
                    Behavior on width { NumberAnimation { duration: Style.motion.fast } }
                }
            }
            OutlineButton { symbol: "plus"; onClicked: phone.volume = phone.volume + 10 }
            DigitText { Layout.preferredWidth: 110; pixelSize: Style.h3; isBold: true; text: qsTr("%1%").arg(phone.volume) }
        }

        Caption { Layout.topMargin: 18; text: qsTr("Dashboard sounds") }
        ToggleRow { Layout.fillWidth: true; title: qsTr("Alert chime"); subtitle: qsTr("Warnings and critical alerts sound once, then repeat every 10 s"); checked: true }
        ToggleRow { Layout.fillWidth: true; title: qsTr("Ringtone in helmet"); subtitle: qsTr("Incoming calls ring through the paired headset"); checked: true }
        ToggleRow { Layout.fillWidth: true; title: qsTr("Indicator tick"); subtitle: qsTr("A soft tick while an indicator is on"); checked: true }
        ToggleRow { Layout.fillWidth: true; title: qsTr("Touch sounds"); checked: false }
        Item { Layout.fillHeight: true }
    }
}
