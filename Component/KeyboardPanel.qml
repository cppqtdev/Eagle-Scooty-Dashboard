import QtQuick
import QtQuick.VirtualKeyboard

// The on-screen keyboard for the touch panel (Wi-Fi passwords, dialling). Loaded
// only in board mode, where the image ships Qt Virtual Keyboard.
InputPanel {
    id: panel
    z: 200
    width: parent.width
    y: active ? parent.height - height : parent.height

    Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
}
