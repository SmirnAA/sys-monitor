import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import "." as Components

Rectangle {
    id: root

    property url iconSource
    property string title: ""
    property string valueText: "0"
    property string unitText: "KB/s"
    property color accentColor: "#34d399"
    property var history: []

    radius: 14
    color: "#26221d"
    border.width: 1
    border.color: Qt.rgba(1, 1, 1, 0.08)
    implicitHeight: 138

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: 12
        anchors.bottomMargin: 0
        spacing: 4

        RowLayout {
            spacing: 8

            Components.IconBadge {
                source: root.iconSource
                accentColor: root.accentColor
                wrapSize: 28
                iconSize: 16
            }

            QQC2.Label {
                text: root.title
                color: Qt.rgba(246 / 255, 245 / 255, 244 / 255, 0.58)
                font.bold: true
                font.pixelSize: 12
            }
        }

        RowLayout {
            spacing: 4

            QQC2.Label {
                text: root.valueText
                color: root.accentColor
                font.bold: true
                font.pixelSize: 22
            }

            QQC2.Label {
                text: root.unitText
                color: Qt.rgba(246 / 255, 245 / 255, 244 / 255, 0.42)
                font.pixelSize: 11
                Layout.topMargin: 10
            }
        }

        Components.WaveChart {
            Layout.fillWidth: true
            Layout.preferredHeight: 52
            values: root.history
            strokeColor: root.accentColor
            fillColor: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.28)
        }
    }
}
