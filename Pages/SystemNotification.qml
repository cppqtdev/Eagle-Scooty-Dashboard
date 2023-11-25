import QtQuick 2.15
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3
import QtLocation 5.15
import QtPositioning 5.6
import Style 1.0
import "../Component"

EaglePage {
    id:root
    width: parent.width
    leftPadding: 100
    header:RowLayout{
        width: parent.width
        spacing: 5
        PrefsLabel{
            Layout.alignment: Qt.AlignLeft
            Layout.leftMargin: 100
            font.pixelSize: Style.h2
            isBold: true
            isStyle: true
            text: qsTr("Notification")
            MouseArea{
                anchors.fill: parent
                onClicked: myTost.open()
            }
        }
    }
    contentData: ColumnLayout{
        width: root.width
        spacing: 20
        Item{
            Layout.fillWidth: true
        }

        Image{
            width: parent.width
            Layout.alignment: Qt.AlignLeft
            source: "qrc:/Icons/HorizontalSeparator.png"
        }
        InfoPopup{
            infoColor: "#00CC99"
            icon: "qrc:/Icons/Notification/Success.svg"
            title:  qsTr("Success")
            subTitle: qsTr("Order Placed Successfully. Thank you for shopping with us.")
        }
        InfoPopup{
            infoColor: "#EB5757"
            icon: "qrc:/Icons/Notification/Error.svg"
            title:  qsTr("Error")
            subTitle: qsTr("Payment for order could not be proceed. Please try again.")
        }
        InfoPopup{
            infoColor: "#F2C94C"
            icon: "qrc:/Icons/Notification/Warning.svg"
            title:  qsTr("Warning")
            subTitle: qsTr("Order will not delivered in this pincode. Please try other pincode.")
        }
        InfoPopup{
            infoColor: "#5458F7"
            icon: "qrc:/Icons/Notification/Info.svg"
            title:  qsTr("Info")
            subTitle: qsTr("You will receive a tracking link as soon as your order ships.")
        }
        Toast{
            id:myTost
            x:700
            y:200
        }
    }
}
