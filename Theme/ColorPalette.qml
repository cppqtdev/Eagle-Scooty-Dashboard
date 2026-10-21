import QtQuick

QtObject {
    property color ground: "#F3F7F7"
    property color surface: "#FFFFFF"
    property color surfaceRaised: "#FFFFFF"
    property color surfaceSunken: "#E8EEEE"
    property color border: "#CAD6D6"
    property color borderStrong: "#91A5A5"

    property color textPrimary: "#102526"
    property color textSecondary: "#3E5556"
    property color textMuted: "#5A6F70"   // 4.8:1 on the ground (ISO 15008 asks for at least 3:1, WCAG 4.5:1)
    property color textOnAccent: "#FFFFFF"

    property color accent: "#087F83"
    property color accentStrong: "#045457"
    property color accentSoft: "#CDEAEA"

    property color success: "#16A34A"
    property color warning: "#D97706"
    property color danger: "#DC2626"
    property color shadow: "#40000000"
}
