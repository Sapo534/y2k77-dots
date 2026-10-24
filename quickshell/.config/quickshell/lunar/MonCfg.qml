pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Настройки монитора. Лежат в ~/.config/lunar/monitor.json, правятся и руками (live reload).
Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/.config/lunar"
    readonly property var a: store.adapter
    property bool ready: false

    function diskShown(mount) { return a.barDiskList.indexOf(mount) >= 0 }

    function toggleDisk(mount) {
        const l = a.barDiskList.slice()
        const i = l.indexOf(mount)
        if (i >= 0) l.splice(i, 1)
        else l.push(mount)
        a.barDiskList = l
    }

    function toggle(key) { a[key] = !a[key] }

    // FileView сам папку не создаёт
    Process {
        running: true
        command: ["mkdir", "-p", root.dir]
        onExited: root.ready = true
    }

    FileView {
        id: store
        path: root.ready ? root.dir + "/monitor.json" : ""
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => { if (error === FileViewError.FileNotFound) writeAdapter() }

        adapter: JsonAdapter {
            property bool barEnabled: true     // весь блок в баре
            property bool barCpu: true
            property bool barCpuTemp: true
            property bool barGpu: true
            property bool barGpuTemp: false
            property bool barRam: true
            property bool barBattery: true     // на десктопе скрыт сам
            property var barDiskList: ["/"]    // точки монтирования
        }
    }
}
