import QtQuick
import QtQuick.Shapes

Shape {
    id: siluetaEsquinaDerecha

    property real ala: 22
    property real cuerpoRadio: 28
    property color relleno: "#0d1011"
    property color bordeColor: "transparent"
    property real bordeAncho: 0

    antialiasing: true
    layer.enabled: true
    layer.samples: 8
    layer.smooth: true

    ShapePath {
        id: trazo
        fillColor: siluetaEsquinaDerecha.relleno
        strokeWidth: siluetaEsquinaDerecha.bordeAncho
        strokeColor: siluetaEsquinaDerecha.bordeColor

        readonly property real w: siluetaEsquinaDerecha.width
        readonly property real h: siluetaEsquinaDerecha.height
        readonly property real g: Math.max(0, Math.min(siluetaEsquinaDerecha.ala, trazo.h / 3, trazo.w / 6))
        readonly property real r: Math.max(0, Math.min(siluetaEsquinaDerecha.cuerpoRadio, trazo.h / 2, trazo.w / 3 - trazo.g))

        // Start at absolute top-right screen corner (w, 0)
        startX: trazo.w
        startY: 0

        // 1. Flush down along right screen bezel to right wing tip
        PathLine {
            x: trazo.w
            y: trazo.h
        }

        // 2. Inverted concave wing fusing into right screen bezel
        PathArc {
            x: trazo.w - trazo.g
            y: Math.max(0, trazo.h - trazo.g)
            radiusX: trazo.g
            radiusY: trazo.g
            direction: PathArc.Counterclockwise
        }

        // 3. Bottom edge to bottom-left corner start
        PathLine {
            x: Math.min(trazo.w - trazo.g, trazo.g + trazo.r)
            y: Math.max(0, trazo.h - trazo.g)
        }

        // 4. Smooth rounded bottom-left corner
        PathArc {
            x: trazo.g
            y: Math.max(0, trazo.h - trazo.g - trazo.r)
            radiusX: trazo.r
            radiusY: trazo.r
            direction: PathArc.Counterclockwise
        }

        // 5. Left vertical edge up to top wing start
        PathLine {
            x: trazo.g
            y: Math.min(trazo.h, trazo.g)
        }

        // 6. Inverted concave wing fusing into top screen bezel
        PathArc {
            x: 0
            y: 0
            radiusX: trazo.g
            radiusY: trazo.g
            direction: PathArc.Counterclockwise
        }

        // 7. Flush top screen border back to (w, 0)
        PathLine {
            x: trazo.w
            y: 0
        }
    }
}
