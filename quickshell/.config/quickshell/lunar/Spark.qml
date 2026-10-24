import QtQuick

// График по истории (0..maxValue). values — сплошная линия с заливкой,
// values2 — пунктир (обычно температура, °C на той же шкале 0..100).
Canvas {
    id: c

    property var values: []
    property var values2: []
    property int points: 60
    property real maxValue: 100
    property color lineColor: "#e8e8e8"
    property color line2Color: "#7a7a7a"
    property bool live: true

    implicitHeight: 56

    onValuesChanged: if (live) requestPaint()
    onValues2Changed: if (live) requestPaint()
    onLiveChanged: if (live) requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    function series(ctx, arr, fill) {
        const n = arr.length
        if (n < 2) return
        const step = width / (points - 1)
        const pad = 1.5
        const hh = height - pad * 2
        const x = i => width - (n - 1 - i) * step
        const y = v => pad + hh - Math.max(0, Math.min(1, v / maxValue)) * hh

        ctx.beginPath()
        ctx.moveTo(x(0), y(arr[0]))
        for (let i = 1; i < n; i++) ctx.lineTo(x(i), y(arr[i]))
        ctx.stroke()
        if (fill) {
            ctx.lineTo(x(n - 1), height)
            ctx.lineTo(x(0), height)
            ctx.closePath()
            ctx.fill()
        }
    }

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        ctx.clearRect(0, 0, width, height)

        ctx.lineWidth = 1
        ctx.strokeStyle = "#252525"
        for (const f of [0.25, 0.5, 0.75]) {
            const gy = Math.round(height * f) + 0.5
            ctx.beginPath()
            ctx.moveTo(0, gy)
            ctx.lineTo(width, gy)
            ctx.stroke()
        }

        ctx.lineJoin = "round"
        ctx.setLineDash([3, 3])
        ctx.strokeStyle = line2Color
        series(ctx, values2, false)

        ctx.setLineDash([])
        ctx.lineWidth = 1.5
        ctx.strokeStyle = lineColor
        ctx.fillStyle = Qt.rgba(lineColor.r, lineColor.g, lineColor.b, 0.12)
        series(ctx, values, true)
    }
}
