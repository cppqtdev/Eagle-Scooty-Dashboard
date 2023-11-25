import QtQuick 2.15
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3
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
