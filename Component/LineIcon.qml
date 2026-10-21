import QtQuick
import Style 1.0

// A 24 x 24 line icon in any colour. The paths are drawn as SVG made on the fly,
// so one icon serves every theme and state without a file per colour (the
// board's Qt has no colour effects to tint a fixed picture).
Image {
    id: root

    property string name
    property color color: Style.textPrimary
    property real strokeWidth: 1.8
    property int size: 28

    readonly property var paths: ({
        display: "M12 3v2M12 19v2M5.6 5.6l1.4 1.4M17 17l1.4 1.4M3 12h2M19 12h2M5.6 18.4L7 17M17 7l1.4-1.4M12 8a4 4 0 1 0 0 8a4 4 0 1 0 0-8z",
        bluetooth: "M7 7l10 10l-5 4V3l5 4L7 17",
        wifi: "M2 9a15 15 0 0 1 20 0M5 12.5a10 10 0 0 1 14 0M8.5 16a5 5 0 0 1 7 0M12 19.5h.01",
        sound: "M4 9h4l5-4v14l-5-4H4zM16 9a4 4 0 0 1 0 6M18.5 6.5a8 8 0 0 1 0 11",
        documents: "M14 3H7a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8zM14 3v5h5M9 13h6M9 17h6",
        diagnostics: "M3 12h4l3-8l4 16l3-8h4",
        trips: "M6 19a2 2 0 1 0 0-4a2 2 0 1 0 0 4zM18 9a2 2 0 1 0 0-4a2 2 0 1 0 0 4zM8 17h8a3 3 0 0 0 0-6H8a3 3 0 0 1 0-6h8",
        notifications: "M6 16V11a6 6 0 0 1 12 0v5l2 2H4zM10 20a2 2 0 0 0 4 0",
        update: "M12 4v11M7 10l5 5l5-5M5 20h14",
        profile: "M12 12a4 4 0 1 0 0-8a4 4 0 1 0 0 8zM4 21a8 8 0 0 1 16 0",
        about: "M12 3a9 9 0 1 0 0 18a9 9 0 1 0 0-18zM12 11v6M12 7.5h.01",
        phone: "M5 4h4l2 5l-2.5 1.5a11 11 0 0 0 5 5L15 13l5 2v4a2 2 0 0 1-2 2A16 16 0 0 1 3 6a2 2 0 0 1 2-2",
        headset: "M4 15v-3a8 8 0 0 1 16 0v3M4 15a2 2 0 0 0 2 2h1v-5H6a2 2 0 0 0-2 2zM20 15a2 2 0 0 1-2 2h-1v-5h1a2 2 0 0 1 2 2z",
        chevron: "M9 6l6 6l-6 6"
    })

    sourceSize: Qt.size(size, size)
    width: size
    height: size
    // Rebuilt only when the name or colour changes; the cache key is the URL itself.
    source: paths[name] === undefined ? ""
            : "data:image/svg+xml;utf8," + encodeURIComponent(
                  '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="'
                  + root.color + '" stroke-width="' + root.strokeWidth
                  + '" stroke-linecap="round" stroke-linejoin="round"><path d="' + paths[name] + '"/></svg>')
}
