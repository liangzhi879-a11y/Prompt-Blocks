import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

// Security red team test panel
Rectangle {
    id: redTeamRoot
    color: "transparent"

    property string promptText: ""

    // Result state
    property bool hasResult: false
    property var resultData: null
    property string lastResultJson: ""

    // Selected attack categories
    property var selectedCategories: ["越狱", "注入", "敏感诱导", "角色突破"]

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.containerPadding
        spacing: Theme.spacingSM

        // Header
        Text {
            text: Icons.diamond + " " + qsTr("红队安全测试")
            color: Theme.onBackground
            font.pixelSize: Theme.fontSM
            font.weight: Font.DemiBold
        }

        // Attack vector categories
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingXS

            Text {
                text: qsTr("攻击向量类别:")
                color: Theme.onSurface
                font.pixelSize: Theme.fontXS
            }

            Flow {
                Layout.fillWidth: true
                spacing: Theme.spacingSM

                Repeater {
                    model: [
                        { name: "越狱", icon: Icons.circleThin, desc: "尝试绕过系统限制" },
                        { name: "注入", icon: Icons.add, desc: "注入恶意指令" },
                        { name: "敏感诱导", icon: Icons.circleFilled, desc: "诱导输出敏感信息" },
                        { name: "角色突破", icon: Icons.star, desc: "突破角色设定" },
                        { name: "指令覆盖", icon: Icons.warning, desc: "覆盖系统指令" },
                        { name: "信息泄露", icon: Icons.circleThin, desc: "泄露系统信息" }
                    ]

                    delegate: Rectangle {
                        width: catRow.width + Theme.spacingMD
                        height: Theme.heightXS
                        radius: height / 2
                        color: isSelected ? Theme.error : (catHover.hovered ? Theme.surfaceRaised : Theme.surfaceVariant)
                        border.color: isSelected ? Theme.error : Theme.border
                        border.width: 1

                        property bool isSelected: redTeamRoot.selectedCategories.indexOf(modelData.name) >= 0

                        Row {
                            id: catRow
                            anchors.centerIn: parent
                            spacing: Theme.spacingXXS

                            Text {
                                text: modelData.icon
                                font.pixelSize: Theme.fontSM
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: modelData.name
                                color: isSelected ? Theme.onPrimary : Theme.onSurface
                                font.pixelSize: Theme.fontSM
                                font.bold: isSelected
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        HoverHandler { id: catHover }
                        TapHandler {
                            onTapped: {
                                var idx = redTeamRoot.selectedCategories.indexOf(modelData.name)
                                var newCats = redTeamRoot.selectedCategories.slice()
                                if (idx >= 0) {
                                    newCats.splice(idx, 1)
                                } else {
                                    newCats.push(modelData.name)
                                }
                                redTeamRoot.selectedCategories = newCats
                            }
                        }

                        Behavior on color { enabled: !Theme.animReducedMotion; ColorAnimation { duration: Theme.animFast } }
                    }
                }
            }
        }

        // Run red team test button
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            radius: Theme.radiusSM
            color: {
                if (testViewModel && testViewModel.isRunning) return Theme.border
                return runRedHover.hovered ? Qt.darker(Theme.error, 1.2) : Theme.error
            }

            Row {
                anchors.centerIn: parent
                spacing: Theme.spacingS

                Text {
                    text: testViewModel && testViewModel.isRunning ? Icons.hourglass : Icons.sparkle
                    font.pixelSize: Theme.fontML
                    color: Theme.onPrimary
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: testViewModel && testViewModel.isRunning ? qsTr("红队测试中...") : qsTr("运行红队测试")
                    color: Theme.onPrimary
                    font.pixelSize: Theme.fontSM
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            HoverHandler { id: runRedHover }
            TapHandler {
                onTapped: runRedTeamTest()
            }

            Behavior on color { enabled: !Theme.animReducedMotion; ColorAnimation { duration: Theme.animFast } }
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
                color: Theme.error

                Behavior on width { enabled: !Theme.animReducedMotion; NumberAnimation { duration: Theme.animNormal } }
            }
        }

        // Loading animation
        Row {
            Layout.fillWidth: true
            visible: testViewModel && testViewModel.isRunning
            spacing: Theme.spacingS

            Text {
                text: Icons.sparkle
                font.pixelSize: Theme.fontSM
                anchors.verticalCenter: parent.verticalCenter

                SequentialAnimation on opacity {
                    running: redTeamRoot.visible && testViewModel && testViewModel.isRunning
                    loops: Animation.Infinite
                    NumberAnimation { from: 1.0; to: 0.3; duration: Theme.animSlow }
                    NumberAnimation { from: 0.3; to: 1.0; duration: Theme.animSlow }
                }
            }
            Text {
                text: qsTr("正在进行红队安全测试，请稍候...")
                color: Theme.error
                font.pixelSize: Theme.fontXS
                anchors.verticalCenter: parent.verticalCenter
                opacity: 0.7
            }
        }

        // Error message display
        Rectangle {
            Layout.fillWidth: true
            visible: testViewModel && testViewModel.errorMessage.length > 0
            height: redErrorRow.height + 12
            radius: Theme.radiusSM
            color: Theme.errorContainer
            border.color: Theme.error
            border.width: 1

            Row {
                id: redErrorRow
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
            id: redTeamResultScroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: availableWidth

            ColumnLayout {
                id: redTeamResultContent
                width: redTeamResultScroll.availableWidth
                spacing: Theme.spacingSM
                visible: redTeamRoot.hasResult

                // Safety score - large circular indicator
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Theme.spacingXS

                    Text {
                        text: qsTr("综合安全得分")
                        color: Theme.onBackground
                        font.pixelSize: Theme.fontSM
                        font.weight: Font.DemiBold
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Canvas {
                        id: scoreCircle
                        Layout.preferredWidth: 120
                        Layout.preferredHeight: 120
                        Layout.alignment: Qt.AlignHCenter

                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.reset()

                            var cx = width / 2
                            var cy = height / 2
                            var r = 48
                            var lineW = 8

                            var score = redTeamRoot.resultData ? redTeamRoot.resultData.safetyScore : 0
                            var pct = score / 100

                            // Background circle
                            ctx.beginPath()
                            ctx.arc(cx, cy, r, 0, 2 * Math.PI)
                            ctx.strokeStyle = Theme.surfaceVariant
                            ctx.lineWidth = lineW
                            ctx.stroke()

                            // Score arc
                            var startAngle = -Math.PI / 2
                            var endAngle = startAngle + (2 * Math.PI * pct)
                            ctx.beginPath()
                            ctx.arc(cx, cy, r, startAngle, endAngle)
                            ctx.strokeStyle = score >= 80 ? Theme.secondary :
                                               score >= 60 ? Theme.warning : Theme.error
                            ctx.lineWidth = lineW
                            ctx.lineCap = "round"
                            ctx.stroke()

                            // Score text
                            ctx.fillStyle = Theme.onBackground
                            ctx.font = "bold 24px sans-serif"
                            ctx.textAlign = "center"
                            ctx.textBaseline = "middle"
                            ctx.fillText(score.toFixed(0), cx, cy - 6)

                            ctx.fillStyle = Theme.onSurfaceVariant
                            ctx.font = Theme.fontXS + "px sans-serif"
                            ctx.fillText("/ 100", cx, cy + 14)
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Theme.heightMD
                        radius: Theme.radiusSM
                        color: Theme.infoContainer
                        border.color: Theme.primary
                        border.width: 1

                        Column {
                            anchors.centerIn: parent
                            spacing: 1

                            Text {
                                text: {
                                    var lt = redTeamRoot.resultData ? redTeamRoot.resultData.avgLatency_ms : 0
                                    return lt >= 1000 ? (lt / 1000).toFixed(1) + "s" : lt + "ms"
                                }
                                color: Theme.primary
                                font.pixelSize: Theme.fontLG
                                font.bold: true
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            Text {
                                text: qsTr("平均响应")
                                color: Theme.onSurfaceVariant
                                font.pixelSize: Theme.fontXS
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }
                }

                // Radar chart for security dimensions
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Theme.spacingXS

                    Text {
                        text: qsTr("安全维度雷达图")
                        color: Theme.onBackground
                        font.pixelSize: Theme.fontSM
                        font.weight: Font.DemiBold
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Canvas {
                        id: radarChart
                        Layout.preferredWidth: 200
                        Layout.preferredHeight: 200
                        Layout.alignment: Qt.AlignHCenter

                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.reset()

                            var cx = width / 2
                            var cy = height / 2
                            var maxR = 75

                            // Security dimensions with scores
                            var dimensions = redTeamRoot.getSecurityDimensions()
                            var dimCount = dimensions.length
                            if (dimCount < 3) {
                                ctx.fillStyle = Theme.onSurfaceVariant
                                ctx.font = "11px sans-serif"
                                ctx.textAlign = "center"
                                ctx.fillText(qsTr("运行测试后显示雷达图"), cx, cy)
                                return
                            }

                            var angleStep = (2 * Math.PI) / dimCount
                            var startAngle = -Math.PI / 2

                            // Draw concentric grid circles (20%, 40%, 60%, 80%, 100%)
                            for (var level = 1; level <= 5; level++) {
                                var levelR = maxR * level / 5
                                ctx.beginPath()
                                for (var d = 0; d <= dimCount; d++) {
                                    var angle = startAngle + d * angleStep
                                    var px = cx + levelR * Math.cos(angle)
                                    var py = cy + levelR * Math.sin(angle)
                                    if (d === 0) ctx.moveTo(px, py)
                                    else ctx.lineTo(px, py)
                                }
                                ctx.closePath()
                                ctx.strokeStyle = Theme.divider
                                ctx.lineWidth = 0.5
                                ctx.stroke()
                            }

                            // Draw axis lines and labels
                            for (var d = 0; d < dimCount; d++) {
                                var angle = startAngle + d * angleStep
                                var endX = cx + maxR * Math.cos(angle)
                                var endY = cy + maxR * Math.sin(angle)

                                ctx.beginPath()
                                ctx.moveTo(cx, cy)
                                ctx.lineTo(endX, endY)
                                ctx.strokeStyle = Theme.border
                                ctx.lineWidth = 0.5
                                ctx.stroke()

                                // Label
                                var labelR = maxR + 16
                                var lx = cx + labelR * Math.cos(angle)
                                var ly = cy + labelR * Math.sin(angle)
                                ctx.fillStyle = Theme.onSurfaceVariant
                                ctx.font = Theme.fontS + "px sans-serif"
                                ctx.textAlign = "center"
                                ctx.textBaseline = "middle"
                                ctx.fillText(dimensions[d].name, lx, ly)
                            }

                            // Draw data polygon (filled)
                            ctx.beginPath()
                            for (var d = 0; d < dimCount; d++) {
                                var angle = startAngle + d * angleStep
                                var val = dimensions[d].score / 100
                                var px = cx + maxR * val * Math.cos(angle)
                                var py = cy + maxR * val * Math.sin(angle)
                                if (d === 0) ctx.moveTo(px, py)
                                else ctx.lineTo(px, py)
                            }
                            ctx.closePath()
                            ctx.fillStyle = Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.15)
                            ctx.fill()
                            ctx.strokeStyle = Theme.error
                            ctx.lineWidth = 2
                            ctx.stroke()

                            // Draw data points
                            for (var d = 0; d < dimCount; d++) {
                                var angle = startAngle + d * angleStep
                                var val = dimensions[d].score / 100
                                var px = cx + maxR * val * Math.cos(angle)
                                var py = cy + maxR * val * Math.sin(angle)

                                ctx.beginPath()
                                ctx.arc(px, py, 3, 0, 2 * Math.PI)
                                ctx.fillStyle = dimensions[d].score >= 80 ? Theme.secondary :
                                               dimensions[d].score >= 60 ? Theme.warning : Theme.error
                                ctx.fill()
                            }
                        }
                    }
                }

                // Intercept rate
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingSM

                    Text {
                        text: Icons.blocked + " " + qsTr("拦截率")
                        color: Theme.onBackground
                        font.pixelSize: Theme.fontSM
                        font.weight: Font.Medium
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 12
                        radius: 6
                        color: Theme.surfaceVariant

                        Rectangle {
                            width: parent.width * (redTeamRoot.resultData ? redTeamRoot.resultData.interceptRate / 100 : 0)
                            height: parent.height
                            radius: 6
                            color: redTeamRoot.resultData && redTeamRoot.resultData.interceptRate >= 80 ? Theme.secondary :
                                   redTeamRoot.resultData && redTeamRoot.resultData.interceptRate >= 60 ? Theme.warning : Theme.error

                            Behavior on width { enabled: !Theme.animReducedMotion; NumberAnimation { duration: Theme.animNormal } }
                        }
                    }

                    Text {
                        text: redTeamRoot.resultData ? redTeamRoot.resultData.interceptRate.toFixed(1) + "%" : "0%"
                        color: Theme.onSurface
                        font.pixelSize: Theme.fontSM
                        font.bold: true
                        Layout.preferredWidth: 45
                    }
                }

                // Stats row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingSM

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Theme.heightMD
                        radius: Theme.radiusSM
                        color: Theme.successContainer
                        border.color: Theme.secondary
                        border.width: 1

                        Column {
                            anchors.centerIn: parent
                            spacing: 1

                            Text {
                                text: redTeamRoot.resultData ? redTeamRoot.resultData.blockedCount.toString() : "0"
                                color: Theme.secondary
                                font.pixelSize: Theme.fontLG
                                font.bold: true
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            Text {
                                text: qsTr("已拦截")
                                color: Theme.onSurfaceVariant
                                font.pixelSize: Theme.fontXS
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Theme.heightMD
                        radius: Theme.radiusSM
                        color: Theme.errorContainer
                        border.color: Theme.error
                        border.width: 1

                        Column {
                            anchors.centerIn: parent
                            spacing: 1

                            Text {
                                text: redTeamRoot.resultData ? redTeamRoot.resultData.unblockedCount.toString() : "0"
                                color: Theme.error
                                font.pixelSize: Theme.fontLG
                                font.bold: true
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            Text {
                                text: qsTr("未拦截")
                                color: Theme.onSurfaceVariant
                                font.pixelSize: Theme.fontXS
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }
                }

                // Smart optimization button
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    radius: Theme.radiusSM
                    color: redOptBtnHover.hovered ? Qt.darker(Theme.accent, 1.1) : Theme.accent

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

                    HoverHandler { id: redOptBtnHover }
                    TapHandler {
                        onTapped: {
                            if (promptOptimizer) {
                                var projectId = moduleCardModel ? moduleCardModel.getProjectId() : ""
                                promptOptimizer.optimize(redTeamRoot.promptText, redTeamRoot.lastResultJson, projectId)
                                // Open optimization popup immediately to show progress
                                if (optimizationResultPopup) {
                                    optimizationResultPopup.resetAndOpen()
                                }
                            }
                        }
                    }

                    Behavior on color { enabled: !Theme.animReducedMotion; ColorAnimation { duration: Theme.animFast } }
                }

                // Unblocked attack cases list
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingXS

                    Text {
                        text: Icons.warning + " " + qsTr("未拦截攻击案例")
                        color: Theme.error
                        font.pixelSize: Theme.fontSM
                        font.weight: Font.DemiBold
                        visible: redTeamRoot.getUnblockedCases().length > 0
                    }

                    Column {
                        Layout.fillWidth: true
                        spacing: Theme.spacingXS

                        Repeater {
                            model: redTeamRoot.getUnblockedCases()

                            delegate: Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: caseExpanded ? caseContent.implicitHeight + Theme.spacingSM * 2 : 36
                                radius: Theme.radiusSM
                                color: Theme.errorContainer
                                border.color: Theme.error
                                border.width: 1
                                clip: false

                                property bool caseExpanded: false

                                ColumnLayout {
                                    id: caseContent
                                    anchors.fill: parent
                                    anchors.margins: Theme.spacingXS
                                    spacing: Theme.spacingXXS

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: Theme.spacingSM

                                        // Category badge
                                        Badge {
                                            text: modelData.category
                                            badgeStyle: 0
                                            badgeSize: 0
                                        }

                                        Text {
                                            text: modelData.vector.substring(0, 30) + "..."
                                            color: Theme.onSurface
                                            font.pixelSize: Theme.fontXS
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }

                                        Rectangle {
                                            width: 18
                                            height: 18
                                            radius: 9
                                            color: expCaseHover.hovered ? Theme.surfaceRaised : "transparent"

                                            Text {
                                                anchors.centerIn: parent
                                                text: caseExpanded ? Icons.chevronUp : Icons.chevronDown
                                                font.pixelSize: Theme.fontXXS
                                                color: Theme.onSurfaceVariant
                                            }

                                            HoverHandler { id: expCaseHover }
                                            TapHandler {
                                                onTapped: caseExpanded = !caseExpanded
                                            }
                                        }
                                    }

                                    // Expanded details
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        visible: caseExpanded
                                        spacing: Theme.spacingXXS

                                        Text {
                                            text: qsTr("攻击向量:")
                                            color: Theme.warning
                                            font.pixelSize: Theme.fontXS
                                            font.bold: true
                                        }
                                        Text {
                                            text: modelData.vector
                                            color: Theme.onSurface
                                            font.pixelSize: Theme.fontXS
                                            wrapMode: Text.WordWrap
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: qsTr("AI输出:")
                                            color: Theme.error
                                            font.pixelSize: Theme.fontXS
                                            font.bold: true
                                        }
                                        Text {
                                            text: modelData.output
                                            color: Theme.error
                                            font.pixelSize: Theme.fontXS
                                            wrapMode: Text.WordWrap
                                            Layout.fillWidth: true
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: Theme.spacingSM
                                            visible: modelData.dangerLevel > 0 || modelData.problemType !== "" || modelData.safetyAssessment !== ""

                                            Text {
                                                text: qsTr("危险等级:")
                                                color: Theme.warning
                                                font.pixelSize: Theme.fontXS
                                                font.bold: true
                                            }
                                            Badge {
                                                text: (modelData.dangerLevel || 0).toString()
                                                badgeStyle: (modelData.dangerLevel || 0) >= 7 ? 3 :
                                                         (modelData.dangerLevel || 0) >= 4 ? 2 : 4
                                                badgeSize: 0
                                            }
                                        }

                                        Text {
                                            text: (modelData.problemType && modelData.problemType !== "") ?
                                                  qsTr("问题类型: ") + modelData.problemType : ""
                                            color: Theme.error
                                            font.pixelSize: Theme.fontXS
                                            visible: modelData.problemType && modelData.problemType !== ""
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: modelData.safetyAssessment || ""
                                            color: Theme.onSurfaceVariant
                                            font.pixelSize: Theme.fontXS
                                            wrapMode: Text.WordWrap
                                            visible: modelData.safetyAssessment !== ""
                                            Layout.fillWidth: true
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Hardening suggestions
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingXS
                    visible: redTeamRoot.resultData && redTeamRoot.resultData.hardeningSuggestions

                    Text {
                        text: Icons.diamond + " " + qsTr("加固建议")
                        color: Theme.onBackground
                        font.pixelSize: Theme.fontSM
                        font.weight: Font.DemiBold
                    }

                    ScrollView {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 80
                        clip: true

                        TextArea {
                            text: redTeamRoot.resultData ? redTeamRoot.resultData.hardeningSuggestions : ""
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
            }
        }

        // No result placeholder
        Column {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !redTeamRoot.hasResult && !(testViewModel && testViewModel.isRunning)
            spacing: Theme.spacingSM

            Text {
                text: Icons.sparkle
                font.pixelSize: Theme.fontXXXL
                anchors.horizontalCenter: parent.horizontalCenter
                opacity: 0.3
            }
            Text {
                text: qsTr("选择攻击类别并运行红队测试")
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

        function onRedTeamCompleted(resultJson) {
            try {
                redTeamRoot.resultData = JSON.parse(resultJson)
                redTeamRoot.hasResult = true
                redTeamRoot.lastResultJson = resultJson
                scoreCircle.requestPaint()
                radarChart.requestPaint()
            } catch (e) {
                console.log("[RedTeamPanel] Failed to parse result:", e)
            }
        }

        function onTestError(errorMsg) {
            console.log("[RedTeamPanel] Error:", errorMsg)
        }
    }

    function runRedTeamTest() {
        if (!testViewModel) return
        if (redTeamRoot.selectedCategories.length === 0) return

        var categoriesJson = JSON.stringify(redTeamRoot.selectedCategories)
        testViewModel.runRedTeamTest(redTeamRoot.promptText, categoriesJson)
    }

    function getUnblockedCases() {
        if (!redTeamRoot.resultData || !redTeamRoot.resultData.unblockedCases) return []
        return redTeamRoot.resultData.unblockedCases
    }

    function getSecurityDimensions() {
        // Build dimension data for the radar chart from resultData
        if (!redTeamRoot.resultData) return []

        var dims = []

        // Use dimensionScores if available from the backend
        if (redTeamRoot.resultData.dimensionScores) {
            var ds = redTeamRoot.resultData.dimensionScores
            var keys = Object.keys(ds)
            for (var i = 0; i < keys.length; i++) {
                dims.push({"name": keys[i], "score": ds[keys[i]]})
            }
            return dims
        }

        // Fallback: derive from category test results
        var categories = redTeamRoot.selectedCategories
        var safetyScore = redTeamRoot.resultData.safetyScore || 0
        var interceptRate = redTeamRoot.resultData.interceptRate || 0
        var blockedCount = redTeamRoot.resultData.blockedCount || 0
        var totalCount = blockedCount + (redTeamRoot.resultData.unblockedCount || 0)
        totalCount = Math.max(totalCount, 1)

        // Build dimensions from selected categories
        for (var i = 0; i < categories.length; i++) {
            var catScore = 50  // Default neutral score
            // If we have per-category data, use it
            if (redTeamRoot.resultData.categoryScores && redTeamRoot.resultData.categoryScores[categories[i]]) {
                catScore = redTeamRoot.resultData.categoryScores[categories[i]]
            } else {
                // Estimate from overall stats
                catScore = Math.round(interceptRate)
            }
            dims.push({"name": categories[i], "score": catScore})
        }

        // Add overall dimensions
        dims.push({"name": qsTr("拦截率"), "score": Math.round(interceptRate)})
        dims.push({"name": qsTr("鲁棒性"), "score": Math.round(safetyScore)})

        return dims
    }
}
