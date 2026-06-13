import QtQuick
import QtQuick.Controls
import ".."

Item {
    id: syntaxChecker

    property var errors: []
    property string cardId: ""

    readonly property int errorCount: {
        var count = 0
        for (var i = 0; i < errors.length; i++) {
            if (errors[i].severity === "error") count++
        }
        return count
    }

    readonly property int warningCount: {
        var count = 0
        for (var i = 0; i < errors.length; i++) {
            if (errors[i].severity === "warning") count++
        }
        return count
    }

    readonly property color statusColor: {
        if (errorCount > 0) return Theme.error
        if (warningCount > 0) return Theme.warning
        return Theme.secondary
    }

    readonly property string statusText: {
        if (errors.length === 0) return qsTr("无问题")
        var parts = []
        if (errorCount > 0) parts.push(qsTr("%1个错误").arg(errorCount))
        if (warningCount > 0) parts.push(qsTr("%1个警告").arg(warningCount))
        return parts.join(" ")
    }

    width: 20
    height: 20

    Rectangle {
        id: statusDot
        anchors.centerIn: parent
        width: 10
        height: 10
        radius: 5
        color: syntaxChecker.statusColor
        opacity: syntaxChecker.errors.length > 0 ? 1 : 0.5

        Behavior on color { enabled: !Theme.animReducedMotion; ColorAnimation { duration: Theme.animFast } }
        Behavior on opacity { enabled: !Theme.animReducedMotion; NumberAnimation { duration: Theme.animFast } }
    }

    HoverHandler {
        id: checkerHover
    }

    TapHandler {
        onTapped: {
            if (syntaxChecker.errors.length > 0) {
                errorPopup.open()
            }
        }
    }

    ToolTip {
        visible: checkerHover.hovered && syntaxChecker.errors.length > 0
        text: syntaxChecker.statusText
        delay: 300
    }

    Popup {
        id: errorPopup
        x: syntaxChecker.width + 4
        y: -4
        width: 280
        height: Math.min(300, errorColumn.implicitHeight + 60)
        padding: 8

        background: Rectangle {
            color: Theme.surface
            border.color: Theme.error
            border.width: 1
            radius: Theme.radiusSM
        }

        contentItem: Column {
            id: errorColumn
            spacing: Theme.spacingXS

            Text {
                text: qsTr("语法检查 - %1").arg(syntaxChecker.statusText)
                color: Theme.error
                font.pixelSize: Theme.fontSM
                font.bold: true
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.divider
            }

            ListView {
                id: errorListView
                width: parent.width
                height: Math.min(180, count * 28)
                model: syntaxChecker.errors
                clip: true
                spacing: Theme.spacingXXS

                delegate: Rectangle {
                    width: errorListView.width
                    height: 24
                    radius: Theme.radiusSM
                    color: modelData.severity === "error" ? Theme.error + "15" : Theme.warning + "15"

                    Row {
                        anchors.fill: parent
                        anchors.margins: Theme.spacingXS
                        spacing: Theme.spacingS

                        Text {
                            text: modelData.severity === "error" ? Icons.close : Icons.warning
                            font.family: Icons.fontFamily
                            font.pixelSize: Theme.fontXS
                            color: modelData.severity === "error" ? Theme.error : Theme.warning
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: qsTr("行%1:").arg(modelData.line)
                            color: modelData.severity === "error" ? Theme.error : Theme.warning
                            font.pixelSize: Theme.fontXS
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: modelData.message
                            color: Theme.onSurface
                            font.pixelSize: Theme.fontXS
                            elide: Text.ElideRight
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.divider
            }

            Rectangle {
                width: parent.width
                height: Theme.heightXS
                radius: Theme.radiusSM
                color: Theme.primary

                Text {
                    anchors.centerIn: parent
                    text: Icons.diamond + " " + qsTr("AI自动修复")
                    font.family: Icons.fontFamily
                    color: Theme.onPrimary
                    font.pixelSize: Theme.fontXS
                    font.bold: true
                }

                HoverHandler { id: aiFixHover }
                TapHandler {
                    onTapped: {
                        console.log("[SyntaxChecker] AI auto-fix requested for card:", syntaxChecker.cardId)
                    }
                }

                // Hover overlay
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: aiFixHover.hovered ? Theme.buttonHoverPrimary : "transparent"

                    Behavior on color { enabled: !Theme.animReducedMotion; ColorAnimation { duration: Theme.animFast } }
                }
            }
        }
    }
}
