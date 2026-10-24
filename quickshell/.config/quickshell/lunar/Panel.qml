import QtQuick
import QtQuick.Layouts

// Карточка-секция: дети попадают во внутренний ColumnLayout
Rectangle {
    id: p

    default property alias content: inner.data
    property int pad: 12

    implicitHeight: inner.implicitHeight + pad * 2
    radius: 6
    color: "#171717"
    border.width: 1
    border.color: "#303030"

    ColumnLayout {
        id: inner
        anchors.fill: parent
        anchors.margins: p.pad
        spacing: 8
    }
}
