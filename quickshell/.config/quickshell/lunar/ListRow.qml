import QtQuick
import QtQuick.Layouts

Rectangle {
    id: r
    property string title: ""
    property string subtitle: ""
    property string trailing: ""
    property bool highlighted: false
    signal clicked()
    signal secondaryClicked()

    implicitHeight: 42
    radius: 6
    color: m.containsMouse ? "#242424" : "#171717"
    border.width: 1
    border.color: highlighted ? "#e8e8e8" : "#303030"

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 11
        anchors.rightMargin: 11
        spacing: 8

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
                Layout.fillWidth: true
                text: r.title
                color: "#eeeeee"
                font.family: "monospace"
                font.pixelSize: 11
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                visible: r.subtitle !== ""
                text: r.subtitle
                color: "#808080"
                font.family: "monospace"
                font.pixelSize: 9
                elide: Text.ElideRight
            }
        }

        Text {
            text: r.trailing
            color: "#999999"
            font.family: "monospace"
            font.pixelSize: 10
        }
    }

    MouseArea {
        id: m
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => mouse.button === Qt.RightButton ? r.secondaryClicked() : r.clicked()
    }
}
