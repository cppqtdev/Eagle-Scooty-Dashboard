import QtQuick

// The picture for an alert: the matching telltale where there is one, otherwise
// the severity symbol.
Image {
    property string key
    property int severity: 0

    sourceSize: Qt.size(48, 48)
    source: {
        switch (key) {
        case "tyre": return "qrc:/Icons/topIcons/icn_tyrepressure_glow.svg"
        case "sideStand": return "qrc:/Icons/topIcons/icn_sidestandenabled_glow.svg"
        case "batteryTemp": return "qrc:/Icons/topIcons/icn_batterytemp_glow.svg"
        }
        return severity === 2 ? "qrc:/Icons/Notification/Error.svg"
             : severity === 1 ? "qrc:/Icons/Notification/Warning.svg"
             : key === "charge" ? "qrc:/Icons/Notification/Success.svg"
             : "qrc:/Icons/Notification/Info.svg"
    }
}
