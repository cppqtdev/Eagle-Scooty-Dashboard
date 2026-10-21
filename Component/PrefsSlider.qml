import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Style 1.0
Slider {
    id: control
    property bool labelVisible: true
    property real setHandleHeight: height + 5
    property color checkedColor: Style.accent
    property color handlerColor: Style.surfaceRaised
    property bool tooltipVisible: true
    width: 680
    height: 20
    leftPadding:5
    from:0
    to:100
    background: Rectangle {
        x: -2
        y: control.topPadding + control.availableHeight / 2 - height / 2
        implicitWidth: control.width
        implicitHeight: control.height
        width: control.availableWidth
        height: implicitHeight
        radius: height / 2
        color: Style.surfaceSunken
        border.width: 1
        border.color: Style.border

        Rectangle {
            width: control.visualPosition == 0 ? 0 : control.handle.x + control.handle.width
            height: parent.height
            color: control.checkedColor
            radius: height / 2
            layer.enabled: control.pressed
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: control.checkedColor
                shadowBlur: 0.25
            }
        }
    }

    handle: Rectangle {
        visible: labelVisible
        x: control.visualPosition * (control.availableWidth - width) - 2
        y: control.topPadding + control.availableHeight / 2 - height / 2
        implicitWidth: setHandleHeight + 6
        height: setHandleHeight + 6
        radius: implicitWidth / 2
        color: "transparent"
        border.width: implicitWidth * 0.33
        border.color: handlerColor

        layer.enabled: control.pressed
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: control.checkedColor
            shadowBlur: 0.3
        }

        Image{
            visible: control.visualPosition != -1 && tooltipVisible
            source: "qrc:/Icons/tooltip.svg"
            anchors.bottom: parent.top
            anchors.topMargin: 5
            anchors.horizontalCenter: parent.horizontalCenter
            PrefsLabel{
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 3
                text:  control.value.toFixed(0) + "%";
                font.pixelSize: Style.h4
                color: Style.textOnAccent
            }
        }
    }
}
