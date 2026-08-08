import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "." as Components

Rectangle {
    id: root

    property url iconSource
    property string title: ""
    property string detail: ""
    property string valueText: "0%"
    property string tempText: ""
    property bool tempVisible: false
    property color accentColor: "#34d399"
    property var history: []

    radius: 14
    color: "#26221d"
    border.width: 1
    border.color: Qt.rgba(1, 1, 1, 0.08)
    implicitHeight: 108

    RowLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        Components.IconBadge {
            source: root.iconSource
            accentColor: root.accentColor
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 3

            Kirigami.Heading {
                text: root.title
                level: 3
                font.pixelSize: 15
                font.weight: Font.DemiBold
                color: Qt.rgba(246 / 255, 245 / 255, 244 / 255, 0.96)
            }

            QQC2.Label {
                text: root.detail
                color: Qt.rgba(246 / 255, 245 / 255, 244 / 255, 0.45)
                font.pixelSize: 12
            }
        }

        ColumnLayout {
            Layout.preferredWidth: 128
            Layout.alignment: Qt.AlignVCenter
            spacing: 4

            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 10

                QQC2.Label {
                    visible: root.tempVisible
                    text: root.tempText
                    color: root.accentColor
                    font.bold: true
                    font.pixelSize: 14
                }

                QQC2.Label {
                    text: root.valueText
                    color: root.accentColor
                    font.bold: true
                    font.pixelSize: 14
                }
            }

            Components.HistoryLine {
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                Layout.alignment: Qt.AlignRight
                values: root.history
                strokeColor: root.accentColor
            }
        }
    }
}
