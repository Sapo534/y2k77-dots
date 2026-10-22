import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: s

    property string title: ""
    property var node: null        // current default node
    property var nodes: []         // selectable nodes
    signal pick(var n)

    readonly property var audio: node?.audio ?? null
    spacing: 8

    RowLayout {
        Layout.fillWidth: true

        Text {
            text: s.title
            color: "#777777"
            font.family: "monospace"
            font.letterSpacing: 1.4
            font.pixelSize: 9
        }

        Item { Layout.fillWidth: true }

        Text {
            text: s.audio ? (s.audio.muted ? "MUTED" : Math.round(s.audio.volume * 100) + "%") : "—"
            color: "#ffffff"
            font.family: "monospace"
            font.pixelSize: 12
        }

        Btn {
            label: s.audio?.muted ? "UNMUTE" : "MUTE"
            onClicked: if (s.audio) s.audio.muted = !s.audio.muted
        }
    }

    Sld {
        Layout.fillWidth: true
        enabled: s.audio !== null
        value: (s.audio?.volume ?? 0) * 100
        onMoved: if (s.audio) s.audio.volume = value / 100
    }

    Repeater {
        model: s.nodes

        delegate: ListRow {
            required property var modelData
            Layout.fillWidth: true
            title: modelData.description || modelData.nickname || modelData.name
            highlighted: modelData.id === s.node?.id
            trailing: highlighted ? "●" : ""
            onClicked: s.pick(modelData)
        }
    }
}
