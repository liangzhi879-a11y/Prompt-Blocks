import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

// Variable assignment panel for test preparation
Rectangle {
    id: varAssignRoot
    color: "transparent"

    property var variables: []
    property var values: ({})

    signal testValuesChanged(var valuesMap)

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.spacingSM

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingSM

            Text {
                text: Icons.diamond + " " + qsTr("变量赋值")
                color: Theme.onBackground
                font.pixelSize: Theme.fontSM
                font.weight: Font.DemiBold
            }

            Item { Layout.fillWidth: true }

            // AI generate test values button
            Rectangle {
                width: aiGenRow.width + 12
                height: 24
                radius: Theme.radiusSM
                color: aiGenHover.hovered ? Theme.primaryMuted : "transparent"
                border.color: Theme.primary
                border.width: 1

                Row {
                    id: aiGenRow
                    anchors.centerIn: parent
                    spacing: Theme.spacingXXS

                    Text {
                        text: Icons.star
                        font.pixelSize: Theme.fontXS
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: qsTr("AI生成测试值")
                        color: Theme.primary
                        font.pixelSize: Theme.fontXS
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                HoverHandler { id: aiGenHover }
                TapHandler {
                    onTapped: generateRandomValues()
                }
            }

            // Save preset button
            Rectangle {
                width: saveRow.width + 10
                height: 24
                radius: Theme.radiusSM
                color: saveHover.hovered ? Theme.surfaceVariant : "transparent"
                border.color: Theme.border
                border.width: 1

                Row {
                    id: saveRow
                    anchors.centerIn: parent
                    spacing: Theme.spacingXXS

                    Text {
                        text: Icons.circleThin
                        font.pixelSize: Theme.fontXS
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: qsTr("保存预设")
                        color: Theme.onSurfaceVariant
                        font.pixelSize: Theme.fontXS
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                HoverHandler { id: saveHover }
                TapHandler {
                    onTapped: savePreset()
                }
            }

            // Load preset button
            Rectangle {
                width: loadRow.width + 10
                height: 24
                radius: Theme.radiusSM
                color: loadHover.hovered ? Theme.surfaceVariant : "transparent"
                border.color: Theme.border
                border.width: 1

                Row {
                    id: loadRow
                    anchors.centerIn: parent
                    spacing: Theme.spacingXXS

                    Text {
                        text: Icons.folder
                        font.pixelSize: Theme.fontXS
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: qsTr("加载预设")
                        color: Theme.onSurfaceVariant
                        font.pixelSize: Theme.fontXS
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                HoverHandler { id: loadHover }
                TapHandler {
                    onTapped: presetDialog.open()
                }
            }
        }

        // Variable list
        Column {
            id: varList
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Theme.spacingXS
            clip: true

            Repeater {
                model: varAssignRoot.variables

                delegate: Rectangle {
                    width: varList.width
                    height: Theme.heightSM
                    radius: Theme.radiusSM
                    color: Theme.background
                    border.color: Theme.border
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.spacingSM
                        anchors.rightMargin: Theme.spacingSM
                        spacing: Theme.spacingSM

                        // Type icon
                        Text {
                            text: modelData.var_type === "text" ? Icons.edit :
                                  modelData.var_type === "number" ? Icons.tag :
                                  modelData.var_type === "list" ? Icons.list :
                                  modelData.var_type === "boolean" ? Icons.accept : Icons.edit
                            font.pixelSize: Theme.fontSM
                            Layout.alignment: Qt.AlignVCenter
                        }

                        // Variable name
                        Text {
                            text: modelData.name
                            color: Theme.primary
                            font.pixelSize: Theme.fontSM
                            font.family: Theme.codeFontFamily
                            font.weight: Font.Medium
                            Layout.preferredWidth: 70
                            elide: Text.ElideRight
                        }

                        // Value input
                        TextField {
                            id: valueField
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            placeholderText: modelData.default_value || qsTr("输入测试值...")
                            placeholderTextColor: Theme.onSurfaceVariant
                            color: Theme.onBackground
                            font.pixelSize: Theme.fontSM
                            // Use Component.onCompleted to set initial value (avoids binding loop)
                            Component.onCompleted: {
                                text = varAssignRoot.values[modelData.name] || modelData.default_value || ""
                            }

                            background: Rectangle {
                                color: Theme.surface
                                radius: Theme.radiusSM
                                border.color: valueField.activeFocus ? Theme.primary : Theme.borderLight
                                border.width: 1
                            }

                            onTextChanged: {
                                var newValues = Object.assign({}, varAssignRoot.values)
                                newValues[modelData.name] = text
                                varAssignRoot.values = newValues
                                varAssignRoot.testValuesChanged(newValues)
                            }
                        }
                    }
                }
            }

            // Empty state
            Text {
                visible: varAssignRoot.variables.length === 0
                text: qsTr("暂无变量，请先在提示词中使用 {{变量名}} 定义变量")
                color: Theme.onSurfaceVariant
                font.pixelSize: Theme.fontXS
                wrapMode: Text.WordWrap
                width: varList.width
                horizontalAlignment: Text.AlignHCenter
                opacity: 0.6
            }
        }
    }

    // Preset dialog
    VariablePresetDialog {
        id: presetDialog
        currentValues: varAssignRoot.values
        onLoadPreset: function(values) {
            varAssignRoot.values = values
            varAssignRoot.valuesChanged(values)
        }
    }

    function generateRandomValues() {
        if (!testViewModel) {
            // Fallback: simple random generation
            _generateFallbackValues()
            return
        }

        // Use LLM to generate variable values
        var varsJson = JSON.stringify(varAssignRoot.variables)
        var resultJson = testViewModel.generateVariableValues(varsJson)
        try {
            var values = JSON.parse(resultJson)
            if (values && Object.keys(values).length > 0) {
                varAssignRoot.values = values
                varAssignRoot.valuesChanged()
                varAssignRoot.testValuesChanged(values)
                return
            }
        } catch (e) {
        }

        // Fallback if LLM fails
        _generateFallbackValues()
    }

    function _generateFallbackValues() {
        var newValues = {}
        var sampleTexts = ["示例文本", "测试数据", "用户输入", "产品描述", "技术方案"]
        var sampleNumbers = ["10", "50", "100", "0.5", "1.0"]
        var sampleBooleans = ["true", "false"]
        var sampleLists = ["选项A,选项B,选项C", "项目1,项目2"]

        for (var i = 0; i < varAssignRoot.variables.length; i++) {
            var v = varAssignRoot.variables[i]
            switch (v.var_type) {
            case "number":
                newValues[v.name] = sampleNumbers[Math.floor(Math.random() * sampleNumbers.length)]
                break
            case "boolean":
                newValues[v.name] = sampleBooleans[Math.floor(Math.random() * sampleBooleans.length)]
                break
            case "list":
                newValues[v.name] = sampleLists[Math.floor(Math.random() * sampleLists.length)]
                break
            default:
                newValues[v.name] = sampleTexts[Math.floor(Math.random() * sampleTexts.length)]
                break
            }
        }
        varAssignRoot.values = newValues
        varAssignRoot.valuesChanged()
        varAssignRoot.testValuesChanged(newValues)
    }

    function savePreset() {
        presetDialog.saveCurrentPreset()
    }
}
