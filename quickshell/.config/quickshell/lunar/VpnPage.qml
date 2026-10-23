import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Flickable {
    id: page
    Layout.fillWidth: true
    Layout.fillHeight: true
    clip: true
    contentWidth: width
    contentHeight: col.implicitHeight
    boundsBehavior: Flickable.StopAtBounds

    property bool active: false

    // Имена конфигов: /etc/amnezia/amneziawg/<имя>.conf  (только [a-z0-9_-])
    property var profiles: ["awg0"]
    property var states: ({})

    // Split tunneling (списки лежат в ~/.config/vpn-bypass/)
    property var bypassEntries: []   // { kind: "ip"|"domain", value }
    property var bypassApps: []      // { label, cmd }

    readonly property string bin: Quickshell.env("HOME") + "/.local/bin/"

    function refresh() { statusProc.running = true; listProc.running = true }
    onActiveChanged: if (active) refresh()

    // systemctl is-active не требует прав
    Process {
        id: statusProc
        command: ["sh", "-c",
            "for p in " + page.profiles.join(" ")
            + "; do echo \"$p $(systemctl is-active awg-quick@$p)\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const s = {}
                for (const line of text.trim().split("\n")) {
                    const parts = line.split(" ")
                    if (parts[0]) s[parts[0]] = parts[1]
                }
                page.states = s
            }
        }
    }

    Process {
        id: listProc
        command: [page.bin + "vpn-bypass", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const entries = []
                const apps = []
                for (const line of text.split("\n")) {
                    const tab = line.indexOf("\t")
                    if (tab < 0) continue
                    const kind = line.slice(0, tab)
                    const value = line.slice(tab + 1).trim()
                    if (!value) continue
                    if (kind === "app") {
                        const sep = value.indexOf("|")
                        if (sep > 0)
                            apps.push({ label: value.slice(0, sep).trim(), cmd: value.slice(sep + 1).trim() })
                    } else {
                        entries.push({ kind: kind, value: value })
                    }
                }
                page.bypassEntries = entries
                page.bypassApps = apps
            }
        }
    }

    Timer { interval: 3000; repeat: true; running: page.active; onTriggered: page.refresh() }
    Timer { id: settle; interval: 900; onTriggered: page.refresh() }

    ColumnLayout {
        id: col
        width: page.width
        spacing: 8

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "AMNEZIAWG"
                color: "#777777"
                font.family: "monospace"
                font.letterSpacing: 1.4
                font.pixelSize: 9
            }
            Item { Layout.fillWidth: true }
            Btn { label: "REFRESH"; onClicked: page.refresh() }
        }

        Repeater {
            model: page.profiles

            delegate: ListRow {
                required property var modelData
                readonly property string st: page.states[modelData] ?? "unknown"
                readonly property bool up: st === "active" || st === "activating"

                Layout.fillWidth: true
                title: modelData
                subtitle: st === "active" ? "Connected"
                        : st === "activating" ? "Connecting…"
                        : st === "failed" ? "Failed · journalctl -u awg-quick@" + modelData
                        : "Disconnected"
                trailing: st === "active" ? "ON" : "OFF"
                highlighted: st === "active"

                onClicked: {
                    Quickshell.execDetached(["systemctl", up ? "stop" : "start", "awg-quick@" + modelData])
                    settle.restart()
                }
            }
        }

        Rectangle { Layout.fillWidth: true; Layout.topMargin: 6; height: 1; color: "#292929" }

        // ── Приложения: запуск мимо туннеля ──
        Text {
            text: "APPS · ЗАПУСК МИМО VPN"
            color: "#777777"
            font.family: "monospace"
            font.letterSpacing: 1.4
            font.pixelSize: 9
        }

        Repeater {
            model: page.bypassApps

            delegate: ListRow {
                required property var modelData
                Layout.fillWidth: true
                title: modelData.label
                subtitle: modelData.cmd
                trailing: "RUN"
                onClicked: Quickshell.execDetached([page.bin + "novpn"].concat(modelData.cmd.split(" ")))
            }
        }

        Text {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            visible: page.bypassApps.length === 0
            text: "Пусто. Добавь строки «Название|команда» в ~/.config/vpn-bypass/apps.txt"
            color: "#555555"
            font.family: "monospace"
            font.pixelSize: 9
        }

        Rectangle { Layout.fillWidth: true; Layout.topMargin: 6; height: 1; color: "#292929" }

        // ── IP / подсети / домены ──
        RowLayout {
            Layout.fillWidth: true

            Text {
                Layout.fillWidth: true
                text: "BYPASS · IP / ДОМЕНЫ"
                color: "#777777"
                font.family: "monospace"
                font.letterSpacing: 1.4
                font.pixelSize: 9
                elide: Text.ElideRight
            }
            Btn {
                label: "+ CLIPBOARD"
                onClicked: {
                    Quickshell.execDetached([page.bin + "vpn-bypass", "clip"])
                    settle.restart()
                }
            }
            Btn {
                label: "RELOAD"
                onClicked: {
                    Quickshell.execDetached([page.bin + "vpn-bypass", "reload"])
                    settle.restart()
                }
            }
        }

        Repeater {
            model: page.bypassEntries

            delegate: ListRow {
                required property var modelData
                Layout.fillWidth: true
                title: modelData.value
                subtitle: modelData.kind === "domain" ? "Домен" : "IP / подсеть"
                onSecondaryClicked: {
                    Quickshell.execDetached([page.bin + "vpn-bypass", "rm", modelData.value])
                    settle.restart()
                }
            }
        }

        Text {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: page.bypassEntries.length === 0
                ? "Скопируй домен или IP и нажми + CLIPBOARD."
                : "ПКМ по записи — удалить. Скопируй домен или IP и нажми + CLIPBOARD."
            color: "#555555"
            font.family: "monospace"
            font.pixelSize: 9
        }
    }
}
