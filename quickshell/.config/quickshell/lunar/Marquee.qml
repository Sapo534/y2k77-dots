import QtQuick

// Бегущая строка: если текст не влезает — едет до конца, пауза, обратно.
Item {
    id: m
    property string text: ""
    property color color: "#cccccc"
    property int pixelSize: 11
    property int maxWidth: 170
    property int speed: 25   // мс на пиксель

    readonly property real overflow: Math.max(0, label.implicitWidth - width)

    implicitWidth: Math.min(label.implicitWidth, maxWidth)
    implicitHeight: label.implicitHeight
    clip: true

    onTextChanged: label.x = 0

    Text {
        id: label
        text: m.text
        color: m.color
        font.family: "monospace"
        font.pixelSize: m.pixelSize
    }

    SequentialAnimation {
        running: m.overflow > 0 && m.visible
        loops: Animation.Infinite
        PauseAnimation { duration: 1500 }
        NumberAnimation { target: label; property: "x"; to: -m.overflow; duration: m.overflow * m.speed }
        PauseAnimation { duration: 1500 }
        NumberAnimation { target: label; property: "x"; to: 0; duration: m.overflow * m.speed }
    }
}
