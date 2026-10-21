import QtQuick
import QtQuick.Controls
import Style 1.0

// The handlebar keys and the encoder, for a panel without touch (and alongside
// it on one with touch). Every source ends in the same five actions, so a key,
// a turn of the dial and a CAN button frame can never disagree:
//
//   left / right  the previous or next screen, in footer order
//   up / down     the previous or next control on the screen (a dial turn)
//   ok            act on the focused control (a dial press)
//   back          close what is open over the page, otherwise go home
//
// Over everything, an incoming call takes ok as answer and back as decline,
// and a critical alert takes ok as acknowledge. The focused control wears an
// accent ring that glides between controls; it shows once a key is used and
// fades after eight seconds without one.
Item {
    id: root

    // Set by the canvas.
    property Item canvas
    property StackView stack
    property var pages: []          // footer order
    property string currentPage
    signal navigate(string page)

    property bool keysInUse: false
    // The control the keys are on. Kept here rather than read from the window's
    // focus, which an inactive window (or an offscreen render) does not hand out.
    property Item focused: null
    onScopeChanged: focused = null

    // What up and down move through: the overlay that holds the rider, or the page.
    readonly property Item scope: phone.callState === 1 ? null
                                 : stack ? stack.currentItem : null

    function step(forward) {
        touchKey()
        if (!scope)
            return
        const items = focusables(scope)
        if (items.length === 0)
            return
        const at = items.indexOf(focused)
        const next = at < 0 ? (forward ? 0 : items.length - 1)
                            : (at + (forward ? 1 : items.length - 1)) % items.length
        focused = items[next]
        focused.forceActiveFocus(Qt.TabFocusReason)
        ensureVisible(focused)
    }

    // Every control on the page in reading order: the page's own order, with the
    // rows of a list or a scrolling page sorted by where they sit.
    function focusables(item) {
        const found = []
        function walk(node) {
            // The page itself may still be fading in; only hidden parts inside it count.
            if (!node.visible || !node.enabled || (node !== item && node.opacity === 0))
                return
            if (node !== item && isFocusable(node)) {
                found.push(node)
                return
            }
            let kids = []
            for (let i = 0; i < node.children.length; ++i)
                kids.push(node.children[i])
            if (node.parent && node.parent.contentItem === node)
                kids.sort((a, b) => a.y - b.y || a.x - b.x)
            for (const kid of kids)
                walk(kid)
        }
        walk(item)
        return found
    }

    function screen(forward) {
        touchKey()
        const at = pages.indexOf(currentPage)
        const next = (Math.max(0, at) + (forward ? 1 : pages.length - 1)) % pages.length
        navigate(pages[next])
    }

    function ok() {
        touchKey()
        if (phone.callState === 1) {
            phone.answer()
            return
        }
        if (alertCenter.critical.id !== undefined) {
            alertCenter.acknowledge(alertCenter.critical.id)
            return
        }
        const item = focused
        if (!item || !scope || !isInside(item, scope) || !item.visible) {
            step(true)   // nothing chosen yet: the first press picks the first control
            return
        }
        if (item.checkable !== undefined && item.checkable) {
            item.toggle()
            item.toggled()
        }
        if (typeof item.clicked === "function")
            item.clicked()
    }

    function back() {
        touchKey()
        if (phone.callState === 1) {
            phone.decline()
            return
        }
        if (stack.currentItem && stack.currentItem.gEagleStack && stack.currentItem.gEagleStack.depth > 1) {
            stack.currentItem.gEagleStack.pop()
            return
        }
        if (currentPage !== "home")
            navigate("home")
        focused = null
        canvas.forceActiveFocus()
    }

    function isInside(item, ancestor) {
        for (let p = item; p; p = p.parent) {
            if (p === ancestor)
                return true
        }
        return false
    }

    // A control the rider can act on: anything that clicks (buttons, rows, tabs).
    function isFocusable(item) {
        return item.focusPolicy !== undefined && item.focusPolicy !== Qt.NoFocus
               && item.pressed !== undefined && typeof item.clicked === "function"
    }

    // Scroll whatever list or page holds the item so all of it is on screen.
    function ensureVisible(item) {
        for (let p = item.parent; p; p = p.parent) {
            if (p.contentY === undefined || p.contentItem === undefined || !p.interactive)
                continue
            const top = item.mapToItem(p.contentItem, 0, 0).y
            if (top < p.contentY)
                p.contentY = top
            else if (top + item.height > p.contentY + p.height)
                p.contentY = top + item.height - p.height
        }
    }

    // On the board a rotary encoder arrives as a wheel: one detent, one step.
    WheelHandler {
        enabled: boardMode
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => root.step(event.angleDelta.y < 0)
    }

    // The ring fades after a while without a key, as it would after a touch.
    onKeysInUseChanged: if (keysInUse) idle.restart()
    function touchKey() { keysInUse = true; idle.restart() }
    Timer {
        id: idle
        interval: 8000
        onTriggered: root.keysInUse = false
    }

    // The ring around the focused control, following it as lists scroll.
    Rectangle {
        id: ring

        property Item target: root.keysInUse && root.focused && root.focused.visible ? root.focused : null

        function place() {
            if (!target)
                return
            const at = target.mapToItem(root, 0, 0)
            x = at.x - 5
            y = at.y - 5
            width = target.width + 10
            height = target.height + 10
        }

        onTargetChanged: place()
        color: "transparent"
        radius: 8
        border.width: 3
        border.color: Style.isDark ? Style.accentStrong : Style.accent
        opacity: target ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Style.motion.fast } }
        Behavior on x { NumberAnimation { duration: Style.motion.fast; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: Style.motion.fast; easing.type: Easing.OutCubic } }
        Behavior on width { NumberAnimation { duration: Style.motion.fast } }
        Behavior on height { NumberAnimation { duration: Style.motion.fast } }

        // Lists scroll under it; keep up while it is shown.
        Timer {
            interval: 50
            repeat: true
            running: ring.visible
            onTriggered: ring.place()
        }
    }
}
