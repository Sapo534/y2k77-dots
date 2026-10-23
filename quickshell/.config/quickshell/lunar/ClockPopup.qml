import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

PopupWindow {
    id: cp

    required property var barWindow
    required property var svc
    property bool open: false
    property bool hold: false      // true на время скриншота: отпускаем grab, чтобы не закрыться
    property int tab: 0
    signal requestClose()

    // ── календарь ──
    function fmtDate(d) { return Qt.formatDate(d, "yyyy-MM-dd") }
    function firstOfMonth(d) { return new Date(d.getFullYear(), d.getMonth(), 1) }
    // сетка с понедельника, 6 недель
    function cellDate(i) {
        const f = viewMonth
        const off = (f.getDay() + 6) % 7
        return new Date(f.getFullYear(), f.getMonth(), 1 - off + i)
    }

    property date viewMonth: firstOfMonth(new Date())
    property string selected: fmtDate(new Date())
    readonly property string today: fmtDate(new Date(svc.nowMs))

    onOpenChanged: if (open) {
        const n = new Date()
        viewMonth = firstOfMonth(n)
        selected = fmtDate(n)
    }

    anchor.window: barWindow
    anchor.rect.x: barWindow.width - width - 12
    anchor.rect.y: barWindow.height + 8

    implicitWidth: 400
    implicitHeight: 580
    visible: open || card.opacity > 0.01
    color: "transparent"

    HyprlandFocusGrab {
        windows: [cp, cp.barWindow]
        active: cp.open && !cp.hold
        onCleared: cp.requestClose()
    }

    Rectangle {
        id: card
        anchors.fill: parent
        anchors.margins: 1
        radius: 11
        color: "#101010"
        border.width: 1
        border.color: "#383838"

        opacity: cp.open ? 1 : 0
        scale: cp.open ? 1 : 0.97
        Behavior on opacity { NumberAnimation { duration: 140 } }
        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 17
            spacing: 10

            // ── шапка ──
            RowLayout {
                Layout.fillWidth: true

                ColumnLayout {
                    spacing: 3
                    Text {
                        text: "TIME & PLANNER"
                        color: "#f2f2f2"
                        font.family: "monospace"
                        font.bold: true
                        font.letterSpacing: 1.2
                        font.pixelSize: 13
                    }
                    Text {
                        text: Qt.formatDate(new Date(cp.svc.nowMs), "dddd, d MMMM yyyy").toUpperCase()
                        color: "#666666"
                        font.family: "monospace"
                        font.pixelSize: 9
                        font.letterSpacing: 0.8
                    }
                }

                Item { Layout.fillWidth: true }
                Btn { label: "×"; implicitWidth: 28; onClicked: cp.requestClose() }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                Btn { label: "CALENDAR"; active: cp.tab === 0; onClicked: cp.tab = 0 }
                Btn { label: "CLOCK"; active: cp.tab === 1; onClicked: cp.tab = 1 }
                Item { Layout.fillWidth: true }
            }

            // Звонит — заглушить (виден на обеих вкладках)
            Btn {
                Layout.fillWidth: true
                visible: cp.svc.ringing
                active: true
                label: "■ STOP — " + cp.svc.ringText
                onClicked: cp.svc.dismiss()
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#292929" }

            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: cp.tab

                // ════════ CALENDAR + PLANNER ════════
                ColumnLayout {
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Btn {
                            label: "‹"
                            implicitWidth: 28
                            onClicked: cp.viewMonth = new Date(cp.viewMonth.getFullYear(), cp.viewMonth.getMonth() - 1, 1)
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: Qt.formatDate(cp.viewMonth, "MMMM yyyy").toUpperCase()
                            color: "#eeeeee"
                            font.family: "monospace"
                            font.letterSpacing: 1.2
                            font.pixelSize: 12
                        }
                        Item { Layout.fillWidth: true }
                        Btn {
                            label: "TODAY"
                            onClicked: {
                                const n = new Date()
                                cp.viewMonth = cp.firstOfMonth(n)
                                cp.selected = cp.fmtDate(n)
                            }
                        }
                        Btn {
                            label: "›"
                            implicitWidth: 28
                            onClicked: cp.viewMonth = new Date(cp.viewMonth.getFullYear(), cp.viewMonth.getMonth() + 1, 1)
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 7
                        columnSpacing: 2
                        rowSpacing: 2

                        Repeater {
                            model: ["MO", "TU", "WE", "TH", "FR", "SA", "SU"]
                            delegate: Text {
                                required property string modelData
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                text: modelData
                                color: "#666666"
                                font.family: "monospace"
                                font.pixelSize: 9
                                font.letterSpacing: 1
                            }
                        }

                        Repeater {
                            model: 42
                            delegate: Rectangle {
                                id: cell
                                required property int index
                                readonly property var d: cp.cellDate(index)
                                readonly property string key: cp.fmtDate(d)
                                readonly property bool sel: key === cp.selected
                                readonly property bool inMonth: d.getMonth() === cp.viewMonth.getMonth()

                                Layout.fillWidth: true
                                Layout.preferredHeight: 30
                                radius: 5
                                color: sel ? "#e8e8e8" : (cm.containsMouse ? "#242424" : "transparent")
                                border.width: (key === cp.today && !sel) ? 1 : 0
                                border.color: "#777777"

                                Text {
                                    anchors.centerIn: parent
                                    text: cell.d.getDate()
                                    color: cell.sel ? "#111111" : (cell.inMonth ? "#dddddd" : "#555555")
                                    font.family: "monospace"
                                    font.pixelSize: 11
                                }

                                // точка: в этот день есть невыполненные дела
                                Rectangle {
                                    visible: cp.svc.hasEvents(cell.key)
                                    width: 4
                                    height: 4
                                    radius: 2
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 3
                                    color: cell.sel ? "#111111" : "#e8e8e8"
                                }

                                MouseArea {
                                    id: cm
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: cp.selected = cell.key
                                }
                            }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: "#292929" }

                    Text {
                        text: "PLANNER · " + Qt.formatDate(new Date(cp.selected + "T00:00:00"), "dd MMM").toUpperCase()
                        color: "#777777"
                        font.family: "monospace"
                        font.letterSpacing: 1.4
                        font.pixelSize: 9
                    }

                    Flickable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        contentWidth: width
                        contentHeight: evCol.implicitHeight
                        boundsBehavior: Flickable.StopAtBounds

                        ColumnLayout {
                            id: evCol
                            width: parent.width
                            spacing: 6

                            Repeater {
                                model: cp.svc.eventsOn(cp.selected)

                                delegate: ListRow {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    implicitHeight: 34
                                    title: (modelData.time ? modelData.time + "  " : "") + modelData.text
                                    trailing: modelData.done ? "✓" : ""
                                    opacity: modelData.done ? 0.5 : 1
                                    onClicked: cp.svc.toggleEvent(modelData.id)
                                    onSecondaryClicked: cp.svc.removeEvent(modelData.id)
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                wrapMode: Text.Wrap
                                text: cp.svc.eventsOn(cp.selected).length === 0
                                    ? "На этот день пусто."
                                    : "ЛКМ — выполнено, ПКМ — удалить."
                                color: "#555555"
                                font.family: "monospace"
                                font.pixelSize: 9
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Field {
                            id: evTime
                            Layout.preferredWidth: 62
                            placeholder: "HH:MM"
                            maxLength: 5
                            onAccepted: evText.focusInput()
                        }
                        Field {
                            id: evText
                            Layout.fillWidth: true
                            placeholder: "Новое дело…"
                            onAccepted: addEv.clicked()
                        }
                        Btn {
                            id: addEv
                            label: "ADD"
                            onClicked: {
                                // пустое время = дело на весь день; кривое — не добавляем
                                const raw = evTime.text.trim()
                                const t = raw === "" ? "" : cp.svc.normTime(raw)
                                if (raw !== "" && t === "") return
                                if (cp.svc.addEvent(cp.selected, t, evText.text)) {
                                    evText.clear()
                                    evTime.clear()
                                }
                            }
                        }
                    }
                }

                // ════════ CLOCK + TIMER + ALARMS ════════
                Flickable {
                    id: clockPage
                    clip: true
                    contentWidth: width
                    contentHeight: clockCol.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: clockCol
                        width: clockPage.width
                        spacing: 8

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: Qt.formatTime(new Date(cp.svc.nowMs), "HH:mm:ss")
                            color: "#ffffff"
                            font.family: "monospace"
                            font.pixelSize: 38
                            font.bold: true
                        }

                        Rectangle { Layout.fillWidth: true; Layout.topMargin: 4; height: 1; color: "#292929" }

                        // ── таймер ──
                        Text {
                            text: "TIMER"
                            color: "#777777"
                            font.family: "monospace"
                            font.letterSpacing: 1.4
                            font.pixelSize: 9
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            visible: cp.svc.timerActive
                            spacing: 8

                            Text {
                                text: cp.svc.dur(cp.svc.timerLeft)
                                color: "#ffffff"
                                opacity: cp.svc.timerRunning ? 1 : 0.5
                                font.family: "monospace"
                                font.pixelSize: 24
                            }

                            Item { Layout.fillWidth: true }

                            Btn {
                                label: cp.svc.timerRunning ? "PAUSE" : "RESUME"
                                onClicked: cp.svc.timerRunning ? cp.svc.pauseTimer() : cp.svc.resumeTimer()
                            }
                            Btn { label: "RESET"; onClicked: cp.svc.resetTimer() }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            visible: cp.svc.timerActive
                            height: 4
                            radius: 2
                            color: "#292929"

                            Rectangle {
                                height: parent.height
                                radius: 2
                                color: "#e8e8e8"
                                width: cp.svc.timerTotal > 0
                                    ? Math.min(1, cp.svc.timerLeft / cp.svc.timerTotal) * parent.width : 0
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Repeater {
                                model: [1, 5, 10, 25]
                                delegate: Btn {
                                    required property int modelData
                                    label: modelData + " MIN"
                                    onClicked: cp.svc.startTimer(modelData * 60)
                                }
                            }

                            Item { Layout.fillWidth: true }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Field {
                                id: tmMin
                                Layout.preferredWidth: 90
                                placeholder: "минуты"
                                maxLength: 5
                                onAccepted: tmGo.clicked()
                            }
                            Btn {
                                id: tmGo
                                label: "START"
                                onClicked: {
                                    const m = parseFloat(tmMin.text.replace(",", "."))
                                    if (m > 0) {
                                        cp.svc.startTimer(m * 60)
                                        tmMin.clear()
                                    }
                                }
                            }
                            Item { Layout.fillWidth: true }
                        }

                        Rectangle { Layout.fillWidth: true; Layout.topMargin: 4; height: 1; color: "#292929" }

                        // ── будильники ──
                        Text {
                            text: "ALARMS"
                            color: "#777777"
                            font.family: "monospace"
                            font.letterSpacing: 1.4
                            font.pixelSize: 9
                        }

                        Repeater {
                            model: cp.svc.alarms

                            delegate: ListRow {
                                required property var modelData
                                Layout.fillWidth: true
                                title: modelData.time
                                subtitle: modelData.daily ? "Каждый день" : "Один раз"
                                trailing: modelData.enabled ? "ON" : "OFF"
                                highlighted: modelData.enabled
                                onClicked: cp.svc.toggleAlarm(modelData.id)
                                onSecondaryClicked: cp.svc.removeAlarm(modelData.id)
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            text: cp.svc.alarms.length === 0
                                ? "Будильников нет."
                                : "ЛКМ — вкл/выкл, ПКМ — удалить."
                            color: "#555555"
                            font.family: "monospace"
                            font.pixelSize: 9
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Field {
                                id: alTime
                                Layout.preferredWidth: 70
                                placeholder: "HH:MM"
                                maxLength: 5
                                onAccepted: alGo.clicked()
                            }
                            Btn {
                                id: alDaily
                                property bool daily: true
                                label: daily ? "DAILY" : "ONCE"
                                active: daily
                                onClicked: daily = !daily
                            }
                            Btn {
                                id: alGo
                                label: "ADD"
                                onClicked: {
                                    if (cp.svc.addAlarm(cp.svc.normTime(alTime.text), alDaily.daily))
                                        alTime.clear()
                                }
                            }
                            Item { Layout.fillWidth: true }
                        }
                    }
                }
            }
        }
    }
}
