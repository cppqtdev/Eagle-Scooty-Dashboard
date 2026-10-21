import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
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

    palette.window: Style.background
    palette.windowText: Style.textPrimary
    palette.base: Style.surface
    palette.alternateBase: Style.surfaceSunken
    palette.text: Style.textPrimary
    palette.button: Style.surfaceRaised
    palette.buttonText: Style.textPrimary
    palette.highlight: Style.accent
    palette.highlightedText: Style.textOnAccent
    palette.placeholderText: Style.textMuted
    palette.light: Style.surfaceRaised
    palette.midlight: Style.border
    palette.mid: Style.textMuted
    palette.dark: Style.textPrimary
    palette.shadow: Style.shadow

    background: Item{
        anchors.fill: parent
        Rectangle {
            anchors.fill: parent
            color: Style.background
        }
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

    Rectangle {
        z: 10000
        anchors.fill: parent
        color: "black"
        // Desktop preview of a panel backlight. The production target can
        // connect the same persisted value to its display driver instead.
        opacity: Math.max(0, (76 - themeController.brightness) / 160)
        visible: opacity > 0
        enabled: false

        Behavior on opacity {
            NumberAnimation { duration: Style.motion.normal }
        }
    }
}
