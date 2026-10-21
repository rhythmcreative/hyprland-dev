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

        // Inicia en la esquina superior derecha absoluta (w, 0)
        startX: trazo.w
        startY: 0

        // 1. Línea recta hacia abajo a lo largo del bisel derecho de la pantalla
        PathLine {
            x: trazo.w
            y: trazo.h
        }

        // 2. Ala cóncava inferior que se funde con el bisel derecho
        PathArc {
            x: trazo.w - trazo.g
            y: Math.max(0, trazo.h - trazo.g)
            radiusX: trazo.g
            radiusY: trazo.g
            direction: PathArc.Counterclockwise
        }

        // 3. Borde inferior horizontal hacia la izquierda
        PathLine {
            x: trazo.g + trazo.r
            y: Math.max(0, trazo.h - trazo.g)
        }

        // 4. Esquina redondeada inferior izquierda
        PathArc {
            x: trazo.g
            y: Math.max(0, trazo.h - trazo.g - trazo.r)
            radiusX: trazo.r
            radiusY: trazo.r
            direction: PathArc.Clockwise
        }

        // 5. Borde vertical izquierdo subiendo hacia el ala superior
        PathLine {
            x: trazo.g
            y: Math.min(trazo.h, trazo.g)
        }

        // 6. Ala cóncava superior que se funde con el bisel superior de la pantalla
        PathArc {
            x: 0
            y: 0
            radiusX: trazo.g
            radiusY: trazo.g
            direction: PathArc.Counterclockwise
        }

        // 7. Línea recta a lo largo del bisel superior de regreso a (w, 0)
        PathLine {
            x: trazo.w
            y: 0
        }
    }
}
