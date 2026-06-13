import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

// Batch regression test panel
Rectangle {
    id: batchTestRoot
    color: "transparent"

    property string promptText: ""

    // Batch result state
    property bool hasResult: false
    property var resultData: null
    property int avgResponseTime: 0
    property int minResponseTime: 0
    property int maxResponseTime: 0
    property string lastResultJson: ""

    // Settings
    property int sampleCount: 10

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.containerPadding
        spacing: Theme.spacingSM

        // Sample count configuration
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingSM

            Text {
                text: Icons.diamond + " " + qsTr("批量测试")
                color: Theme.onBackground
                font.pixelSize: Theme.fontSM
                font.weight: Font.DemiBold
            }

            Item { Layout.fillWidth: true }

            Text {
                text: qsTr("样本数")
                color: Theme.onSurface
                font.pixelSize: Theme.fontXS
                Layout.alignment: Qt.AlignVCenter
            }

            SpinBox {
                id: sampleSpinBox
                from: 1
                to: 100
                value: batchTestRoot.sampleCount
                onValueChanged: batchTestRoot.sampleCount = value
                Layout.preferredWidth: 96
                Layout.preferredHeight: Theme.heightXS

                contentItem: TextInput {
                    text: sampleSpinBox.textFromValue(sampleSpinBox.value, sampleSpinBox.locale)
                    font.pixelSize: Theme.fontSM
                    color: Theme.onBackground
                    horizontalAlignment: Qt.AlignHCenter
                    verticalAlignment: Qt.AlignVCenter
                    readOnly: !sampleSpinBox.editable
                    validator: sampleSpinBox.validator
                    inputMethodHints: sampleSpinBox.inputMethodHints
                }

                background: Rectangle {
                    color: Theme.background
                    radius: Theme.radiusSM
                    border.color: Theme.border
                    border.width: 1
                }

                up.indicator: Rectangle {
                    x: parent.width - width
                    height: parent.height
                    width: 32
                    radius: Theme.radiusSM
                    color: upHover.hovered ? Theme.primaryMuted : Theme.surfaceVariant

                    Text {
                        anchors.centerIn: parent
                        text: "+"
                        color: Theme.onSurface
                        font.pixelSize: Theme.fontMD
                    }

                    HoverHandler { id: upHover }
                }

                down.indicator: Rectangle {
                    x: 0
                    height: parent.height
                    width: 32
                    radius: Theme.radiusSM
                    color: downHover.hovered ? Theme.primaryMuted : Theme.surfaceVariant

                    Text {
                        anchors.centerIn: parent
                        text: "-"
                        color: Theme.onSurface
                        font.pixelSize: Theme.fontMD
                    }

                    HoverHandler { id: downHover }
                }
            }
        }

        // Action buttons row
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingSM

            // Generate test set button
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                radius: Theme.radiusSM
                color: genSetHover.hovered ? Theme.accentMuted : "transparent"
                border.color: Theme.accent
                border.width: 1

                Row {
                    anchors.centerIn: parent
                    spacing: Theme.spacingXS

                    Text {
                        text: Icons.list
                        font.pixelSize: Theme.fontS
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: qsTr("生成测试集")
                        color: Theme.accent
                        font.pixelSize: Theme.fontXS
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                HoverHandler { id: genSetHover }
                TapHandler {
                    onTapped: generateTestSet()
                }
            }

            // Run batch test button
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                radius: Theme.radiusSM
                color: {
                    if (testViewModel && testViewModel.isRunning) return Theme.border
                    return runBatchHover.hovered ? Qt.darker(Theme.primary, 1.1) : Theme.primary
                }

                Row {
                    anchors.centerIn: parent
                    spacing: Theme.spacingXS

                    Text {
                        text: testViewModel && testViewModel.isRunning ? Icons.hourglass : Icons.next
                        font.family: Icons.fontFamily
                        font.pixelSize: Theme.fontS
                        color: "#ffffff"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: testViewModel && testViewModel.isRunning ? qsTr("测试中...") : qsTr("运行批量测试")
                        color: "#ffffff"
                        font.pixelSize: Theme.fontXS
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                HoverHandler { id: runBatchHover }
                TapHandler {
                    onTapped: runBatchTest()
                }
            }
        }

        // Progress bar
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

        // Loading animation
        Row {
            Layout.fillWidth: true
            visible: testViewModel && testViewModel.isRunning
            spacing: Theme.spacingS

            Text {
                text: Icons.hourglass
                font.pixelSize: Theme.fontSM
                anchors.verticalCenter: parent.verticalCenter

                SequentialAnimation on opacity {
                    running: batchTestRoot.visible && testViewModel && testViewModel.isRunning
                    loops: Animation.Infinite
                    NumberAnimation { from: 1.0; to: 0.3; duration: Theme.animSlow }
                    NumberAnimation { from: 0.3; to: 1.0; duration: Theme.animSlow }
                }
            }
            Text {
                text: qsTr("正在调用AI模型进行批量测试，请稍候...")
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
            height: batchErrorRow.height + 12
            radius: Theme.radiusSM
            color: Theme.errorContainer
            border.color: Theme.error
            border.width: 1

            Row {
                id: batchErrorRow
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
        ScrollView {
            id: batchResultScroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: availableWidth

            ColumnLayout {
                id: batchResultContent
                width: batchResultScroll.availableWidth
                spacing: Theme.spacingSM
                visible: batchTestRoot.hasResult

                // Average scores with standard deviation
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingXS

                    Text {
                        text: Icons.up + " " + qsTr("平均得分")
                        color: Theme.onBackground
                        font.pixelSize: Theme.fontSM
                        font.weight: Font.DemiBold
                    }

                    // Content score
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacingSM

                        Text {
                            text: qsTr("内容")
                            color: Theme.onSurface
                            font.pixelSize: Theme.fontXS
                            Layout.preferredWidth: 30
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 8
                            radius: 4
                            color: Theme.surfaceVariant

                            Rectangle {
                                width: parent.width * Math.min(batchTestRoot.getResultAvg("content") / 10, 1)
                                height: parent.height
                                radius: 4
                                color: batchTestRoot.getResultAvg("content") >= 7 ? Theme.secondary :
                                       batchTestRoot.getResultAvg("content") >= 4 ? Theme.warning : Theme.error

                                Behavior on width { enabled: !Theme.animReducedMotion; NumberAnimation { duration: Theme.animNormal } }
                            }
                        }

                        Badge {
                            text: batchTestRoot.getResultAvg("content").toFixed(1) + " \u00B1" + batchTestRoot.getResultStd("content").toFixed(1)
                            badgeStyle: 4
                            badgeSize: 0
                        }
                    }

                    // Format score
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacingSM

                        Text {
                            text: qsTr("格式")
                            color: Theme.onSurface
                            font.pixelSize: Theme.fontXS
                            Layout.preferredWidth: 30
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 8
                            radius: 4
                            color: Theme.surfaceVariant

                            Rectangle {
                                width: parent.width * Math.min(batchTestRoot.getResultAvg("format") / 10, 1)
                                height: parent.height
                                radius: 4
                                color: batchTestRoot.getResultAvg("format") >= 7 ? Theme.secondary :
                                       batchTestRoot.getResultAvg("format") >= 4 ? Theme.warning : Theme.error

                                Behavior on width { enabled: !Theme.animReducedMotion; NumberAnimation { duration: Theme.animNormal } }
                            }
                        }

                        Badge {
                            text: batchTestRoot.getResultAvg("format").toFixed(1) + " \u00B1" + batchTestRoot.getResultStd("format").toFixed(1)
                            badgeStyle: 4
                            badgeSize: 0
                        }
                    }

                    // Safety score
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacingSM

                        Text {
                            text: qsTr("安全")
                            color: Theme.onSurface
                            font.pixelSize: Theme.fontXS
                            Layout.preferredWidth: 30
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 8
                            radius: 4
                            color: Theme.surfaceVariant

                            Rectangle {
                                width: parent.width * Math.min(batchTestRoot.getResultAvg("safety") / 10, 1)
                                height: parent.height
                                radius: 4
                                color: batchTestRoot.getResultAvg("safety") >= 7 ? Theme.secondary :
                                       batchTestRoot.getResultAvg("safety") >= 4 ? Theme.warning : Theme.error

                                Behavior on width { enabled: !Theme.animReducedMotion; NumberAnimation { duration: Theme.animNormal } }
                            }
                        }

                        Badge {
                            text: batchTestRoot.getResultAvg("safety").toFixed(1) + " \u00B1" + batchTestRoot.getResultStd("safety").toFixed(1)
                            badgeStyle: 4
                            badgeSize: 0
                        }
                    }

                    // Consistency score
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacingSM

                        Text {
                            text: qsTr("一致性")
                            color: Theme.onSurface
                            font.pixelSize: Theme.fontXS
                            Layout.preferredWidth: 30
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 8
                            radius: 4
                            color: Theme.surfaceVariant

                            Rectangle {
                                width: parent.width * Math.min(batchTestRoot.getResultAvg("consistency") / 10, 1)
                                height: parent.height
                                radius: 4
                                color: batchTestRoot.getResultAvg("consistency") >= 7 ? Theme.secondary :
                                       batchTestRoot.getResultAvg("consistency") >= 4 ? Theme.warning : Theme.error

                                Behavior on width { enabled: !Theme.animReducedMotion; NumberAnimation { duration: Theme.animNormal } }
                            }
                        }

                        Badge {
                            text: batchTestRoot.getResultAvg("consistency").toFixed(1) + " \u00B1" + batchTestRoot.getResultStd("consistency").toFixed(1)
                            badgeStyle: 4
                            badgeSize: 0
                        }
                    }

                    // Speed score
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacingSM

                        Text {
                            text: qsTr("速度")
                            color: Theme.onSurface
                            font.pixelSize: Theme.fontXS
                            Layout.preferredWidth: 30
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 8
                            radius: 4
                            color: Theme.surfaceVariant

                            Rectangle {
                                width: parent.width * Math.min(batchTestRoot.getResultAvg("speed") / 10, 1)
                                height: parent.height
                                radius: 4
                                color: batchTestRoot.getResultAvg("speed") >= 7 ? Theme.secondary :
                                       batchTestRoot.getResultAvg("speed") >= 4 ? Theme.warning : Theme.error

                                Behavior on width { enabled: !Theme.animReducedMotion; NumberAnimation { duration: Theme.animNormal } }
                            }
                        }

                        Badge {
                            text: batchTestRoot.getResultAvg("speed").toFixed(1) + " \u00B1" + batchTestRoot.getResultStd("speed").toFixed(1)
                            badgeStyle: 4
                            badgeSize: 0
                        }
                    }

                    // Average response time display
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacingSM

                        Text {
                            text: qsTr("平均响应")
                            color: Theme.onSurface
                            font.pixelSize: Theme.fontXS
                            Layout.preferredWidth: 45
                        }

                        Text {
                            text: batchTestRoot.avgResponseTime > 0 ?
                                  (batchTestRoot.avgResponseTime >= 1000 ?
                                   (batchTestRoot.avgResponseTime / 1000).toFixed(1) + "s" :
                                   batchTestRoot.avgResponseTime + "ms") : "-"
                            color: batchTestRoot.avgResponseTime > 5000 ? Theme.warning :
                                   batchTestRoot.avgResponseTime > 10000 ? Theme.error : Theme.onSurface
                            font.pixelSize: Theme.fontXS
                            font.bold: true
                            Layout.fillWidth: true
                        }
                    }

                    // Min-Max response time
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacingSM

                        Text {
                            text: qsTr("响应范围")
                            color: Theme.onSurface
                            font.pixelSize: Theme.fontXS
                            Layout.preferredWidth: 45
                        }

                        Text {
                            text: batchTestRoot.minResponseTime + "ms - " + batchTestRoot.maxResponseTime + "ms"
                            color: Theme.onSurfaceVariant
                            font.pixelSize: Theme.fontXS
                            Layout.fillWidth: true
                        }
                    }
                }

                // Score distribution chart (Canvas)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingXS

                    Text {
                        text: Icons.diamond + " " + qsTr("分数分布")
                        color: Theme.onBackground
                        font.pixelSize: Theme.fontSM
                        font.weight: Font.DemiBold
                    }

                    Canvas {
                        id: distChart
                        Layout.fillWidth: true
                        Layout.preferredHeight: 120

                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.reset()

                            var data = batchTestRoot.getResultDistribution()
                            if (!data || data.length === 0) {
                                // Draw placeholder
                                ctx.fillStyle = Theme.onSurfaceVariant
                                ctx.font = Theme.fontS + "px sans-serif"
                                ctx.textAlign = "center"
                                ctx.fillText(qsTr("运行测试后显示分布图"), width / 2, height / 2)
                                return
                            }

                            var w = width
                            var h = height
                            var barCount = data.length
                            var labels = ["0-2", "2-4", "4-6", "6-8", "8-10"]
                            var maxVal = Math.max.apply(null, data)
                            if (maxVal === 0) maxVal = 1

                            var marginLeft = 30
                            var marginBottom = 20
                            var marginTop = 10
                            var marginRight = 10
                            var chartW = w - marginLeft - marginRight
                            var chartH = h - marginTop - marginBottom

                            // Draw Y-axis gridlines
                            ctx.strokeStyle = Theme.divider
                            ctx.lineWidth = 0.5
                            for (var g = 0; g <= 4; g++) {
                                var gy = marginTop + chartH * (1 - g / 4)
                                ctx.beginPath()
                                ctx.moveTo(marginLeft, gy)
                                ctx.lineTo(w - marginRight, gy)
                                ctx.stroke()

                                // Y-axis labels
                                ctx.fillStyle = Theme.onSurfaceVariant
                                ctx.font = Theme.fontXXS + "px sans-serif"
                                ctx.textAlign = "right"
                                ctx.fillText(Math.round(maxVal * g / 4).toString(), marginLeft - 4, gy + 3)
                            }

                            var barWidth = chartW / barCount
                            var barColors = [Theme.error, Theme.warning, Theme.warning, Theme.secondary, Theme.secondary]

                            // Draw bars with gradient
                            for (var i = 0; i < barCount; i++) {
                                var barH = (data[i] / maxVal) * chartH
                                var x = marginLeft + i * barWidth + 4
                                var y = marginTop + chartH - barH
                                var bw = barWidth - 8

                                // Bar gradient
                                var grad = ctx.createLinearGradient(x, y, x, marginTop + chartH)
                                grad.addColorStop(0, barColors[i] || Theme.primary)
                                grad.addColorStop(1, Qt.rgba(barColors[i].r, barColors[i].g, barColors[i].b, 0.4))
                                ctx.fillStyle = grad
                                ctx.beginPath()
                                ctx.roundedRect(x, y, bw, barH, 3, 3)
                                ctx.fill()

                                // Count label on top
                                ctx.fillStyle = Theme.onSurface
                                ctx.font = "bold " + Theme.fontS + "px sans-serif"
                                ctx.textAlign = "center"
                                if (data[i] > 0) {
                                    ctx.fillText(data[i].toString(), x + bw / 2, y - 3)
                                }

                                // Bucket label at bottom
                                ctx.fillStyle = Theme.onSurfaceVariant
                                ctx.font = Theme.fontXXS + "px sans-serif"
                                ctx.fillText(labels[i] || "", x + bw / 2, h - 4)
                            }

                            // Draw axes
                            ctx.strokeStyle = Theme.onSurfaceVariant
                            ctx.lineWidth = 1
                            ctx.beginPath()
                            ctx.moveTo(marginLeft, marginTop)
                            ctx.lineTo(marginLeft, marginTop + chartH)
                            ctx.lineTo(w - marginRight, marginTop + chartH)
                            ctx.stroke()
                        }
                    }
                }

                // Smart optimization button
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    radius: Theme.radiusSM
                    color: batchOptBtnHover.hovered ? Qt.darker(Theme.accent, 1.1) : Theme.accent

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

                    HoverHandler { id: batchOptBtnHover }
                    TapHandler {
                        onTapped: {
                            if (promptOptimizer) {
                                var projectId = moduleCardModel ? moduleCardModel.getProjectId() : ""
                                promptOptimizer.optimize(batchTestRoot.promptText, batchTestRoot.lastResultJson, projectId)
                                // Open optimization popup immediately to show progress
                                if (optimizationResultPopup) {
                                    optimizationResultPopup.resetAndOpen()
                                }
                            }
                        }
                    }

                    Behavior on color { enabled: !Theme.animReducedMotion; ColorAnimation { duration: Theme.animFast } }
                }

                // Low-score samples list
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingXS

                    Text {
                        text: Icons.warning + " " + qsTr("低分样本 (%1)").arg(batchTestRoot.getLowScoreCount())
                        color: Theme.warning
                        font.pixelSize: Theme.fontSM
                        font.weight: Font.DemiBold
                    }

                    Column {
                        Layout.fillWidth: true
                        spacing: Theme.spacingXS

                        Repeater {
                            model: batchTestRoot.getLowScoreSamples()

                            delegate: Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: lowScoreExpanded ? lowScoreContent.implicitHeight + Theme.spacingSM * 2 : 32
                                radius: Theme.radiusSM
                                color: Theme.errorContainer
                                border.color: Theme.error
                                border.width: 1
                                clip: false

                                property bool lowScoreExpanded: false

                                ColumnLayout {
                                    id: lowScoreContent
                                    anchors.fill: parent
                                    anchors.margins: Theme.spacingXS
                                    spacing: Theme.spacingXXS

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: Theme.spacingSM

                                        Text {
                                            text: Icons.close
                                            font.pixelSize: Theme.fontXS
                                        }

                                        Text {
                                            text: modelData.input.substring(0, 40) + (modelData.input.length > 40 ? "..." : "")
                                            color: Theme.onSurface
                                            font.pixelSize: Theme.fontXS
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            text: qsTr("C:%1 F:%2 S:%3 Cs:%4 Sp:%5").arg(modelData.contentScore).arg(modelData.formatScore).arg(modelData.safetyScore).arg(modelData.consistencyScore || 0).arg(modelData.speedScore || 0)
                                            color: Theme.error
                                            font.pixelSize: Theme.fontXS
                                        }

                                        Rectangle {
                                            width: 18
                                            height: 18
                                            radius: 9
                                            color: expHover.hovered ? Theme.surfaceRaised : "transparent"

                                            Text {
                                                anchors.centerIn: parent
                                                text: parent.parent.parent.parent.lowScoreExpanded ? Icons.chevronUp : Icons.chevronDown
                                                font.pixelSize: Theme.fontXXS
                                                color: Theme.onSurfaceVariant
                                            }

                                            HoverHandler { id: expHover }
                                            TapHandler {
                                                onTapped: parent.parent.parent.parent.lowScoreExpanded = !parent.parent.parent.parent.lowScoreExpanded
                                            }
                                        }
                                    }

                                    // Expanded output
                                    ScrollView {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        visible: lowScoreExpanded
                                        clip: true

                                        TextArea {
                                            text: modelData.output || ""
                                            readOnly: true
                                            color: Theme.onSurface
                                            font.pixelSize: Theme.fontXS
                                            wrapMode: TextArea.WordWrap
                                            background: Rectangle {
                                                color: Theme.background
                                                radius: Theme.radiusSM
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // No result placeholder
        Column {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !batchTestRoot.hasResult && !(testViewModel && testViewModel.isRunning)
            spacing: Theme.spacingSM

            Text {
                text: Icons.chart
                font.pixelSize: Theme.fontXXXL
                anchors.horizontalCenter: parent.horizontalCenter
                opacity: 0.3
            }
            Text {
                text: qsTr("设置样本数并运行批量测试")
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

        function onBatchTestCompleted(resultJson) {
            try {
                batchTestRoot.resultData = JSON.parse(resultJson)
                batchTestRoot.hasResult = true
                batchTestRoot.lastResultJson = resultJson
                // Parse response time info
                if (batchTestRoot.resultData.responseTime) {
                    batchTestRoot.avgResponseTime = batchTestRoot.resultData.responseTime.average_ms || 0
                    batchTestRoot.minResponseTime = batchTestRoot.resultData.responseTime.min_ms || 0
                    batchTestRoot.maxResponseTime = batchTestRoot.resultData.responseTime.max_ms || 0
                }
                distChart.requestPaint()
            } catch (e) {
                console.log("[BatchTestPanel] Failed to parse result:", e)
            }
        }

        function onTestError(errorMsg) {
            console.log("[BatchTestPanel] Error:", errorMsg)
        }
    }

    function generateTestSet() {
        if (!testViewModel) return
        var result = testViewModel.generateSampleInputs(batchTestRoot.promptText, batchTestRoot.sampleCount)
        // Just show the generated samples in console for now
        console.log("[BatchTestPanel] Generated test set:", result)
    }

    function runBatchTest() {
        if (!testViewModel) return

        testViewModel.runBatchTestFromPrompt(batchTestRoot.promptText, batchTestRoot.sampleCount)
    }

    function getResultAvg(dimension) {
        if (!batchTestRoot.resultData || !batchTestRoot.resultData.averageScores) return 0
        return batchTestRoot.resultData.averageScores[dimension] || 0
    }

    function getResultStd(dimension) {
        if (!batchTestRoot.resultData || !batchTestRoot.resultData.standardDeviations) return 0
        return batchTestRoot.resultData.standardDeviations[dimension] || 0
    }

    function getResultDistribution() {
        if (!batchTestRoot.resultData || !batchTestRoot.resultData.distribution) return []
        // Return content distribution by default
        return batchTestRoot.resultData.distribution["content"] || []
    }

    function getLowScoreCount() {
        if (!batchTestRoot.resultData || !batchTestRoot.resultData.lowScoreSamples) return 0
        return batchTestRoot.resultData.lowScoreSamples.length
    }

    function getLowScoreSamples() {
        if (!batchTestRoot.resultData || !batchTestRoot.resultData.lowScoreSamples) return []
        return batchTestRoot.resultData.lowScoreSamples
    }
}
