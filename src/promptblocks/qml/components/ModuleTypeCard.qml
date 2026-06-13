import QtQuick
import QtQuick.Controls
import ".."

Rectangle {
    id: typeCard

    property string moduleType: "identity_role"
    property string moduleTitle: "Identity & Role"
    property string moduleIcon: Icons.person
    property color moduleColor: (Theme.moduleTypeColors[moduleType] || {}).accent || Theme.primary
    property color moduleBgColor: (Theme.moduleTypeColors[moduleType] || {}).bg || Theme.primaryContainer
    property string moduleDescription: ""

    signal moduleTypeClicked(string type)

    width: parent ? parent.width - Theme.spacingMD * 2 : 260
    height: 56
    radius: Theme.radiusMD

    // Gradient background using module type color
    gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop {
            position: 0.0
            color: Qt.rgba(typeCard.moduleBgColor.r,
                           typeCard.moduleBgColor.g,
                           typeCard.moduleBgColor.b,
                           hoverHandler.hovered ? 1.0 : 0.6)
        }
        GradientStop {
            position: 1.0
            color: hoverHandler.hovered ? Theme.surfaceRaised : Theme.cardBackground
        }
    }

    border.color: hoverHandler.hovered ? moduleColor : Theme.cardBorder
    border.width: 1

    // Left accent border
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: Theme.spacingXXS
        width: 4
        radius: 2
        color: typeCard.moduleColor
        opacity: hoverHandler.hovered ? 1.0 : 0.6
        Behavior on opacity { enabled: !Theme.animReducedMotion; NumberAnimation { duration: Theme.animFast } }
    }

    // Hover scale animation
    scale: tapHandler.pressed ? 0.97 : (hoverHandler.hovered ? 1.02 : 1.0)
    Behavior on scale { enabled: !Theme.animReducedMotion; NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }
    Behavior on border.color { enabled: !Theme.animReducedMotion; ColorAnimation { duration: Theme.animNormal } }

    Row {
        anchors.fill: parent
        anchors.leftMargin: Theme.spacingMD
        anchors.rightMargin: Theme.spacingMD
        spacing: Theme.spacingSM

        Text {
            text: typeCard.moduleIcon
            font.pixelSize: Theme.fontXL2
            anchors.verticalCenter: parent.verticalCenter
            opacity: hoverHandler.hovered ? 1.0 : 0.8
            Behavior on opacity { enabled: !Theme.animReducedMotion; NumberAnimation { duration: Theme.animFast } }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: typeCard.width - Theme.heightXS - Theme.spacingXL - Theme.spacingMD * 2
            spacing: 1

            Text {
                text: typeCard.moduleTitle
                color: Theme.onBackground
                font.pixelSize: Theme.fontMD
                font.weight: Font.Medium
                elide: Text.ElideRight
                width: parent.width
            }
            Text {
                text: typeCard.moduleDescription
                color: Theme.onSurfaceVariant
                font.pixelSize: Theme.fontSM
                elide: Text.ElideRight
                width: parent.width
            }
        }
    }

    HoverHandler {
        id: hoverHandler
    }

    TapHandler {
        id: tapHandler
        onDoubleTapped: typeCard.moduleTypeClicked(typeCard.moduleType)
    }
}
