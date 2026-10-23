import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

PopupWindow {
    id: pp

    required property var barWindow
    property var player: null
    property bool open: false
    property bool hold: false   // true на время скриншота
    signal requestClose()

    property string iconName: ""
    property string iconUrl: ""
    property string sourceName: ""

    // Обложка: не даём плееру подменить хорошую картинку мыльной
    property string shownArt: ""
    property string shownTitle: ""
    property real shownWidth: 0

    // Firefox/Zen не отдают mpris:length, пока трек не докачан
    // Zen отдаёт mpris:length только вспышками (после перемотки), и значение при этом
    // постоянное — запоминаем длину на время трека и больше не мигаем.
    readonly property real liveLength: (player?.lengthSupported ?? false) ? (player?.length ?? 0) : 0
    readonly property string trackKey: (player?.trackTitle ?? "") + "|" + (player?.trackArtist ?? "")
    property real knownLength: 0
    property string knownFor: ""
    readonly property bool hasLength: knownLength > 0

    onLiveLengthChanged: if (liveLength > 0) { knownLength = liveLength; knownFor = trackKey }
    onTrackKeyChanged: if (knownFor !== trackKey) knownLength = 0
    Component.onCompleted: if (liveLength > 0) { knownLength = liveLength; knownFor = trackKey }
    onPlayerChanged: {
        shownArt = ""; shownTitle = ""; shownWidth = 0
        knownLength = liveLength > 0 ? liveLength : 0
        knownFor = trackKey
    }

    function fmt(s) {
        s = Math.max(0, Math.floor(s || 0))
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0")
    }

    anchor.window: barWindow
    anchor.rect.x: (barWindow.width - width) / 2
    anchor.rect.y: barWindow.height + 8

    implicitWidth: 440
    implicitHeight: col.implicitHeight + 36
    visible: open || card.opacity > 0.01
    color: "transparent"

    HyprlandFocusGrab {
        windows: [pp, pp.barWindow]
        active: pp.open && !pp.hold
        onCleared: pp.requestClose()
    }

    // MPRIS не шлёт position сам — дёргаем, пока играет
    Timer {
        interval: 500
        repeat: true
        running: pp.open && (pp.player?.isPlaying ?? false) && (pp.player?.positionSupported ?? false)
        onTriggered: pp.player.positionChanged()
    }

    Rectangle {
        id: card
        anchors.fill: parent
        anchors.margins: 1
        radius: 11
        color: "#101010"
        border.width: 1
        border.color: "#383838"

        opacity: pp.open ? 1 : 0
        scale: pp.open ? 1 : 0.97
        Behavior on opacity { NumberAnimation { duration: 140 } }
        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

        ColumnLayout {
            id: col
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 17
            spacing: 10

            // Источник
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                SourceIcon {
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                    iconName: pp.iconName
                    iconUrl: pp.iconUrl
                }
                Text {
                    text: pp.sourceName.toUpperCase()
                    color: "#777777"
                    font.family: "monospace"
                    font.letterSpacing: 1.4
                    font.pixelSize: 9
                }
                Item { Layout.fillWidth: true }
            }

            // Обложка / превью
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 240
                radius: 6
                color: "#171717"
                border.width: 1
                border.color: "#303030"
                clip: true

                Image {
                    id: cover
                    anchors.fill: parent
                    source: pp.shownArt
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    smooth: true
                    mipmap: true
                    visible: status === Image.Ready
                }
                // невидимый «пробник»: грузит новую обложку и сравнивает размер
                Image {
                    id: probe
                    visible: false
                    asynchronous: true
                    source: pp.player?.trackArtUrl ?? ""
                    onStatusChanged: {
                        if (status !== Image.Ready) return
                        const title = pp.player?.trackTitle ?? ""
                        if (title !== pp.shownTitle || implicitWidth >= pp.shownWidth) {
                            pp.shownArt = source
                            pp.shownTitle = title
                            pp.shownWidth = implicitWidth
                        }
                    }
                }
                Text {
                    anchors.centerIn: parent
                    visible: cover.status !== Image.Ready
                    text: "NO COVER"
                    color: "#555555"
                    font.family: "monospace"
                    font.pixelSize: 10
                }
            }

            // Название / исполнитель
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Marquee {
                    Layout.fillWidth: true
                    text: pp.player ? (pp.player.trackTitle || pp.player.identity) : ""
                    color: "#f2f2f2"
                    pixelSize: 13
                }
                Marquee {
                    Layout.fillWidth: true
                    text: pp.player?.trackArtist || "—"
                    color: "#888888"
                    pixelSize: 10
                    opacity: pp.player?.trackArtist ? 1 : 0.35
                }
            }

            // Прогресс
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                opacity: pp.hasLength ? 1 : 0.5

                Text {
                    text: pp.fmt(pp.player?.position)
                    color: "#888888"
                    font.family: "monospace"
                    font.pixelSize: 9
                }
                Sld {
                    Layout.fillWidth: true
                    to: Math.max(1, pp.knownLength)
                    enabled: pp.hasLength && (pp.player?.canSeek ?? false)
                    value: pp.hasLength ? Math.min(pp.player.position, pp.knownLength) : 0
                    onMoved: if (pp.player) pp.player.position = value
                }
                Text {
                    text: pp.fmt(pp.knownLength)
                    color: "#888888"
                    font.family: "monospace"
                    font.pixelSize: 9
                }
            }

            // Управление
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Item { Layout.fillWidth: true }
                Btn {
                    label: "PREV"
                    enabled: pp.player?.canGoPrevious ?? false
                    opacity: enabled ? 1 : 0.35
                    onClicked: pp.player.previous()
                }
                Btn {
                    label: "-5s"
                    enabled: pp.player?.canSeek ?? false
                    opacity: enabled ? 1 : 0.35
                    onClicked: pp.player.seek(-5)
                }
                Btn {
                    label: pp.player?.isPlaying ? "PAUSE" : "PLAY"
                    active: true
                    implicitWidth: 64
                    enabled: pp.player?.canTogglePlaying ?? false
                    opacity: enabled ? 1 : 0.35
                    onClicked: pp.player.togglePlaying()
                }
                Btn {
                    label: "+5s"
                    enabled: pp.player?.canSeek ?? false
                    opacity: enabled ? 1 : 0.35
                    onClicked: pp.player.seek(5)
                }
                Btn {
                    label: "NEXT"
                    enabled: pp.player?.canGoNext ?? false
                    opacity: enabled ? 1 : 0.35
                    onClicked: pp.player.next()
                }
                Item { Layout.fillWidth: true }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#292929" }

            // Громкость плеера (не глобальная)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                enabled: pp.player?.volumeSupported ?? false
                opacity: enabled ? 1 : 0.4

                Text {
                    text: "PLAYER VOLUME"
                    color: "#777777"
                    font.family: "monospace"
                    font.letterSpacing: 1.4
                    font.pixelSize: 9
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Sld {
                        Layout.fillWidth: true
                        value: (pp.player?.volume ?? 0) * 100
                        onMoved: if (pp.player) pp.player.volume = value / 100
                    }

                    Rectangle {
                        Layout.preferredWidth: 54
                        Layout.preferredHeight: 26
                        radius: 5
                        color: "#202020"
                        border.width: 1
                        border.color: volInput.activeFocus ? "#e8e8e8" : "#3a3a3a"

                        TextInput {
                            id: volInput
                            anchors.fill: parent
                            anchors.leftMargin: 6
                            anchors.rightMargin: 16
                            horizontalAlignment: TextInput.AlignRight
                            verticalAlignment: TextInput.AlignVCenter
                            color: "#ffffff"
                            selectByMouse: true
                            font.family: "monospace"
                            font.pixelSize: 11
                            validator: IntValidator { bottom: 0; top: 100 }
                            inputMethodHints: Qt.ImhDigitsOnly

                            onEditingFinished: {
                                if (pp.player && text !== "")
                                    pp.player.volume = Math.max(0, Math.min(100, Number(text))) / 100
                                focus = false
                            }
                        }
                        // пока не печатаем — показываем актуальную громкость
                        Binding {
                            target: volInput
                            property: "text"
                            value: Math.round((pp.player?.volume ?? 0) * 100)
                            when: !volInput.activeFocus
                        }
                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            text: "%"
                            color: "#777777"
                            font.family: "monospace"
                            font.pixelSize: 11
                        }
                    }
                }
            }
        }
    }
}
