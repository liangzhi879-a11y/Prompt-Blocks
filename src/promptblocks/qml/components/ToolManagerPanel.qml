import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

Rectangle {
    id: toolManager

    signal toolAdded(string name)
    signal toolRemoved(string name)

    property bool isExpanded: false

    height: isExpanded ? expandedHeight : collapsedHeight
    implicitHeight: isExpanded ? expandedHeight : collapsedHeight
    readonly property int collapsedHeight: Theme.heightSM
    readonly property int expandedHeight: 220

    color: Theme.surface
    border.color: Theme.panelBorder
    border.width: 1
    radius: Theme.radiusSM

    Behavior on height { enabled: !Theme.animReducedMotion; NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header row
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.heightSM
            Layout.leftMargin: Theme.spacingSM
            Layout.rightMargin: Theme.spacingSM

            Rectangle {
                width: 3; height: 14; radius: 2
                color: Theme.moduleTypeColors["capability_tool"].accent
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                text: Icons.settings + " 工具配置"
                color: Theme.onBackground
                font.pixelSize: Theme.fontSM
                font.weight: Font.DemiBold
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                text: "(" + toolList.count + ")"
                color: Theme.onSurfaceVariant
                font.pixelSize: Theme.fontXS
                Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }

            Text {
                text: toolManager.isExpanded ? Icons.chevronUp : Icons.chevronDown
                font.pixelSize: Theme.fontXXS
                color: Theme.onSurfaceVariant
                Layout.alignment: Qt.AlignVCenter
            }

            TapHandler {
                onTapped: toolManager.isExpanded = !toolManager.isExpanded
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.divider }

        // Expanded content
        ColumnLayout {
            visible: toolManager.isExpanded
            opacity: toolManager.isExpanded ? 1 : 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Theme.spacingXS

            Behavior on opacity { enabled: !Theme.animReducedMotion; NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }

            // Add tool form
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 68
                Layout.margins: Theme.spacingS
                color: Theme.surfaceVariant
                radius: Theme.radiusSM
                border.color: Theme.border
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingS
                    spacing: Theme.spacingXS

                    // Name + ToolType row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacingXS

                        TextField {
                            id: toolNameInput
                            Layout.fillWidth: true
                            Layout.preferredHeight: 24
                            placeholderText: "\u5DE5\u5177\u540D\u79F0"
                            font.pixelSize: Theme.fontXS
                            color: Theme.onBackground
                            background: Rectangle {
                                color: Theme.background
                                radius: 2
                                border.color: toolNameInput.activeFocus ? Theme.primary : Theme.border
                                border.width: 1
                            }
                        }

                        ComboBox {
                            id: toolTypeCombo
                            Layout.preferredWidth: 80
                            Layout.preferredHeight: 24
                            model: ["function", "api", "cli", "sdk"]
                            currentIndex: 0
                            font.pixelSize: Theme.fontXS

                            background: Rectangle {
                                color: Theme.background
                                radius: 2
                                border.color: Theme.border
                                border.width: 1
                            }

                            contentItem: Text {
                                text: toolTypeCombo.currentText
                                font.pixelSize: Theme.fontXS
                                color: Theme.onBackground
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        Rectangle {
                            id: addToolBtn
                            width: 28
                            height: 24
                            radius: 2
                            color: addToolBtnMA.containsMouse ? Theme.primary : Theme.primaryMuted

                            Text {
                                anchors.centerIn: parent
                                text: "+"
                                color: addToolBtnMA.containsMouse ? Theme.onPrimary : Theme.primary
                                font.pixelSize: Theme.fontMD
                                font.bold: true
                            }

                            MouseArea {
                                id: addToolBtnMA
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var name = toolNameInput.text.trim()
                                    if (name.length > 0 && toolModel) {
                                        var ttype = toolTypeCombo.currentText
                                        var desc = toolDescInput.text.trim()
                                        var params = toolParamsInput.text.trim()
                                        var endpoint = toolEndpointInput.text.trim()
                                        toolModel.addTool(name, ttype, desc, params, endpoint)
                                        toolNameInput.text = ""
                                        toolDescInput.text = ""
                                        toolParamsInput.text = ""
                                        toolEndpointInput.text = ""
                                        toolManager.toolAdded(name)
                                    }
                                }
                            }
                        }
                    }

                    // Description + Endpoint row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacingXS

                        TextField {
                            id: toolDescInput
                            Layout.fillWidth: true
                            Layout.preferredHeight: 24
                            placeholderText: "\u63CF\u8FF0\uFF08\u53EF\u9009\uFF09"
                            font.pixelSize: Theme.fontXS
                            color: Theme.onBackground
                            background: Rectangle {
                                color: Theme.background
                                radius: 2
                                border.color: toolDescInput.activeFocus ? Theme.primary : Theme.border
                                border.width: 1
                            }
                        }

                        TextField {
                            id: toolParamsInput
                            Layout.preferredWidth: 70
                            Layout.preferredHeight: 24
                            placeholderText: "\u53C2\u6570"
                            font.pixelSize: Theme.fontXS
                            color: Theme.onBackground
                            background: Rectangle {
                                color: Theme.background
                                radius: 2
                                border.color: toolParamsInput.activeFocus ? Theme.primary : Theme.border
                                border.width: 1
                            }
                        }

                        TextField {
                            id: toolEndpointInput
                            Layout.preferredWidth: 70
                            Layout.preferredHeight: 24
                            placeholderText: "\u7AEF\u70B9"
                            font.pixelSize: Theme.fontXS
                            color: Theme.onBackground
                            background: Rectangle {
                                color: Theme.background
                                radius: 2
                                border.color: toolEndpointInput.activeFocus ? Theme.primary : Theme.border
                                border.width: 1
                            }
                        }
                    }
                }
            }

            // Tool list with empty state
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: Theme.spacingS

                ListView {
                    id: toolList
                    anchors.fill: parent
                    clip: true
                    spacing: Theme.spacingXXS
                    model: toolModel
                    visible: toolList.count > 0

                    delegate: Rectangle {
                        width: toolList.width - 4
                        height: 26
                        radius: Theme.radiusSM
                        color: toolItemHover.hovered ? Theme.primaryMuted : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 6
                            anchors.rightMargin: 4
                            spacing: Theme.spacingXS

                            Text {
                                text: model.toolType === "function" ? Icons.settings :
                                      model.toolType === "api" ? Icons.circleThin :
                                      model.toolType === "cli" ? Icons.folder : Icons.folder
                                font.pixelSize: Theme.fontXS
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Text {
                                text: model.name
                                color: Theme.onBackground
                                font.pixelSize: Theme.fontXS
                                font.family: Theme.fontFamily
                                font.bold: true
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                elide: Text.ElideRight
                            }

                            Text {
                                text: model.toolType
                                color: Theme.onSurfaceVariant
                                font.pixelSize: Theme.fontS
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Rectangle {
                                width: 18
                                height: 18
                                radius: 9
                                color: delToolHover.hovered ? Theme.error : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: Icons.close
                                    color: delToolHover.hovered ? Theme.onPrimary : Theme.onSurfaceVariant
                                    font.pixelSize: Theme.fontXXS
                                }

                                HoverHandler { id: delToolHover }
                                TapHandler {
                                    onTapped: {
                                        if (toolModel) {
                                            toolModel.removeTool(model.toolId)
                                            toolManager.toolRemoved(model.name)
                                        }
                                    }
                                }
                            }
                        }

                        HoverHandler { id: toolItemHover }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: toolList.count === 0
                    text: "\u6682\u65E0\u5DE5\u5177\u3002\u6A21\u4EFF agent \u642D\u5EFA\uFF0C\n\u6DFB\u52A0\u5DE5\u5177\u4F9BAI\u751F\u6210\u65F6\u53C2\u8003\u3002"
                    color: Theme.onSurfaceVariant
                    font.pixelSize: Theme.fontXS
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
}
