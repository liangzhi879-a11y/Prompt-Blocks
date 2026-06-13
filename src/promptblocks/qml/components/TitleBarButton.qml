import QtQuick
import ".."

Rectangle {
    id: btn
    width: 46
    height: 32
    color: hoverHandler.hovered ? (isClose ? Theme.buttonHoverDanger : Theme.surfaceVariant) : "transparent"
    radius: 4

    property string icon: ""
    property bool isClose: false

    signal clicked()

    Text {
        anchors.centerIn: parent
        text: btn.icon
        color: btn.isClose && hoverHandler.hovered ? Theme.onPrimary : Theme.onSurfaceVariant
        font.pixelSize: 12
        font.family: Theme.fontFamily
    }

    HoverHandler {
        id: hoverHandler
    }

    TapHandler {
        onTapped: btn.clicked()
    }

    Behavior on color { enabled: !Theme.animReducedMotion; ColorAnimation { duration: Theme.animFast } }
}
