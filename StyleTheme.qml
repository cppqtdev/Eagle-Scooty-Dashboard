pragma Singleton

import QtQuick
import "Theme" as ThemeComponents

QtObject {
    id: root

    readonly property bool isDark: themeController.dark
    readonly property int themeMode: themeController.mode
    readonly property int autoMode: 0
    readonly property int lightMode: 1
    readonly property int darkMode: 2

    readonly property ThemeComponents.Typography typography: ThemeComponents.Typography {}
    readonly property ThemeComponents.Metrics metrics: ThemeComponents.Metrics {}
    readonly property ThemeComponents.Motion motion: ThemeComponents.Motion {}

    readonly property ThemeComponents.ColorPalette lightPalette: ThemeComponents.ColorPalette {}
    readonly property ThemeComponents.ColorPalette darkPalette: ThemeComponents.ColorPalette {
        ground: "#080B0D"
        surface: "#101619"
        surfaceRaised: "#172024"
        surfaceSunken: "#0C1113"
        border: "#26363A"
        borderStrong: "#3B5257"

        textPrimary: "#F4FAFA"
        textSecondary: "#C4D1D2"
        textMuted: "#829799"
        textOnAccent: "#FFFFFF"

        accent: "#18B8B3"
        accentStrong: "#69FFF6"
        accentSoft: "#163B3C"

        success: "#31D158"
        warning: "#FFB340"
        danger: "#FF453A"
        shadow: "#A0000000"
    }

    readonly property ThemeComponents.ColorPalette target: isDark ? darkPalette : lightPalette

    property color background: target.ground
    property color surface: target.surface
    property color surfaceRaised: target.surfaceRaised
    property color surfaceSunken: target.surfaceSunken
    property color border: target.border
    property color borderStrong: target.borderStrong
    property color textPrimary: target.textPrimary
    property color textSecondary: target.textSecondary
    property color textMuted: target.textMuted
    property color textOnAccent: target.textOnAccent
    property color accent: target.accent
    property color accentStrong: target.accentStrong
    property color accentSoft: target.accentSoft
    property color success: target.success
    property color warning: target.warning
    property color danger: target.danger
    property color shadow: target.shadow

    Behavior on background { ColorAnimation { duration: root.motion.theme } }
    Behavior on surface { ColorAnimation { duration: root.motion.theme } }
    Behavior on surfaceRaised { ColorAnimation { duration: root.motion.theme } }
    Behavior on surfaceSunken { ColorAnimation { duration: root.motion.theme } }
    Behavior on border { ColorAnimation { duration: root.motion.theme } }
    Behavior on borderStrong { ColorAnimation { duration: root.motion.theme } }
    Behavior on textPrimary { ColorAnimation { duration: root.motion.theme } }
    Behavior on textSecondary { ColorAnimation { duration: root.motion.theme } }
    Behavior on textMuted { ColorAnimation { duration: root.motion.theme } }
    Behavior on accent { ColorAnimation { duration: root.motion.theme } }
    Behavior on accentStrong { ColorAnimation { duration: root.motion.theme } }
    Behavior on accentSoft { ColorAnimation { duration: root.motion.theme } }

    // Ride-mode accents: the speed, the mode chip and the battery bar follow the mode.
    readonly property color modeEco: isDark ? "#31D158" : "#16A34A"
    readonly property color modeCity: isDark ? "#18B8B3" : "#087F83"
    readonly property color modeSport: isDark ? "#FF7A2F" : "#EA580C"

    function modeColor(mode) {
        return mode === 2 ? modeSport : mode === 1 ? modeCity : modeEco
    }

    // Shadows and glows need the GPU scene graph; the board's software renderer skips them.
    readonly property bool effects: typeof effectsEnabled === "undefined" ? true : effectsEnabled

    function setDark(dark) {
        themeController.dark = dark
    }

    function setMode(mode) {
        themeController.mode = mode
    }

    function toggle() {
        themeController.toggle()
    }

    // Compatibility aliases for existing screens. New code should use the
    // semantic roles above rather than appearance-specific names.
    readonly property color fontColor: textOnAccent
    readonly property color baseColor: textPrimary
    readonly property color styleColor: accentStrong
    readonly property color grayColor: textMuted

    property int left : 0
    property int right : 1
    property int alternate : 2

    readonly property int h1: typography.titleLarge
    readonly property int h2: typography.title
    readonly property int h3: typography.heading
    readonly property int h4: typography.bodyLarge
    readonly property int h5: typography.body
    readonly property int h6: typography.bodySmall
    readonly property int paragraph: typography.bodySmall

    readonly property string lightFontFamily: typography.lightFamily
    readonly property string regularFontFamily: typography.regularFamily
    readonly property string mediumFontFamily: typography.mediumFamily
    readonly property string boldFontFamily: typography.boldFamily
    readonly property bool fontsReady: typography.ready
}
