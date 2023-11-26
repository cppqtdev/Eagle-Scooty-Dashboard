import QtQuick 2.15
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3
import QtGraphicalEffects 1.15
import Style 1.0


Button {
    id:control

    property real radius: 4
    property color backgroundColor: "#14A44D"
    property color smallBackgroundColor: "#14A44D"
    property string setIcon: ""
    property color textColor: "#FFFFFF"

    property real borderWidth: 0
    property color borderColor: "transparent"
    property real iconWidth: 18
    property real iconHeight: 18
    implicitHeight: 45
    implicitWidth: 120
    SystemPalette { id: myPalette; colorGroup: SystemPalette.Active }

    contentItem:RowLayout{
        anchors.centerIn: parent
        width: parent.width
        IconButton{
            z:2
            implicitWidth: control.iconWidth
            implicitHeight: control.iconHeight
            setIcon: control.setIcon
            iconWidth: control.iconWidth
            iconHeight: control.iconHeight
            iconBackground:control.smallBackgroundColor
        }
        PrefsLabel{
            z:2
            color: control.textColor
            font.pixelSize: Style.paragraph
            text: control.text
        }
    }

    background: Rectangle{
        implicitHeight: control.implicitHeight
        implicitWidth: control.implicitWidth
        radius: control.radius
        color: control.backgroundColor
        border.width: control.borderWidth
        border.color: control.borderColor

        visible: false

        Behavior on color {

            ColorAnimation {
                easing.type: Easing.Linear
                duration: 200
            }
        }

        Rectangle{
            id:indicator
            property int mx
            property int my
            x:mx-width/2
            y:my-height/2
            height:width
            radius: control.radius
            color: Qt.lighter(myPalette.highlight)
        }
    }

    Rectangle{
        id:mask
        radius: control.radius
        anchors.fill: parent
        visible: false
    }

    OpacityMask{
        anchors.fill: background
        source: background
        maskSource: mask
    }

    MouseArea{
        id:mouseArea
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        cursorShape: Qt.PointingHandCursor
        anchors.fill: parent
    }

    ParallelAnimation{
        id:main
        NumberAnimation{
            target: indicator
            properties: 'width'
            from:0
            to:control.width *2.5
            duration: 200
        }
        NumberAnimation{
            target: indicator
            properties: 'opacity'
            from:0.9
            to:0
            duration: 200
        }
    }

    onPressed: {
        indicator.mx = mouseArea.mouseX
        indicator.my = mouseArea.mouseY
        main.restart()
    }
}
