import QtQuick
import ".."

Item {
    id: root

    // ── Properties ──
    property string text: ""
    property int btnStyle: 1  // styleSecondary
    property int btnSize: 1   // sizeMd
    property string icon: ""
    property bool enabled: true
    property bool loading: false

    // ── Enum constants ──
    readonly property int stylePrimary: 0
    readonly property int styleSecondary: 1
    readonly property int styleDanger: 2
    readonly property int styleGhost: 3

    readonly property int sizeSm: 0
    readonly property int sizeMd: 1
    readonly property int sizeLg: 2

    // ── Signals ──
    signal clicked()

    // ── Computed sizes ──
    readonly property int _height: btnSize === PBButton.sizeSm ? 28 : btnSize === PBButton.sizeMd ? 34 : 42
    readonly property int _paddingH: btnSize === PBButton.sizeSm ? Theme.spacingSM : btnSize === PBButton.sizeMd ? Theme.spacingMD : Theme.spacingLG
    readonly property int _fontSize: btnSize === PBButton.sizeSm ? Theme.fontSM : btnSize === PBButton.sizeMd ? Theme.fontMD : Theme.fontLG
    readonly property int _radius: btnSize === PBButton.sizeSm ? Theme.radiusSM : Theme.radiusMD

    implicitWidth: row.width + _paddingH * 2
    implicitHeight: _height

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: root._radius
        opacity: root.enabled ? 1.0 : 0.5
        scale: tapHandler.pressed ? 0.95 : 1.0

        color: {
            if (!root.enabled) return Theme.surfaceVariant
            else if (root.btnStyle === PBButton.stylePrimary) return Theme.primary
            else if (root.btnStyle === PBButton.styleSecondary) return hoverHandler.hovered ? Theme.surfaceRaised : Theme.surfaceVariant
            else if (root.btnStyle === PBButton.styleDanger) return Theme.error
            else if (root.btnStyle === PBButton.styleGhost) return "transparent"
            else return Theme.surfaceVariant
        }
        border.width: root.btnStyle === PBButton.styleSecondary ? 1 : 0
        border.color: Theme.border

        // Hover overlay — preserves base color so text/ icon contrast stays correct
        Rectangle {
            anchors.fill: parent
            radius: bg.radius
            color: {
                if (!root.enabled || !hoverHandler.hovered) return "transparent"
                else if (root.btnStyle === PBButton.stylePrimary) return Theme.buttonHoverPrimary
                else if (root.btnStyle === PBButton.styleDanger) return Theme.buttonHoverDanger
                else if (root.btnStyle === PBButton.styleGhost) return Theme.cardHover
                else return Theme.cardHover
            }

            Behavior on color {
                enabled: !Theme.animReducedMotion
                ColorAnimation { duration: Theme.animFast }
            }
        }

        Behavior on color {
            enabled: !Theme.animReducedMotion
            ColorAnimation { duration: Theme.animFast }
        }
        Behavior on scale {
            enabled: !Theme.animReducedMotion
            NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing }
        }

        Row {
            id: row
            anchors.centerIn: parent
            spacing: root.icon !== "" ? Theme.spacingXS : 0
            opacity: root.loading ? 0.0 : 1.0

            Behavior on opacity {
                enabled: !Theme.animReducedMotion
                NumberAnimation { duration: Theme.animFast }
            }

            Text {
                text: root.icon
                font.family: Theme.fontFamily
                font.pixelSize: root._fontSize
                visible: root.icon !== ""
                color: {
                    if (root.btnStyle === PBButton.stylePrimary) return Theme.onPrimary
                    else if (root.btnStyle === PBButton.styleDanger) return Theme.onPrimary
                    else return Theme.onSurface
                }
            }
            Text {
                text: root.text
                font.family: Theme.fontFamily
                font.pixelSize: root._fontSize
                font.weight: root.btnStyle === PBButton.stylePrimary ? Font.Medium : Font.Normal
                color: {
                    if (root.btnStyle === PBButton.stylePrimary) return Theme.onPrimary
                    else if (root.btnStyle === PBButton.styleDanger) return Theme.onPrimary
                    else return Theme.onSurface
                }
            }
        }

        // Loading spinner
        Rectangle {
            anchors.centerIn: parent
            width: root._fontSize
            height: root._fontSize
            radius: width / 2
            color: "transparent"
            border.width: 2
            border.color: root.btnStyle === PBButton.stylePrimary || root.btnStyle === PBButton.styleDanger
                          ? Theme.onPrimary : Theme.onSurface
            visible: root.loading
            RotationAnimator on rotation {
                running: root.loading && !Theme.animReducedMotion
                from: 0
                to: 360
                duration: 800
                loops: Animation.Infinite
            }
        }

        HoverHandler {
            id: hoverHandler
            enabled: root.enabled
        }

        TapHandler {
            id: tapHandler
            enabled: root.enabled && !root.loading
            onTapped: root.clicked()
        }
    }
}
