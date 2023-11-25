import QtQuick 2.15
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.5
import Style 1.0

import "../Component"
EaglePage {
    id:root
    signal backToHome()
    header:Item{
        width: root.width
        height: 80
        BackButton{
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 40
            text:qsTr("Back To Home")
            onClicked: backToHome()
        }
    }

    Component{
        id:profilePage
        Profile{
        }
    }
    Component{
        id:displayPage
        Display{
        }
    }
    Component{
        id:bluetoothPage
        Bluetooth{
        }
    }
    Component{
        id:mytripPage
        MyTrips{
        }
    }
    Component{
        id:aboutPage
        About{
        }
    }
    Component{
        id:soundPage
        Sound{
        }
    }
    Component{
        id:systemNotificationPage
        SystemNotification{
        }
    }
    Component{
        id:systemUpdatePage
        SystemUpdate{
        }
    }


    function switchPage(index){
        switch(index){
        case 0:
            settingsLoader.sourceComponent = profilePage
            break;
        case 1:
            settingsLoader.sourceComponent =  displayPage
            break;
        case 2:
            settingsLoader.sourceComponent =  bluetoothPage
            break;
        case 3:
            settingsLoader.sourceComponent =  mytripPage
            break;
        case 4:
            settingsLoader.sourceComponent =  soundPage
            break;
        case 5:
            settingsLoader.sourceComponent =  aboutPage
            break;
        case 6:
            settingsLoader.sourceComponent =  systemNotificationPage
            break;
        case 7:
            settingsLoader.sourceComponent =  systemUpdatePage
            break;
        }
    }

    RowLayout{
        anchors.fill: parent
        Pane{
            padding: 0
            Layout.preferredWidth: root.width * 0.18
            Layout.fillHeight: true
            background: Rectangle{
                anchors.fill: parent
                color: Style.background
                Image{
                    source: "qrc:/Icons/separator.png"
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            ListView{
                id:listItemView
                anchors.fill: parent
                highlightFollowsCurrentItem :true
                highlight:null
                spacing:20
                model:["Profile","Display","Bluetooth","MyTrip","Sound","About","Notification","System Update"]
                delegate:ListItemDelegate{
                    spacing: 20
                    title: modelData
                    width: listItemView.width
                    onClicked:   {
                        ListView.view.currentIndex = index
                        root.switchPage(index)
                    }
                }
            }
        }

        Item{
            Layout.fillWidth: true
            Layout.fillHeight: true
            StackView{
                id:pageStackView
                anchors.fill: parent
                initialItem:Loader{
                    id:settingsLoader
                    sourceComponent: profilePage
                    onLoaded: item.gEagleStack = pageStackView
                }
            }
        }
    }
}
