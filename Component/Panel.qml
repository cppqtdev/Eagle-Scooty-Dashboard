import QtQuick
import QtQuick.Controls
import Style 1.0

// A group of content on a screen. It draws nothing: content sits straight on
// the page background, kept apart by spacing alone, as the cluster reads best
// without boxes. A Pane, so content can sit in it with padding and it sizes
// itself to what it holds; the default padding is 0 for content that lays
// itself out against the edges.
Pane {
    padding: 0
    background: null
}
