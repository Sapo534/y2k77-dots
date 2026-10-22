import QtQuick
import QtQuick.Layouts
import Quickshell

Flickable {
    id: page
    Layout.fillWidth: true
    Layout.fillHeight: true
    clip: true
    contentWidth: width
    contentHeight: col.implicitHeight
    boundsBehavior: Flickable.StopAtBounds

    property bool active: false
    property string armed: ""   // id действия, ожидающего подтверждения

    onActiveChanged: if (!active) armed = ""

    readonly property var actions: [
        { id: "logout",   label: "LOG OUT",  hint: "Завершить сессию",
          cmd: ["sh", "-c", "loginctl terminate-session \"$XDG_SESSION_ID\" 2>/dev/null || hyprctl dispatch exit"] },
        { id: "reboot",   label: "REBOOT",   hint: "Перезагрузить компьютер",
          cmd: ["systemctl", "reboot"] },
        { id: "poweroff", label: "SHUTDOWN", hint: "Выключить компьютер",
          cmd: ["systemctl", "poweroff"] }
    ]

    // Подтверждение сбрасывается само
    Timer { id: disarm; interval: 4000; onTriggered: page.armed = "" }

    ColumnLayout {
        id: col
        width: page.width
        spacing: 8

        Text {
            text: "POWER"
            color: "#777777"
            font.family: "monospace"
            font.letterSpacing: 1.4
            font.pixelSize: 9
        }

        Repeater {
            model: page.actions

            delegate: ListRow {
                required property var modelData
                readonly property bool isArmed: page.armed === modelData.id

                Layout.fillWidth: true
                implicitHeight: 50
                title: modelData.label
                subtitle: isArmed ? "Нажми ещё раз для подтверждения" : modelData.hint
                trailing: isArmed ? "CONFIRM" : ""
                highlighted: isArmed

                onClicked: {
                    if (isArmed) {
                        page.armed = ""
                        Quickshell.execDetached(modelData.cmd)
                    } else {
                        page.armed = modelData.id
                        disarm.restart()
                    }
                }
            }
        }
    }
}
