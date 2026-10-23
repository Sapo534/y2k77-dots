import QtQuick
import QtQuick.Layouts

// Дата + время одной кнопкой. Если идёт таймер — слева показывает остаток,
// если звонит будильник/таймер — мигает (клик = заглушить).
Rectangle {
    id: b

    property var svc: null
    property date now: new Date()
    property bool open: false
    signal clicked()

    readonly property bool ringing: svc?.ringing ?? false
    readonly property bool lit: open || (ringing && now.getSeconds() % 2 === 0)

    implicitWidth: row.implicitWidth + 20
    implicitHeight: 26
    radius: 4
    color: lit ? "#eeeeee" : (m.containsMouse ? "#2a2a2a" : "#202020")

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 10

        Text {
            visible: b.svc?.timerActive ?? false
            text: b.svc ? "T " + b.svc.dur(b.svc.timerLeft) : ""
            color: b.lit ? "#111111" : "#cccccc"
            opacity: (b.svc?.timerRunning ?? false) ? 1 : 0.5
            font.family: "monospace"
            font.pixelSize: 11
        }

        Text {
            text: Qt.formatDateTime(b.now, "dd MMM").toUpperCase()
            color: b.lit ? "#444444" : "#888888"
            font.family: "monospace"
            font.pixelSize: 11
        }

        Text {
            text: Qt.formatDateTime(b.now, "HH:mm:ss")
            color: b.lit ? "#111111" : "#ffffff"
            font.family: "monospace"
            font.pixelSize: 13
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
