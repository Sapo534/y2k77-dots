import QtQuick
import QtQuick.Layouts

// Компактные показатели в баре. Клик — открыть/закрыть вкладку MONITOR в CC.
Rectangle {
    id: w

    property bool open: false
    signal clicked()

    readonly property bool cpuOn: MonCfg.a.barCpu || MonCfg.a.barCpuTemp
    readonly property bool gpuOn: SysStats.hasGpu && (MonCfg.a.barGpu || MonCfg.a.barGpuTemp)
    readonly property bool batOn: MonCfg.a.barBattery && SysStats.hasBattery
    readonly property int diskCount: SysStats.diskMounts.filter(m => MonCfg.diskShown(m)).length
    readonly property bool hasAny: cpuOn || gpuOn || MonCfg.a.barRam || batOn || diskCount > 0

    visible: MonCfg.a.barEnabled && hasAny
    implicitWidth: row.implicitWidth + 18
    implicitHeight: 26
    radius: 4
    color: open ? "#eeeeee" : (m.containsMouse ? "#2a2a2a" : "#202020")

    function join(a, b) { return a && b ? a + " " + b : (a || b) }
    function pct(v) { return Math.round(v) + "%" }
    function deg(v) { return Math.round(v) + "°" }

    component Metric: Row {
        id: mt
        property string label: ""
        property string value: ""
        property bool warn: false
        property bool inverted: false
        spacing: 5

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: mt.label
            color: mt.inverted ? "#666666" : "#777777"
            font.family: "monospace"
            font.pixelSize: 10
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: mt.value
            color: mt.warn ? (mt.inverted ? "#c62828" : "#ff7a7a")
                           : (mt.inverted ? "#111111" : "#ffffff")
            font.family: "monospace"
            font.pixelSize: 11
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 12

        Metric {
            visible: w.cpuOn
            inverted: w.open
            label: "CPU"
            value: w.join(MonCfg.a.barCpu ? w.pct(SysStats.cpu) : "",
                          MonCfg.a.barCpuTemp && SysStats.cpuTemp >= 0 ? w.deg(SysStats.cpuTemp) : "")
            warn: SysStats.cpu >= 90 || SysStats.cpuTemp >= 85
        }

        Metric {
            visible: w.gpuOn
            inverted: w.open
            label: "GPU"
            value: w.join(MonCfg.a.barGpu ? w.pct(SysStats.gpu) : "",
                          MonCfg.a.barGpuTemp && SysStats.gpuTemp >= 0 ? w.deg(SysStats.gpuTemp) : "")
            warn: SysStats.gpu >= 95 || SysStats.gpuTemp >= 85
        }

        Metric {
            visible: MonCfg.a.barRam
            inverted: w.open
            label: "RAM"
            value: w.pct(SysStats.ramPct)
            warn: SysStats.ramPct >= 90
        }

        Repeater {
            model: SysStats.diskMounts

            delegate: Metric {
                id: dm
                required property var modelData
                readonly property var d: SysStats.diskInfo[modelData] ?? null

                visible: MonCfg.diskShown(modelData) && d !== null
                inverted: w.open
                label: modelData === "/" ? "/" : modelData.split("/").pop().toUpperCase()
                value: d ? w.pct(d.used / d.size * 100) : ""
                warn: d ? d.used / d.size >= 0.9 : false
            }
        }

        Metric {
            visible: w.batOn
            inverted: w.open
            label: "BAT"
            value: (SysStats.charging ? "+" : "") + w.pct(SysStats.batPct)
            warn: SysStats.batPct <= 15 && !SysStats.charging
        }
    }

    MouseArea {
        id: m
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: w.clicked()
    }
}
