//import QtQuick 2.15
//import QtLocation 5.15
//import QtPositioning 5.6

//import QtQuick.Layouts 1.3
//import Style 1.0

//Item {
//    anchors.fill: parent
//    PositionSource {
//        id: positionSource
//    }

//    Plugin {
//        id: mapPlugin
//        name: "osm" // "mapboxgl", "esri", ...
//    }

//    Map {
//        id: map
//        anchors.fill: parent
//        plugin: mapPlugin
//        center: QtPositioning.coordinate(59.91, 10.75) // Oslo
//        zoomLevel: 14
//        property MapCircle circle

//        Component.onCompleted: {
//            circle = Qt.createQmlObject('import QtLocation 5.3; MapCircle {}', root)
//            circle.center = positionSource.position.coordinate
//            circle.radius = 5000.0
//            circle.color = 'green'
//            circle.border.width = 3
//            map.addMapItem(circle)
//        }
//    }
//}
import QtQuick 2.0
import QtQuick.Controls 2.2
import QtQuick.Window 2.0
import QtLocation 5.9
import QtPositioning 5.5


Item {
    id: myItem
    anchors.fill: parent
    Plugin {
        id: mapPlugin
        name: "osm"
    }

    Map {
        id: map
        objectName: "mapboxgl"
        property double lat: 20.5937
        property double lon: 78.9629
        visible: true
        anchors.fill: parent
        plugin: mapPlugin
        center {
            latitude: lat
            longitude: lon
        }
        zoomLevel: 4
        ListView {
            height: 1
            model: map
            delegate: Text {
                text: "Latitude: " + (center.latitude).toFixed(3) + " Longitude: " + (center.longitude).toFixed(3)
            }
        }

        MouseArea{
            id: mouseArea
            property var positionRoot: map.toCoordinate(Qt.point(mouseX, mouseY))
            anchors.fill: parent
            onClicked: {
                var component = Qt.createComponent("addAttribute.qml")
                if (component.status === Component.Ready) {
                    var dialog = component.createObject(parent,{popupType: 1})
                    dialog.sqlPosition = positionRoot
                    dialog.show()
                }
            }
        }

        MapQuickItem {
            id: marker
            objectName: "marker"
            visible: true
            anchorPoint.x: 0.5 * image.width
            anchorPoint.y: image.height
            sourceItem: Image {
                id: image
                source: "qrc:/Icons/MapIcons/pump.svg"
                MouseArea{
                    anchors.fill: parent
                    onClicked: {
                        ToolTip.timeout = 2000
                        ToolTip.visible = true
                        ToolTip.text = qsTr("Coordinates: %1, %2").arg(marker.coordinate.latitude).arg(marker.coordinate.longitude)
                    }
                }
            }
        }

        MapParameter {
            type: "source"
            property var name: "coordinates"
            property var sourceType: "geojson"
            property var data: '{ "type": "FeatureCollection", "features": \
            [{ "type": "Feature", "properties": {}, "geometry": { \
            "type": "LineString", "coordinates": [[ 8.541484, \
            47.366850 ], [8.542171, 47.370018],[8.545561, 47.369233]]}}]}'
        }

        MapParameter {
            type: "layer"
            property var name: "layer"
            property var layerType: "line"
            property var source: "coordinates"
            property var before: "road-label-small"
        }

        MapParameter {
            objectName: "paint"
            type: "paint"
            property var layer: "layer"
            property var lineColor: "black"
            property var lineWidth: 8.0
        }

        MapParameter {
            type: "layout"
            property var layer: "layer"
            property var lineJoin: "round"
            property var lineCap: "round"
        }
    }
    Canvas {                          //Create Grid
        id: canvas
        anchors.fill : parent
        visible: false
        property int distance: 25
        onPaint: {
            var context = getContext("2d")
            context.lineWidth = 1
            context.strokeStyle = "black"
            context.beginPath()
            var gridRows = height/distance;
            for(var i=0; i < gridRows+1; i++){
                context.moveTo(0, distance*i);
                context.lineTo(width, distance*i);
            }

            var gridColumns = width/distance
            for(var j=0; j < gridColumns+1; j++){
                context.moveTo(distance*j, 0);
                context.lineTo(distance*j, height);
            }
            context.closePath()
            context.stroke()
        }
    }
}
