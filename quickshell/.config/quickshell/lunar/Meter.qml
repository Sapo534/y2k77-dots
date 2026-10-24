import QtQuick

// Горизонтальная полоска заполнения, value 0..1
Rectangle {
    id: m

    property real value: 0
    property color fill: "#e8e8e8"

    implicitHeight: 6
    radius: 3
    color: "#292929"

    Rectangle {
        width: parent.width * Math.max(0, Math.min(1, m.value))
        height: parent.height
        radius: 3
        color: m.fill
        Behavior on width { NumberAnimation { duration: 200 } }
    }
}
