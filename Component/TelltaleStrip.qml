import QtQuick
import QtQuick.Layouts
import Style 1.0
import Eagle.Blink 1.0

// The row of telltales: indicators, beams, side stand, battery temperature,
// tyres, ABS and the malfunction lamp (MIL). Every lamp follows the vehicle; the
// indicators flash on the shared clock. lampCheck lights them all, for the
// bulb check at key-on.
RowLayout {
    id: strip

    property bool lampCheck: false

    spacing: 22

    Telltale {
        lampCheck: strip.lampCheck
        active: dashboardData.leftIndicator
        blinking: true
        blinkPhase: BlinkClock.on
        offSource: "qrc:/Icons/topIcons/icn_leftindicator.svg"
        onSource: "qrc:/Icons/topIcons/icn_leftindicator_glow.svg"
    }
    Telltale {
        lampCheck: strip.lampCheck
        active: dashboardData.lowBeam && !dashboardData.highBeam
        offSource: "qrc:/Icons/topIcons/icn_lowbeam.svg"
        onSource: "qrc:/Icons/topIcons/icn_lowbeam_glow.svg"
    }
    Telltale {
        lampCheck: strip.lampCheck
        active: dashboardData.sideStandDown
        iconSize: 65
        offSource: "qrc:/Icons/topIcons/icn_sidestandenabled.svg"
        onSource: "qrc:/Icons/topIcons/icn_sidestandenabled_glow.svg"
    }
    Telltale {
        lampCheck: strip.lampCheck
        active: dashboardData.batteryTempC >= 55
        offSource: "qrc:/Icons/topIcons/icn_batterytemp.svg"
        onSource: "qrc:/Icons/topIcons/icn_batterytemp_glow.svg"
    }
    Telltale {
        lampCheck: strip.lampCheck
        active: Math.min(dashboardData.tyreFrontBar, dashboardData.tyreRearBar) < 1.8
        offSource: "qrc:/Icons/topIcons/icn_tyrepressure.svg"
        onSource: "qrc:/Icons/topIcons/icn_tyrepressure_glow.svg"
    }
    Telltale {
        lampCheck: strip.lampCheck
        active: dashboardData.absFault
        iconSize: 50
        offSource: "qrc:/Icons/topIcons/icn_abs.png"
        onSource: "qrc:/Icons/topIcons/icn_abs_glow.png"
    }
    Telltale {
        lampCheck: strip.lampCheck
        active: dashboardData.checkEngine
        iconSize: 50
        offSource: "qrc:/Icons/topIcons/icn_malfunction.png"
        onSource: "qrc:/Icons/topIcons/icn_malfunction_glow.png"
    }
    Telltale {
        lampCheck: strip.lampCheck
        active: dashboardData.highBeam
        offSource: "qrc:/Icons/topIcons/icn_highbeam.svg"
        onSource: "qrc:/Icons/topIcons/icn_highbeam_glow.svg"
    }
    Telltale {
        lampCheck: strip.lampCheck
        active: dashboardData.rightIndicator
        blinking: true
        blinkPhase: BlinkClock.on
        offSource: "qrc:/Icons/topIcons/icn_rightindicator.svg"
        onSource: "qrc:/Icons/topIcons/icn_rightindicator _glow.svg"
    }
}
