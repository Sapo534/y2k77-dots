import QtQuick

// Кольцевая диаграмма. segments: [{ value: 0..1, color: "#hex" }, ...] — идут по кругу подряд.
Canvas {
    id: d

    property var segments: []
    property real thickness: 10
    property string centerText: ""
    property string subText: ""
    property int centerSize: 13
    property bool live: true

    implicitWidth: 92
    implicitHeight: 92

    onSegmentsChanged: if (live) requestPaint()
    onLiveChanged: if (live) requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        ctx.clearRect(0, 0, width, height)

        const cx = width / 2
        const cy = height / 2
        const r = Math.min(width, height) / 2 - thickness / 2 - 1
        const full = Math.PI * 2

        ctx.lineWidth = thickness
        ctx.lineCap = "butt"
        ctx.strokeStyle = "#292929"
        ctx.beginPath()
        ctx.arc(cx, cy, r, 0, full)
        ctx.stroke()

        let a = -Math.PI / 2
        for (const s of segments) {
            const v = Math.max(0, Math.min(1, s.value))
            if (v < 0.003) continue
            ctx.strokeStyle = s.color
            ctx.beginPath()
            ctx.arc(cx, cy, r, a, a + full * v)
            ctx.stroke()
            a += full * v
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 0

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: d.centerText
            color: "#ffffff"
            font.family: "monospace"
            font.bold: true
            font.pixelSize: d.centerSize
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: d.subText !== ""
            text: d.subText
            color: "#777777"
            font.family: "monospace"
            font.pixelSize: 8
            font.letterSpacing: 1
        }
    }
}
