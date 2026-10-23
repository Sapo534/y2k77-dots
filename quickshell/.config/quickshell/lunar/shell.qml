import Quickshell
import Quickshell.Io
import QtQuick

ShellRoot {
    id: shell
    property bool ccVisible: false
    property bool hold: false   // true = меню не закрываются при потере фокуса (скриншот)

    // Таймер/будильники/планировщик: один на все мониторы
    ClockService { id: clockSvc }

    // qs ipc call lunar toggleControlCenter
    // qs ipc call lunar hold / release  — обернуть скриншот, см. ниже
    IpcHandler {
        target: "lunar"
        function toggleControlCenter(): void { shell.ccVisible = !shell.ccVisible }
        function hold(): void { shell.hold = true }
        function release(): void { shell.hold = false }
    }

    // страховка, если release не позвали
    Timer { interval: 30000; running: shell.hold; onTriggered: shell.hold = false }

    Variants {
        model: Quickshell.screens

        Bar {
            required property var modelData
            screen: modelData
            svc: clockSvc
            hold: shell.hold
            ccOpen: shell.ccVisible
            onToggleControlCenter: shell.ccVisible = !shell.ccVisible
            onRequestClose: shell.ccVisible = false
        }
    }
}
