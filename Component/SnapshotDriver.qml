import QtQuick
import Style 1.0

// --snapshot <dir>: walks through every page and alert state and saves each as a
// 1920 x 1080 PNG, then quits. Used for documentation and to review the UI on
// panel sizes without the hardware.
QtObject {
    id: driver

    property Item canvas
    property int step: -1

    // [file name, seconds to wait before the shot, what to do first]
    readonly property var steps: [
        ["01-boot", 0.6, () => {}],
        ["02-home-riding", 9.0, () => {}],
        ["03-home-dark", 1.2, () => Style.setMode(Style.darkMode)],
        ["04-alert-banner", 1.2, () => { Style.setMode(Style.lightMode); simulator.trigger("lowTyre") }],
        ["05-critical-alert", 1.2, () => { simulator.trigger("clear"); simulator.trigger("motorFault") }],
        ["06-incoming-call", 1.4, () => { simulator.trigger("clear"); phone.simulateIncomingCall() }],
        ["07-active-call", 3.2, () => { phone.answer(); canvas.navigate("phone") }],
        ["08-phone", 1.2, () => phone.hangUp()],
        ["08b-keypad", 1.2, () => canvas.openKeypad()],
        ["09-music", 1.2, () => canvas.navigate("music")],
        ["10-charging", 6.0, () => { simulator.toggleCharging(); canvas.navigate("charging") }],
        ["11-documents", 1.2, () => { simulator.toggleCharging(); canvas.navigate("documents") }],
        ["12-diagnostics", 1.2, () => { simulator.trigger("overheat"); canvas.navigate("diagnostics") }],
        ["13-settings-display", 1.2, () => { simulator.trigger("clear"); canvas.openSetting(0) }],
        ["13b-settings-bluetooth", 1.2, () => canvas.openSetting(1)],
        ["13c-settings-wifi", 1.2, () => canvas.openSetting(2)],
        ["13d-settings-trips", 1.2, () => canvas.openSetting(6)],
        ["13e-settings-about", 1.2, () => canvas.openSetting(10)],
        ["14-map", 1.2, () => canvas.navigate("map")],
        ["15-home-sport-dark", 3.0, () => { canvas.navigate("home"); Style.setMode(Style.darkMode); dashboardData.rideMode = 2 }],
    ]

    function next() {
        step++
        if (step >= steps.length) {
            Style.setMode(Style.autoMode)
            Qt.quit()
            return
        }
        steps[step][2]()
        timer.interval = steps[step][1] * 1000
        timer.start()
    }

    property Timer timer: Timer {
        onTriggered: driver.canvas.grabToImage(result => {
            result.saveToFile(snapshotDir + "/" + driver.steps[driver.step][0] + ".png")
            driver.next()
        })
    }

    Component.onCompleted: next()
}
