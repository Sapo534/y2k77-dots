import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking

Flickable {
    id: page
    Layout.fillWidth: true
    Layout.fillHeight: true
    clip: true
    contentWidth: width
    contentHeight: col.implicitHeight
    boundsBehavior: Flickable.StopAtBounds

    property bool active: false

    readonly property var allDevices: Array.from(Networking.devices.values)
    // Only WifiDevice has scannerEnabled
    readonly property var wifi: allDevices.find(d => typeof d.scannerEnabled === "boolean") ?? null
    readonly property var wired: allDevices.filter(d => d !== wifi)
    readonly property var networks: wifi ? Array.from(wifi.networks.values)
        .filter(n => n.name)
        .sort((a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength)) : []

    // Scan only while the tab is visible
    Binding {
        target: page.wifi
        property: "scannerEnabled"
        value: page.active
        when: page.wifi !== null
    }

    ColumnLayout {
        id: col
        width: page.width
        spacing: 8

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "WI-FI"
                color: "#777777"
                font.family: "monospace"
                font.letterSpacing: 1.4
                font.pixelSize: 9
            }

            Item { Layout.fillWidth: true }

            Btn {
                visible: page.wifi !== null
                label: Networking.wifiEnabled ? "TURN OFF" : "TURN ON"
                onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
            }
            Btn { label: "ADVANCED"; onClicked: Quickshell.execDetached(["nm-connection-editor"]) }
        }

        Repeater {
            model: page.wired

            delegate: ListRow {
                required property var modelData
                Layout.fillWidth: true
                title: modelData.name
                subtitle: modelData.connected ? "Connected" : "Disconnected"
                highlighted: modelData.connected
            }
        }

        Text {
            visible: page.wifi === null
            text: "No Wi-Fi adapter"
            color: "#666666"
            font.family: "monospace"
            font.pixelSize: 10
        }

        Repeater {
            model: Networking.wifiEnabled ? page.networks : []

            delegate: ListRow {
                required property var modelData
                Layout.fillWidth: true
                title: modelData.name
                subtitle: modelData.connected ? "Connected"
                        : modelData.stateChanging ? "Working…"
                        : modelData.known ? "Saved" : "New"
                trailing: Math.round(modelData.signalStrength * 100) + "%"
                highlighted: modelData.connected

                // Left click: connect/disconnect. Right click: forget.
                onClicked: modelData.connected ? modelData.disconnect() : modelData.connect()
                onSecondaryClicked: if (modelData.known) modelData.forget()
            }
        }
    }
}
