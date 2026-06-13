import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

Popup {
    id: optimizationPopup
    width: Math.round(parent ? parent.width * 0.65 : 832)
    height: Math.round(parent ? parent.height * 0.80 : 640)
    padding: Theme.spacingMD
    modal: true
    focus: true
    closePolicy: _isLoading ? Popup.CloseOnEscape : (Popup.CloseOnEscape | Popup.CloseOnPressOutside)

    // Popup renders in the overlay layer — font must be set explicitly here
    // because it does not inherit from ApplicationWindow.
    font.family: Theme.fontFamily

    signal retryingRequested()

    property string resultJson: ""
    property string currentProjectId: ""
    property int currentStep: 0
    property string stepDescription: ""

    // Convenience: popup is in the loading phase (steps 0-2)
    readonly property bool _isLoading: optimizationPopup.currentStep >= 0 && optimizationPopup.currentStep < 3

    // Parsed result data
    property string originalPrompt: ""
    property string optimizedPrompt: ""
    property var problemAnalysis: null
    property var changes: []
    property var improvementReport: null

    background: Rectangle {
        color: Theme.surface
        radius: Theme.radiusMD
        border.color: Theme.border
        border.width: 1
    }

    contentItem: ColumnLayout {
        spacing: Theme.spacingMD

        // Header row
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingSM

            Text {
                text: qsTr("智能优化结果")
                color: Theme.onBackground
                font.pixelSize: Theme.fontLG
                font.bold: true
                font.family: Theme.fontFamily
                Layout.fillWidth: true
            }

            Rectangle {
                width: 28
                height: Theme.heightXS
                radius: Theme.radiusSM
                color: optCloseHover.hovered ? Theme.surfaceRaised : "transparent"
                visible: !optimizationPopup._isLoading

                Text {
                    anchors.centerIn: parent
                    text: Icons.close
                    font.family: Icons.fontFamily
                    color: Theme.onSurfaceVariant
                    font.pixelSize: Theme.fontMD
                }

                HoverHandler { id: optCloseHover }
                TapHandler { onTapped: optimizationPopup.close() }
            }
        }

        // Three-step progress indicator
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingXS
            visible: optimizationPopup.currentStep >= 0 && optimizationPopup.currentStep < 3

            RowLayout {
                Layout.fillWidth: true
                spacing: 0

                Repeater {
                    model: [
                        { label: qsTr("问题分析"), icon: Icons.circleThin },
                        { label: qsTr("提示词优化"), icon: Icons.sparkle },
                        { label: qsTr("效果验证"), icon: Icons.accept }
                    ]

                    delegate: Rectangle {
                        Layout.fillWidth: true
                        height: 48
                        radius: Theme.radiusSM
                        color: {
                            if (optimizationPopup.currentStep === -1) return Theme.errorContainer
                            if (index < optimizationPopup.currentStep) return Theme.primaryMuted
                            if (index === optimizationPopup.currentStep) return Theme.primaryContainer
                            return Theme.surfaceVariant
                        }
                        border.color: {
                            if (optimizationPopup.currentStep === -1) return Theme.error
                            if (index <= optimizationPopup.currentStep) return Theme.primary
                            return Theme.border
                        }
                        border.width: 1

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: Theme.spacingXXS

                            Text {
                                text: {
                                    if (optimizationPopup.currentStep === -1) return Icons.cancel
                                    if (index < optimizationPopup.currentStep) return Icons.accept
                                    return modelData.icon
                                }
                                color: {
                                    if (optimizationPopup.currentStep === -1) return Theme.error
                                    if (index <= optimizationPopup.currentStep) return Theme.primary
                                    return Theme.onSurfaceVariant
                                }
                                font.pixelSize: Theme.fontSM
                                font.family: Icons.fontFamily
                                Layout.alignment: Qt.AlignHCenter

                                // Pulse animation for current step
                                SequentialAnimation on opacity {
                                    running: index === optimizationPopup.currentStep && optimizationPopup.currentStep > 0 && optimizationPopup.currentStep < 3
                                    loops: Animation.Infinite
                                    NumberAnimation { from: 1.0; to: 0.4; duration: Theme.animSlow; easing.type: Theme.animEasing }
                                    NumberAnimation { from: 0.4; to: 1.0; duration: Theme.animSlow; easing.type: Theme.animEasing }
                                }
                            }
                            Text {
                                text: modelData.label
                                color: index <= optimizationPopup.currentStep ? Theme.primary : Theme.onSurfaceVariant
                                font.pixelSize: Theme.fontXS
                                font.bold: index <= optimizationPopup.currentStep
                                font.family: Theme.fontFamily
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }
                }
            }

            // Step description with loading animation (kept lightweight, no spinner)
            Text {
                Layout.fillWidth: true
                visible: optimizationPopup.currentStep > 0 && optimizationPopup.currentStep < 3
                text: optimizationPopup.stepDescription
                color: Theme.primary
                font.pixelSize: Theme.fontSM
                font.family: Theme.fontFamily
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }
        }

        // Prominent loading state (visible while step is 0-2, fills the space)
        Item {
            id: loadingState
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 200
            visible: optimizationPopup.currentStep >= 0 && optimizationPopup.currentStep < 3

            ColumnLayout {
                anchors.centerIn: parent
                spacing: Theme.spacingLG

                // Three animated dots (clean modern loader)
                Row {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 8

                    Repeater {
                        model: 3
                        delegate: Rectangle {
                            width: 12
                            height: 12
                            radius: 6
                            color: Theme.primary
                            opacity: 0.3

                            SequentialAnimation on opacity {
                                loops: Animation.Infinite
                                NumberAnimation { to: 1.0; duration: 600 }
                                NumberAnimation { to: 0.3; duration: 600 }
                            }
                        }
                    }
                }

                // Status text
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: optimizationPopup.stepDescription || qsTr("正在准备…")
                    color: Theme.onBackground
                    font.pixelSize: Theme.fontLG
                    font.family: Theme.fontFamily
                    font.weight: Font.Medium
                    horizontalAlignment: Text.AlignHCenter
                    lineHeight: 1.5
                }

                // Subtitle hint
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("AI 正在分析您的提示词，这可能需要 10-30 秒")
                    color: Theme.onSurfaceVariant
                    font.pixelSize: Theme.fontSM
                    font.family: Theme.fontFamily
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    Layout.maximumWidth: 360
                    lineHeight: 1.5
                }
            }
        }

        // Error state display (shown when optimization fails)
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Theme.spacingSM
            visible: optimizationPopup.currentStep === -1

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.maximumHeight: 220
                radius: Theme.radiusSM
                color: Theme.errorContainer
                border.color: Theme.error
                border.width: 1

                ColumnLayout {
                    id: errorContent
                    anchors.fill: parent
                    anchors.margins: Theme.spacingMD
                    spacing: Theme.spacingXS

                    Text {
                        text: Icons.warning + " " + qsTr("优化失败")
                        color: Theme.error
                        font.pixelSize: Theme.fontMD
                        font.bold: true
                    }

                    Text {
                        text: optimizationPopup.stepDescription
                        color: Theme.onSurfaceVariant
                        font.pixelSize: Theme.fontSM
                        font.family: Theme.fontFamily
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                }
            }

            // Retry and close buttons
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingSM

                Rectangle {
                    Layout.fillWidth: true
                    height: Theme.heightSM
                    radius: Theme.radiusSM
                    color: Theme.surfaceVariant
                    border.color: Theme.border
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: qsTr("关闭")
                        color: Theme.onSurface
                        font.pixelSize: Theme.fontSM
                        font.family: Theme.fontFamily
                    }

                    TapHandler { onTapped: optimizationPopup.close() }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: Theme.heightSM
                    radius: Theme.radiusSM
                    color: Theme.primary

                    Text {
                        anchors.centerIn: parent
                        text: Icons.diamond + " " + qsTr("重试优化")
                        color: Theme.onPrimary
                        font.pixelSize: Theme.fontSM
                        font.bold: true
                    }

                    TapHandler {
                        onTapped: {
                            // Re-trigger optimization with the same parameters
                            if (promptOptimizer && promptOptimizer.isOptimizing === false) {
                                optimizationPopup.currentStep = 0
                                optimizationPopup.stepDescription = qsTr("正在准备…")
                                // The caller (test panel) will need to re-trigger
                                optimizationPopup.retryingRequested()
                            }
                        }
                    }

                    Behavior on color { enabled: !Theme.animReducedMotion; ColorAnimation { duration: Theme.animFast } }
                }
            }
        }

        // Scrollable content (hidden during optimization, shown after completion)
        ScrollView {
            id: contentScroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 200
            clip: true
            visible: optimizationPopup.currentStep >= 3
            contentWidth: availableWidth

            ColumnLayout {
                width: contentScroll.availableWidth
                spacing: Theme.spacingMD

                // Problem analysis section (collapsible)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingXS
                    visible: optimizationPopup.problemAnalysis !== null

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacingSM

                        Text {
                            text: Icons.circleThin + " " + qsTr("问题分析")
                            color: Theme.onBackground
                            font.pixelSize: Theme.fontSM
                            font.bold: true
                            }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            width: 20
                            height: 20
                            radius: 10
                            color: analysisExpandHover.hovered ? Theme.surfaceRaised : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: analysisSection.visible ? Icons.chevronUp : Icons.chevronDown
                                font.pixelSize: Theme.fontXXS
                                font.family: Icons.fontFamily
                                color: Theme.onSurfaceVariant
                            }

                            HoverHandler { id: analysisExpandHover }
                            TapHandler { onTapped: analysisSection.visible = !analysisSection.visible }
                        }
                    }

                    ColumnLayout {
                        id: analysisSection
                        Layout.fillWidth: true
                        spacing: Theme.spacingXS

                        Repeater {
                            model: optimizationPopup.problemAnalysis
                                   ? (optimizationPopup.problemAnalysis.problems || [])
                                   : []

                            delegate: Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: problemContent.implicitHeight + Theme.spacingSM * 2
                                Layout.topMargin: Theme.spacingXS
                                Layout.bottomMargin: Theme.spacingXS
                                radius: Theme.radiusSM
                                color: Theme.surfaceVariant
                                border.color: Theme.border
                                border.width: 1

                                ColumnLayout {
                                    id: problemContent
                                    anchors.fill: parent
                                    anchors.margins: Theme.spacingSM
                                    spacing: Theme.spacingXXS

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: Theme.spacingSM

                                        Badge {
                                            text: modelData.dimension || ""
                                            badgeStyle: 2
                                            badgeSize: 0
                                        }

                                        Text {
                                            text: modelData.issue || ""
                                            color: Theme.onSurface
                                            font.pixelSize: Theme.fontXS
                                            font.family: Theme.fontFamily
                                            font.bold: true
                                            Layout.fillWidth: true
                                            wrapMode: Text.WordWrap
                                        }
                                    }

                                    Text {
                                        text: qsTr("证据: ") + (modelData.evidence || "")
                                        color: Theme.onSurfaceVariant
                                        font.pixelSize: Theme.fontXS
                                        font.family: Theme.fontFamily
                                        Layout.fillWidth: true
                                        wrapMode: Text.WordWrap
                                        visible: modelData.evidence
                                    }

                                    Text {
                                        text: qsTr("改进方向: ") + (modelData.suggestion || "")
                                        color: Theme.secondary
                                        font.pixelSize: Theme.fontXS
                                        font.family: Theme.fontFamily
                                        Layout.fillWidth: true
                                        wrapMode: Text.WordWrap
                                        visible: modelData.suggestion
                                    }
                                }
                            }
                        }
                    }
                }

                // Optimization comparison area
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingXS

                    Text {
                        text: Icons.diamond + " " + qsTr("优化对比")
                        color: Theme.onBackground
                        font.pixelSize: Theme.fontSM
                        font.bold: true
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacingMD

                        // Original prompt
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            spacing: Theme.spacingXS

                            Text {
                                text: qsTr("原始提示词")
                                color: Theme.onSurfaceVariant
                                font.pixelSize: Theme.fontXS
                                font.family: Theme.fontFamily
                                font.bold: true
                                lineHeight: 1.5
                            }

                            ScrollView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.minimumHeight: 160
                                Layout.preferredHeight: 160
                                clip: true

                                TextArea {
                                    text: optimizationPopup.originalPrompt
                                    readOnly: true
                                    color: Theme.onSurface
                                    font.pixelSize: Theme.fontXS
                                    font.family: Theme.codeFontFamily
                                    wrapMode: TextArea.WordWrap
                                    selectByMouse: true
                                    background: Rectangle {
                                        color: Theme.codeBackground
                                        radius: Theme.radiusSM
                                        border.color: Theme.border
                                        border.width: 1
                                    }
                                }
                            }
                        }

                        // Optimized prompt
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            spacing: Theme.spacingXS

                            Text {
                                text: qsTr("优化后提示词")
                                color: Theme.secondary
                                font.pixelSize: Theme.fontXS
                                font.family: Theme.fontFamily
                                font.bold: true
                                lineHeight: 1.5
                            }

                            ScrollView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.minimumHeight: 160
                                Layout.preferredHeight: 160
                                clip: true

                                TextArea {
                                    text: optimizationPopup.optimizedPrompt
                                    readOnly: true
                                    color: Theme.onSurface
                                    font.pixelSize: Theme.fontXS
                                    font.family: Theme.codeFontFamily
                                    wrapMode: TextArea.WordWrap
                                    selectByMouse: true
                                    background: Rectangle {
                                        color: Theme.successContainer
                                        radius: Theme.radiusSM
                                        border.color: Theme.secondary
                                        border.width: 1
                                    }
                                }
                            }
                        }
                    }

                    // Changes list
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: Theme.spacingSM
                        spacing: Theme.spacingSM
                        visible: optimizationPopup.changes.length > 0

                        Text {
                            text: Icons.edit + " " + qsTr("变更说明")
                            color: Theme.onBackground
                            font.pixelSize: Theme.fontXS
                                font.bold: true
                            lineHeight: 1.5
                        }

                        Repeater {
                            model: optimizationPopup.changes

                            delegate: Rectangle {
                                Layout.fillWidth: true
                                Layout.topMargin: 0
                                Layout.bottomMargin: Theme.spacingSM
                                implicitHeight: changeContent.implicitHeight + Theme.spacingSM * 2
                                Layout.preferredHeight: changeContent.implicitHeight + Theme.spacingSM * 2
                                radius: Theme.radiusSM
                                color: Theme.surfaceVariant
                                border.color: Theme.border
                                border.width: 1

                                ColumnLayout {
                                    id: changeContent
                                    anchors.fill: parent
                                    anchors.margins: Theme.spacingSM
                                    spacing: Theme.spacingXXS

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: Theme.spacingSM

                                        Badge {
                                            text: modelData.dimension || ""
                                            badgeStyle: 0   // styleInfo — neutral accent
                                            badgeSize: 0
                                        }

                                        Text {
                                            text: modelData.reason || ""
                                            color: Theme.onSurfaceVariant
                                            font.pixelSize: Theme.fontXS
                                            font.family: Theme.fontFamily
                                            Layout.fillWidth: true
                                            wrapMode: Text.WordWrap
                                            lineHeight: 1.5
                                        }
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: Theme.spacingSM

                                        // "前" label: ↓ icon + error color (multi-channel encoding)
                                        Badge {
                                            text: Icons.down + " " + qsTr("前")
                                            badgeStyle: 3   // styleError
                                            badgeSize: 0
                                        }
                                        Text {
                                            text: modelData.before || ""
                                            color: Theme.onSurface
                                            font.pixelSize: Theme.fontXS
                                            font.family: Theme.fontFamily
                                            Layout.fillWidth: true
                                            wrapMode: Text.WordWrap
                                            lineHeight: 1.5
                                        }
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: Theme.spacingSM

                                        // "后" label: ↑ icon + success color (multi-channel encoding)
                                        Badge {
                                            text: Icons.up + " " + qsTr("后")
                                            badgeStyle: 1   // styleSuccess
                                            badgeSize: 0
                                        }
                                        Text {
                                            text: modelData.after || ""
                                            color: Theme.onSurface
                                            font.pixelSize: Theme.fontXS
                                            font.family: Theme.fontFamily
                                            Layout.fillWidth: true
                                            wrapMode: Text.WordWrap
                                            lineHeight: 1.5
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Improvement assessment area
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: assessmentCard.implicitHeight + Theme.spacingSM * 2
                    spacing: Theme.spacingXS
                    visible: optimizationPopup.improvementReport !== null

                    Text {
                        text: Icons.diamond + " " + qsTr("改进评估")
                        color: Theme.onBackground
                        font.pixelSize: Theme.fontSM
                        font.bold: true
                        lineHeight: 1.5
                    }

                    Rectangle {
                        id: assessmentCard
                        Layout.fillWidth: true
                        radius: Theme.radiusSM
                        color: Theme.surfaceVariant
                        border.color: Theme.border
                        border.width: 1
                        implicitHeight: assessmentContent.implicitHeight + Theme.spacingSM * 2

                        ColumnLayout {
                            id: assessmentContent
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: Theme.spacingSM
                            spacing: Theme.spacingXS

                            // Per-dimension improvement status
                            Repeater {
                                model: optimizationPopup.improvementReport
                                       ? (optimizationPopup.improvementReport.improvements || [])
                                       : []

                                delegate: RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Theme.spacingSM

                                    Text {
                                        text: modelData.resolved ? Icons.accept : Icons.warning
                                        font.pixelSize: Theme.fontXS
                                        font.family: Icons.fontFamily
                                    }
                                    Text {
                                        text: modelData.dimension || ""
                                        color: Theme.onSurface
                                        font.pixelSize: Theme.fontXS
                                        font.family: Theme.fontFamily
                                        font.bold: true
                                        Layout.preferredWidth: 60
                                        lineHeight: 1.5
                                    }
                                    Text {
                                        text: modelData.resolved ? qsTr("已解决") : qsTr("部分解决")
                                        color: modelData.resolved ? Theme.secondary : Theme.warning
                                        font.pixelSize: Theme.fontXS
                                        font.family: Theme.fontFamily
                                        lineHeight: 1.5
                                    }
                                    Text {
                                        text: modelData.improvement || ""
                                        color: Theme.onSurfaceVariant
                                        font.pixelSize: Theme.fontXS
                                        font.family: Theme.fontFamily
                                        Layout.fillWidth: true
                                        wrapMode: Text.WordWrap
                                        lineHeight: 1.5
                                    }
                                }
                            }

                            // New issues
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Theme.spacingXXS
                                visible: optimizationPopup.improvementReport
                                         && optimizationPopup.improvementReport.newIssues
                                         && optimizationPopup.improvementReport.newIssues.length > 0

                                Text {
                                    text: Icons.warning + " " + qsTr("新引入的问题:")
                                    color: Theme.warning
                                    font.pixelSize: Theme.fontXS
                                                font.bold: true
                                    lineHeight: 1.5
                                }

                                Repeater {
                                    model: optimizationPopup.improvementReport
                                           ? (optimizationPopup.improvementReport.newIssues || [])
                                           : []

                                    delegate: Text {
                                        text: Icons.bullet + " " + modelData
                                        color: Theme.warning
                                        font.pixelSize: Theme.fontXS
                                                        Layout.fillWidth: true
                                        wrapMode: Text.WordWrap
                                        lineHeight: 1.5
                                    }
                                }
                            }

                            // Overall improvement & confidence
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Theme.spacingSM
                                visible: optimizationPopup.improvementReport !== null

                                Rectangle {
                                    width: overallText.width + 12
                                    height: 22
                                    radius: 11
                                    color: {
                                        var level = optimizationPopup.improvementReport
                                                   ? optimizationPopup.improvementReport.overallImprovement
                                                   : ""
                                        if (level === "\u663E\u8457") return Theme.secondary
                                        if (level === "\u4E2D\u7B49") return Theme.primary
                                        if (level === "\u8F7B\u5FAE") return Theme.warning
                                        return Theme.onSurfaceVariant
                                    }

                                    Text {
                                        id: overallText
                                        anchors.centerIn: parent
                                        text: optimizationPopup.improvementReport
                                              ? optimizationPopup.improvementReport.overallImprovement || ""
                                              : ""
                                        color: Theme.onPrimary
                                        font.pixelSize: Theme.fontXS
                                        font.family: Theme.fontFamily
                                        font.bold: true
                                    }
                                }

                                Text {
                                    text: qsTr("整体改进")
                                    color: Theme.onSurface
                                    font.pixelSize: Theme.fontXS
                                    font.family: Theme.fontFamily
                                    lineHeight: 1.5
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: qsTr("置信度: %1%").arg(
                                        optimizationPopup.improvementReport
                                        ? Math.round((optimizationPopup.improvementReport.confidence || 0) * 100)
                                        : 0
                                    )
                                    color: Theme.primary
                                    font.pixelSize: Theme.fontXS
                                    font.family: Theme.fontFamily
                                    font.bold: true
                                    lineHeight: 1.5
                                }
                            }
                        }
                    }
                }
            }
        }

        // Action buttons (hidden during optimization, shown after completion)
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.heightSM
            spacing: Theme.spacingSM
            visible: optimizationPopup.currentStep >= 3

            // Discard button (Ghost style — secondary action)
            PBButton {
                text: qsTr("放弃")
                btnStyle: 3   // styleGhost
                btnSize: 1    // sizeMd → 34px height, fontMD (14px)
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.preferredHeight: Theme.heightSM
                onClicked: optimizationPopup.close()
            }

            // Apply optimization button (Primary style — main action, wider, elevated)
            PBButton {
                text: qsTr("应用优化")
                btnStyle: 0   // stylePrimary
                btnSize: 1    // sizeMd → 34px height, fontMD (14px)
                Layout.fillWidth: true
                Layout.preferredWidth: 2
                Layout.preferredHeight: Theme.heightSM
                onClicked: applyOptimization()
            }
        }
    }

    // Connections to promptOptimizer
    Connections {
        target: promptOptimizer

        function onOptimizationCompleted(resultJson) {
            optimizationPopup.currentStep = 3
            optimizationPopup.stepDescription = qsTr("优化完成")
            // Set resultJson which triggers onResultJsonChanged → parseResult
            optimizationPopup.resultJson = resultJson
        }

        function onOptimizationError(message) {
            // Python side already sets currentStep=-1 via stepChanged,
            // but ensure the error state is shown even if signal order differs
            optimizationPopup.currentStep = -1
            optimizationPopup.stepDescription = message
        }

        function onStepChanged() {
            if (promptOptimizer) {
                optimizationPopup.currentStep = promptOptimizer.currentStep
                optimizationPopup.stepDescription = promptOptimizer.stepDescription
            }
        }
    }

    function parseResult(json) {
        try {
            var data = JSON.parse(json)
            optimizationPopup.originalPrompt = data.originalPrompt || ""
            optimizationPopup.optimizedPrompt = data.optimizedPrompt || ""
            optimizationPopup.problemAnalysis = data.problemAnalysis || null
            optimizationPopup.changes = data.changes || []
            optimizationPopup.improvementReport = data.improvementReport || null
        } catch (e) {
            console.log("[OptimizationResultPopup] Failed to parse result:", e)
        }
    }

    function applyOptimization() {
        if (optimizationPopup.optimizedPrompt.length === 0) return

        // Update all module card contents with the optimized prompt
        if (moduleCardModel) {
            moduleCardModel.updateAllContent(optimizationPopup.optimizedPrompt)
        }

        // Trigger preview and export data update
        if (mainViewRoot) {
            mainViewRoot.previewText = mainViewRoot.compilePreview()
            mainViewRoot.updateExportData()
        }

        optimizationPopup.close()
    }

    function resetAndOpen() {
        // Reset state for a new optimization run
        optimizationPopup.resultJson = ""
        optimizationPopup.originalPrompt = ""
        optimizationPopup.optimizedPrompt = ""
        optimizationPopup.problemAnalysis = null
        optimizationPopup.changes = []
        optimizationPopup.improvementReport = null
        optimizationPopup.currentStep = 0
        optimizationPopup.stepDescription = qsTr("正在准备…")
        optimizationPopup.open()
    }

    onResultJsonChanged: {
        if (resultJson.length > 0) {
            parseResult(resultJson)
        }
    }
}
