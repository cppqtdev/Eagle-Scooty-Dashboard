import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
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
    Component{
        id:documentsPage
        Documents{
        }
    }
    Component{
        id:diagnosticsPage
        Diagnostics{
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
        case 8:
            settingsLoader.sourceComponent =  documentsPage
            break;
        case 9:
            settingsLoader.sourceComponent =  diagnosticsPage
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
                model:[qsTr("Profile"),qsTr("Display"),qsTr("Bluetooth"),qsTr("My Trips"),qsTr("Sound"),qsTr("About"),qsTr("Notifications"),qsTr("System Update"),qsTr("Documents"),qsTr("Diagnostics")]
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
