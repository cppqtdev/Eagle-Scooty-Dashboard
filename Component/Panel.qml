import QtQuick
import QtQuick.Controls
import Style 1.0

// The card every screen groups its content in. A Pane, so content can sit in
// it with padding and the card sizes itself to what it holds; the default
// padding is 0 for content that lays itself out against the edges.
Pane {
    padding: 0

    background: Rectangle {
        radius: Style.metrics.radiusLg
        color: Style.surface
        border.color: Style.border
        border.width: 1
    }
}
