import QtQuick
import QtQuick.Layouts
import Style 1.0

// Battery and range above the navigation bar. The bar's tabs show which page is
// open: the active one gets the accent dot, and only one can be active at a time.
Image {
    id: root

    property string currentPage: "home"
    signal navigate(string page)

    width: parent.width
    source: Style.isDark ? "qrc:/Icons/dark/bottom_dark.png" : "qrc:/Icons/green.png"
    sourceSize: Qt.size(root.width, Style.isDark ? 150 : 134)

    component Tab: Item {
        id: tab
        property string page
        property string icon
        readonly property bool current: root.currentPage === page

        Layout.preferredWidth: 90
        Layout.preferredHeight: 80

        IconButton {
            anchors.centerIn: parent
            roundIcon: true
            iconWidth: 55
            iconHeight: 55
            setIcon: tab.icon
            opacity: tab.current ? 1 : 0.6
            scale: tab.current ? 1.08 : 1
            onClicked: root.navigate(tab.page)
            Behavior on opacity { NumberAnimation { duration: Style.motion.fast } }
            Behavior on scale { NumberAnimation { duration: Style.motion.normal; easing.type: Easing.OutBack } }
        }
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            width: tab.current ? 28 : 0
            height: 4
            radius: 2
            color: Style.modeColor(dashboardData.rideMode)
            Behavior on width { NumberAnimation { duration: Style.motion.normal; easing.type: Easing.OutCubic } }
        }
    }

    Image {
        visible: !Style.isDark
        source: "qrc:/Icons/white.png"
        sourceSize.height: 116
        width: parent.width
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
    }

    RowLayout {
        width: parent.width * 0.35
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        spacing: 16

        ColumnLayout {
            spacing: 2
            DigitText {
                pixelSize: Style.h1
                isBold: true
                isStyle: true
                color: dashboardData.batteryPercent <= 15 && !dashboardData.charging ? Style.warning : Style.accentStrong
                text: qsTr("%1%").arg(dashboardData.batteryPercent)
            }
            PrefsLabel {
                font.pixelSize: Style.h6
                color: Style.textMuted
                text: dashboardData.charging ? qsTr("Charging") : qsTr("Battery")
            }
        }
        ProgressRunning {
            Layout.fillWidth: true
            implicitHeight: 20
            value: dashboardData.batteryPercent
            charging: dashboardData.charging
            fillColor: Style.modeColor(dashboardData.rideMode)
        }
        ColumnLayout {
            spacing: 2
            DigitText {
                Layout.alignment: Qt.AlignRight
                pixelSize: Style.h1
                isBold: true
                isStyle: true
                text: qsTr("%1 km").arg(dashboardData.rangeKm)
            }
            PrefsLabel {
                Layout.alignment: Qt.AlignRight
                font.pixelSize: Style.h6
                color: Style.textMuted
                text: qsTr("Range")
            }
        }
    }

    RowLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 12
        width: parent.width * 0.9

        Item { Layout.preferredWidth: 75 }
        RowLayout {
            spacing: 24
            Tab { page: "home"; icon: "qrc:/Icons/bottomIcons/home.svg" }
            Tab { page: "map"; icon: "qrc:/Icons/bottomIcons/map.svg" }
            Tab { page: "phone"; icon: "qrc:/Icons/bottomIcons/phone.svg" }
        }
        Item { Layout.fillWidth: true }
        RowLayout {
            spacing: 24
            Tab { page: "music"; icon: "qrc:/Icons/bottomIcons/Music.svg" }
            Tab { page: "charging"; icon: "qrc:/Icons/bottomIcons/petrol.svg" }
            Tab { page: "settings"; icon: "qrc:/Icons/bottomIcons/settings.svg" }
        }
        Item { Layout.preferredWidth: 75 }
    }
}
