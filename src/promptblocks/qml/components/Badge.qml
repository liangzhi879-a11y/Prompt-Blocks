import QtQuick
import ".."

Item {
    id: root

    // ── Properties ──
    property string text: ""
    property int badgeStyle: 4  // styleNeutral
    property int badgeSize: 1   // sizeMd

    // ── Enum constants ──
    readonly property int styleInfo: 0
    readonly property int styleSuccess: 1
    readonly property int styleWarning: 2
    readonly property int styleError: 3
    readonly property int styleNeutral: 4

    readonly property int sizeSm: 0
    readonly property int sizeMd: 1

    // ── Computed ──
    readonly property int _fontSize: badgeSize === Badge.sizeSm ? Theme.fontXS : Theme.fontSM
    readonly property int _paddingH: badgeSize === Badge.sizeSm ? Theme.spacingSM : Theme.spacingMD
    readonly property int _paddingV: badgeSize === Badge.sizeSm ? 2 : Theme.spacingXS
    readonly property int _radius: badgeSize === Badge.sizeSm ? Theme.radiusSM : Theme.radiusMD

    readonly property color _bgColor: {
        if (root.badgeStyle === Badge.styleInfo) return Theme.infoContainer
        else if (root.badgeStyle === Badge.styleSuccess) return Theme.successContainer
        else if (root.badgeStyle === Badge.styleWarning) return Theme.warningContainer
        else if (root.badgeStyle === Badge.styleError) return Theme.errorContainer
        else if (root.badgeStyle === Badge.styleNeutral) return Theme.surfaceVariant
        else return Theme.surfaceVariant
    }
    readonly property color _textColor: {
        if (root.badgeStyle === Badge.styleInfo) return Theme.onInfoContainer
        else if (root.badgeStyle === Badge.styleSuccess) return Theme.onSuccessContainer
        else if (root.badgeStyle === Badge.styleWarning) return Theme.onWarningContainer
        else if (root.badgeStyle === Badge.styleError) return Theme.onErrorContainer
        else if (root.badgeStyle === Badge.styleNeutral) return Theme.onSurfaceVariant
        else return Theme.onSurfaceVariant
    }

    implicitWidth: label.width + _paddingH * 2
    implicitHeight: label.height + _paddingV * 2

    Rectangle {
        anchors.fill: parent
        radius: root._radius
        color: root._bgColor

        Text {
            id: label
            anchors.centerIn: parent
            text: root.text
            font.pixelSize: root._fontSize
            font.weight: Font.Medium
            color: root._textColor
        }
    }
}
