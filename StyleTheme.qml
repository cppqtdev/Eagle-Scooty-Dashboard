pragma Singleton

import QtQuick 2.15
QtObject {
    property bool isDark: false
    readonly property color background: isDark ? "#00000000" : "#DCF3F3"
    readonly property color fontColor: "#FFFFFF"
    readonly property color baseColor: isDark ? systemPalette.base : systemPalette.windowText
    readonly property color styleColor: "#045457"
    readonly property color grayColor: "#7C7C7C"

    property int left : 0
    property int right : 1
    property int alternate : 2

    readonly property int h1: 28
    readonly property int h2: 26
    readonly property int h3: 24
    readonly property int h4: 22
    readonly property int h5: 20
    readonly property int h6: 18
    readonly property int paragraph : 16

    readonly property var systemPalette: SystemPalette { colorGroup: SystemPalette.Active }

    readonly property var helveticaNeureMedium: FontLoader{
        source:"qrc:/fonts/HelveticaNeueLTCom-Md.ttf"
    }
    readonly property var helveticaNeureBold: FontLoader{
        source:"qrc:/fonts/HelveticaNeueLTCom-Bd.ttf"
    }
    readonly property var helveticaNeurRoman: FontLoader{
        source:"qrc:/fonts/HelveticaNeueLTCom-Roman.ttf"
    }
    readonly property var helveticaNeurLight: FontLoader{
        source: "qrc:/fonts/HelveticaNeueLTCom-Lt.ttf"
    }
}
