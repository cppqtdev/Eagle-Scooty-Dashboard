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
        chevron: "M9 6l6 6l-6 6",
        chevronsLeft: "M12 5l-7 7l7 7M20 5l-7 7l7 7",
        chevronsRight: "M4 5l7 7l-7 7M12 5l7 7l-7 7",
        engine: "M3 10h2V8h3V6h7v2h2l2 2h2v6h-2l-2 2H8l-2-2H5v-3H3zM9 6V4h5v2",
        language: "M12 3a9 9 0 1 0 0 18a9 9 0 1 0 0-18zM3 12h18M12 3a14 14 0 0 1 0 18M12 3a14 14 0 0 0 0 18",
        flag: "M5 22V3M5 4h11l-2 4l2 4H5",
        checkCircle: "M12 3a9 9 0 1 0 0 18a9 9 0 1 0 0-18zM8 12.5l2.7 2.7L16 9.5",
        alertCircle: "M12 3a9 9 0 1 0 0 18a9 9 0 1 0 0-18zM12 7.5v5.5M12 16.5h.01",
        xCircle: "M12 3a9 9 0 1 0 0 18a9 9 0 1 0 0-18zM9 9l6 6M15 9l-6 6",
        chevronDown: "M5 8l7 7l7-7",
        chevronsDown: "M5 5l7 7l7-7M5 12l7 7l7-7",
        recents: "M12 3a9 9 0 1 0 0 18a9 9 0 1 0 0-18zM12 7v5l3 2",
        favourites: "M12 3l2.8 5.7l6.2.9l-4.5 4.4l1 6.2L12 17.3l-5.5 2.9l1-6.2L3 9.6l6.2-.9z",
        contacts: "M9 11a3.5 3.5 0 1 0 0-7a3.5 3.5 0 1 0 0 7zM2.5 20a6.5 6.5 0 0 1 13 0M16 4.5a3.5 3.5 0 0 1 0 6.5M18 14a6.5 6.5 0 0 1 3.5 6",
        dialpad: "M6 4h.01M12 4h.01M18 4h.01M6 10h.01M12 10h.01M18 10h.01M6 16h.01M12 16h.01M18 16h.01M12 21h.01",
        play: "M7 4l13 8l-13 8z",
        pause: "M8 4v16M16 4v16",
        previous: "M18 5l-10 7l10 7zM6 5v14",
        next: "M6 5l10 7l-10 7zM18 5v14",
        mute: "M9 3a3 3 0 0 1 3 3v5a3 3 0 0 1-6 0V6a3 3 0 0 1 3-3zM5 11a7 7 0 0 0 14 0M12 18v3M3 3l18 18",
        mic: "M12 3a3 3 0 0 1 3 3v5a3 3 0 0 1-6 0V6a3 3 0 0 1 3-3zM5 11a7 7 0 0 0 14 0M12 18v3",
        endcall: "M3 15c5-5 13-5 18 0l-2 3l-4-1.5v-3a10 10 0 0 0-6 0v3L5 18z",
        sun: "M12 3v2M12 19v2M5.6 5.6l1.4 1.4M17 17l1.4 1.4M3 12h2M19 12h2M5.6 18.4L7 17M17 7l1.4-1.4M12 8a4 4 0 1 0 0 8a4 4 0 1 0 0-8z",
        moon: "M20 14.5A8 8 0 0 1 9.5 4a8 8 0 1 0 10.5 10.5z",
        auto: "M12 3a9 9 0 1 0 0 18zM12 3a9 9 0 0 1 0 18"
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
