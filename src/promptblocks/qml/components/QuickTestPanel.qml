import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

// Quick single test panel
Rectangle {
    id: quickTestRoot
    color: "transparent"

    property string promptText: ""
    property string editedPreviewText: ""

    // Test result state
    property string outputText: ""
    property real contentScore: 0
    property real formatScore: 0
    property real safetyScore: 0
    property real consistencyScore: 0
    property real speedScore: 0
    property real latencyMs: 0
    property string suggestions: ""
    property bool hasResult: false
    property string lastResultJson: ""

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.containerPadding
        spacing: Theme.spacingSM

        // Test input area
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingXS

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingSM

                Text {
                    text: Icons.square + " " + qsTr("测试输入")
                    color: Theme.onBackground
                    font.pixelSize: Theme.fontSM
                    font.weight: Font.DemiBold
                }

                Item { Layout.fillWidth: true }

                // AI generate test question button
                Rectangle {
                    width: aiQRow.width + 10
                    height: 22
                    radius: Theme.radiusSM
                    color: aiQHover.hovered ? Theme.primaryMuted : "transparent"
                    border.color: Theme.primary
                    border.width: 1

                    Row {
                        id: aiQRow
                        anchors.centerIn: parent
                        spacing: Theme.spacingXXS

                        Text {
                            text: Icons.star
                            font.pixelSize: Theme.fontS
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: qsTr("AI生成测试问题")
                            color: Theme.primary
                            font.pixelSize: Theme.fontXS
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    HoverHandler { id: aiQHover }
                    TapHandler {
                        onTapped: generateTestQuestion()
                    }
                }
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.preferredHeight: 80
                clip: true

                TextArea {
                    id: testInputArea
                    placeholderText: qsTr("输入测试问题...")
                    placeholderTextColor: Theme.onSurfaceVariant
                    color: Theme.onBackground
                    font.pixelSize: Theme.fontSM
                    wrapMode: TextArea.WordWrap
                    selectByMouse: true
                    background: Rectangle {
                        color: Theme.background
                        radius: Theme.radiusSM
                        border.color: testInputArea.activeFocus ? Theme.primary : Theme.border
                        border.width: 1
                    }
                }
            }
        }

        // Run test button
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            radius: Theme.radiusSM
            color: {
                if (!isEnabled) return Theme.border
                return runHover.hovered ? Qt.darker(Theme.primary, 1.1) : Theme.primary
            }

            property bool isEnabled: testInputArea.text.trim().length > 0 &&
                                   !(testViewModel && testViewModel.isRunning)

            Row {
                anchors.centerIn: parent
                spacing: Theme.spacingS

                Text {
                    text: testViewModel && testViewModel.isRunning ? Icons.hourglass : Icons.play
                    font.pixelSize: Theme.fontML
                    color: Theme.onPrimary
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: testViewModel && testViewModel.isRunning ? qsTr("测试中...") : qsTr("运行测试")
                    color: Theme.onPrimary
                    font.pixelSize: Theme.fontSM
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            HoverHandler { id: runHover }
            TapHandler {
                onTapped: runQuickTest()
            }

            Behavior on color { enabled: !Theme.animReducedMotion; ColorAnimation { duration: Theme.animFast } }
        }

        // Loading indicator
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 4
            radius: 2
            color: Theme.surfaceVariant
            visible: testViewModel && testViewModel.isRunning

            Rectangle {
                width: parent.width * (testViewModel ? testViewModel.progress / Math.max(testViewModel.totalTests, 1) : 0)
                height: parent.height
                radius: 2
                color: Theme.primary

                Behavior on width { enabled: !Theme.animReducedMotion; NumberAnimation { duration: Theme.animNormal } }
            }
        }

        // Loading animation overlay
        Row {
            Layout.fillWidth: true
            visible: testViewModel && testViewModel.isRunning
            spacing: Theme.spacingS
            layoutDirection: Qt.LeftToRight

            Text {
                text: Icons.hourglass
                font.pixelSize: Theme.fontSM
                anchors.verticalCenter: parent.verticalCenter

                SequentialAnimation on opacity {
                    running: quickTestRoot.visible && testViewModel && testViewModel.isRunning
                    loops: Animation.Infinite
                    NumberAnimation { from: 1.0; to: 0.3; duration: Theme.animSlow }
                    NumberAnimation { from: 0.3; to: 1.0; duration: Theme.animSlow }
                }
            }
            Text {
                text: qsTr("正在调用AI模型，请稍候...")
                color: Theme.primary
                font.pixelSize: Theme.fontXS
                anchors.verticalCenter: parent.verticalCenter
                opacity: 0.7
            }
        }

        // Error message display
        Rectangle {
            Layout.fillWidth: true
            visible: testViewModel && testViewModel.errorMessage.length > 0
            height: errorRow.height + 12
            radius: Theme.radiusSM
            color: Theme.errorContainer
            border.color: Theme.error
            border.width: 1

            Row {
                id: errorRow
                anchors.centerIn: parent
                spacing: Theme.spacingS

                Text {
                    text: Icons.warning
                    font.pixelSize: Theme.fontS
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: testViewModel ? testViewModel.errorMessage : ""
                    color: Theme.error
                    font.pixelSize: Theme.fontXS
                    anchors.verticalCenter: parent.verticalCenter
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }

        // Results area
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Theme.spacingSM
            visible: quickTestRoot.hasResult

            // LLM Output
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingXS

                Text {
                    text: Icons.edit + " " + qsTr("LLM输出")
                    color: Theme.onBackground
                    font.pixelSize: Theme.fontSM
                    font.weight: Font.DemiBold
                }

                ScrollView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                    clip: true

                    TextArea {
                        id: outputDisplay
                        text: quickTestRoot.outputText
                        readOnly: true
                        color: Theme.onBackground
                        font.pixelSize: Theme.fontSM
                        font.family: Theme.codeFontFamily
                        wrapMode: TextArea.WordWrap
                        selectByMouse: true
                        background: Rectangle {
                            color: Theme.background
                            radius: Theme.radiusSM
                            border.color: Theme.border
                            border.width: 1
                        }
                    }
                }
            }

            // Score bars
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingXS

                Text {
                    text: Icons.diamond + " " + qsTr("评分")
                    color: Theme.onBackground
                    font.pixelSize: Theme.fontSM
                    font.weight: Font.DemiBold
                }

                // Content quality score
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingSM

                    Text {
                        text: qsTr("内容质量")
                        color: Theme.onSurface
                        font.pixelSize: Theme.fontXS
                        Layout.preferredWidth: 55
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 8
                        radius: 4
                        color: Theme.surfaceVariant

                        Rectangle {
                            width: parent.width * (quickTestRoot.contentScore / 10)
                            height: parent.height
                            radius: 4
                            color: quickTestRoot.contentScore >= 7 ? Theme.secondary :
                                   quickTestRoot.contentScore >= 4 ? Theme.warning : Theme.error

                            Behavior on width { enabled: !Theme.animReducedMotion; NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasing } }
                            Behavior on color { enabled: !Theme.animReducedMotion; ColorAnimation { duration: Theme.animFast } }
                        }
                    }

                    Text {
                        text: quickTestRoot.contentScore.toFixed(1)
                        color: Theme.onSurfaceVariant
                        font.pixelSize: Theme.fontSM
                    }
                }

                // Format compliance score
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingSM

                    Text {
                        text: qsTr("格式规范")
                        color: Theme.onSurface
                        font.pixelSize: Theme.fontXS
                        Layout.preferredWidth: 55
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 8
                        radius: 4
                        color: Theme.surfaceVariant

                        Rectangle {
                            width: parent.width * (quickTestRoot.formatScore / 10)
                            height: parent.height
                            radius: 4
                            color: quickTestRoot.formatScore >= 7 ? Theme.secondary :
                                   quickTestRoot.formatScore >= 4 ? Theme.warning : Theme.error

                            Behavior on width { enabled: !Theme.animReducedMotion; NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasing } }
                            Behavior on color { enabled: !Theme.animReducedMotion; ColorAnimation { duration: Theme.animFast } }
                        }
                    }

                    Badge {
                        text: quickTestRoot.formatScore.toFixed(1)
                        badgeStyle: 4
                        badgeSize: 0
                    }
                }

                // Safety level score
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingSM

                    Text {
                        text: qsTr("安全等级")
                        color: Theme.onSurface
                        font.pixelSize: Theme.fontXS
                        Layout.preferredWidth: 55
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 8
                        radius: 4
                        color: Theme.surfaceVariant

                        Rectangle {
                            width: parent.width * (quickTestRoot.safetyScore / 10)
                            height: parent.height
                            radius: 4
                            color: quickTestRoot.safetyScore >= 7 ? Theme.secondary :
                                   quickTestRoot.safetyScore >= 4 ? Theme.warning : Theme.error

                            Behavior on width { enabled: !Theme.animReducedMotion; NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasing } }
                            Behavior on color { enabled: !Theme.animReducedMotion; ColorAnimation { duration: Theme.animFast } }
                        }
                    }

                    Badge {
                        text: quickTestRoot.safetyScore.toFixed(1)
                        badgeStyle: 4
                        badgeSize: 0
                    }
                }

                // Consistency score (NEW)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingSM

                    Text {
                        text: qsTr("一致性")
                        color: Theme.onSurface
                        font.pixelSize: Theme.fontXS
                        Layout.preferredWidth: 55
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 8
                        radius: 4
                        color: Theme.surfaceVariant

                        Rectangle {
                            width: parent.width * (quickTestRoot.consistencyScore / 10)
                            height: parent.height
                            radius: 4
                            color: quickTestRoot.consistencyScore >= 7 ? Theme.secondary :
                                   quickTestRoot.consistencyScore >= 4 ? Theme.warning : Theme.error

                            Behavior on width { enabled: !Theme.animReducedMotion; NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasing } }
                            Behavior on color { enabled: !Theme.animReducedMotion; ColorAnimation { duration: Theme.animFast } }
                        }
                    }

                    Badge {
                        text: quickTestRoot.consistencyScore.toFixed(1)
                        badgeStyle: 4
                        badgeSize: 0
                    }
                }

                // Speed score (NEW)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingSM

                    Text {
                        text: qsTr("响应速度")
                        color: Theme.onSurface
                        font.pixelSize: Theme.fontXS
                        Layout.preferredWidth: 55
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 8
                        radius: 4
                        color: Theme.surfaceVariant

                        Rectangle {
                            width: parent.width * (quickTestRoot.speedScore / 10)
                            height: parent.height
                            radius: 4
                            color: quickTestRoot.speedScore >= 7 ? Theme.secondary :
                                   quickTestRoot.speedScore >= 4 ? Theme.warning : Theme.error

                            Behavior on width { enabled: !Theme.animReducedMotion; NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasing } }
                            Behavior on color { enabled: !Theme.animReducedMotion; ColorAnimation { duration: Theme.animFast } }
                        }
                    }

                    Badge {
                        text: quickTestRoot.speedScore.toFixed(1)
                        badgeStyle: 4
                        badgeSize: 0
                    }
                }

                // Latency display
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingSM

                    Text {
                        text: qsTr("延迟")
                        color: Theme.onSurface
                        font.pixelSize: Theme.fontXS
                        Layout.preferredWidth: 55
                    }

                    Text {
                        text: quickTestRoot.latencyMs > 0 ?
                              (quickTestRoot.latencyMs >= 1000 ?
                               (quickTestRoot.latencyMs / 1000).toFixed(1) + "s" :
                               quickTestRoot.latencyMs + "ms") : "-"
                        color: quickTestRoot.latencyMs > 5000 ? Theme.warning :
                               quickTestRoot.latencyMs > 10000 ? Theme.error : Theme.onSurface
                        font.pixelSize: Theme.fontXS
                        font.bold: true
                        Layout.fillWidth: true
                    }
                }
            }

            // Improvement suggestions
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingXS
                visible: quickTestRoot.suggestions.length > 0

                Text {
                    text: Icons.star + " " + qsTr("改进建议")
                    color: Theme.onBackground
                    font.pixelSize: Theme.fontSM
                    font.weight: Font.DemiBold
                }

                ScrollView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    clip: true

                    TextArea {
                        text: quickTestRoot.suggestions
                        readOnly: true
                        color: Theme.onSurface
                        font.pixelSize: Theme.fontXS
                        wrapMode: TextArea.WordWrap
                        background: Rectangle {
                            color: Theme.successContainer
                            radius: Theme.radiusSM
                            border.color: Theme.secondary
                            border.width: 1
                        }
                    }
                }
            }

            // Smart optimization button
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                radius: Theme.radiusSM
                color: optBtnHover.hovered ? Qt.darker(Theme.accent, 1.1) : Theme.accent
                visible: quickTestRoot.hasResult

                Row {
                    anchors.centerIn: parent
                    spacing: Theme.spacingS

                    Text {
                        text: Icons.sparkle
                        font.pixelSize: Theme.fontSM
                        color: Theme.onPrimary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: qsTr("智能优化")
                        color: Theme.onPrimary
                        font.pixelSize: Theme.fontSM
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                HoverHandler { id: optBtnHover }
                TapHandler {
                    onTapped: {
                        if (promptOptimizer) {
                            var projectId = moduleCardModel ? moduleCardModel.getProjectId() : ""
                            promptOptimizer.optimize(quickTestRoot.promptText, quickTestRoot.lastResultJson, projectId)
                            // Open optimization popup immediately to show progress
                            if (optimizationResultPopup) {
                                optimizationResultPopup.resetAndOpen()
                            }
                        }
                    }
                }

                Behavior on color { enabled: !Theme.animReducedMotion; ColorAnimation { duration: Theme.animFast } }
            }
        }

        // No result placeholder
        Column {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !quickTestRoot.hasResult && !(testViewModel && testViewModel.isRunning)
            spacing: Theme.spacingSM

            Text {
                text: Icons.link
                font.pixelSize: Theme.fontXXXL
                anchors.horizontalCenter: parent.horizontalCenter
                opacity: 0.3
            }
            Text {
                text: qsTr("输入测试问题并点击运行")
                color: Theme.onSurfaceVariant
                font.pixelSize: Theme.fontSM
                horizontalAlignment: Text.AlignHCenter
                anchors.horizontalCenter: parent.horizontalCenter
                opacity: 0.5
            }
        }
    }

    // Connections to testViewModel
    Connections {
        target: testViewModel

        function onQuickTestCompleted(resultJson) {
            try {
                var result = JSON.parse(resultJson)
                quickTestRoot.outputText = result.output || ""
                quickTestRoot.contentScore = result.contentScore || 0
                quickTestRoot.formatScore = result.formatScore || 0
                quickTestRoot.safetyScore = result.safetyScore || 0
                quickTestRoot.consistencyScore = result.consistencyScore || 0
                quickTestRoot.speedScore = result.speedScore || 0
                quickTestRoot.latencyMs = result.latency_ms || 0
                quickTestRoot.suggestions = result.suggestions || ""
                quickTestRoot.hasResult = true
                quickTestRoot.lastResultJson = resultJson
            } catch (e) {
                console.log("[QuickTestPanel] Failed to parse result:", e)
            }
        }

        function onTestError(errorMsg) {
            quickTestRoot.outputText = qsTr("错误: ") + errorMsg
            quickTestRoot.hasResult = true
        }
    }

    function runQuickTest() {
        if (!testViewModel) return
        var input = testInputArea.text.trim()
        if (input.length === 0) return

        // Use edited preview text if available, otherwise fall back to compiled prompt
        var effectivePrompt = quickTestRoot.editedPreviewText.length > 0
                               ? quickTestRoot.editedPreviewText
                               : quickTestRoot.promptText

        testViewModel.runQuickTest(effectivePrompt, input)
    }

    function generateTestQuestion() {
        if (!testViewModel) {
            testInputArea.text = qsTr("请帮我分析这个问题并给出建议")
            return
        }

        // Use LLM to generate a specific test question
        var resultJson = testViewModel.generateSampleInputs(quickTestRoot.promptText, 1)
        try {
            var samples = JSON.parse(resultJson)
            if (samples && samples.length > 0 && samples[0].input) {
                testInputArea.text = samples[0].input
                return
            }
        } catch (e) {
        }

        // Fallback
        var samples = [
            qsTr("请帮我分析这个问题并给出建议"),
            qsTr("根据以上要求，完成以下任务"),
            qsTr("请解释这个概念并提供示例"),
            qsTr("帮我优化这段内容的表达方式"),
            qsTr("针对这个场景，给出你的专业意见")
        ]
        testInputArea.text = samples[Math.floor(Math.random() * samples.length)]
    }
}
