import QtQuick
import Quickshell

// Фавикон сайта; пока грузится или если нет сети — иконка из темы
Item {
    id: i
    property string iconName: ""
    property string iconUrl: ""

    implicitWidth: 16
    implicitHeight: 16

    Image {
        anchors.fill: parent
        visible: !fav.ready
        source: Quickshell.iconPath(i.iconName, "multimedia-player")
        sourceSize.width: 32
        sourceSize.height: 32
        fillMode: Image.PreserveAspectFit
        smooth: true
    }

    Image {
        id: fav
        readonly property bool ready: status === Image.Ready
        anchors.fill: parent
        visible: ready
        source: i.iconUrl
        asynchronous: true
        cache: true
        sourceSize.width: 32
        sourceSize.height: 32
        fillMode: Image.PreserveAspectFit
        smooth: true
    }
}
