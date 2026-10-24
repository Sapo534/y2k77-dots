import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Bluetooth

PopupWindow {
    id: cc

    required property var barWindow
    property bool open: false
    property bool hold: false   // true на время скриншота
    property int tab: 0
    property bool hasBacklight: false
    property int brightness: 50
    readonly property bool hasBt: !!Bluetooth.defaultAdapter
    signal requestClose()

    anchor.window: barWindow
    anchor.rect.x: barWindow.width - width - 12
    anchor.rect.y: barWindow.height + 8

    implicitWidth: 440
    implicitHeight: 560
    visible: open || card.opacity > 0.01   // keep alive for the fade-out
    color: "transparent"

    onOpenChanged: if (open) brightnessProc.running = true
    onHasBtChanged: if (!hasBt && tab === 2) tab = 0

    // Click outside closes it. If the popup closes instantly on open,
    // delete this block and set grabFocus: true instead.
    HyprlandFocusGrab {
        windows: [cc, cc.barWindow]
        active: cc.open && !cc.hold
        onCleared: cc.requestClose()
    }

    // brightnessctl only exists for backlights (laptops). Hidden when absent.
    Process {
        id: brightnessProc
        command: ["brightnessctl", "-m"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.trim().match(/(\d+)%/)
                if (m) {
                    cc.hasBacklight = true
                    if (!brightnessSlider.pressed)
                        cc.brightness = Number(m[1])
                }
            }
        }
    }

    Timer {
        interval: 120
        repeat: true
        running: brightnessSlider.pressed
        onTriggered: Quickshell.execDetached(["brightnessctl", "set", Math.round(brightnessSlider.value) + "%"])
    }

    Rectangle {
        id: card
        anchors.fill: parent
        anchors.margins: 1
        radius: 11
        color: "#101010"
        border.width: 1
        border.color: "#383838"

        opacity: cc.open ? 1 : 0
        scale: cc.open ? 1 : 0.97
        Behavior on opacity { NumberAnimation { duration: 140 } }
        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 17
            spacing: 10

            RowLayout {
                Layout.fillWidth: true

                ColumnLayout {
                    spacing: 3
                    Text {
                        text: "CONTROL CENTER"
                        color: "#f2f2f2"
                        font.family: "monospace"
                        font.bold: true
                        font.letterSpacing: 1.2
                        font.pixelSize: 13
                    }
                    Text {
                        text: "LUNAR STATION / SYSTEM"
                        color: "#666666"
                        font.family: "monospace"
                        font.pixelSize: 9
                        font.letterSpacing: 0.8
                    }
                }

                Item { Layout.fillWidth: true }
                Btn { label: "×"; implicitWidth: 28; onClicked: cc.requestClose() }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                Btn { label: "AUDIO"; active: cc.tab === 0; onClicked: cc.tab = 0 }
                Btn { label: "NETWORK"; active: cc.tab === 1; onClicked: cc.tab = 1 }
                Btn { label: "BLUETOOTH"; visible: cc.hasBt; active: cc.tab === 2; onClicked: cc.tab = 2 }
                Btn { label: "VPN"; active: cc.tab === 3; onClicked: cc.tab = 3 }
                Btn { label: "MONITOR"; active: cc.tab === 5; onClicked: cc.tab = 5 }
                Btn { label: "POWER"; active: cc.tab === 4; onClicked: cc.tab = 4 }
                Item { Layout.fillWidth: true }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#292929" }

            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: cc.tab

                AudioPage {}
                NetworkPage { active: cc.open && cc.tab === 1 }
                BluetoothPage { }
                VpnPage { active: cc.open && cc.tab === 3 }
                PowerPage { active: cc.open && cc.tab === 4 }
                MonitorPage { active: cc.open && cc.tab === 5 }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#292929"; visible: cc.hasBacklight }

            ColumnLayout {
                Layout.fillWidth: true
                visible: cc.hasBacklight
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "DISPLAY BRIGHTNESS"
                        color: "#eeeeee"
                        font.family: "monospace"
                        font.pixelSize: 11
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: Math.round(brightnessSlider.value) + "%"
                        color: "#ffffff"
                        font.family: "monospace"
                        font.pixelSize: 12
                    }
                }

                Sld {
                    id: brightnessSlider
                    Layout.fillWidth: true
                    from: 1
                    value: cc.brightness
                    onMoved: cc.brightness = Math.round(value)
                    onPressedChanged: if (!pressed)
                        Quickshell.execDetached(["brightnessctl", "set", Math.round(value) + "%"])
                }
            }

            Text {
                text: "LUNAR STATION     •     ARCH / HYPRLAND"
                color: "#555555"
                font.family: "monospace"
                font.pixelSize: 10
            }
        }
    }
}
