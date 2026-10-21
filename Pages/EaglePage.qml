import QtQuick
import QtQuick.Controls
import Style 1.0

// Every screen. Transparent, so a page shown inside a rounded panel (the settings
// detail) does not paint a square background over the panel's corners.
Page {
    padding: 0
    background: null

    property var gEagleStack: StackView.view
}
