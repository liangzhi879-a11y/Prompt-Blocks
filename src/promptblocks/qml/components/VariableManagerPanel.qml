import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

Rectangle {
    id: varManager

    // Signals
    signal variableAdded(string name)
    signal variableRemoved(string name)

    // Properties
    property bool isExpanded: false
    property string addName: ""
    property string addType: "text"
    property string addDescription: ""
    property string addDefaultValue: ""

    height: isExpanded ? expandedHeight : collapsedHeight
    implicitHeight: isExpanded ? expandedHeight : collapsedHeight
    readonly property int collapsedHeight: Theme.heightSM
    readonly property int expandedHeight: 260

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
                color: Theme.accent
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                text: Icons.diamond + " 变量与参数"
                color: Theme.onBackground
                font.pixelSize: Theme.fontSM
                font.weight: Font.DemiBold
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                text: "(" + varList.count + ")"
                color: Theme.onSurfaceVariant
                font.pixelSize: Theme.fontXS
                Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }

            Text {
                text: varManager.isExpanded ? Icons.chevronUp : Icons.chevronDown
                font.pixelSize: Theme.fontXXS
                color: Theme.onSurfaceVariant
                Layout.alignment: Qt.AlignVCenter
            }

            TapHandler {
                onTapped: varManager.isExpanded = !varManager.isExpanded
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.divider }

        // ── Expanded content ──
        ColumnLayout {
            visible: varManager.isExpanded
            opacity: varManager.isExpanded ? 1 : 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Theme.spacingXS

            Behavior on opacity { enabled: !Theme.animReducedMotion; NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }

            // Add variable form
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 80
                Layout.margins: Theme.spacingS
                color: Theme.surfaceVariant
                radius: Theme.radiusSM
                border.color: Theme.border
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingS
                    spacing: Theme.spacingXS

                    // Name + Type row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacingXS

                        TextField {
                            id: varNameInput
                            Layout.fillWidth: true
                            Layout.preferredHeight: 24
                            placeholderText: "变量名"
                            font.pixelSize: Theme.fontXS
                            color: Theme.onBackground
                            background: Rectangle {
                                color: Theme.background
                                radius: 2
                                border.color: varNameInput.activeFocus ? Theme.primary : Theme.border
                                border.width: 1
                            }
                        }

                        ComboBox {
                            id: varTypeCombo
                            Layout.preferredWidth: 70
                            Layout.preferredHeight: 24
                            model: ["text", "number", "boolean", "list"]
                            currentIndex: 0
                            font.pixelSize: Theme.fontXS

                            background: Rectangle {
                                color: Theme.background
                                radius: 2
                                border.color: Theme.border
                                border.width: 1
                            }

                            contentItem: Text {
                                text: varTypeCombo.currentText
                                font.pixelSize: Theme.fontXS
                                color: Theme.onBackground
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        Rectangle {
                            id: addBtn
                            width: Theme.heightXS
                            height: 24
                            radius: 2
                            color: addBtnMA.containsMouse ? Theme.primary : Theme.primaryMuted

                            Text {
                                anchors.centerIn: parent
                                text: "+"
                                color: addBtnMA.containsMouse ? Theme.onPrimary : Theme.primary
                                font.pixelSize: Theme.fontMD
                                font.bold: true
                            }

                            MouseArea {
                                 id: addBtnMA
                                 anchors.fill: parent
                                 hoverEnabled: true
                                 cursorShape: Qt.PointingHandCursor
                                 onClicked: {
                                     var name = varNameInput.text.trim()
                                     if (name.length > 0 && variableModel) {
                                         var type = varTypeCombo.currentText
                                         var desc = varDescInput.text.trim()
                                         var defVal = varDefaultInput.text.trim()
                                         variableModel.addVariable(name, type, defVal, "global", desc)
                                         varNameInput.text = ""
                                         varDescInput.text = ""
                                         varDefaultInput.text = ""
                                         varManager.variableAdded(name)
                                     }
                                 }
                             }
                        }
                    }

                    // Description + Default value row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacingXS

                        TextField {
                            id: varDescInput
                            Layout.fillWidth: true
                            Layout.preferredHeight: 24
                            placeholderText: "说明（可选）"
                            font.pixelSize: Theme.fontXS
                            color: Theme.onBackground
                            background: Rectangle {
                                color: Theme.background
                                radius: 2
                                border.color: varDescInput.activeFocus ? Theme.primary : Theme.border
                                border.width: 1
                            }
                        }

                        TextField {
                            id: varDefaultInput
                            Layout.preferredWidth: 80
                            Layout.preferredHeight: 24
                            placeholderText: "默认值"
                            font.pixelSize: Theme.fontXS
                            color: Theme.onBackground
                            background: Rectangle {
                                color: Theme.background
                                radius: 2
                                border.color: varDefaultInput.activeFocus ? Theme.primary : Theme.border
                                border.width: 1
                            }
                        }
                    }
                }
            }

            // Variable list area with empty state
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: Theme.spacingS

                // Variable list
                ListView {
                    id: varList
                    anchors.fill: parent
                    clip: true
                    spacing: Theme.spacingXXS
                    model: variableModel
                    visible: varList.count > 0

                    delegate: Rectangle {
                        width: varList.width - 4
                        height: Theme.heightXS
                        radius: Theme.radiusSM
                        color: varItemHover.hovered ? Theme.primaryMuted : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.spacingS
                            anchors.rightMargin: Theme.spacingXS
                            spacing: Theme.spacingXS

                            Text {
                                text: model.name
                                color: Theme.onBackground
                                font.pixelSize: Theme.fontXS
                                font.family: Theme.codeFontFamily
                                font.bold: true
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                elide: Text.ElideRight
                            }

                            Text {
                                text: model.varType
                                color: Theme.onSurfaceVariant
                                font.pixelSize: Theme.fontS
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Text {
                                text: model.description || ""
                                color: Theme.onSurfaceVariant
                                font.pixelSize: Theme.fontS
                                Layout.alignment: Qt.AlignVCenter
                                elide: Text.ElideRight
                                Layout.maximumWidth: 60
                            }

                            Rectangle {
                                width: 20
                                height: 20
                                radius: 10
                                color: delVarHover.hovered ? Theme.error : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: Icons.close
                                    color: delVarHover.hovered ? Theme.onPrimary : Theme.onSurfaceVariant
                                    font.pixelSize: Theme.fontS
                                }

                                HoverHandler { id: delVarHover }
                                TapHandler {
                                    onTapped: {
                                        if (variableModel) {
                                            variableModel.removeVariable(model.varId)
                                            varManager.variableRemoved(model.name)
                                        }
                                    }
                                }
                            }
                        }

                        HoverHandler { id: varItemHover }
                    }
                }

                // Empty state — only visible when truly empty
                Text {
                    anchors.centerIn: parent
                    visible: varList.count === 0
                    text: "暂无变量。在上方表单中添加变量，\n或使用AI自动生成。"
                    color: Theme.onSurfaceVariant
                    font.pixelSize: Theme.fontXS
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
}
