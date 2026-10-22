import QtQuick

Rectangle {
    id: b
    property string label: ""
    property bool active: false
    signal clicked()

    implicitHeight: 28
    implicitWidth: t.implicitWidth + 22
    radius: 5
    color: active ? "#e8e8e8" : (m.containsMouse ? "#383838" : "#202020")
    border.width: 1
    border.color: "#3a3a3a"

    Text {
        id: t
        anchors.centerIn: parent
        text: b.label
        color: b.active ? "#111111" : "#dddddd"
        font.family: "monospace"
        font.pixelSize: 10
    }

    MouseArea {
        id: m
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: b.clicked()
    }
}
