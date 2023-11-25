import QtQuick 2.15
import QtQuick.Controls 2.5
import Style 1.0
Page {
    padding:0
    background: Rectangle{
        anchors.fill: parent
        color: Style.background
    }

    property var gEagleStack: StackView.view
}
