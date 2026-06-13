import QtQuick
import QtQuick.Controls
import ".."

Popup {
    id: errorPopupRoot

    property var errors: []
    property string cardId: ""

    x: 0
    y: 0
    width: 300
    height: Math.min(360, errorContent.implicitHeight + 32)
    padding: 12
    modal: false
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    background: Rectangle {
        color: Theme.surface
        border.color: Theme.error
        border.width: 1
        radius: Theme.radiusMD

        Rectangle {
            anchors.fill: parent
            anchors.margins: -2
            radius: parent.radius + 2
            color: "transparent"
            border.color: Theme.shadowColor
            border.width: 2
            z: -1
        }
    }

    contentItem: Column {
        id: errorContent
        spacing: Theme.spacingSM

        // Header
        Row {
            spacing: Theme.spacingS

            Text {
                text: Icons.warning
                font.pixelSize: Theme.fontLG
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: qsTr("\u8BED\u6CD5\u68C0\u67E5\u7ED3\u679C")
                color: Theme.error
                font.pixelSize: Theme.fontMD
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }

            Item { width: 4 }

            Text {
                text: qsTr("(%1\u6761)").arg(errorPopupRoot.errors.length)
                color: Theme.onSurfaceVariant
                font.pixelSize: Theme.fontSM
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // Divider
        Rectangle {
            width: parent.width
            height: 1
            color: Theme.divider
        }

        // Error list
        ScrollView {
            width: parent.width
            height: Math.min(220, errorPopupRoot.errors.length * 32)
            clip: true

            ListView {
                model: errorPopupRoot.errors
                spacing: Theme.spacingXS

                delegate: Rectangle {
                    width: ListView.view.width
                    height: Theme.heightXS
                    radius: Theme.radiusSM
                    color: modelData.severity === "error" ? Theme.error + "12" : Theme.warning + "12"

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: Theme.spacingS

                        Text {
                            text: modelData.severity === "error" ? Icons.close : Icons.warning
                            font.pixelSize: Theme.fontS
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: qsTr("L%1").arg(modelData.line)
                            color: modelData.severity === "error" ? Theme.error : Theme.warning
                            font.pixelSize: Theme.fontXS
                            font.bold: true
                            font.family: Theme.codeFontFamily
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
        }

        // Divider
        Rectangle {
            width: parent.width
            height: 1
            color: Theme.divider
        }

        // AI auto-fix button
        Rectangle {
            width: parent.width
            height: 32
            radius: Theme.radiusSM
            color: aiFixHover.hovered ? Theme.primary : Theme.primaryMuted
            border.color: Theme.primary
            border.width: 1

            Row {
                anchors.centerIn: parent
                spacing: Theme.spacingS

                Text {
                    text: Icons.sparkle
                    font.pixelSize: Theme.fontML
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: qsTr("AI\u81EA\u52A8\u4FEE\u590D")
                    color: aiFixHover.hovered ? Theme.onPrimary : Theme.primary
                    font.pixelSize: Theme.fontSM
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            HoverHandler { id: aiFixHover }
            TapHandler {
                onTapped: {
                    console.log("[ErrorPopup] AI auto-fix requested for card:", errorPopupRoot.cardId)
                    errorPopupRoot.close()
                }
            }

            Behavior on color { enabled: !Theme.animReducedMotion; ColorAnimation { duration: Theme.animFast } }
        }
    }
}
