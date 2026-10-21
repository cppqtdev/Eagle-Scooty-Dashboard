import QtQuick
import QtQuick.Controls
import Style 1.0
Page {
    padding:0
    background: Rectangle{
        anchors.fill: parent
        color: Style.background
    }

    property var gEagleStack: StackView.view
}
