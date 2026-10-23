import QtQuick

Rectangle {
    id: f
    property alias text: input.text
    property string placeholder: ""
    property alias maxLength: input.maximumLength
    property alias horizontalAlignment: input.horizontalAlignment
    signal accepted()

    function clear() { input.text = "" }
    function focusInput() { input.forceActiveFocus() }

    implicitHeight: 28
    implicitWidth: 80
    radius: 5
    color: "#202020"
    border.width: 1
    border.color: input.activeFocus ? "#e8e8e8" : "#3a3a3a"

    TextInput {
        id: input
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        verticalAlignment: TextInput.AlignVCenter
        color: "#ffffff"
        selectByMouse: true
        clip: true
        font.family: "monospace"
        font.pixelSize: 11
        onAccepted: f.accepted()
    }

    Text {
        anchors.left: input.left
        anchors.verticalCenter: parent.verticalCenter
        visible: input.text === ""
        text: f.placeholder
        color: "#555555"
        font.family: "monospace"
        font.pixelSize: 11
    }
}
