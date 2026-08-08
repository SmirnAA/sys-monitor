import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as Plasma5Support
import "components" as Components

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    readonly property int chartPoints: 28
    readonly property color colorNormal: "#8bd889"
    readonly property color colorWarning: "#f4b24d"
    readonly property color colorCritical: "#ff6b6b"
    readonly property color colorUp: "#f4b24d"
    readonly property color colorDown: "#67c2ba"
    readonly property color colorMonochrome: "#deddda"
    readonly property color colorCpu: "#34d399"
    readonly property color colorRam: "#a78bfa"
    readonly property color colorSwap: "#facc15"
    readonly property color colorGpu: "#c084fc"
    readonly property color colorDownload: "#60a5fa"

    property var payload: ({
        cpu: 0,
        cpuTemp: null,
        mem: {
            ramPct: 0,
            swapPct: 0,
            ramUsedMB: 0,
            ramTotalMB: 0,
            swapUsedMB: 0,
            swapTotalMB: 0
        },
        net: {
            upKB: 0,
            downKB: 0
        },
        gpuPct: null,
        gpuType: "none"
    })
    property var prevCpuRaw: null
    property var prevNetRaw: null
    property real prevTimestampMs: 0

    property var cpuHistory: []
    property var ramHistory: []
    property var swapHistory: []
    property var gpuHistory: []
    property var upHistory: []
    property var downHistory: []

    property string helperPath: toLocalFile(Qt.resolvedUrl("../code/monitor.py"))
    property string cpuIcon: Qt.resolvedUrl("../../icons/cpu-symbolic.svg")
    property string gpuIcon: Qt.resolvedUrl("../../icons/gpu-symbolic.svg")
    property string ramIcon: Qt.resolvedUrl("../../icons/ram-symbolic.svg")
    property string swapIcon: Qt.resolvedUrl("../../icons/swap-symbolic.svg")
    property string uploadIcon: Qt.resolvedUrl("../../icons/upload-symbolic.svg")
    property string downloadIcon: Qt.resolvedUrl("../../icons/download-symbolic.svg")

    function switchSizeFromSize(formFactor, compactMax, fullMin) {
        if (Plasmoid.formFactor === PlasmaCore.Types.Planar) {
            return -1;
        }

        if (Plasmoid.formFactor === formFactor) {
            return 1;
        }

        if (!Number.isFinite(compactMax)) {
            compactMax = Kirigami.Units.iconSizes.enormous - 1;
        }

        if (fullMin <= 0) {
            fullMin = Kirigami.Units.iconSizes.enormous - 1;
        }

        return Math.max(compactMax, fullMin);
    }

    switchWidth: switchSizeFromSize(PlasmaCore.Types.Horizontal, compactRepresentationItem?.Layout.maximumWidth ?? Infinity, fullRepresentationItem?.Layout.minimumWidth ?? -1)
    switchHeight: switchSizeFromSize(PlasmaCore.Types.Vertical, compactRepresentationItem?.Layout.maximumHeight ?? Infinity, fullRepresentationItem?.Layout.minimumHeight ?? -1)
    preferredRepresentation: Plasmoid.formFactor === PlasmaCore.Types.Planar ? fullRepresentation : compactRepresentation

    function toLocalFile(url) {
        let value = url.toString();
        if (value.startsWith("file://")) {
            value = value.slice(7);
        }
        return decodeURIComponent(value);
    }

    function runHelper() {
        executable.exec(`python3 "${helperPath}"`);
    }

    function appendHistory(current, value) {
        const next = current.slice(0);
        next.push(Math.max(0, value || 0));
        while (next.length > chartPoints) {
            next.shift();
        }
        return next;
    }

    function usageColor(percent) {
        if (plasmoid.configuration.monochromeMode) {
            return colorMonochrome;
        }
        if (percent < 60) {
            return colorNormal;
        }
        if (percent < 80) {
            return colorWarning;
        }
        return colorCritical;
    }

    function staticColor(colorValue) {
        return plasmoid.configuration.monochromeMode ? colorMonochrome : colorValue;
    }

    function tempColor(tempC) {
        if (plasmoid.configuration.monochromeMode) {
            return colorMonochrome;
        }
        if (tempC < 55) {
            return "#67c2ba";
        }
        if (tempC < 75) {
            return colorWarning;
        }
        return colorCritical;
    }

    function formatSpeed(kb) {
        if (kb >= 1024) {
            return `${(kb / 1024).toFixed(1)}MB/s`;
        }
        return `${kb}KB/s`;
    }

    function splitSpeed(kb) {
        if (kb >= 1024) {
            return { value: (kb / 1024).toFixed(1), unit: "MB/s" };
        }
        return { value: `${kb}`, unit: "KB/s" };
    }

    function formatMemory(mb) {
        if (mb >= 1024) {
            return `${(mb / 1024).toFixed(1)} GiB`;
        }
        return `${mb} MiB`;
    }

    function formatGpuType(type) {
        if (type === "nvidia") {
            return "NVIDIA";
        }
        if (type === "amd") {
            return "AMD";
        }
        return "GPU";
    }

    function panelValueWidth(text, fallback) {
        const count = Math.max((text || "").length, fallback);
        return Math.max(34, count * 8);
    }

    function applyRawData(raw) {
        const timestampMs = Number(raw.timestampMs || 0);
        let cpu = 0;
        let upKB = 0;
        let downKB = 0;

        if (prevCpuRaw !== null) {
            const dIdle = Number(raw.cpuRaw.idle) - Number(prevCpuRaw.idle);
            const dTotal = Number(raw.cpuRaw.total) - Number(prevCpuRaw.total);
            cpu = dTotal === 0 ? 0 : Math.round((1 - (dIdle / dTotal)) * 100);
        }
        prevCpuRaw = raw.cpuRaw;

        if (prevNetRaw !== null && prevTimestampMs > 0 && timestampMs > prevTimestampMs) {
            const dt = (timestampMs - prevTimestampMs) / 1000;
            upKB = Math.max(0, Math.round((Number(raw.netRaw.txBytes) - Number(prevNetRaw.txBytes)) / dt / 1024));
            downKB = Math.max(0, Math.round((Number(raw.netRaw.rxBytes) - Number(prevNetRaw.rxBytes)) / dt / 1024));
        }
        prevNetRaw = raw.netRaw;
        prevTimestampMs = timestampMs;

        payload = {
            cpu: Math.max(0, cpu),
            cpuTemp: raw.cpuTemp,
            mem: raw.mem,
            net: {
                upKB: upKB,
                downKB: downKB
            },
            gpuPct: raw.gpuType === "none" ? null : Number(raw.gpuPct || 0),
            gpuType: raw.gpuType
        };

        cpuHistory = appendHistory(cpuHistory, payload.cpu);
        ramHistory = appendHistory(ramHistory, payload.mem.ramPct);
        swapHistory = appendHistory(swapHistory, payload.mem.swapPct);
        gpuHistory = appendHistory(gpuHistory, payload.gpuPct === null ? 0 : payload.gpuPct);
        upHistory = appendHistory(upHistory, payload.net.upKB);
        downHistory = appendHistory(downHistory, payload.net.downKB);
    }

    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []

        function exec(command) {
            disconnectSource(command);
            connectSource(command);
        }

        onNewData: function(sourceName, data) {
            disconnectSource(sourceName);
            const stdout = data["stdout"] || "";
            if (!stdout.length) {
                return;
            }

            try {
                applyRawData(JSON.parse(stdout));
            } catch (error) {
                console.log(`sys-monitor parse failed: ${error}`);
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: Math.max(1, plasmoid.configuration.refreshInterval || 2) * 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.runHelper()
    }

    compactRepresentation: Item {
        implicitWidth: compactRow.width + 12
        implicitHeight: 24
        Layout.minimumHeight: 24
        Layout.maximumHeight: 24
        Layout.minimumWidth: compactRow.width + 12
        Layout.preferredWidth: compactRow.width + 12
        Layout.maximumWidth: compactRow.width + 12
        LayoutMirroring.enabled: false

        Row {
            id: compactRow
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 6
            spacing: 0
            layoutDirection: Qt.LeftToRight

            Item {
                visible: plasmoid.configuration.showCpu
                width: cpuRow.width
                height: 24

                Row {
                    id: cpuRow
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 5

                    Kirigami.Icon {
                        source: root.cpuIcon
                        width: 14
                        height: 14
                        color: root.usageColor(root.payload.cpu)
                    }

                    QQC2.Label {
                        width: 34
                        text: `${root.payload.cpu}%`
                        color: root.usageColor(root.payload.cpu)
                        font.family: "JetBrains Mono"
                        font.bold: true
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            Item {
                visible: plasmoid.configuration.showCpu && plasmoid.configuration.showRam
                width: 8
                height: 24

                QQC2.Label {
                    anchors.centerIn: parent
                    text: "|"
                    color: Qt.rgba(238 / 255, 238 / 255, 236 / 255, 0.24)
                    font.bold: true
                    font.pixelSize: 11
                }
            }

            Item {
                visible: plasmoid.configuration.showRam
                width: ramRow.width
                height: 24

                Row {
                    id: ramRow
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 5

                    Kirigami.Icon {
                        source: root.ramIcon
                        width: 14
                        height: 14
                        color: root.usageColor(root.payload.mem.ramPct)
                    }

                    QQC2.Label {
                        width: 34
                        text: `${root.payload.mem.ramPct}%`
                        color: root.usageColor(root.payload.mem.ramPct)
                        font.family: "JetBrains Mono"
                        font.bold: true
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            Item {
                visible: plasmoid.configuration.showSwap && (plasmoid.configuration.showCpu || plasmoid.configuration.showRam)
                width: 8
                height: 24

                QQC2.Label {
                    anchors.centerIn: parent
                    text: "|"
                    color: Qt.rgba(238 / 255, 238 / 255, 236 / 255, 0.24)
                    font.bold: true
                    font.pixelSize: 11
                }
            }

            Item {
                visible: plasmoid.configuration.showSwap
                width: swapRow.width
                height: 24

                Row {
                    id: swapRow
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 5

                    Kirigami.Icon {
                        source: root.swapIcon
                        width: 14
                        height: 14
                        color: root.usageColor(root.payload.mem.swapPct)
                    }

                    QQC2.Label {
                        width: 34
                        text: `${root.payload.mem.swapPct}%`
                        color: root.usageColor(root.payload.mem.swapPct)
                        font.family: "JetBrains Mono"
                        font.bold: true
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            Item {
                visible: plasmoid.configuration.showNetwork && (plasmoid.configuration.showCpu || plasmoid.configuration.showRam || plasmoid.configuration.showSwap)
                width: 8
                height: 24

                QQC2.Label {
                    anchors.centerIn: parent
                    text: "|"
                    color: Qt.rgba(238 / 255, 238 / 255, 236 / 255, 0.24)
                    font.bold: true
                    font.pixelSize: 11
                }
            }

            Item {
                visible: plasmoid.configuration.showNetwork
                width: upRow.width
                height: 24

                Row {
                    id: upRow
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 5

                    Kirigami.Icon {
                        source: root.uploadIcon
                        width: 14
                        height: 14
                        color: root.staticColor(root.colorUp)
                    }

                    QQC2.Label {
                        width: root.panelValueWidth(text, 7)
                        text: root.formatSpeed(root.payload.net.upKB)
                        color: root.staticColor(root.colorUp)
                        font.family: "JetBrains Mono"
                        font.bold: true
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            Item {
                visible: plasmoid.configuration.showNetwork
                width: 8
                height: 24

                QQC2.Label {
                    anchors.centerIn: parent
                    text: "|"
                    color: Qt.rgba(238 / 255, 238 / 255, 236 / 255, 0.24)
                    font.bold: true
                    font.pixelSize: 11
                }
            }

            Item {
                visible: plasmoid.configuration.showNetwork
                width: downRow.width
                height: 24

                Row {
                    id: downRow
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 5

                    Kirigami.Icon {
                        source: root.downloadIcon
                        width: 14
                        height: 14
                        color: root.staticColor(root.colorDown)
                    }

                    QQC2.Label {
                        width: root.panelValueWidth(text, 7)
                        text: root.formatSpeed(root.payload.net.downKB)
                        color: root.staticColor(root.colorDown)
                        font.family: "JetBrains Mono"
                        font.bold: true
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onClicked: root.expanded = !root.expanded
        }
    }

    fullRepresentation: Item {
        implicitWidth: 360
        implicitHeight: 520
        Layout.minimumWidth: 360
        Layout.minimumHeight: 520

        Rectangle {
            anchors.fill: parent
            radius: 22
            color: "#1f1b17"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.06)

            Flickable {
                anchors.fill: parent
                anchors.margins: 10
                contentWidth: width
                contentHeight: popupColumn.implicitHeight
                clip: true

                ColumnLayout {
                    id: popupColumn
                    width: parent.width
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Kirigami.Heading {
                            Layout.fillWidth: true
                            text: "System Monitor"
                            level: 2
                            font.pixelSize: 17
                            font.weight: Font.DemiBold
                            color: Qt.rgba(246 / 255, 245 / 255, 244 / 255, 0.96)
                        }

                        Kirigami.Icon {
                            source: "utilities-system-monitor"
                            width: 14
                            height: 14
                            color: Qt.rgba(246 / 255, 245 / 255, 244 / 255, 0.55)
                        }

                        Kirigami.Icon {
                            source: "application-menu"
                            width: 14
                            height: 14
                            color: Qt.rgba(246 / 255, 245 / 255, 244 / 255, 0.55)
                        }
                    }

                    Components.MetricCard {
                        visible: plasmoid.configuration.showCpu
                        Layout.fillWidth: true
                        iconSource: root.cpuIcon
                        title: "CPU"
                        detail: "Processor load"
                        valueText: `${root.payload.cpu}%`
                        tempText: root.payload.cpuTemp === null ? "" : `${root.payload.cpuTemp}°C`
                        tempVisible: root.payload.cpuTemp !== null
                        accentColor: root.payload.cpuTemp === null
                            ? root.staticColor(root.colorCpu)
                            : root.tempColor(root.payload.cpuTemp)
                        history: root.cpuHistory
                    }

                    Components.MetricCard {
                        visible: plasmoid.configuration.showGpu && root.payload.gpuPct !== null
                        Layout.fillWidth: true
                        iconSource: root.gpuIcon
                        title: "GPU"
                        detail: `${root.formatGpuType(root.payload.gpuType)} load`
                        valueText: `${root.payload.gpuPct === null ? 0 : root.payload.gpuPct}%`
                        accentColor: root.staticColor(root.colorGpu)
                        history: root.gpuHistory
                    }

                    Components.MetricCard {
                        visible: plasmoid.configuration.showRam
                        Layout.fillWidth: true
                        iconSource: root.ramIcon
                        title: "RAM"
                        detail: `${root.formatMemory(root.payload.mem.ramUsedMB)} / ${root.formatMemory(root.payload.mem.ramTotalMB)}`
                        valueText: `${root.payload.mem.ramPct}%`
                        accentColor: root.staticColor(root.colorRam)
                        history: root.ramHistory
                    }

                    Components.MetricCard {
                        visible: plasmoid.configuration.showSwap
                        Layout.fillWidth: true
                        iconSource: root.swapIcon
                        title: "Swap"
                        detail: root.payload.mem.swapTotalMB > 0
                            ? `${root.formatMemory(root.payload.mem.swapUsedMB)} / ${root.formatMemory(root.payload.mem.swapTotalMB)}`
                            : "No swap configured"
                        valueText: `${root.payload.mem.swapPct}%`
                        accentColor: root.staticColor(root.colorSwap)
                        history: root.swapHistory
                    }

                    RowLayout {
                        visible: plasmoid.configuration.showNetwork
                        Layout.fillWidth: true
                        spacing: 8

                        Components.NetCard {
                            Layout.fillWidth: true
                            iconSource: root.uploadIcon
                            title: "Upload"
                            valueText: root.splitSpeed(root.payload.net.upKB).value
                            unitText: root.splitSpeed(root.payload.net.upKB).unit
                            accentColor: root.staticColor(root.colorCpu)
                            history: root.upHistory
                        }

                        Components.NetCard {
                            Layout.fillWidth: true
                            iconSource: root.downloadIcon
                            title: "Download"
                            valueText: root.splitSpeed(root.payload.net.downKB).value
                            unitText: root.splitSpeed(root.payload.net.downKB).unit
                            accentColor: root.staticColor(root.colorDownload)
                            history: root.downHistory
                        }
                    }
                }
            }
        }
    }
}
