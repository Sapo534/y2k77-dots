import QtQuick
import QtQuick.Layouts

Flickable {
    id: page
    Layout.fillWidth: true
    Layout.fillHeight: true
    clip: true
    contentWidth: width
    contentHeight: col.implicitHeight
    boundsBehavior: Flickable.StopAtBounds

    property bool active: false

    // Пока вкладка открыта — SysStats опрашивает и GPU
    Binding { target: SysStats; property: "pageActive"; value: page.active }

    component Cap: Text {
        color: "#777777"
        font.family: "monospace"
        font.letterSpacing: 1.4
        font.pixelSize: 9
    }

    component KV: RowLayout {
        id: kv
        property string k: ""
        property string v: ""
        Text { text: kv.k; color: "#777777"; font.family: "monospace"; font.pixelSize: 10 }
        Item { Layout.fillWidth: true }
        Text { text: kv.v; color: "#dddddd"; font.family: "monospace"; font.pixelSize: 10 }
    }

    ColumnLayout {
        id: col
        width: page.width
        spacing: 10

        // ── CPU ──
        Panel {
            Layout.fillWidth: true

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Cap { text: "CPU" }
                Text {
                    Layout.fillWidth: true
                    text: SysStats.cpuModel
                    color: "#555555"
                    font.family: "monospace"
                    font.pixelSize: 9
                    elide: Text.ElideRight
                }
                Text {
                    text: Math.round(SysStats.cpu) + "%"
                        + (SysStats.cpuTemp >= 0 ? "  ·  " + Math.round(SysStats.cpuTemp) + "°C" : "")
                    color: "#ffffff"
                    font.family: "monospace"
                    font.pixelSize: 12
                }
            }

            Spark {
                Layout.fillWidth: true
                Layout.preferredHeight: 56
                values: SysStats.cpuHist
                values2: SysStats.cpuTempHist
                live: page.active
            }

            Text {
                text: "—— LOAD %     ┄┄ TEMP °C     60 s"
                color: "#555555"
                font.family: "monospace"
                font.pixelSize: 9
            }

            Flow {
                Layout.fillWidth: true
                Layout.preferredHeight: childrenRect.height
                spacing: 3

                Repeater {
                    model: SysStats.coreCount

                    delegate: Rectangle {
                        id: coreBar
                        required property int index
                        readonly property real v: SysStats.cores[index] ?? 0

                        width: 16
                        height: 30
                        radius: 2
                        color: "#202020"

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: parent.height * coreBar.v / 100
                            radius: 2
                            color: coreBar.v >= 90 ? "#ff7a7a" : "#e8e8e8"
                            Behavior on height { NumberAnimation { duration: 200 } }
                        }
                    }
                }
            }
        }

        // ── GPU ──
        Panel {
            Layout.fillWidth: true
            visible: SysStats.hasGpu

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Cap { text: "GPU" }
                Text {
                    Layout.fillWidth: true
                    text: SysStats.gpuName
                    color: "#555555"
                    font.family: "monospace"
                    font.pixelSize: 9
                    elide: Text.ElideRight
                }
                Text {
                    text: Math.round(SysStats.gpu) + "%"
                        + (SysStats.gpuTemp >= 0 ? "  ·  " + Math.round(SysStats.gpuTemp) + "°C" : "")
                    color: "#ffffff"
                    font.family: "monospace"
                    font.pixelSize: 12
                }
            }

            Spark {
                Layout.fillWidth: true
                Layout.preferredHeight: 56
                values: SysStats.gpuHist
                values2: SysStats.gpuTempHist
                live: page.active
            }

            KV {
                Layout.fillWidth: true
                visible: SysStats.gpuMemTotal > 0
                k: "VRAM"
                v: Math.round(SysStats.gpuMemUsed) + " / " + Math.round(SysStats.gpuMemTotal) + " MiB"
            }
            Meter {
                Layout.fillWidth: true
                visible: SysStats.gpuMemTotal > 0
                value: SysStats.gpuMemTotal > 0 ? SysStats.gpuMemUsed / SysStats.gpuMemTotal : 0
            }
        }

        // ── RAM ──
        Panel {
            Layout.fillWidth: true

            RowLayout {
                Layout.fillWidth: true
                Cap { text: "MEMORY" }
                Item { Layout.fillWidth: true }
                Text {
                    text: SysStats.fmtKiB(SysStats.ramUsed) + " / " + SysStats.fmtKiB(SysStats.ramTotal)
                    color: "#ffffff"
                    font.family: "monospace"
                    font.pixelSize: 12
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 14

                Donut {
                    Layout.preferredWidth: 92
                    Layout.preferredHeight: 92
                    live: page.active
                    centerText: Math.round(SysStats.ramPct) + "%"
                    subText: "RAM"
                    segments: SysStats.ramTotal > 0 ? [
                        { value: SysStats.ramUsed / SysStats.ramTotal,
                          color: SysStats.ramPct >= 90 ? "#ff7a7a" : "#e8e8e8" },
                        { value: Math.min(SysStats.ramCached, SysStats.ramTotal - SysStats.ramUsed) / SysStats.ramTotal,
                          color: "#5a5a5a" }
                    ] : []
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    KV {
                        Layout.fillWidth: true
                        k: "USED"
                        v: SysStats.fmtKiB(SysStats.ramUsed)
                    }
                    KV {
                        Layout.fillWidth: true
                        k: "CACHE"
                        v: SysStats.fmtKiB(Math.min(SysStats.ramCached, SysStats.ramTotal - SysStats.ramUsed))
                    }
                    KV {
                        Layout.fillWidth: true
                        k: "FREE"
                        v: SysStats.fmtKiB(Math.max(0, SysStats.ramTotal - SysStats.ramUsed - SysStats.ramCached))
                    }
                    KV {
                        Layout.fillWidth: true
                        visible: SysStats.swapTotal > 0
                        k: "SWAP"
                        v: SysStats.fmtKiB(SysStats.swapUsed) + " / " + SysStats.fmtKiB(SysStats.swapTotal)
                    }
                    Meter {
                        Layout.fillWidth: true
                        visible: SysStats.swapTotal > 0
                        value: SysStats.swapTotal > 0 ? SysStats.swapUsed / SysStats.swapTotal : 0
                        fill: "#9a9a9a"
                    }
                }
            }

            Spark {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                values: SysStats.ramHist
                live: page.active
            }
        }

        // ── Диски ──
        Panel {
            Layout.fillWidth: true
            visible: SysStats.diskMounts.length > 0

            RowLayout {
                Layout.fillWidth: true
                Cap { text: "DISKS" }
                Item { Layout.fillWidth: true }
                Text {
                    text: "BAR — показывать в баре"
                    color: "#555555"
                    font.family: "monospace"
                    font.pixelSize: 9
                }
            }

            Repeater {
                model: SysStats.diskMounts

                delegate: RowLayout {
                    id: diskRow
                    required property var modelData
                    readonly property var d: SysStats.diskInfo[modelData] ?? null
                    readonly property real frac: d ? d.used / d.size : 0

                    Layout.fillWidth: true
                    spacing: 10

                    Donut {
                        Layout.preferredWidth: 46
                        Layout.preferredHeight: 46
                        thickness: 6
                        centerSize: 10
                        live: page.active
                        centerText: diskRow.d ? Math.round(diskRow.frac * 100) + "" : ""
                        segments: diskRow.d ? [{ value: diskRow.frac, color: diskRow.frac >= 0.9 ? "#ff7a7a" : "#e8e8e8" }] : []
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            Layout.fillWidth: true
                            text: diskRow.modelData
                            color: "#eeeeee"
                            font.family: "monospace"
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            text: diskRow.d
                                ? SysStats.fmtBytes(diskRow.d.used) + " / " + SysStats.fmtBytes(diskRow.d.size)
                                  + " · " + diskRow.d.fs + " · " + diskRow.d.source
                                : ""
                            color: "#808080"
                            font.family: "monospace"
                            font.pixelSize: 9
                            elide: Text.ElideRight
                        }
                    }

                    Btn {
                        label: "BAR"
                        active: MonCfg.diskShown(diskRow.modelData)
                        onClicked: MonCfg.toggleDisk(diskRow.modelData)
                    }
                }
            }
        }

        // ── Батарея ──
        Panel {
            Layout.fillWidth: true
            visible: SysStats.hasBattery

            RowLayout {
                Layout.fillWidth: true
                Cap { text: "BATTERY" }
                Item { Layout.fillWidth: true }
                Text {
                    text: SysStats.batState.toUpperCase()
                    color: "#999999"
                    font.family: "monospace"
                    font.pixelSize: 10
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Text {
                    text: Math.round(SysStats.batPct) + "%"
                    color: "#ffffff"
                    font.family: "monospace"
                    font.bold: true
                    font.pixelSize: 22
                }
                Meter {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 10
                    radius: 5
                    value: SysStats.batPct / 100
                    fill: SysStats.batPct <= 15 && !SysStats.charging ? "#ff7a7a" : "#e8e8e8"
                }
            }

            KV {
                Layout.fillWidth: true
                k: SysStats.charging ? "TO FULL" : "TO EMPTY"
                v: SysStats.fmtTime(SysStats.charging ? SysStats.bat.timeToFull : SysStats.bat.timeToEmpty)
            }
            KV {
                Layout.fillWidth: true
                visible: (SysStats.bat?.changeRate ?? 0) > 0
                k: "POWER"
                v: (SysStats.bat?.changeRate ?? 0).toFixed(1) + " W"
            }
        }

        // ── Настройки бара ──
        Panel {
            Layout.fillWidth: true

            Cap { text: "IN BAR" }

            Flow {
                Layout.fillWidth: true
                Layout.preferredHeight: childrenRect.height
                spacing: 6

                Btn { label: "SHOW"; active: MonCfg.a.barEnabled; onClicked: MonCfg.toggle("barEnabled") }
                Btn { label: "CPU %"; active: MonCfg.a.barCpu; onClicked: MonCfg.toggle("barCpu") }
                Btn { label: "CPU °C"; active: MonCfg.a.barCpuTemp; onClicked: MonCfg.toggle("barCpuTemp") }
                Btn { label: "GPU %"; active: MonCfg.a.barGpu; onClicked: MonCfg.toggle("barGpu") }
                Btn { label: "GPU °C"; active: MonCfg.a.barGpuTemp; onClicked: MonCfg.toggle("barGpuTemp") }
                Btn { label: "RAM"; active: MonCfg.a.barRam; onClicked: MonCfg.toggle("barRam") }
                Btn { label: "BATTERY"; active: MonCfg.a.barBattery; onClicked: MonCfg.toggle("barBattery") }
            }

            Text {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                text: "Разделы для бара — кнопка BAR у диска. Конфиг: ~/.config/lunar/monitor.json"
                color: "#555555"
                font.family: "monospace"
                font.pixelSize: 9
            }
        }
    }
}
