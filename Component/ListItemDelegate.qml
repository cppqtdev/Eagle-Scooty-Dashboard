import QtQuick 2.15
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3
import Style 1.0
ItemDelegate {
    id:root
    property string title: ""
    highlighted: ListView.isCurrentItem
    height: 50
    hoverEnabled: true
    focus: true

    background: Rectangle{
        color: "transparent"
        anchors.fill: parent
        radius: 8
    }

    PrefsLabel {
        anchors.centerIn: parent
        opacity: 0.87
        text: title
        font.pixelSize: root.highlighted ?  Style.h2 : Style.h3
        isBold: root.highlighted
        isStyle: root.highlighted
    }
}
