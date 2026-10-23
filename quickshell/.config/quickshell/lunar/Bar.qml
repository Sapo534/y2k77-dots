import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import Quickshell.Wayland

PanelWindow {
    id: bar

    property bool ccOpen: false
    property bool hold: false
    property bool clockOpen: false
    required property var svc
    signal toggleControlCenter()
    signal requestClose()

    anchors { top: true; left: true; right: true }

    // Без этого попапы бара не получают клавиатурный фокус и поля ввода молчат
    WlrLayershell.keyboardFocus: (ccOpen || playerOpen || clockOpen)
        ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    implicitHeight: 44
    color: "#101010"

    readonly property var tl: Hyprland.activeToplevel
    readonly property var sinkAudio: Pipewire.defaultAudioSink?.audio ?? null
    property bool playerOpen: false

    readonly property var players: Mpris.players.values
    readonly property var player: players.find(p => p.isPlaying) ?? players[0] ?? null

    onPlayerChanged: if (!player) playerOpen = false
    onCcOpenChanged: if (ccOpen) { playerOpen = false; clockOpen = false }

    SystemClock { id: clock; precision: SystemClock.Seconds }
    PwObjectTracker { objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : [] }

    readonly property var sites: [
        { re: /youtube|youtu\.be|ytimg/, domain: "youtube.com" },
        { re: /spotify|scdn\.co/,        domain: "spotify.com" },
        { re: /soundcloud|sndcdn/,       domain: "soundcloud.com" }
    ]

    function hostOf(u) {
        const m = /^https?:\/\/([^\/:?#]+)/i.exec(u || "")
        return m ? m[1].replace(/^www\./, "") : ""
    }

    function sourceOf(p) {
        if (!p) return { icon: "", url: "", name: "" }
        let host = hostOf((p.metadata ?? {})["xesam:url"])
        if (!host) {
            const art = (p.trackArtUrl ?? "").toLowerCase()
            const s = sites.find(s => s.re.test(art))
            if (s) host = s.domain
        }
        return {
            icon: p.desktopEntry || (p.identity ?? "").toLowerCase(),
            url: host ? "https://www.google.com/s2/favicons?sz=64&domain=" + host : "",
            name: host || p.identity || ""
        }
    }

    readonly property var source: sourceOf(player)

    ControlCenter {
        barWindow: bar
        open: bar.ccOpen && (!Hyprland.focusedMonitor || Hyprland.focusedMonitor.name === bar.screen?.name)
        onRequestClose: bar.requestClose()
        hold: bar.hold
    }

    PlayerPopup {
      barWindow: bar
      player: bar.player
      open: bar.playerOpen && bar.player !== null
      onRequestClose: bar.playerOpen = false
      iconName: bar.source.icon
      iconUrl: bar.source.url
      sourceName: bar.source.name
      hold: bar.hold
    }

    ClockPopup {
        barWindow: bar
        svc: bar.svc
        hold: bar.hold
        open: bar.clockOpen
        onRequestClose: bar.clockOpen = false
    }

    Rectangle {
        anchors.fill: parent
        color: "#101010"
        border.width: 1
        border.color: "#303030"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            spacing: 16

            Text {
                text: "S A P O"
                color: "#ffffff"
                font.family: "monospace"
                font.bold: true
                font.pixelSize: 14
                Layout.alignment: Qt.AlignVCenter
            }

            // Workspaces: Hyprland keeps this model live, no manual refresh needed
            Row {
                spacing: 5
                Layout.alignment: Qt.AlignVCenter

                Repeater {
                    model: Array.from(Hyprland.workspaces.values).sort((a, b) => {
                        const aS = a.name?.startsWith("special:") ?? false
                        const bS = b.name?.startsWith("special:") ?? false
                        if (aS !== bS)
                            return aS ? 1 : -1
                        return a.id - b.id
                    })

                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool isActive: modelData.id === Hyprland.focusedWorkspace?.id

                        width: 28
                        height: 26
                        radius: 4
                        color: isActive ? "#eeeeee" : "#202020"

                        Text {
                            anchors.centerIn: parent
                            text: modelData.id > 0 ? modelData.id : "S"
                            color: parent.isActive ? "#111111" : "#999999"
                            font.family: "monospace"
                            font.pixelSize: 12
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: modelData.activate()
                        }
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 20
                Layout.alignment: Qt.AlignVCenter
                color: "#303030"
            }

            // Active window
            RowLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 50
                spacing: 8

                Text {
                    text: bar.tl?.wayland?.appId || bar.tl?.lastIpcObject?.class || "DESKTOP"
                    color: "#eeeeee"
                    font.family: "monospace"
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    Layout.maximumWidth: 130
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    text: bar.tl?.title || "No active window"
                    color: "#888888"
                    font.family: "monospace"
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            // Tray
            Row {
                spacing: 10
                Layout.alignment: Qt.AlignVCenter

                Repeater {
                    model: SystemTray.items

                    delegate: Item {
                        id: trayEntry
                        required property var modelData
                        width: 20
                        height: 24

                        Image {
                            anchors.centerIn: parent
                            width: 18
                            height: 18
                            source: trayEntry.modelData.icon
                            sourceSize.width: 36
                            sourceSize.height: 36
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

                            function openItemMenu() {
                                const item = trayEntry.modelData
                                if (!item.hasMenu)
                                    return
                                // null = scene coordinates (bar is a window, not an Item)
                                const pos = trayEntry.mapToItem(null, 0, trayEntry.height)
                                item.display(bar, pos.x, pos.y)
                            }

                            onClicked: mouse => {
                                const item = trayEntry.modelData
                                if (mouse.button === Qt.LeftButton) {
                                    if (item.onlyMenu) openItemMenu()
                                    else item.activate()
                                } else if (mouse.button === Qt.MiddleButton) {
                                    item.secondaryActivate()
                                } else {
                                    openItemMenu()
                                }
                            }

                            onWheel: wheel => trayEntry.modelData.scroll(wheel.angleDelta.y, false)
                        }
                    }
                }
            }

            // Control center button: click = open, wheel = volume, middle = mute
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: volText.implicitWidth + 18
                implicitHeight: 26
                radius: 4
                color: bar.ccOpen ? "#eeeeee" : (volMouse.containsMouse ? "#2a2a2a" : "#202020")

                Text {
                    id: volText
                    anchors.centerIn: parent
                    text: !bar.sinkAudio ? "VOL —"
                        : bar.sinkAudio.muted ? "VOL MUTE"
                        : "VOL " + Math.round(bar.sinkAudio.volume * 100) + "%"
                    color: bar.ccOpen ? "#111111" : "#cccccc"
                    font.family: "monospace"
                    font.pixelSize: 11
                }

                MouseArea {
                    id: volMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton

                    onClicked: mouse => {
                        if (mouse.button === Qt.MiddleButton) {
                            if (bar.sinkAudio) bar.sinkAudio.muted = !bar.sinkAudio.muted
                        } else {
                            bar.toggleControlCenter()
                        }
                    }

                    onWheel: wheel => {
                        if (!bar.sinkAudio) return
                        const v = bar.sinkAudio.volume + (wheel.angleDelta.y > 0 ? 0.03 : -0.03)
                        bar.sinkAudio.volume = Math.max(0, Math.min(1, v))
                    }
                }
            }

            // Дата + время одной кнопкой: клик = меню (календарь / часы)
            ClockButton {
                Layout.alignment: Qt.AlignVCenter
                svc: bar.svc
                now: clock.date
                open: bar.clockOpen
                onClicked: {
                    if (bar.svc.ringing) { bar.svc.dismiss(); return }
                    if (!bar.clockOpen) {
                        if (bar.ccOpen) bar.requestClose()
                        bar.playerOpen = false
                    }
                    bar.clockOpen = !bar.clockOpen
                }
            }
          }
          PlayerButton {
            iconName: bar.source.icon
            iconUrl: bar.source.url
            anchors.centerIn: parent
            player: bar.player
            open: bar.playerOpen
            onClicked: {
                if (!bar.playerOpen && bar.ccOpen) bar.requestClose()
                bar.clockOpen = false
                bar.playerOpen = !bar.playerOpen
            }
        }
    }
}
