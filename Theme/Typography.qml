import QtQuick

QtObject {
    id: root

    readonly property FontLoader lightLoader: FontLoader {
        source: "qrc:/fonts/Orbitron-Regular.ttf"
    }
    readonly property FontLoader regularLoader: FontLoader {
        source: "qrc:/fonts/Orbitron-Regular.ttf"
    }
    readonly property FontLoader mediumLoader: FontLoader {
        source: "qrc:/fonts/Orbitron-Medium.ttf"
    }
    readonly property FontLoader boldLoader: FontLoader {
        source: "qrc:/fonts/Orbitron-Bold.ttf"
    }

    readonly property string fallbackFamily: "Arial"
    readonly property string lightFamily: lightLoader.status === FontLoader.Ready
                                          ? lightLoader.font.family : fallbackFamily
    readonly property string regularFamily: regularLoader.status === FontLoader.Ready
                                            ? regularLoader.font.family : fallbackFamily
    readonly property string mediumFamily: mediumLoader.status === FontLoader.Ready
                                           ? mediumLoader.font.family : regularFamily
    readonly property string boldFamily: boldLoader.status === FontLoader.Ready
                                         ? boldLoader.font.family : mediumFamily

    readonly property bool ready: lightLoader.status === FontLoader.Ready
                                  && regularLoader.status === FontLoader.Ready
                                  && mediumLoader.status === FontLoader.Ready
                                  && boldLoader.status === FontLoader.Ready

    // Sized for a 1920 x 1080 canvas shown on a 1024 x 600 panel: about half size,
    // so nothing here may drop below ~12 px on the panel.
    readonly property int display: 40
    readonly property int titleLarge: 34
    readonly property int title: 30
    readonly property int heading: 28
    readonly property int bodyLarge: 26
    readonly property int body: 24
    readonly property int bodySmall: 22
    readonly property int caption: 20
}
