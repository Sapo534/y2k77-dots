import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire

Flickable {
    id: page
    Layout.fillWidth: true
    Layout.fillHeight: true
    clip: true
    contentWidth: width
    contentHeight: col.implicitHeight
    boundsBehavior: Flickable.StopAtBounds

    // Without a tracker, node.audio stays null
    PwObjectTracker { objects: Pipewire.nodes.values }

    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)
    readonly property var sources: Pipewire.nodes.values.filter(n => !n.isSink && !n.isStream && n.audio)

    ColumnLayout {
        id: col
        width: page.width
        spacing: 14

        AudioSection {
            Layout.fillWidth: true
            title: "OUTPUT"
            node: Pipewire.defaultAudioSink
            nodes: page.sinks
            onPick: n => Pipewire.preferredDefaultAudioSink = n
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: "#292929" }

        AudioSection {
            Layout.fillWidth: true
            title: "INPUT"
            node: Pipewire.defaultAudioSource
            nodes: page.sources
            onPick: n => Pipewire.preferredDefaultAudioSource = n
        }
    }
}
