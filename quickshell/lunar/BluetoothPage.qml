import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth

Flickable {
    id: page
    Layout.fillWidth: true
    Layout.fillHeight: true
    clip: true
    contentWidth: width
    contentHeight: col.implicitHeight
    boundsBehavior: Flickable.StopAtBounds

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var devices: adapter ? Array.from(adapter.devices.values)
        .filter(d => d.paired || d.connected || adapter.discovering)
        .sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired)
                        || (a.name || "").localeCompare(b.name || "")) : []

    ColumnLayout {
        id: col
        width: page.width
        spacing: 8

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "DEVICES"
                color: "#777777"
                font.family: "monospace"
                font.letterSpacing: 1.4
                font.pixelSize: 9
            }

            Item { Layout.fillWidth: true }

            Btn {
                visible: page.adapter !== null && page.adapter.enabled
                label: page.adapter?.discovering ? "STOP SCAN" : "SCAN"
                onClicked: page.adapter.discovering = !page.adapter.discovering
            }
            Btn {
                visible: page.adapter !== null
                label: page.adapter?.enabled ? "TURN OFF" : "TURN ON"
                onClicked: page.adapter.enabled = !page.adapter.enabled
            }
        }

        Text {
            visible: page.adapter === null
            text: "No Bluetooth adapter"
            color: "#666666"
            font.family: "monospace"
            font.pixelSize: 10
        }

        Repeater {
            model: page.adapter?.enabled ? page.devices : []

            delegate: ListRow {
                required property var modelData
                Layout.fillWidth: true
                title: modelData.name || modelData.address
                subtitle: (modelData.connected ? "Connected" : modelData.paired ? "Paired" : "Available")
                          + (modelData.batteryAvailable ? " · " + Math.round(modelData.battery * 100) + "%" : "")
                highlighted: modelData.connected

                // Left click: connect / disconnect / pair. Right click: forget.
                onClicked: {
                    if (modelData.connected) modelData.disconnect()
                    else if (modelData.paired) modelData.connect()
                    else modelData.pair()
                }
                onSecondaryClicked: if (modelData.paired) modelData.forget()
            }
        }
    }
}
