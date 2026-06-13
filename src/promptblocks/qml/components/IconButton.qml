import QtQuick
import QtQuick.Controls
import ".."

Item {
    id: root

    // ── Properties ──
    property string icon: ""
    property int btnSize: 1   // sizeMd
    property int btnStyle: 0  // styleDefault
    property string tooltip: ""

    // ── Enum constants ──
    readonly property int styleDefault: 0
    readonly property int stylePrimary: 1
    readonly property int styleDanger: 2

    readonly property int sizeSm: 0
    readonly property int sizeMd: 1
    readonly property int sizeLg: 2

    // ── Signals ──
    signal clicked()

    // ── Computed sizes ──
    readonly property int _dimension: btnSize === IconButton.sizeSm ? 24 : btnSize === IconButton.sizeMd ? 32 : 40
    readonly property int _fontSize: btnSize === IconButton.sizeSm ? Theme.fontSM : btnSize === IconButton.sizeMd ? Theme.fontMD : Theme.fontLG

    implicitWidth: _dimension
    implicitHeight: _dimension

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: width / 2
        opacity: root.enabled ? 1.0 : 0.4
        scale: tapHandler.pressed ? 0.9 : 1.0

        color: {
            if (!hoverHandler.hovered) return "transparent"
            else if (root.btnStyle === IconButton.stylePrimary) return Theme.buttonHoverPrimary
            else if (root.btnStyle === IconButton.styleDanger) return Theme.buttonHoverDanger
            else return Theme.cardHover
        }

        Behavior on color {
            enabled: !Theme.animReducedMotion
            ColorAnimation { duration: Theme.animFast }
        }
        Behavior on scale {
            enabled: !Theme.animReducedMotion
            NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing }
        }

        Text {
            anchors.centerIn: parent
            text: root.icon
            font.family: Icons.fontFamily
            font.pixelSize: root._fontSize
            color: {
                if (root.btnStyle === IconButton.stylePrimary) return Theme.primary
                else if (root.btnStyle === IconButton.styleDanger) return Theme.error
                else return Theme.onSurfaceVariant
            }
        }

        HoverHandler {
            id: hoverHandler
            enabled: root.enabled
        }

        TapHandler {
            id: tapHandler
            enabled: root.enabled
            onTapped: root.clicked()
        }
    }

    // Tooltip
    ToolTip {
        visible: root.tooltip !== "" && hoverHandler.hovered
        text: root.tooltip
        delay: 500
    }
}
