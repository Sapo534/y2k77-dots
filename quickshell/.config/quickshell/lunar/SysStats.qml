pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

// Общий сборщик метрик для бара и вкладки MONITOR (один на все мониторы).
Singleton {
    id: root

    readonly property int points: 60        // длина истории, 1 точка = 1 сек
    property bool pageActive: false         // выставляет MonitorPage, пока вкладка открыта

    // ── CPU ──
    property real cpu: 0                    // 0..100
    property var cores: []                  // по ядрам, 0..100
    readonly property int coreCount: cores.length
    property real cpuTemp: -1               // °C, -1 = нет датчика
    property string cpuModel: ""
    property var cpuHist: []
    property var cpuTempHist: []

    // ── GPU ──
    property bool hasGpu: false
    property string gpuName: ""
    property real gpu: 0
    property real gpuTemp: -1
    property real gpuMemUsed: 0             // MiB
    property real gpuMemTotal: 0
    property var gpuHist: []
    property var gpuTempHist: []

    // ── RAM ──
    property real ramTotal: 0               // KiB
    property real ramUsed: 0
    property real ramCached: 0
    property real swapTotal: 0
    property real swapUsed: 0
    readonly property real ramPct: ramTotal > 0 ? ramUsed / ramTotal * 100 : 0
    property var ramHist: []

    // ── Диски ──
    property var diskMounts: []             // меняется только когда набор точек поменялся
    property var diskInfo: ({})             // mount -> { source, fs, size, used } (байты)

    // ── Батарея ──
    readonly property var bat: UPower.displayDevice
    readonly property bool hasBattery: bat?.isPresent ?? false
    readonly property real batPct: hasBattery ? bat.percentage * 100 : 0
    readonly property bool charging: hasBattery && bat.state === UPowerDeviceState.Charging
    readonly property string batState: !hasBattery ? ""
        : bat.state === UPowerDeviceState.Charging ? "Charging"
        : bat.state === UPowerDeviceState.FullyCharged ? "Full"
        : "Discharging"

    // GPU опрашиваем только когда он реально нужен (nvidia-smi будит dGPU на ноутах)
    readonly property bool wantGpu: pageActive
        || (MonCfg.a.barEnabled && (MonCfg.a.barGpu || MonCfg.a.barGpuTemp))
    onWantGpuChanged: if (wantGpu) gpuProc.running = true

    property string cpuTempDir: ""
    property int tickCount: 0
    property var prevStat: []

    // ── helpers ──
    function push(arr, v) {
        const n = arr.concat([v])
        return n.length > points ? n.slice(n.length - points) : n
    }

    function fmtBytes(b) {
        const u = ["B", "KiB", "MiB", "GiB", "TiB"]
        let i = 0
        while (b >= 1024 && i < u.length - 1) { b /= 1024; i++ }
        return (i >= 3 ? b.toFixed(1) : Math.round(b)) + " " + u[i]
    }
    function fmtKiB(k) { return fmtBytes(k * 1024) }
    function fmtTime(s) {
        if (!s || s <= 0) return "—"
        const h = Math.floor(s / 3600)
        const m = Math.floor((s % 3600) / 60)
        return h > 0 ? h + "h " + m + "m" : m + "m"
    }

    // ── парсеры ──
    function parseStat(text) {
        const cur = []
        for (const l of text.split("\n")) {
            if (!l.startsWith("cpu")) break
            const v = l.trim().split(/\s+/).slice(1, 9).map(Number)
            cur.push({ total: v.reduce((x, y) => x + y, 0), idle: v[3] + (v[4] || 0) })
        }
        if (prevStat.length === cur.length && cur.length > 0) {
            const u = cur.map((c, i) => {
                const dt = c.total - prevStat[i].total
                const di = c.idle - prevStat[i].idle
                return dt > 0 ? Math.max(0, Math.min(100, 100 * (1 - di / dt))) : 0
            })
            cpu = u[0]
            cores = u.slice(1)
        }
        prevStat = cur
    }

    function parseMem(text) {
        const m = {}
        for (const l of text.split("\n")) {
            const i = l.indexOf(":")
            if (i > 0) m[l.slice(0, i)] = parseInt(l.slice(i + 1))
        }
        ramTotal = m.MemTotal || 0
        ramUsed = ramTotal - (m.MemAvailable || 0)
        ramCached = (m.Cached || 0) + (m.Buffers || 0)
        swapTotal = m.SwapTotal || 0
        swapUsed = swapTotal - (m.SwapFree || 0)
    }

    function parseGpu(text) {
        const p = text.trim().split(",").map(s => s.trim())
        if (p.length < 5) { hasGpu = false; return }
        const n = s => { const v = Number(s); return isNaN(v) ? -1 : v }
        hasGpu = true
        gpuName = p[0]
        gpu = Math.max(0, n(p[1]))
        gpuTemp = n(p[2])
        gpuMemUsed = Math.max(0, n(p[3]))
        gpuMemTotal = Math.max(0, n(p[4]))
    }

    function parseDisks(text) {
        const info = {}
        const mounts = []
        const seen = {}
        const skip = ["/run", "/var/lib/docker", "/var/lib/containers", "/snap", "/nix/store"]
        for (const line of text.trim().split("\n").slice(1)) {
            const p = line.trim().split(/\s+/)
            if (p.length < 5) continue
            const src = p[0]
            if (!src.startsWith("/dev/") || src.startsWith("/dev/loop")) continue
            if (seen[src]) continue                 // сабвольюмы btrfs и т.п. — одна запись
            const mount = p.slice(4).join(" ")
            if (skip.some(s => mount.startsWith(s))) continue
            const size = Number(p[2])
            if (!(size > 0)) continue
            seen[src] = true
            mounts.push(mount)
            info[mount] = { source: src, fs: p[1], size: size, used: Number(p[3]) }
        }
        if (JSON.stringify(mounts) !== JSON.stringify(diskMounts)) diskMounts = mounts
        diskInfo = info
    }

    function sample() {
        statFile.reload()
        memFile.reload()
        if (cpuTempDir !== "") tempFile.reload()
        tickCount++
        if (wantGpu && tickCount % 2 === 0) gpuProc.running = true

        cpuHist = push(cpuHist, cpu)
        ramHist = push(ramHist, ramPct)
        if (cpuTemp >= 0) cpuTempHist = push(cpuTempHist, cpuTemp)
        if (wantGpu && hasGpu) {
            gpuHist = push(gpuHist, gpu)
            if (gpuTemp >= 0) gpuTempHist = push(gpuTempHist, gpuTemp)
        }
    }

    // ── источники ──
    FileView { id: statFile; path: "/proc/stat"; onLoaded: root.parseStat(text()) }
    FileView { id: memFile; path: "/proc/meminfo"; onLoaded: root.parseMem(text()) }

    FileView {
        path: "/proc/cpuinfo"
        onLoaded: {
            const m = /model name\s*:\s*(.+)/.exec(text())
            if (m) root.cpuModel = m[1].replace(/\((R|TM)\)/g, "").replace(/\s+/g, " ").trim()
        }
    }

    // Датчик CPU: coretemp (Intel) / k10temp (AMD)
    Process {
        running: true
        command: ["sh", "-c",
            "for d in /sys/class/hwmon/hwmon*; do case \"$(cat $d/name 2>/dev/null)\" in coretemp|k10temp|zenpower|cpu_thermal) echo $d; break;; esac; done"]
        stdout: StdioCollector { onStreamFinished: root.cpuTempDir = text.trim() }
    }
    FileView {
        id: tempFile
        path: root.cpuTempDir !== "" ? root.cpuTempDir + "/temp1_input" : ""
        onLoaded: root.cpuTemp = Number(text().trim()) / 1000
    }

    Process {
        id: gpuProc
        command: ["sh", Quickshell.shellPath("scripts/gpu.sh")]
        stdout: StdioCollector { onStreamFinished: root.parseGpu(text) }
    }

    Process {
        id: diskProc
        command: ["df", "-B1", "--output=source,fstype,size,used,target",
                  "-x", "tmpfs", "-x", "devtmpfs", "-x", "efivarfs", "-x", "squashfs", "-x", "overlay"]
        stdout: StdioCollector { onStreamFinished: root.parseDisks(text) }
    }

    Timer { interval: 1000; repeat: true; running: true; triggeredOnStart: true; onTriggered: root.sample() }
    Timer { interval: 10000; repeat: true; running: true; triggeredOnStart: true; onTriggered: diskProc.running = true }
}
