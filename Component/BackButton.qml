import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Style 1.0
Button{
    id:control
    contentItem:PrefsLabel{
        text: control.text
    }

    background: Rectangle{
        anchors.fill: parent
        color: "transparent"
    }
}
