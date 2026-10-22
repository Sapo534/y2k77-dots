import QtQuick
import QtQuick.Controls

Slider {
    id: s
    from: 0
    to: 100
    implicitHeight: 24

    background: Rectangle {
        x: s.leftPadding
        y: s.topPadding + s.availableHeight / 2 - height / 2
        width: s.availableWidth
        height: 4
        radius: 2
        color: "#292929"

        Rectangle {
            width: s.visualPosition * parent.width
            height: parent.height
            radius: 2
            color: "#e8e8e8"
        }
    }

    handle: Rectangle {
        x: s.leftPadding + s.visualPosition * (s.availableWidth - width)
        y: s.topPadding + s.availableHeight / 2 - height / 2
        width: 12
        height: 12
        radius: 6
        color: s.pressed ? "#ffffff" : "#d8d8d8"
        border.width: 2
        border.color: "#101010"
    }
}
