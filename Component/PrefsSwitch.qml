import QtQuick 2.15
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3
import Style 1.0
Switch {
    id:control
    property color backgroundColor: myPalette.highlight
    SystemPalette { id: myPalette; colorGroup: SystemPalette.Active }
    spacing : 10
    indicator: Rectangle{
        implicitHeight: 32
        implicitWidth: 56
        x:control.leftPadding
        y:parent.height /2 - height/2
        radius: width/2
        color: control.checked ? control.backgroundColor : "#074041"
        border.width: control.checked ? 2 : 1
        border.color: control.checked ? control.backgroundColor : "transparent"


        Rectangle{
            x:control.checked ? (parent.width-width) - 2: 2
            NumberAnimation on x{
                duration: 5000
            }

            width: 28
            height: 28
            radius: height/2
            color: control.checked ? "#FFFFFF" : "#B3B3B3"
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    contentItem: PrefsLabel{
        font.pixelSize: Style.h2
        text: control.text
        verticalAlignment: Text.AlignVCenter
        leftPadding: control.indicator.width + control.spacing
    }
}
