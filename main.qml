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

    Component.onCompleted: root.showMaximized()

    header: Header{}
    footer: Footer{
        onSettingsClicked: {
            mainLoader.item.replace(null,settingsPage)
        }
        onMusicClicked: mainLoader.item.replace(null,musicPage)
        onCallingClicked: mainLoader.item.replace(null,callingPage)
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
        }
    }
}
