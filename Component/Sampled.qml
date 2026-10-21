import QtQuick

// A value shown at a readable rate. Vehicle signals arrive many times a second;
// a cluster shows a figure for long enough to be read in a glance (2–4 updates a
// second is the usual rule), and only moves when it has really changed.
QtObject {
    id: root

    property real source: 0
    property real value: source
    property int interval: 333          // ms between updates of the shown value
    property real deadband: 0           // changes smaller than this are not shown

    property Timer timer: Timer {
        interval: root.interval
        repeat: true
        running: true
        onTriggered: {
            if (Math.abs(root.source - root.value) > root.deadband)
                root.value = root.source
        }
    }

    Component.onCompleted: value = source
}
