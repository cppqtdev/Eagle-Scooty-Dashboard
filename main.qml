import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3
import Style 1.0

import "./Component"
import "./Pages"
ApplicationWindow {
    id:root
    width: 1920
    height: 1080
    visible: true
    color: Style.background
    title: qsTr("Eagle Theme")

    background: Item{
        anchors.fill: parent
        Image{
            anchors.fill: parent
            visible: Style.isDark
            source: "qrc:/Icons/dark/background.png"
        }
    }

    Component.onCompleted: root.showMaximized()

    header: Header{}
    footer: Footer{
        id:footerLayout
        onSettingsClicked: {
            mainLoader.item.replace(null,settingsPage)
        }
        onMusicClicked: mainLoader.item.replace(null,musicPage)
        onCallingClicked: mainLoader.item.replace(null,callingPage)
        onHomeClicked: mainLoader.item.replace(null,homePage)
        onChargeClicked: mainLoader.item.replace(null,chargingPage)
        onMapClicked: mainLoader.item.replace(null,mapPage)

    }

    Component{
        id:chargingPage
        Charing{

        }
    }

    Component{
        id:mapPage
        MapPage{

        }
    }

    Component{
        id:homePage
        HomePage{

        }
    }

    Component{
        id:callingPage
        Callling{

        }
    }

    Component{
        id:musicPage
        MusicPage{

        }
    }

    Component{
        id:settingsPage
        SettingsPage{
            objectName: "SettingsPage"
            onBackToHome: {
                mainLoader.item.replace(null,homePage)
            }
        }
    }

    contentData:Loader{
        id:mainLoader
        anchors.fill: parent
        sourceComponent:StackView{
            id:mainStack
            initialItem:homePage
            onCurrentItemChanged: {
                var footer = footerlayout()
                if(currentItem.objectName == "SettingsPage"){
                    footer.visible = false
                }else{
                    footer.visible = true
                }
            }
        }
    }

    function footerlayout(){
        return footerLayout
    }
}
