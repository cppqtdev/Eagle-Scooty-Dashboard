import QtQuick
import QtQuick.Window
import QtQuick.Controls
import Style 1.0

import "./Component"
import "./Pages"

// The dashboard is laid out once on a 1920 × 1080 canvas and scaled to whatever
// panel it runs on (1024 × 600, 1280 × 720 or a desktop window), keeping its
// proportions. On the board it runs full screen without window decorations.
ApplicationWindow {
    id: window

    readonly property int designWidth: 1920
    readonly property int designHeight: 1080

    width: snapshotDir.length > 0 ? designWidth : 1440
    height: snapshotDir.length > 0 ? designHeight : 810
    minimumWidth: 640
    minimumHeight: 360
    visible: true
    visibility: boardMode ? Window.FullScreen : Window.Windowed
    flags: boardMode ? Qt.FramelessWindowHint | Qt.Window : Qt.Window
    color: "#000000"
    title: qsTr("Eagle Dashboard")

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

    Item {
        id: root
        objectName: "canvas"

        property string currentPage: "home"
        property alias handlebar: handlebar

        // Screens that need more than a glance are locked while moving.
        property bool rideLock: true
        readonly property var pages: ({
            home: homePage, map: mapPage, phone: callingPage,
            music: musicPage, charging: chargingPage, settings: settingsPage,
            documents: documentsPage, diagnostics: diagnosticsPage
        })

        // Settings opened at one of its entries (by index), for the bench and snapshots.
        function openSetting(index) {
            navigate("settings")
            stack.currentItem.current = index
        }

        function openKeypad() {
            navigate("phone")
            stack.currentItem.gEagleStack.push(Qt.createComponent("qrc:/Pages/Keypad.qml"))
        }

        function navigate(page) {
            if (page === currentPage || !pages[page])
                return
            currentPage = page
            stack.replace(null, pages[page])
        }

        width: window.designWidth
        height: window.designHeight
        anchors.centerIn: parent
        scale: Math.min(window.width / window.designWidth, window.height / window.designHeight)

        Rectangle {
            anchors.fill: parent
            color: Style.background
        }
        Image {
            anchors.fill: parent
            visible: Style.isDark
            source: "qrc:/Icons/dark/background.png"
        }

        Header {
            id: header
            width: parent.width
        }

        StackView {
            id: stack
            anchors.top: header.bottom
            anchors.bottom: footer.top
            anchors.left: parent.left
            anchors.right: parent.right
            clip: true
            initialItem: homePage

            replaceEnter: Transition {
                ParallelAnimation {
                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Style.motion.normal; easing.type: Easing.OutCubic }
                    NumberAnimation { property: "y"; from: 24; to: 0; duration: Style.motion.theme; easing.type: Easing.OutCubic }
                }
            }
            replaceExit: Transition {
                NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Style.motion.fast; easing.type: Easing.InCubic }
            }
            pushEnter: Transition {
                ParallelAnimation {
                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Style.motion.normal }
                    NumberAnimation { property: "x"; from: 60; to: 0; duration: Style.motion.theme; easing.type: Easing.OutCubic }
                }
            }
            pushExit: Transition {
                NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Style.motion.fast }
            }
            popEnter: Transition {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Style.motion.normal }
            }
            popExit: Transition {
                ParallelAnimation {
                    NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Style.motion.fast }
                    NumberAnimation { property: "x"; from: 0; to: 60; duration: Style.motion.normal }
                }
            }
        }

        Footer {
            id: footer
            anchors.bottom: parent.bottom
            width: parent.width
            currentPage: root.currentPage
            onNavigate: page => root.navigate(page)
        }

        Component { id: homePage; HomePage {} }
        Component { id: mapPage; MapPage {} }
        Component { id: callingPage; Callling {} }
        Component { id: musicPage; MusicPage {} }
        Component { id: chargingPage; Charing {} }
        Component { id: documentsPage; Documents {} }
        Component { id: diagnosticsPage; Diagnostics {} }
        Component {
            id: settingsPage
            SettingsPage {}
        }

        RideLock {
            anchors.fill: stack
            z: 10
            armed: root.rideLock
            screenNeedsStop: {
                if (root.currentPage === "settings" || root.currentPage === "documents")
                    return true
                const inner = stack.currentItem ? stack.currentItem.gEagleStack : null
                return root.currentPage === "phone" && !!inner && inner.depth > 1
            }
        }

        AlertBanner {
            anchors.horizontalCenter: parent.horizontalCenter
            y: header.height + 12
            z: 20
        }

        CallOverlay {
            anchors.fill: parent
            z: 30
            phonePageOpen: root.currentPage === "phone"
            onOpenPhone: root.navigate("phone")
        }

        CriticalAlert {
            anchors.fill: parent
            z: 40
        }

        BootScreen {
            anchors.fill: parent
            z: 50
        }

        HandlebarInput {
            id: handlebar
            anchors.fill: parent
            z: 60
            canvas: root
            stack: stack
            pages: ["home", "map", "phone", "music", "charging", "settings"]
            currentPage: root.currentPage
            onNavigate: page => root.navigate(page)
        }

        // The Ride app can press the keys and open pages too, and is told which page is open.
        Connections {
            target: phoneLinkBridge
            ignoreUnknownSignals: true
            function onKeyRequested(key) {
                switch (key) {
                case "up": handlebar.step(false); break
                case "down": handlebar.step(true); break
                case "left": handlebar.screen(false); break
                case "right": handlebar.screen(true); break
                case "ok": handlebar.ok(); break
                case "back": handlebar.back(); break
                }
            }
            function onPageRequested(page) { root.navigate(page) }
        }
        Binding {
            when: phoneLinkBridge !== null
            target: phoneLinkBridge
            property: "currentPage"
            value: root.currentPage
        }

        // Handlebar buttons that arrive over CAN go the same way as keys.
        Connections {
            target: canSource
            function onButtonPressed(button) {
                switch (button) {
                case "up": handlebar.step(false); break
                case "down": handlebar.step(true); break
                case "left": handlebar.screen(false); break
                case "right": handlebar.screen(true); break
                case "ok": handlebar.ok(); break
                case "back": handlebar.back(); break
                }
            }
        }

        Loader {
            active: snapshotDir.length > 0
            source: "qrc:/Component/SnapshotDriver.qml"
            onLoaded: item.canvas = root
        }

        Loader {
            anchors.fill: parent
            z: 200
            active: boardMode
            source: "qrc:/Component/KeyboardPanel.qml"
        }

        // Desktop preview of the panel backlight; the board drives the real one.
        Rectangle {
            anchors.fill: parent
            z: 100
            color: "black"
            opacity: Math.max(0, (76 - themeController.brightness) / 160)
            visible: opacity > 0
            enabled: false
            Behavior on opacity { NumberAnimation { duration: Style.motion.normal } }
        }
    }

    // The handlebar keys. On the board, buttons and a rotary encoder wired as
    // gpio-keys / rotary-encoder arrive as these keys (docs/Inputs.md).
    Shortcut { sequences: ["Up", "PgUp"]; onActivated: handlebar.step(false) }
    Shortcut { sequences: ["Down", "PgDown"]; onActivated: handlebar.step(true) }
    Shortcut { sequence: "Left"; onActivated: handlebar.screen(false) }
    Shortcut { sequence: "Right"; onActivated: handlebar.screen(true) }
    Shortcut { sequences: ["Return", "Enter", "Select"]; onActivated: handlebar.ok() }
    Shortcut { sequences: ["Escape", "Back"]; onActivated: handlebar.back() }

    // Bench keys: a quick way through the demo.
    Shortcut { sequence: "M"; onActivated: dashboardData.cycleRideMode() }
    Shortcut { sequence: "C"; onActivated: phone.callState === 1 ? phone.answer() : phone.simulateIncomingCall() }
    Shortcut { sequence: "X"; onActivated: phone.simulateMessage() }
    Shortcut { sequence: "P"; onActivated: simulator.toggleCharging() }
    Shortcut { sequence: "T"; onActivated: Style.toggle() }
    Shortcut { sequence: "H"; onActivated: dashboardData.highBeam = !dashboardData.highBeam }
    Shortcut { sequence: "F"; onActivated: simulator.trigger("motorFault") }
    Shortcut { sequence: "L"; onActivated: simulator.trigger("lowTyre") }
    Shortcut { sequence: "O"; onActivated: simulator.trigger("overheat") }
    Shortcut { sequence: "Z"; onActivated: simulator.trigger("hazard") }
    Shortcut { sequence: "R"; onActivated: simulator.trigger("reverse") }
    Shortcut { sequence: "Backspace"; onActivated: simulator.trigger("clear") }
    Shortcut { sequence: "1"; onActivated: root.navigate("home") }
    Shortcut { sequence: "2"; onActivated: root.navigate("map") }
    Shortcut { sequence: "3"; onActivated: root.navigate("phone") }
    Shortcut { sequence: "4"; onActivated: root.navigate("music") }
    Shortcut { sequence: "5"; onActivated: root.navigate("charging") }
    Shortcut { sequence: "6"; onActivated: root.navigate("settings") }
}
