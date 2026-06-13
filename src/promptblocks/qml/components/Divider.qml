import QtQuick
import ".."

Item {
    id: root

    // ── Properties ──
    property int orientation: Divider.Horizontal   // Horizontal, Vertical
    property int spacing: 0

    // ── Enum constants ──
    readonly property int Horizontal: 0
    readonly property int Vertical: 1

    implicitWidth: orientation === Horizontal ? parent ? parent.width : 0 : 1
    implicitHeight: orientation === Vertical ? parent ? parent.height : 0 : 1

    Rectangle {
        x: root.orientation === Divider.Horizontal ? root.spacing : 0
        y: root.orientation === Divider.Vertical ? root.spacing : 0
        width: root.orientation === Divider.Horizontal
               ? (root.parent ? root.parent.width - root.spacing * 2 : 0)
               : 1
        height: root.orientation === Divider.Vertical
                ? (root.parent ? root.parent.height - root.spacing * 2 : 0)
                : 1
        color: Theme.divider
    }
}
