import QtQuick
import QtQuick.Controls
import ".."

Rectangle {
    id: splitHandle
    implicitWidth: 4
    implicitHeight: 4
    color: handleHover.hovered ? Theme.primary : Theme.divider

    Behavior on color { enabled: !Theme.animReducedMotion; ColorAnimation { duration: Theme.animFast } }

    HoverHandler {
        id: handleHover
        cursorShape: Qt.SplitHCursor
    }

    // Center accent line
    Rectangle {
        width: 1
        height: parent.height
        anchors.horizontalCenter: parent.horizontalCenter
        color: handleHover.hovered ? Theme.primary : "transparent"
        opacity: 0.6
    }
}
