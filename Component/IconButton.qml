import QtQuick 2.9
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3
import QtGraphicalEffects 1.15
import Style 1.0
Button {
    property string setIcon : ""
    property string setIconText : ""
    property string setIconColor : Style.fontColor
    property string iconBackground: "transparent"

    property real setIconSize: 25
    property real radius: height /2
    property real iconWidth: 28
    property real iconHeight: 28

    property bool isMirror: false
    property bool isGlow: false
    property bool roundIcon: false
    property alias iconSource: iconSource
    property alias roundIconSource: roundIconSource

    id: control
    implicitHeight: 55
    implicitWidth: 55
    contentItem: PrefsLabel{
        text: control.text
    }

    Image{
        id:iconSource
        z:2
        visible: !roundIcon && !setIconText
        mirror: isMirror
        anchors.centerIn: parent
        source: setIcon
        scale: control.pressed ? 0.9 : 1.0
        Behavior on scale { NumberAnimation { duration: 200; } }
    }

    Image{
        id:roundIconSource
        z:2
        visible: roundIcon && !setIconText
        mirror: isMirror
        sourceSize: Qt.size(iconWidth,iconHeight)
        anchors.centerIn: parent
        source: setIcon
        scale: control.pressed ? 0.9 : 1.0
        Behavior on scale { NumberAnimation { duration: 200; } }
    }

    background: Rectangle {
        z:1
        anchors.fill: parent
        radius: control.radius
        color: control.iconBackground
        visible: true
        Behavior on color {
            ColorAnimation {
                duration: 200;
                easing.type: Easing.Linear;
            }
        }

        Rectangle {
            id: indicator
            property int mx
            property int my
            x: mx - width / 2
            y: my - height / 2
            height: width
            radius: width / 2
            color: isGlow ? Qt.lighter("#29BEB6") : Qt.lighter("#B8FF01")
        }
    }

    Rectangle {
        id: mask
        radius: height /2
        anchors.fill: parent
        visible: false
    }

    OpacityMask {
        anchors.fill: background
        source: background
        maskSource: mask
    }

    MouseArea {
        id: mouseArea
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        cursorShape: Qt.PointingHandCursor
        anchors.fill: parent
    }

    ParallelAnimation {
        id: anim
        NumberAnimation {
            target: indicator
            property: 'width'
            from: 0
            to: control.width * 1.5
            duration: 200
        }
        NumberAnimation {
            target: indicator;
            property: 'opacity'
            from: 0.9
            to: 0
            duration: 200
        }
    }

    onPressed: {
        indicator.mx = mouseArea.mouseX
        indicator.my = mouseArea.mouseY
        anim.restart();
    }
}
