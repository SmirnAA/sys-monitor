import QtQuick
import org.kde.kirigami as Kirigami

Rectangle {
    id: root

    property url source
    property color accentColor: "#34d399"
    property int iconSize: 22
    property int wrapSize: 40

    width: wrapSize
    height: wrapSize
    radius: wrapSize >= 40 ? 11 : 8
    color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.14)

    Kirigami.Icon {
        anchors.centerIn: parent
        width: iconSize
        height: iconSize
        source: root.source
        color: root.accentColor
    }
}
