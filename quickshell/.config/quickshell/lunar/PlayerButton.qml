import QtQuick
import QtQuick.Layouts
import Quickshell

Rectangle {
    id: b

    property var player: null
    property bool open: false
    signal clicked()

    property string iconName: ""
    property string iconUrl: ""   // считает Bar: сайт для браузера, иначе сам плеер

    visible: player !== null
    implicitWidth: row.implicitWidth + 20
    implicitHeight: 26
    radius: 4
    color: open ? "#eeeeee" : (m.containsMouse ? "#2a2a2a" : "#202020")

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 8

        SourceIcon {
            Layout.preferredWidth: 16
            Layout.preferredHeight: 16
            iconName: b.iconName
            iconUrl: b.iconUrl
            opacity: b.player?.isPlaying ? 1 : 0.5
        }

        Marquee {
            text: b.player ? (b.player.trackTitle || b.player.identity) : ""
            color: b.open ? "#111111" : "#cccccc"
            maxWidth: 170
        }
    }

    MouseArea {
        id: m
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: b.clicked()
    }
}
