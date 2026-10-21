import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Style 1.0
import Eagle.Blink 1.0

// What the rider must notice before anything else, after the ApexCluster drive
// view: HAZARD between double chevrons in green, flashing with the telltales,
// or REVERSE and the motor's limit in amber with chevrons sweeping down. Shown
// in place of the ride-mode row, so it never sits over the wings.
Control {
    id: root

    readonly property bool hazard: BlinkClock.hazard
    readonly property bool reverse: dashboardData.gear === "R"
    readonly property bool shown: hazard || reverse
    readonly property color tone: reverse ? Style.warning : Style.success

    // A capsule behind it, so it reads over the road it may sit on.
    leftPadding: 18
    rightPadding: 18
    topPadding: 4
    bottomPadding: 4
    background: Rectangle {
        radius: height / 2
        color: Style.alpha(Style.background, 0.9)
        border.color: Style.alpha(root.tone, 0.45)
    }

    opacity: shown ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: Style.motion.normal } }

    contentItem: RowLayout {
        spacing: 18
        LineIcon {
            name: root.reverse ? "chevronsDown" : "chevronsLeft"
            size: 40
            strokeWidth: 2.6
            color: root.tone
            opacity: root.reverse || BlinkClock.on ? 1 : 0.15
        }
        PrefsLabel {
            font.pixelSize: Style.h3
            font.letterSpacing: 3
            isBold: true
            color: root.tone
            text: root.reverse ? qsTr("REVERSE") : qsTr("HAZARD")
        }
        Caption {
            visible: root.reverse
            color: dashboardData.speed >= 4 ? Style.warning : Style.textMuted
            text: qsTr("Max 5 %1").arg(dashboardData.speedUnit)
        }
        LineIcon {
            visible: !root.reverse
            name: "chevronsRight"
            size: 40
            strokeWidth: 2.6
            color: root.tone
            opacity: BlinkClock.on ? 1 : 0.15
        }
    }
}
