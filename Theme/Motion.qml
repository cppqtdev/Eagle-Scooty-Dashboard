import QtQuick

QtObject {
    readonly property int instant: 90
    readonly property int fast: 160
    readonly property int normal: 240
    readonly property int theme: 320

    readonly property int easeIn: Easing.InCubic
    readonly property int easeOut: Easing.OutCubic
    readonly property int easeInOut: Easing.InOutCubic
}
