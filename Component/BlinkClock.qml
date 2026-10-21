pragma Singleton
import QtQuick

// The one flasher every blinking thing follows: the indicator telltales, the
// hazard banner and the road edges. 85 flashes a minute, inside the 60 to 120
// the regulations allow, and each run starts on its lit phase.
QtObject {
    id: clock

    property bool on: true
    readonly property bool needed: dashboardData.leftIndicator || dashboardData.rightIndicator
    readonly property bool hazard: dashboardData.leftIndicator && dashboardData.rightIndicator

    onNeededChanged: { on = true; if (needed) timer.restart() }

    property Timer timer: Timer {
        interval: 353
        repeat: true
        running: clock.needed
        onTriggered: clock.on = !clock.on
    }
}
