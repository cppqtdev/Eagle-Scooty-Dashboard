import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import "../Component"
import Style 1.0
Page {
    padding: 0
    background: Rectangle{
        anchors.fill: parent
        color: Style.background
    }

    Component{
        id:themeIcon
        Image{
            sourceSize: Qt.size(1120.89,596)
            source: Style.isDark ? "qrc:/Icons/Eagle/5.png" : "qrc:/Icons/Eagle/7.png"
        }
    }
    PrefsLabel{
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 30
        font.pixelSize: Style.h2
        color: Style.success
        isBold: true
        text: qsTr("🍃 Echo")
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowVerticalOffset: 2
            shadowColor: "#80000000"
            shadowBlur: 0.1
        }
    }

    PrefsLabel{
        anchors.horizontalCenter: iconTheme.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -150
        font.pixelSize: 120
        isBold: true
        text: dashboardData.speed
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowVerticalOffset: 2
            shadowColor: "#FFFFFF"
            shadowBlur: 0.2
        }
    }
    PrefsLabel{
        anchors.horizontalCenter: iconTheme.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -50
        font.pixelSize: Style.h1
        isBold: true
        text: dashboardData.speedUnit
    }

    Loader{
        id:iconTheme
        width: 1120.89
        height: 596
        anchors.centerIn: parent
        sourceComponent: themeIcon
    }

    ColumnLayout{
        width: root.width
        anchors.horizontalCenter: iconTheme.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 280
        spacing: 10
        ColumnLayout{
            Layout.alignment: Qt.AlignHCenter
            PrefsLabel{
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: Style.h5
                isBold: true
                text: qsTr("Arcade")
            }
            PrefsLabel{
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: Style.h5
                isBold: true
                text: qsTr("By Alifya Design")
            }
        }
        Image{
            Layout.alignment: Qt.AlignHCenter
            source: "qrc:/Icons/fooo.svg"
        }
        RowLayout{
            Layout.alignment: Qt.AlignHCenter
            spacing: 20
            IconButton{
                iconBackground: "transparent"
                setIcon: "qrc:/Icons/Music/first_page.svg"
            }

            IconButton{
                roundIcon: true
                implicitHeight: 60
                implicitWidth: 60
                iconWidth: 24
                iconHeight: 28
                iconBackground: "transparent"
                setIcon: "qrc:/Icons/Music/pause_paly.svg"
            }

            IconButton{
                iconBackground: "transparent"
                setIcon: "qrc:/Icons/Music/last_page.svg"
            }
        }
    }

    ColumnLayout{
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: 40
        spacing: 20
        ColumnLayout{
            Layout.alignment: Qt.AlignLeft
            PrefsLabel{
                Layout.alignment: Qt.AlignLeft
                isStyle: true
                text: qsTr("Trip A")
            }
            PrefsLabel{
                Layout.alignment: Qt.AlignLeft
                font.pixelSize: Style.h6
                color: Style.grayColor
                text: qsTr("%1 km").arg(dashboardData.tripKm)
            }
        }
        Image{
            Layout.preferredWidth: 150
            source: "qrc:/Icons/seprator.png"
        }
        ColumnLayout{
            Layout.alignment: Qt.AlignLeft
            PrefsLabel{
                Layout.alignment: Qt.AlignLeft
                isStyle: true
                text: qsTr("Odometer")
            }
            PrefsLabel{
                Layout.alignment: Qt.AlignLeft
                font.pixelSize: Style.h6
                color: Style.grayColor
                text: qsTr("%L1 km").arg(dashboardData.odometerKm)
            }
        }
        Image{
            Layout.preferredWidth: 150
            source: "qrc:/Icons/seprator.png"
        }
        ColumnLayout{
            Layout.alignment: Qt.AlignLeft
            PrefsLabel{
                Layout.alignment: Qt.AlignLeft
                isStyle: true
                text: qsTr("Temperature")
            }
            PrefsLabel{
                Layout.alignment: Qt.AlignLeft
                font.pixelSize: Style.h6
                color: Style.grayColor
                text: qsTr("%1 °C").arg(dashboardData.temperatureC)
            }
        }
    }

    Image{
        source: "qrc:/Icons/dummyMap.png"
        anchors.left: parent.left
        anchors.leftMargin: 20
        anchors.verticalCenter: parent.verticalCenter
    }

    RowLayout{
        anchors.left: parent.left
        anchors.leftMargin: 40
        anchors.top: parent.top
        anchors.topMargin: 30

        RowLayout{
            IconButton{
                setIcon: "qrc:/Icons/time.svg"
            }
            PrefsLabel{
                Layout.alignment: Qt.AlignLeft
                color: Style.grayColor
                text: qsTr("%1 min").arg(dashboardData.arrivalMinutes)
            }
        }
        RowLayout{
            IconButton{
                setIcon: "qrc:/Icons/entypo_arrow-left.svg"
            }
            PrefsLabel{
                Layout.alignment: Qt.AlignLeft
                color: Style.grayColor
                text: qsTr("%1 km").arg(dashboardData.distanceKm.toFixed(1))
            }
        }
    }
}
