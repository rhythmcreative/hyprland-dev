import QtQuick
import QtQuick.Layouts

Item {
    id: panel

    required property var rootRef
    required property var winRef

    // Pywal-grounded monochrome + restrained semantic palette
    readonly property color colBg: rootRef ? rootRef.colBg : "#1e2130"
    readonly property color colFg: rootRef ? rootRef.colFg : "#dde2ea"
    readonly property color colAccent: rootRef ? rootRef.colAccent : "#9cb2ce"
    readonly property color colRam: (rootRef && rootRef.walData && rootRef.walData.colors && rootRef.walData.colors.color5)
                                    ? rootRef.walData.colors.color5 : colAccent
    readonly property color colDisk: (rootRef && rootRef.walData && rootRef.walData.colors && rootRef.walData.colors.color6)
                                     ? rootRef.walData.colors.color6 : colAccent
    readonly property color colWarm: (rootRef && rootRef.walData && rootRef.walData.colors && rootRef.walData.colors.color3)
                                     ? rootRef.walData.colors.color3 : "#e5c07b"
    readonly property color colHot: "#e06c75"

    readonly property color colSubtle: Qt.rgba(colFg.r, colFg.g, colFg.b, 0.56)
    readonly property color colDim: Qt.rgba(colFg.r, colFg.g, colFg.b, 0.34)
    readonly property color colRule: Qt.rgba(colFg.r, colFg.g, colFg.b, 0.09)
    readonly property color colRowRule: Qt.rgba(colFg.r, colFg.g, colFg.b, 0.055)
    readonly property color colTrack: Qt.rgba(colFg.r, colFg.g, colFg.b, 0.08)
    readonly property color colHover: Qt.rgba(colFg.r, colFg.g, colFg.b, 0.055)

    readonly property string monoFont: "JetBrainsMono Nerd Font"

    // Reactive telemetry from rootRef.sysMonData
    readonly property var d: rootRef ? rootRef.sysMonData : null
    readonly property int cpuPct: d?.cpu?.total_pct ?? 0
    readonly property real cpuFreq: d?.cpu?.freq_ghz ?? 0
    readonly property int cpuTemp: d?.cpu?.temp_c ?? 0
    readonly property string cpuModel: d?.cpu?.short_model || d?.cpu?.model || "Processor"
    readonly property int coresCount: d?.cpu?.cores_count ?? 0
    readonly property var cpuCores: d?.cpu?.cores || []
    readonly property var cpuHistory: d?.cpu?.history || []
    readonly property string loadAvg: d?.cpu?.load_avg || d?.system?.load_avg || ""

    readonly property int ramPct: d?.ram?.pct ?? 0
    readonly property string ramStr: d?.ram?.str || "0.0 / 0.0G"
    readonly property int swapPct: d?.swap?.pct ?? 0
    readonly property string swapStr: d?.swap?.str || "off"
    readonly property int diskPct: d?.disk?.pct ?? 0
    readonly property string diskStr: d?.disk?.str || "0 / 0G"

    readonly property var gpuDevices: d?.gpu?.devices || []
    readonly property string uptimeStr: d?.system?.uptime || "0m"
    readonly property string kernelShort: d?.system?.kernel_short || d?.system?.kernel || ""
    readonly property int tasksTotal: d?.system?.tasks_total ?? 0

    readonly property string sortTab: winRef ? winRef.sysMonProcTab : "cpu"
    readonly property var activeProcs: (sortTab === "cpu" ? (d?.procs_cpu || []) : (d?.procs_mem || [])).slice(0, 6)

    property int hoveredCore: -1
    property string confirmKillPid: ""

    Timer {
        id: confirmResetTimer
        interval: 2800
        onTriggered: panel.confirmKillPid = ""
    }

    onCpuHistoryChanged: cpuCanvas.requestPaint()
    onVisibleChanged: if (visible) cpuCanvas.requestPaint()

    function loadColor(pct, baseCol) {
        if (pct >= 88) return panel.colHot
        if (pct >= 72) return panel.colWarm
        return baseCol
    }

    function tempColor(t) {
        if (t >= 85) return panel.colHot
        if (t >= 72) return panel.colWarm
        return panel.colFg
    }

    function pad2(n) {
        return n < 10 ? ("0" + n) : String(n)
    }

    readonly property int peakCorePct: {
        let m = 0
        for (let i = 0; i < cpuCores.length; i++) {
            if ((cpuCores[i].pct || 0) > m) m = cpuCores[i].pct || 0
        }
        return m
    }

    readonly property int graphYMax: {
        let peak = 0
        const hist = cpuHistory || []
        for (let i = 0; i < hist.length; i++) {
            const v = Number(hist[i]) || 0
            if (v > peak) peak = v
        }
        if (peak <= 28) return 40
        if (peak <= 48) return 60
        if (peak <= 68) return 80
        return 100
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 9

        // ── 1. Compact Hardware Header ───────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 22
            spacing: 6

            Text {
                text: panel.cpuModel
                color: panel.colFg
                font.family: panel.monoFont
                font.pixelSize: 11
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                text: "·"
                color: panel.colDim
                font.family: panel.monoFont
                font.pixelSize: 10
            }

            Text {
                Layout.fillWidth: true
                text: "up " + panel.uptimeStr + (panel.kernelShort ? (" · " + panel.kernelShort) : "")
                color: panel.colSubtle
                font.family: panel.monoFont
                font.pixelSize: 10
                elide: Text.ElideRight
            }

            // Quiet TUI launcher (btop / htop fallback)
            Rectangle {
                implicitWidth: tuiRow.implicitWidth + 10
                implicitHeight: 20
                radius: 4
                color: tuiMouse.containsMouse ? panel.colHover : "transparent"
                Behavior on color { ColorAnimation { duration: 110 } }

                RowLayout {
                    id: tuiRow
                    anchors.centerIn: parent
                    spacing: 4
                    Text {
                        text: "󰆍"
                        color: tuiMouse.containsMouse ? panel.colFg : panel.colSubtle
                        font.family: panel.monoFont
                        font.pixelSize: 11
                    }
                    Text {
                        text: "btop"
                        color: tuiMouse.containsMouse ? panel.colFg : panel.colSubtle
                        font.family: panel.monoFont
                        font.pixelSize: 10
                        font.weight: Font.Medium
                    }
                }

                MouseArea {
                    id: tuiMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (winRef) winRef.sysMonExpanded = false
                        if (rootRef) rootRef.runCmd("kitty -e sh -c 'command -v btop >/dev/null 2>&1 && exec btop || exec htop'")
                    }
                }
            }

            // Quiet close button
            Rectangle {
                implicitWidth: 20
                implicitHeight: 20
                radius: 4
                color: closeMouse.containsMouse ? panel.colHover : "transparent"
                Behavior on color { ColorAnimation { duration: 110 } }

                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    color: closeMouse.containsMouse ? panel.colFg : panel.colSubtle
                    font.family: panel.monoFont
                    font.pixelSize: 10
                }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (winRef) winRef.sysMonExpanded = false
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: panel.colRule
        }

        // ── 2. Live CPU Telemetry (Hero + Area Graph + Core Equalizer) ───────
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 7

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: panel.cpuPct + "%"
                    color: panel.loadColor(panel.cpuPct, panel.colFg)
                    font.family: panel.monoFont
                    font.pixelSize: 22
                    font.weight: Font.Bold
                }

                RowLayout {
                    spacing: 6
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        text: "CPU"
                        color: panel.colDim
                        font.family: panel.monoFont
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.0
                    }
                    Text {
                        text: panel.cpuFreq.toFixed(2) + " GHz"
                        color: panel.colFg
                        font.family: panel.monoFont
                        font.pixelSize: 10
                        font.weight: Font.Medium
                    }
                    Text {
                        visible: panel.cpuTemp > 0
                        text: "·"
                        color: panel.colDim
                        font.family: panel.monoFont
                        font.pixelSize: 10
                    }
                    Text {
                        visible: panel.cpuTemp > 0
                        text: panel.cpuTemp + "°C"
                        color: panel.tempColor(panel.cpuTemp)
                        font.family: panel.monoFont
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }
                }

                Item { Layout.fillWidth: true }

                Text {
                    visible: panel.loadAvg.length > 0
                    text: "load " + panel.loadAvg
                    color: panel.colSubtle
                    font.family: panel.monoFont
                    font.pixelSize: 9
                }
            }

            // Full-width live area sparkline with smart dynamic Y-scale
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 52

                Canvas {
                    id: cpuCanvas
                    anchors.fill: parent
                    antialiasing: true
                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()

                    onPaint: {
                        const ctx = getContext("2d")
                        const w = width
                        const h = height
                        ctx.clearRect(0, 0, w, h)
                        if (w <= 4 || h <= 4) return

                        const padTop = 5
                        const padBot = 2
                        const drawH = h - padTop - padBot
                        const fg = panel.colFg
                        const acc = panel.loadColor(panel.cpuPct, panel.colAccent)
                        const yMax = panel.graphYMax

                        // Subtle 50% and baseline hairlines
                        ctx.strokeStyle = Qt.rgba(fg.r, fg.g, fg.b, 0.06)
                        ctx.lineWidth = 1
                        ctx.beginPath()
                        const midY = Math.round(padTop + drawH * 0.5) + 0.5
                        ctx.moveTo(0, midY)
                        ctx.lineTo(w, midY)
                        ctx.stroke()

                        ctx.strokeStyle = Qt.rgba(fg.r, fg.g, fg.b, 0.11)
                        ctx.beginPath()
                        const baseY = Math.round(h - padBot) + 0.5
                        ctx.moveTo(0, baseY)
                        ctx.lineTo(w, baseY)
                        ctx.stroke()

                        const hist = panel.cpuHistory || []
                        if (hist.length === 0) return

                        const slots = 36
                        const count = hist.length
                        const stepX = w / (slots - 1)
                        const pts = []

                        for (let i = 0; i < count; i++) {
                            const slotIdx = (slots - count) + i
                            const val = Math.max(0, Math.min(yMax, Number(hist[i]) || 0))
                            pts.push({
                                x: slotIdx * stepX,
                                y: padTop + drawH * (1.0 - val / yMax)
                            })
                        }

                        if (pts.length === 1) {
                            pts.unshift({ x: Math.max(0, pts[0].x - stepX * 2), y: pts[0].y })
                        }

                        const grad = ctx.createLinearGradient(0, padTop, 0, h - padBot)
                        grad.addColorStop(0.0, Qt.rgba(acc.r, acc.g, acc.b, 0.25))
                        grad.addColorStop(1.0, Qt.rgba(acc.r, acc.g, acc.b, 0.01))

                        ctx.beginPath()
                        ctx.moveTo(pts[0].x, h - padBot)
                        ctx.lineTo(pts[0].x, pts[0].y)
                        for (let i = 1; i < pts.length; i++) {
                            const xc = (pts[i - 1].x + pts[i].x) * 0.5
                            const yc = (pts[i - 1].y + pts[i].y) * 0.5
                            ctx.quadraticCurveTo(pts[i - 1].x, pts[i - 1].y, xc, yc)
                        }
                        const last = pts[pts.length - 1]
                        ctx.lineTo(last.x, last.y)
                        ctx.lineTo(last.x, h - padBot)
                        ctx.closePath()
                        ctx.fillStyle = grad
                        ctx.fill()

                        ctx.beginPath()
                        ctx.moveTo(pts[0].x, pts[0].y)
                        for (let i = 1; i < pts.length; i++) {
                            const xc = (pts[i - 1].x + pts[i].x) * 0.5
                            const yc = (pts[i - 1].y + pts[i].y) * 0.5
                            ctx.quadraticCurveTo(pts[i - 1].x, pts[i - 1].y, xc, yc)
                        }
                        ctx.lineTo(last.x, last.y)
                        ctx.strokeStyle = Qt.rgba(acc.r, acc.g, acc.b, 0.92)
                        ctx.lineWidth = 1.5
                        ctx.stroke()

                        ctx.beginPath()
                        ctx.arc(last.x - 1, last.y, 2.3, 0, Math.PI * 2)
                        ctx.fillStyle = acc
                        ctx.fill()
                    }
                }

                Text {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    text: panel.graphYMax + "%"
                    color: Qt.rgba(panel.colFg.r, panel.colFg.g, panel.colFg.b, 0.24)
                    font.family: panel.monoFont
                    font.pixelSize: 8
                }
            }

            // Per-Core Vertical Equalizer Strip
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    Text {
                        text: {
                            if (panel.hoveredCore >= 0 && panel.hoveredCore < panel.cpuCores.length) {
                                return "CORE " + panel.pad2(panel.hoveredCore + 1) + "  " + (panel.cpuCores[panel.hoveredCore].pct ?? 0) + "%"
                            }
                            return (panel.coresCount > 0 ? panel.coresCount : panel.cpuCores.length) + " THREADS"
                        }
                        color: panel.hoveredCore >= 0 ? panel.colFg : panel.colDim
                        font.family: panel.monoFont
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.9
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "peak " + panel.peakCorePct + "%"
                        color: panel.colDim
                        font.family: panel.monoFont
                        font.pixelSize: 9
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 24
                    spacing: panel.cpuCores.length > 20 ? 2 : 3

                    Repeater {
                        model: panel.cpuCores

                        delegate: Item {
                            required property var modelData
                            required property int index
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            readonly property int pct: Math.max(0, Math.min(100, modelData.pct ?? 0))
                            readonly property int scaleCap: Math.max(50, panel.peakCorePct)
                            readonly property bool isHov: coreHover.containsMouse

                            Rectangle {
                                anchors.fill: parent
                                radius: 2
                                color: isHov ? Qt.rgba(panel.colFg.r, panel.colFg.g, panel.colFg.b, 0.14) : panel.colTrack
                            }

                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                height: Math.max(2, Math.round(parent.height * Math.min(1.0, pct / scaleCap)))
                                radius: 2
                                color: panel.loadColor(pct, panel.colAccent)
                                opacity: isHov ? 1.0 : (pct > 3 ? (0.52 + 0.45 * Math.min(1.0, pct / scaleCap)) : 0.34)
                                Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                            }

                            MouseArea {
                                id: coreHover
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: panel.hoveredCore = index
                                onExited: if (panel.hoveredCore === index) panel.hoveredCore = -1
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: panel.colRule
        }

        // ── 3. Flat 3-Column Metrics Strip (MEM · SWAP · DISK) + GPUs ────────
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 14

                // MEM
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Text {
                            text: "MEM"
                            color: panel.colDim
                            font.family: panel.monoFont
                            font.pixelSize: 9
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.9
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: panel.ramStr
                            color: panel.colFg
                            font.family: panel.monoFont
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 3
                        radius: 1
                        color: panel.colTrack
                        Rectangle {
                            width: Math.max(2, parent.width * Math.min(100, panel.ramPct) / 100)
                            height: parent.height
                            radius: 1
                            color: panel.loadColor(panel.ramPct, panel.colRam)
                            Behavior on width { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                        }
                    }
                }

                // SWAP
                ColumnLayout {
                    Layout.preferredWidth: 108
                    spacing: 4
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Text {
                            text: "SWAP"
                            color: panel.colDim
                            font.family: panel.monoFont
                            font.pixelSize: 9
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.9
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: panel.swapStr
                            color: panel.swapPct > 0 ? panel.colFg : panel.colSubtle
                            font.family: panel.monoFont
                            font.pixelSize: 10
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 3
                        radius: 1
                        color: panel.colTrack
                        Rectangle {
                            width: panel.swapPct > 0 ? Math.max(2, parent.width * Math.min(100, panel.swapPct) / 100) : 0
                            height: parent.height
                            radius: 1
                            color: panel.colRam
                            opacity: 0.7
                            Behavior on width { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                        }
                    }
                }

                // DISK /
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Text {
                            text: "DISK /"
                            color: panel.colDim
                            font.family: panel.monoFont
                            font.pixelSize: 9
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.9
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: panel.diskStr
                            color: panel.colFg
                            font.family: panel.monoFont
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 3
                        radius: 1
                        color: panel.colTrack
                        Rectangle {
                            width: Math.max(2, parent.width * Math.min(100, panel.diskPct) / 100)
                            height: parent.height
                            radius: 1
                            color: panel.loadColor(panel.diskPct, panel.colDisk)
                            Behavior on width { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                        }
                    }
                }
            }

            // Subtle divider before GPUs
            Rectangle {
                visible: panel.gpuDevices.length > 0
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: panel.colRowRule
            }

            // Single-line compact GPU telemetry rows (D3cold sleep-aware)
            ColumnLayout {
                visible: panel.gpuDevices.length > 0
                Layout.fillWidth: true
                spacing: 4

                Repeater {
                    model: panel.gpuDevices.slice(0, 2)

                    delegate: RowLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 18
                        spacing: 8

                        readonly property bool isSuspended: modelData.suspended === true
                        readonly property int gTemp: modelData.temp_c ?? 0
                        readonly property int gUtil: modelData.util_pct ?? 0
                        readonly property bool hasUtil: modelData.has_util === true
                        readonly property int vramPct: modelData.vram_pct ?? 0
                        readonly property string vramStr: modelData.vram_str || ""

                        Text {
                            text: "GPU"
                            color: panel.colDim
                            font.family: panel.monoFont
                            font.pixelSize: 9
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.8
                        }

                        Text {
                            Layout.fillWidth: true
                            text: modelData.short_name || modelData.name || "GPU"
                            color: isSuspended ? panel.colSubtle : panel.colFg
                            font.family: panel.monoFont
                            font.pixelSize: 10
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                        }

                        Text {
                            visible: isSuspended
                            text: "sleeping"
                            color: panel.colDim
                            font.family: panel.monoFont
                            font.pixelSize: 10
                        }

                        // Compact inline VRAM bar + readout
                        Rectangle {
                            visible: !isSuspended && vramStr.length > 0
                            Layout.preferredWidth: 42
                            Layout.preferredHeight: 3
                            radius: 1
                            color: panel.colTrack
                            Rectangle {
                                width: Math.max(2, parent.width * Math.min(100, vramPct) / 100)
                                height: parent.height
                                radius: 1
                                color: panel.colAccent
                                opacity: 0.8
                                Behavior on width { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                            }
                        }

                        Text {
                            visible: !isSuspended && vramStr.length > 0
                            text: vramStr
                            color: panel.colDim
                            font.family: panel.monoFont
                            font.pixelSize: 9
                        }

                        Text {
                            visible: !isSuspended && gTemp > 0
                            text: gTemp + "°"
                            color: panel.tempColor(gTemp)
                            font.family: panel.monoFont
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            Layout.preferredWidth: 26
                            horizontalAlignment: Text.AlignRight
                        }

                        Text {
                            visible: !isSuspended && hasUtil
                            text: gUtil + "%"
                            color: panel.loadColor(gUtil, panel.colSubtle)
                            font.family: panel.monoFont
                            font.pixelSize: 10
                            Layout.preferredWidth: 30
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: panel.colRule
        }

        // ── 4. Flat Hairline-Divided Process Table ───────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 18
                Layout.bottomMargin: 5
                spacing: 6

                Text {
                    text: "PROCESSES"
                    color: panel.colDim
                    font.family: panel.monoFont
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.0
                }

                Text {
                    visible: panel.tasksTotal > 0
                    text: String(panel.tasksTotal)
                    color: panel.colDim
                    font.family: panel.monoFont
                    font.pixelSize: 9
                }

                Item { Layout.fillWidth: true }

                RowLayout {
                    spacing: 12

                    Item {
                        implicitWidth: tabCpuTxt.implicitWidth + 4
                        implicitHeight: 18

                        Text {
                            id: tabCpuTxt
                            anchors.top: parent.top
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "CPU"
                            color: panel.sortTab === "cpu" ? panel.colFg : (tabCpuMouse.containsMouse ? panel.colSubtle : panel.colDim)
                            font.family: panel.monoFont
                            font.pixelSize: 10
                            font.weight: panel.sortTab === "cpu" ? Font.DemiBold : Font.Normal
                            font.letterSpacing: 0.7
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 1.5
                            radius: 1
                            color: panel.colAccent
                            opacity: panel.sortTab === "cpu" ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 130 } }
                        }

                        MouseArea {
                            id: tabCpuMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (winRef) winRef.sysMonProcTab = "cpu"
                        }
                    }

                    Item {
                        implicitWidth: tabMemTxt.implicitWidth + 4
                        implicitHeight: 18

                        Text {
                            id: tabMemTxt
                            anchors.top: parent.top
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "MEM"
                            color: panel.sortTab === "mem" ? panel.colFg : (tabMemMouse.containsMouse ? panel.colSubtle : panel.colDim)
                            font.family: panel.monoFont
                            font.pixelSize: 10
                            font.weight: panel.sortTab === "mem" ? Font.DemiBold : Font.Normal
                            font.letterSpacing: 0.7
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 1.5
                            radius: 1
                            color: panel.colRam
                            opacity: panel.sortTab === "mem" ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 130 } }
                        }

                        MouseArea {
                            id: tabMemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (winRef) winRef.sysMonProcTab = "mem"
                        }
                    }
                }
            }

            // Column Headers (aligned flush with right axis)
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 14
                Layout.leftMargin: 4
                Layout.rightMargin: 4
                Layout.bottomMargin: 2
                spacing: 8

                Text {
                    text: "PID"
                    color: panel.colDim
                    font.family: panel.monoFont
                    font.pixelSize: 9
                    font.letterSpacing: 0.6
                    Layout.preferredWidth: 44
                }
                Text {
                    text: "PROCESS"
                    color: panel.colDim
                    font.family: panel.monoFont
                    font.pixelSize: 9
                    font.letterSpacing: 0.6
                    Layout.fillWidth: true
                }
                Text {
                    text: "CPU"
                    color: panel.sortTab === "cpu" ? panel.colSubtle : panel.colDim
                    font.family: panel.monoFont
                    font.pixelSize: 9
                    font.letterSpacing: 0.6
                    Layout.preferredWidth: 50
                    horizontalAlignment: Text.AlignRight
                }
                Text {
                    text: "MEM"
                    color: panel.sortTab === "mem" ? panel.colSubtle : panel.colDim
                    font.family: panel.monoFont
                    font.pixelSize: 9
                    font.letterSpacing: 0.6
                    Layout.preferredWidth: 50
                    horizontalAlignment: Text.AlignRight
                }
            }

            // 6 flat hairline-divided rows (MEM flush-right at rest; slides cleanly for kill button on hover)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Repeater {
                    model: panel.activeProcs

                    delegate: Item {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        Layout.preferredHeight: 25

                        readonly property bool rowHovered: rowMouse.containsMouse || killMouse.containsMouse
                        readonly property bool isConfirming: panel.confirmKillPid === String(modelData.pid)
                        readonly property bool showKill: rowHovered || isConfirming
                        readonly property real cpuVal: Number(modelData.cpu) || 0

                        Rectangle {
                            anchors.fill: parent
                            radius: 4
                            color: isConfirming
                                   ? Qt.rgba(panel.colHot.r, panel.colHot.g, panel.colHot.b, 0.08)
                                   : (rowHovered ? panel.colHover : "transparent")
                            Behavior on color { ColorAnimation { duration: 100 } }
                        }

                        Rectangle {
                            visible: index > 0
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 4
                            anchors.rightMargin: 4
                            height: 1
                            color: panel.colRowRule
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                        }

                        RowLayout {
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 4
                            anchors.rightMargin: showKill ? (isConfirming ? 34 : 24) : 4
                            Behavior on anchors.rightMargin { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                            spacing: 8

                            Text {
                                text: String(modelData.pid || "")
                                color: panel.colDim
                                font.family: panel.monoFont
                                font.pixelSize: 10
                                Layout.preferredWidth: 44
                            }

                            Text {
                                text: modelData.name || ""
                                color: panel.colFg
                                font.family: panel.monoFont
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: cpuVal.toFixed(1) + "%"
                                color: cpuVal >= 75 ? panel.colHot
                                     : (cpuVal >= 30 ? panel.colWarm
                                     : (panel.sortTab === "cpu" ? panel.colFg : panel.colSubtle))
                                font.family: panel.monoFont
                                font.pixelSize: 10
                                font.weight: panel.sortTab === "cpu" ? Font.DemiBold : Font.Normal
                                Layout.preferredWidth: 50
                                horizontalAlignment: Text.AlignRight
                            }

                            Text {
                                text: modelData.mem_str || "0M"
                                color: panel.sortTab === "mem" ? panel.colFg : panel.colSubtle
                                font.family: panel.monoFont
                                font.pixelSize: 10
                                font.weight: panel.sortTab === "mem" ? Font.DemiBold : Font.Normal
                                Layout.preferredWidth: 50
                                horizontalAlignment: Text.AlignRight
                            }
                        }

                        // Hover-revealed quiet kill trigger at far right edge
                        Rectangle {
                            anchors.right: parent.right
                            anchors.rightMargin: 3
                            anchors.verticalCenter: parent.verticalCenter
                            width: isConfirming ? 28 : 18
                            height: 17
                            radius: 4
                            opacity: showKill ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 110 } }
                            color: isConfirming
                                   ? Qt.rgba(panel.colHot.r, panel.colHot.g, panel.colHot.b, 0.22)
                                   : (killMouse.containsMouse ? Qt.rgba(panel.colHot.r, panel.colHot.g, panel.colHot.b, 0.16) : "transparent")

                            Text {
                                anchors.centerIn: parent
                                text: isConfirming ? "kill" : "×"
                                color: (isConfirming || killMouse.containsMouse) ? panel.colHot : panel.colSubtle
                                font.family: panel.monoFont
                                font.pixelSize: isConfirming ? 9 : 12
                                font.weight: isConfirming ? Font.DemiBold : Font.Normal
                            }

                            MouseArea {
                                id: killMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    const pidStr = String(modelData.pid || "")
                                    if (!pidStr) return
                                    if (panel.confirmKillPid === pidStr) {
                                        panel.confirmKillPid = ""
                                        confirmResetTimer.stop()
                                        if (rootRef) {
                                            rootRef.runCmd("kill -15 " + pidStr + " 2>/dev/null || true")
                                            if (typeof rootRef.refreshSysMon === "function") rootRef.refreshSysMon()
                                        }
                                    } else {
                                        panel.confirmKillPid = pidStr
                                        confirmResetTimer.restart()
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }
    }
}
