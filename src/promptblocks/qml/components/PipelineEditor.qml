import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

Popup {
    id: pipelineEditor
    width: 380
    height: 560
    padding: Theme.spacingMD
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    property string inputPipelineJson: "[]"
    property string outputPipelineJson: "[]"
    property string previewInputText: ""
    property var availableFilters: ["sanitize", "trim", "lowercase", "uppercase", "json_pretty", "mask_pii"]

    property alias inputFilters: inputFilterModel
    property alias outputFilters: outputFilterModel

    background: Rectangle {
        color: Theme.surface
        radius: Theme.radiusMD
        border.color: Theme.border
        border.width: 1
    }

    contentItem: ColumnLayout {
        spacing: Theme.spacingMD

        // Header
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: qsTr("变量过滤配置")
                color: Theme.onBackground
                font.pixelSize: Theme.fontLG
                font.bold: true
                font.family: Theme.fontFamily
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                width: 24
                height: 24
                radius: 12
                color: closeHover.hovered ? Theme.error : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: Icons.close
                    font.family: Icons.fontFamily
                    color: closeHover.hovered ? Theme.onPrimary : Theme.onSurfaceVariant
                    font.pixelSize: Theme.fontS
                }

                HoverHandler { id: closeHover }
                TapHandler { onTapped: pipelineEditor.close() }
            }
        }

        // Description with detailed filter guide
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingXS

            Text {
                Layout.fillWidth: true
                text: qsTr("变量过滤可以对 {{变量}} 的值应用预处理和后处理，确保数据格式正确、内容安全。")
                color: Theme.onSurfaceVariant
                font.pixelSize: Theme.fontXS
                wrapMode: Text.WordWrap
                font.family: Theme.fontFamily
            }

            // Filter guide (collapsible)
            ColumnLayout {
                id: filterGuideColumn
                Layout.fillWidth: true
                spacing: Theme.spacingXXS

                property bool filterGuideVisible: false

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingXS

                    Text {
                        text: qsTr("过滤方式说明")
                        color: Theme.primary
                        font.pixelSize: Theme.fontXS
                        font.bold: true
                        font.family: Theme.fontFamily
                    }

                    Text {
                        text: filterGuideColumn.filterGuideVisible ? Icons.chevronUp : Icons.chevronDown
                        font.pixelSize: Theme.fontXXS
                        color: Theme.primary
                    }

                    TapHandler {
                        onTapped: filterGuideColumn.filterGuideVisible = !filterGuideColumn.filterGuideVisible
                    }

                    Item { Layout.fillWidth: true }
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: filterGuideColumn.filterGuideVisible ? Math.min(contentHeight, 180) : 0
                    visible: filterGuideColumn.filterGuideVisible
                    clip: true
                    spacing: Theme.spacingXS
                    model: [
                        { name: "sanitize", desc: qsTr("移除HTML标签，防止注入攻击。适用于用户输入可能包含HTML的场景。"), example: "{{user_input | sanitize}}" },
                        { name: "trim", desc: qsTr("去除首尾空白字符。适用于用户可能误输入多余空格的场景。"), example: "{{query | trim}}" },
                        { name: "lowercase", desc: qsTr("转换为小写。适用于不区分大小写的匹配或标准化处理。"), example: "{{keyword | lowercase}}" },
                        { name: "uppercase", desc: qsTr("转换为大写。适用于标题或需要强调的文本。"), example: "{{title | uppercase}}" },
                        { name: "json_pretty", desc: qsTr("格式化JSON输出，增加缩进和换行。适用于输出结构化数据的场景。"), example: "{{api_response | json_pretty}}" },
                        { name: "mask_pii", desc: qsTr("遮蔽个人敏感信息（邮箱、手机号）。适用于隐私保护场景。"), example: "{{user_data | mask_pii}}" },
                    ]
                    delegate: ColumnLayout {
                        width: ListView.view.width
                        spacing: 1

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spacingXS

                            Rectangle {
                                width: 8
                                height: 8
                                radius: 4
                                color: Theme.primary
                            }

                            Text {
                                text: modelData.name
                                color: Theme.onSurface
                                font.pixelSize: Theme.fontXS
                                font.bold: true
                                font.family: Theme.codeFontFamily
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            text: modelData.desc
                            color: Theme.onSurfaceVariant
                            font.pixelSize: Theme.fontXS
                            wrapMode: Text.WordWrap
                            font.family: Theme.fontFamily
                        }

                        Text {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            text: qsTr("示例：") + modelData.example
                            color: Theme.primary
                            font.pixelSize: Theme.fontXS
                            font.family: Theme.codeFontFamily
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            height: 1
                            color: Theme.divider
                        }
                    }

                    Behavior on Layout.preferredHeight { enabled: !Theme.animReducedMotion; NumberAnimation { duration: Theme.animNormal } }
                }
            }
        }

        // ── Input preprocessing ──
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingSM

            Text {
                text: qsTr("输入预处理")
                color: Theme.primary
                font.pixelSize: Theme.fontSM
                font.bold: true
                font.family: Theme.fontFamily
            }

            // Add filter row
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingSM

                ComboBox {
                    id: inputFilterCombo
                    Layout.fillWidth: true
                    model: pipelineEditor.availableFilters
                    currentIndex: 0
                }

                Rectangle {
                    width: 28
                    height: Theme.heightXS
                    radius: Theme.radiusSM
                    color: addInputHover.hovered ? Theme.primary : Theme.primaryMuted

                    Text {
                        anchors.centerIn: parent
                        text: "+"
                        color: addInputHover.hovered ? Theme.onPrimary : Theme.primary
                        font.pixelSize: Theme.fontMD
                        font.bold: true
                    }

                    HoverHandler { id: addInputHover }
                    TapHandler {
                        onTapped: {
                            var name = pipelineEditor.availableFilters[inputFilterCombo.currentIndex]
                            inputFilterModel.append({"filterName": name})
                        }
                    }

                    Behavior on color { enabled: !Theme.animReducedMotion; ColorAnimation { duration: Theme.animFast } }
                }
            }

            // Active input filters
            ListView {
                Layout.fillWidth: true
                height: Math.min(inputFilterModel.count * 32, 96)
                clip: true
                spacing: Theme.spacingXXS

                model: ListModel { id: inputFilterModel }

                delegate: Rectangle {
                    width: ListView.view.width
                    height: Theme.heightXS
                    radius: Theme.radiusSM
                    color: Theme.surfaceVariant

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.spacingSM
                        anchors.rightMargin: Theme.spacingSM
                        spacing: Theme.spacingSM

                        Text {
                            text: model.filterName
                            color: Theme.onSurface
                            font.pixelSize: Theme.fontSM
                            font.family: Theme.codeFontFamily
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            width: 18
                            height: 18
                            radius: 9
                            color: removeInputHover.hovered ? Theme.error : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: Icons.close
                                font.pixelSize: Theme.fontS
                                color: removeInputHover.hovered ? Theme.onPrimary : Theme.onSurfaceVariant
                            }

                            HoverHandler { id: removeInputHover }
                            TapHandler {
                                onTapped: inputFilterModel.remove(index)
                            }
                        }
                    }
                }
            }
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.divider
        }

        // ── Output post-processing ──
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingSM

            Text {
                text: qsTr("输出后处理")
                color: Theme.accent
                font.pixelSize: Theme.fontSM
                font.bold: true
                font.family: Theme.fontFamily
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingSM

                ComboBox {
                    id: outputFilterCombo
                    Layout.fillWidth: true
                    model: pipelineEditor.availableFilters
                    currentIndex: 0
                }

                Rectangle {
                    width: 28
                    height: Theme.heightXS
                    radius: Theme.radiusSM
                    color: addOutputHover.hovered ? Theme.accent : Theme.accentMuted

                    Text {
                        anchors.centerIn: parent
                        text: "+"
                        color: addOutputHover.hovered ? Theme.onPrimary : Theme.accent
                        font.pixelSize: Theme.fontMD
                        font.bold: true
                    }

                    HoverHandler { id: addOutputHover }
                    TapHandler {
                        onTapped: {
                            var name = pipelineEditor.availableFilters[outputFilterCombo.currentIndex]
                            outputFilterModel.append({"filterName": name})
                        }
                    }

                    Behavior on color { enabled: !Theme.animReducedMotion; ColorAnimation { duration: Theme.animFast } }
                }
            }

            ListView {
                Layout.fillWidth: true
                height: Math.min(outputFilterModel.count * 32, 96)
                clip: true
                spacing: Theme.spacingXXS

                model: ListModel { id: outputFilterModel }

                delegate: Rectangle {
                    width: ListView.view.width
                    height: Theme.heightXS
                    radius: Theme.radiusSM
                    color: Theme.surfaceVariant

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.spacingSM
                        anchors.rightMargin: Theme.spacingSM
                        spacing: Theme.spacingSM

                        Text {
                            text: model.filterName
                            color: Theme.onSurface
                            font.pixelSize: Theme.fontSM
                            font.family: Theme.codeFontFamily
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            width: 18
                            height: 18
                            radius: 9
                            color: removeOutputHover.hovered ? Theme.error : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: Icons.close
                                font.pixelSize: Theme.fontS
                                color: removeOutputHover.hovered ? Theme.onPrimary : Theme.onSurfaceVariant
                            }

                            HoverHandler { id: removeOutputHover }
                            TapHandler {
                                onTapped: outputFilterModel.remove(index)
                            }
                        }
                    }
                }
            }
        }

        // ── Preview ──
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingXS

            Text {
                text: qsTr("预览")
                color: Theme.onSurface
                font.pixelSize: Theme.fontSM
                font.bold: true
                font.family: Theme.fontFamily
            }

            ScrollView {
                Layout.fillWidth: true
                height: 60
                clip: true

                TextArea {
                    id: previewArea
                    readOnly: true
                    text: {
                        if (!pipelineProcessor || !pipelineEditor.previewInputText) return ""
                        var filters = []
                        for (var i = 0; i < inputFilterModel.count; i++) {
                            filters.push(inputFilterModel.get(i).filterName)
                        }
                        for (var j = 0; j < outputFilterModel.count; j++) {
                            filters.push(outputFilterModel.get(j).filterName)
                        }
                        var result = pipelineEditor.previewInputText
                        for (var k = 0; k < filters.length; k++) {
                            result = pipelineProcessor.applyFilter(result, filters[k])
                        }
                        return result
                    }
                    color: Theme.onBackground
                    font.pixelSize: Theme.fontXS
                    font.family: Theme.codeFontFamily
                    wrapMode: TextArea.WordWrap
                    background: Rectangle {
                        color: Theme.background
                        radius: Theme.radiusSM
                        border.color: Theme.border
                        border.width: 1
                    }
                }
            }
        }
    }
}
