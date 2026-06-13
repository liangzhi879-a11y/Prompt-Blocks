import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

Rectangle {
    id: panelRoot
    color: Theme.surface

    property string promptText: ""
    property var variableValues: ({})

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.containerPadding
        spacing: Theme.spacingSM

        // Description
        Text {
            Layout.fillWidth: true
            text: qsTr("\u4F18\u5316\u4F60\u4E0E AI \u7684\u5BF9\u8BDD\u8F93\u5165\uFF0C\u964D\u4F4E\u7406\u89E3\u6B67\u4E49\uFF0C\u63D0\u5347\u8F93\u51FA\u53EF\u63A7\u6027\u3002")
            color: Theme.onSurfaceVariant
            font.pixelSize: Theme.fontXS
            wrapMode: Text.WordWrap
            font.family: Theme.fontFamily
        }

        // Input area
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingXS

            Text {
                text: Icons.square + " " + qsTr("原始输入")
                color: Theme.onBackground
                font.pixelSize: Theme.fontSM
                font.weight: Font.DemiBold
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.preferredHeight: 120
                clip: true

                TextArea {
                    id: rawInputArea
                    placeholderText: qsTr("\u7C98\u8D34\u4F60\u60F3\u53D1\u7ED9 AI \u7684\u539F\u59CB\u5185\u5BB9...\n\n\u4F8B\u5982\uFF1A\u89E3\u91CA\u4E00\u4E0B Transformer \u67B6\u6784")
                    color: Theme.onBackground
                    font.pixelSize: Theme.fontSM
                    font.family: Theme.fontFamily
                    wrapMode: TextArea.WordWrap
                    selectByMouse: true
                    background: Rectangle {
                        color: Theme.background
                        radius: Theme.radiusSM
                        border.color: rawInputArea.activeFocus ? Theme.primary : Theme.border
                        border.width: 1
                    }
                }
            }
        }

        // Optimize button
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.heightSM
            radius: Theme.radiusSM
            color: optimBtnHover.hovered ? Theme.primary : Theme.primaryMuted

            RowLayout {
                anchors.centerIn: parent
                spacing: Theme.spacingS

                Text {
                    text: Icons.sparkle
                    font.family: Icons.fontFamily
                    font.pixelSize: Theme.fontMD
                }
                Text {
                    text: singleTurnViewModel && singleTurnViewModel.isOptimizing
                          ? qsTr("\u4F18\u5316\u4E2D...")
                          : qsTr("\u4F18\u5316\u63D0\u793A\u8BCD")
                    color: optimBtnHover.hovered ? Theme.onPrimary : Theme.primary
                    font.pixelSize: Theme.fontSM
                    font.bold: true
                    font.family: Theme.fontFamily
                }
            }

            HoverHandler { id: optimBtnHover }
            TapHandler {
                onTapped: {
                    if (singleTurnViewModel && !singleTurnViewModel.isOptimizing) {
                        singleTurnViewModel.optimize(rawInputArea.text)
                    }
                }
            }

            Behavior on color { enabled: !Theme.animReducedMotion; ColorAnimation { duration: Theme.animFast } }
        }

        // Optimization tips (collapsible)
        ColumnLayout {
            id: tipsSection
            Layout.fillWidth: true
            spacing: Theme.spacingXXS

            property bool tipsVisible: false

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingXS

                Text {
                    text: qsTr("\u4F18\u5316\u7B56\u7565\u8BF4\u660E")
                    color: Theme.primary
                    font.pixelSize: Theme.fontXS
                    font.weight: Font.DemiBold
                    font.family: Theme.fontFamily
                }

                Text {
                    text: tipsSection.tipsVisible ? Icons.chevronUp : Icons.chevronDown
                    font.pixelSize: Theme.fontXXS
                    color: Theme.primary
                    font.family: Icons.fontFamily
                }

                TapHandler {
                    onTapped: tipsSection.tipsVisible = !tipsSection.tipsVisible
                }

                Item { Layout.fillWidth: true }
            }

            ColumnLayout {
                Layout.fillWidth: true
                visible: tipsSection.tipsVisible
                spacing: Theme.spacingXXS

                Repeater {
                    model: [
                        { title: qsTr("\u89D2\u8272\u951A\u5B9A"), desc: qsTr("\u660E\u786E\u5B9A\u4E49 AI \u7684\u4E13\u5BB6\u89D2\u8272\uFF0C\u6FC0\u6D3B\u4E13\u4E1A\u77E5\u8BC6\u548C\u7279\u5B9A\u8BED\u6C14\u3002") },
                        { title: qsTr("\u76EE\u6807\u5177\u8C61\u5316"), desc: qsTr("\u91CF\u5316\u8F93\u51FA\u5F62\u5F0F\u3001\u6570\u91CF\u3001\u957F\u5EA6\u3001\u53D7\u4F17\u548C\u98CE\u683C\u3002") },
                        { title: qsTr("\u80CC\u666F\u6CE8\u5165"), desc: qsTr("\u63D0\u524D\u52A0\u8F7D\u6280\u672F\u6808\u3001\u7248\u672C\u53F7\u3001\u4E1A\u52A1\u573A\u666F\u7B49\u5DF2\u77E5\u6761\u4EF6\u3002") },
                        { title: qsTr("\u683C\u5F0F\u6307\u4EE4"), desc: qsTr("\u89C4\u5B9A\u8F93\u51FA\u6A21\u677F\uFF0C\u786E\u4FDD\u53EF\u89E3\u6790\u548C\u53EF\u8BFB\u3002") },
                        { title: qsTr("\u601D\u7EF4\u94FE\u7EA6\u675F"), desc: qsTr("\u8981\u6C42\u5206\u6B65\u601D\u8003\u5E76\u81EA\u6211\u68C0\u67E5\u3002") },
                        { title: qsTr("\u793A\u4F8B\u9A71\u52A8"), desc: qsTr("\u7528\u8F93\u5165-\u8F93\u51FA\u8303\u4F8B\u4EE3\u66FF\u89E3\u91CA\u89C4\u5219\u3002") },
                        { title: qsTr("\u5B89\u5168\u62A4\u680F"), desc: qsTr("\u63D0\u524D\u8BBE\u5B9A\u4F26\u7406\u548C\u5B89\u5168\u7EA6\u675F\u3002") },
                    ]
                    delegate: RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 8
                        spacing: Theme.spacingS

                        Rectangle {
                            width: 6; height: 6; radius: 3
                            color: Theme.primary
                        }

                        Text {
                            text: modelData.title
                            color: Theme.onSurface
                            font.pixelSize: Theme.fontXS
                            font.bold: true
                            font.family: Theme.fontFamily
                        }

                        Text {
                            text: modelData.desc
                            color: Theme.onSurfaceVariant
                            font.pixelSize: Theme.fontXS
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            font.family: Theme.fontFamily
                        }
                    }
                }
            }
        }

        // Output area
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Theme.spacingXS

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingSM

                Text {
                    text: Icons.accept + " " + qsTr("优化结果")
                    color: Theme.onBackground
                    font.pixelSize: Theme.fontSM
                    font.weight: Font.DemiBold
                }

                Item { Layout.fillWidth: true }

                // Copy button
                Rectangle {
                    width: copyBtnRow.width + 12
                    height: 24
                    radius: Theme.radiusSM
                    color: copyOptHover.hovered ? Theme.primaryMuted : "transparent"
                    border.color: Theme.primary
                    border.width: 1
                    visible: singleTurnViewModel && singleTurnViewModel.optimizedOutput.length > 0

                    Row {
                        id: copyBtnRow
                        anchors.centerIn: parent
                        spacing: Theme.spacingXS

                        Text {
                            text: Icons.list
                            font.family: Icons.fontFamily
                            font.pixelSize: Theme.fontXS
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: qsTr("\u590D\u5236")
                            color: Theme.primary
                            font.pixelSize: Theme.fontXS
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: Theme.fontFamily
                        }
                    }

                    HoverHandler { id: copyOptHover }
                    TapHandler {
                        onTapped: {
                            optimOutputArea.selectAll()
                            optimOutputArea.copy()
                        }
                    }
                }
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                TextArea {
                    id: optimOutputArea
                    readOnly: true
                    text: singleTurnViewModel ? singleTurnViewModel.optimizedOutput : ""
                    color: Theme.onBackground
                    font.pixelSize: Theme.fontSM
                    font.family: Theme.fontFamily
                    wrapMode: TextArea.WordWrap
                    selectByMouse: true
                    placeholderText: singleTurnViewModel && singleTurnViewModel.isOptimizing
                                     ? qsTr("\u6B63\u5728\u8C03\u7528 AI \u4F18\u5316\u4E2D\uFF0C\u8BF7\u7A0D\u5019...")
                                     : qsTr("\u4F18\u5316\u540E\u7684\u63D0\u793A\u8BCD\u5C06\u663E\u793A\u5728\u8FD9\u91CC")
                    background: Rectangle {
                        color: Theme.background
                        radius: Theme.radiusSM
                        border.color: singleTurnViewModel && singleTurnViewModel.optimizedOutput.length > 0
                                      ? Theme.secondary : Theme.border
                        border.width: 1
                    }

                    // Auto-connect to viewmodel updates
                    Connections {
                        target: singleTurnViewModel
                        function onOptimizationCompleted() {
                            optimOutputArea.text = singleTurnViewModel.optimizedOutput
                        }
                        function onOptimizationFailed(message) {
                            optimOutputArea.text = qsTr("\u4F18\u5316\u5931\u8D25: ") + message
                        }
                    }
                }
            }
        }
    }
}
