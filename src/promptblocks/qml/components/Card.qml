import QtQuick
import ".."

Item {
    id: root

    // ── Properties ──
    property int elevation: Card.Flat   // Flat, Raised, Floating
    property int padding: Theme.spacingLG
    property int radius: Theme.radiusMD

    // ── Enum constants ──
    readonly property int Flat: 0
    readonly property int Raised: 1
    readonly property int Floating: 2

    // ── Computed ──
    readonly property int _shadowOffset: elevation === Flat ? 0 : elevation === Raised ? 2 : 6
    readonly property real _shadowOpacity: elevation === Flat ? 0.0 : elevation === Raised ? 0.3 : 0.5

    implicitWidth: childrenRect.width + padding * 2
    implicitHeight: childrenRect.height + padding * 2

    // Shadow layer (simple colored rectangle behind)
    Rectangle {
        id: shadow
        x: root._shadowOffset
        y: root._shadowOffset
        width: parent.width
        height: parent.height
        radius: root.radius
        color: Theme.shadowColor
        opacity: root._shadowOpacity
        visible: root.elevation !== Card.Flat

        Behavior on opacity {
            enabled: !Theme.animReducedMotion
            NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasing }
        }
    }

    // Card body
    Rectangle {
        id: cardBody
        anchors.fill: parent
        radius: root.radius
        color: Theme.cardBackground
        border.width: 1
        border.color: Theme.cardBorder

        // Default data for children
        default property alias data: contentArea.data

        Item {
            id: contentArea
            anchors.fill: parent
            anchors.margins: root.padding
        }
    }
}
