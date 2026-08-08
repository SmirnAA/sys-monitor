import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    property alias cfg_refreshInterval: refreshInterval.value
    property alias cfg_monochromeMode: monochromeMode.checked
    property alias cfg_showCpu: showCpu.checked
    property alias cfg_showRam: showRam.checked
    property alias cfg_showGpu: showGpu.checked
    property alias cfg_showSwap: showSwap.checked
    property alias cfg_showNetwork: showNetwork.checked

    QQC2.SpinBox {
        id: refreshInterval
        Kirigami.FormData.label: "Refresh interval (seconds):"
        from: 1
        to: 10
        editable: true
    }

    QQC2.CheckBox {
        id: monochromeMode
        text: "Monochrome mode"
    }

    QQC2.CheckBox {
        id: showCpu
        text: "Show CPU"
    }

    QQC2.CheckBox {
        id: showRam
        text: "Show RAM"
    }

    QQC2.CheckBox {
        id: showGpu
        text: "Show GPU"
    }

    QQC2.CheckBox {
        id: showSwap
        text: "Show Swap"
    }

    QQC2.CheckBox {
        id: showNetwork
        text: "Show Network"
    }
}
