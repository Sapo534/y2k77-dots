import QtQuick
import Quickshell
import Quickshell.Io

// Один экземпляр на весь шелл (создаётся в shell.qml): планировщик, будильники
// и таймер живут тут, чтобы не дублироваться на каждый монитор
// и продолжать работать, пока меню закрыто.
Scope {
    id: svc

    // ── данные (сохраняются в ~/.local/share/lunar/planner.json) ──
    property var events: []   // { id, date: "yyyy-MM-dd", time: "HH:mm" | "", text, done }
    property var alarms: []   // { id, time: "HH:mm", daily, enabled }

    // ── таймер ──
    property real nowMs: Date.now()
    property real timerTotal: 0      // сек
    property real timerEnd: 0        // ms epoch; 0 = не идёт
    property real timerPaused: 0     // сек, остаток на паузе
    readonly property bool timerRunning: timerEnd > 0
    readonly property bool timerActive: timerRunning || timerPaused > 0
    readonly property real timerLeft: timerRunning ? Math.max(0, (timerEnd - nowMs) / 1000) : timerPaused

    // ── звонок ──
    property bool ringing: false
    property string ringText: ""
    property string sound: "/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga"
    property real soundVolume: 0.01   // 0.0–1.0, громкость звонка

    property string lastMinute: ""

    // ───────── утилиты ─────────
    function uid() { return Date.now().toString(36) + Math.random().toString(36).slice(2, 6) }
    function pad(n) { return String(n).padStart(2, "0") }

    function dur(sec) {
        const s = Math.ceil(Math.max(0, sec))
        const h = Math.floor(s / 3600)
        const m = Math.floor((s % 3600) / 60)
        return (h > 0 ? h + ":" + pad(m) : pad(m)) + ":" + pad(s % 60)
    }

    // "730" / "7:30" / "07:30" → "07:30", мусор → ""
    function normTime(t) {
        const m = /^(\d{1,2}):?(\d{2})$/.exec((t || "").trim())
        if (!m) return ""
        const h = Number(m[1]), mi = Number(m[2])
        return (h < 24 && mi < 60) ? pad(h) + ":" + pad(mi) : ""
    }

    // ───────── хранилище ─────────
    function save() {
        store.setText(JSON.stringify({ events: events, alarms: alarms }, null, 1))
    }

    Process { command: ["mkdir", "-p", Quickshell.env("HOME") + "/.local/share/lunar"]; running: true }

    FileView {
        id: store
        path: Quickshell.env("HOME") + "/.local/share/lunar/planner.json"
        printErrors: false
        onLoaded: {
            try {
                const o = JSON.parse(text())
                svc.events = o.events ?? []
                svc.alarms = o.alarms ?? []
            } catch (e) {
                console.warn("planner.json:", e)
            }
        }
    }

    // ───────── планировщик ─────────
    function eventsOn(date) {
        return events.filter(e => e.date === date)
            .sort((a, b) => (a.time || "99:99").localeCompare(b.time || "99:99"))
    }
    function hasEvents(date) { return events.some(e => e.date === date && !e.done) }

    function addEvent(date, time, txt) {
        const t = (txt || "").trim()
        if (!t) return false
        events = events.concat([{ id: uid(), date: date, time: time, text: t, done: false }])
        save()
        return true
    }
    function toggleEvent(id) {
        events = events.map(e => e.id === id ? Object.assign({}, e, { done: !e.done }) : e)
        save()
    }
    function removeEvent(id) {
        events = events.filter(e => e.id !== id)
        save()
    }

    // ───────── будильники ─────────
    function addAlarm(time, daily) {
        if (!time) return false
        alarms = alarms.concat([{ id: uid(), time: time, daily: daily, enabled: true }])
            .sort((a, b) => a.time.localeCompare(b.time))
        save()
        return true
    }
    function toggleAlarm(id) {
        alarms = alarms.map(a => a.id === id ? Object.assign({}, a, { enabled: !a.enabled }) : a)
        save()
    }
    function removeAlarm(id) {
        alarms = alarms.filter(a => a.id !== id)
        save()
    }

    // ───────── таймер ─────────
    function startTimer(sec) {
        nowMs = Date.now()
        timerTotal = sec
        timerPaused = 0
        timerEnd = nowMs + sec * 1000
    }
    function pauseTimer() {
        if (!timerRunning) return
        timerPaused = Math.max(0.001, (timerEnd - Date.now()) / 1000)
        timerEnd = 0
    }
    function resumeTimer() {
        if (timerPaused <= 0) return
        nowMs = Date.now()
        timerEnd = nowMs + timerPaused * 1000
        timerPaused = 0
    }
    function resetTimer() { timerEnd = 0; timerPaused = 0; timerTotal = 0 }

    // ───────── звонок ─────────
    // Process, а не execDetached: так звук можно оборвать сразу при dismiss()
    Process {
        id: chimeProc
        command: ["pw-play", "--volume=" + svc.soundVolume, svc.sound]
    }
    function chime() { if (!chimeProc.running) chimeProc.running = true }

    function ring(title, body) {
        ringText = body ? title + " · " + body : title
        ringing = true
        Quickshell.execDetached(["notify-send", "-u", "critical", "-a", "lunar", title, body])
        chime()
    }
    function dismiss() { ringing = false; chimeProc.running = false }

    Timer { interval: 3000; repeat: true; running: svc.ringing; onTriggered: svc.chime() }
    Timer { interval: 60000; running: svc.ringing; onTriggered: svc.dismiss() }   // сам замолчит через минуту

    // ───────── тик раз в секунду ─────────
    function tick(d) {
        nowMs = Date.now()

        if (timerEnd > 0 && nowMs >= timerEnd) {
            resetTimer()
            ring("Таймер", "Время вышло")
        }

        const key = Qt.formatDateTime(d, "yyyy-MM-dd HH:mm")
        if (key === lastMinute) return
        lastMinute = key
        const day = key.slice(0, 10)
        const hm = key.slice(11)

        const hit = alarms.filter(a => a.enabled && a.time === hm)
        if (hit.length > 0) {
            ring("Будильник", hm)
            if (hit.some(a => !a.daily)) {
                alarms = alarms.map(a => (a.enabled && a.time === hm && !a.daily)
                    ? Object.assign({}, a, { enabled: false }) : a)
                save()
            }
        }

        for (const e of events)
            if (!e.done && e.date === day && e.time === hm)
                ring("Событие", e.text)
    }

    SystemClock {
        precision: SystemClock.Seconds
        onDateChanged: svc.tick(date)
    }

    Component.onCompleted: lastMinute = Qt.formatDateTime(new Date(), "yyyy-MM-dd HH:mm")
}
