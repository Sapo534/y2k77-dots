import Quickshell
import Quickshell.Io

ShellRoot {
    id: shell
    property bool ccVisible: false

    // qs ipc call lunar toggleControlCenter
    IpcHandler {
        target: "lunar"
        function toggleControlCenter(): void { shell.ccVisible = !shell.ccVisible }
    }

    Variants {
        model: Quickshell.screens

        Bar {
            required property var modelData
            screen: modelData
            ccOpen: shell.ccVisible
            onToggleControlCenter: shell.ccVisible = !shell.ccVisible
            onRequestClose: shell.ccVisible = false
        }
    }
}
