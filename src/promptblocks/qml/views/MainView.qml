import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"
import ".."

Rectangle {
    id: mainViewRoot
    color: Theme.background

    property string selectedCardId: ""
    property int rightPanelTab: 0
    property int testSubTab: 0
    property string searchFilter: ""
    property string previewText: ""
    property var syntaxErrors: ({})
    property string cardListJson: "[]"
    property string variablesJson: "[]"
    property string projectJson: "{}"

    // ── SplitView width persistence ──
    property real _leftWidth: 290
    property real _rightWidth: 360

    // ── ModuleCardModel role constants ──
    readonly property int _blockIdRole: 257
    readonly property int _blockTypeRole: 258
    readonly property int _titleRole: 259
    readonly property int _contentRole: 260
    readonly property int _typeColorRole: 261
    readonly property int _typeIconRole: 262
    readonly property int _typeLabelRole: 263
    readonly property int _orderIndexRole: 264
    readonly property int _isExpandedRole: 265
    readonly property int _editModeRole: 266

    // ── VariableModel role constants ──
    readonly property int _varNameRole: 257
    readonly property int _varTypeRole: 258
    readonly property int _varDefaultValueRole: 259
    readonly property int _varScopeRole: 260
    readonly property int _varDescriptionRole: 261

    // ── Undo/Redo helpers ──
    function pushUndoState() {
        if (!undoManager || !moduleCardModel) return
        // Capture current card list as a JSON snapshot for undo
        var snapshot = []
        var count = moduleCardModel.rowCount()
        for (var i = 0; i < count; i++) {
            var idx = moduleCardModel.index(i, 0)
            snapshot.push({
                blockId: moduleCardModel.data(idx, mainViewRoot._blockIdRole),
                blockType: moduleCardModel.data(idx, mainViewRoot._blockTypeRole),
                title: moduleCardModel.data(idx, mainViewRoot._titleRole),
                content: moduleCardModel.data(idx, mainViewRoot._contentRole),
                orderIndex: i
            })
        }
        undoManager.pushSnapshot(moduleCardModel, JSON.stringify(snapshot))
        undoManager.captureCurrentState()
    }

    function performUndo() {
        if (undoManager && undoManager.canUndo) {
            undoManager.undo()
            previewUpdateTimer.start()
        }
    }

    function performRedo() {
        if (undoManager && undoManager.canRedo) {
            undoManager.redo()
            previewUpdateTimer.start()
        }
    }

    // Preview update timer (debounce)
    Timer {
        id: previewUpdateTimer
        interval: 200
        repeat: false
        onTriggered: {
            mainViewRoot.previewText = compilePreview()
        }
    }

    // Syntax check timer (debounce)
    Timer {
        id: syntaxCheckTimer
        interval: 500
        repeat: false
        onTriggered: runSyntaxCheck()
    }

    function runSyntaxCheck() {
        if (!syntaxChecker) return
        var newErrors = {}
        var count = moduleCardModel ? moduleCardModel.rowCount() : 0
        for (var i = 0; i < count; i++) {
            var idx = moduleCardModel.index(i, 0)
            var content = moduleCardModel.data(idx, mainViewRoot._contentRole)
            var blockId = moduleCardModel.data(idx, mainViewRoot._blockIdRole)
            if (content && content.trim().length > 0) {
                var errs = syntaxChecker.checkAll(content)
                if (errs.length > 0) {
                    newErrors[blockId] = errs
                }
            }
        }
        mainViewRoot.syntaxErrors = newErrors
    }

    function getErrorsForCard(bid) {
        return mainViewRoot.syntaxErrors[bid] || []
    }

    function totalErrorCount() {
        var count = 0
        var keys = Object.keys(mainViewRoot.syntaxErrors)
        for (var i = 0; i < keys.length; i++) {
            count += mainViewRoot.syntaxErrors[keys[i]].length
        }
        return count
    }

    // Module type definitions loaded from Python (single source of truth)
    property var moduleTypes: []

    // Helper: get module type info by type string
    function getModuleTypeInfo(type) {
        for (var i = 0; i < moduleTypes.length; i++) {
            if (moduleTypes[i].type === type) return moduleTypes[i]
        }
        return { type: type, title: type, icon: Icons.list, color: (Theme.moduleTypeColors[type] || {}).accent || Theme.primary, desc: "", label: "??" }
    }

    SplitView {
        id: mainSplitView
        anchors.fill: parent
        orientation: Qt.Horizontal
        handle: SplitViewHandle {}

        // ═══════════════════════════════════════
        // LEFT: Module Library
        // ═══════════════════════════════════════
        Rectangle {
            id: leftSidebar
            SplitView.minimumWidth: 240
            SplitView.preferredWidth: mainViewRoot._leftWidth
            SplitView.fillHeight: true
            color: Theme.surface
            border.color: Theme.panelBorder
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Header
                Rectangle {
                    Layout.fillWidth: true
                    height: Theme.heightLG
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Theme.headerStart }
                        GradientStop { position: 1.0; color: Theme.headerEnd }
                    }
                    color: Theme.surfaceVariant

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacingLG
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacingSM

                        Rectangle {
                            width: 3; height: 18; radius: 2
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: Icons.menu + " " + qsTr("模块资源库")
                            color: Theme.onBackground
                            font.pixelSize: Theme.fontMD
                            font.weight: Font.DemiBold
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Theme.divider }

                // Search/filter
                TextField {
                    id: searchField
                    Layout.fillWidth: true
                    Layout.margins: Theme.spacingSM
                    Layout.preferredHeight: Theme.heightSM
                    placeholderText: qsTr("搜索模块...")
                    font.pixelSize: Theme.fontSM
                    color: Theme.onBackground
                    onTextChanged: mainViewRoot.searchFilter = text.toLowerCase()

                    background: Rectangle {
                        color: Theme.background
                        radius: Theme.radiusSM
                        border.color: searchField.activeFocus ? Theme.primary : Theme.border
                        border.width: 1
                    }

                    leftPadding: 30

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacingSM
                        anchors.verticalCenter: parent.verticalCenter
                        text: Icons.search
                        font.pixelSize: Theme.fontMD
                        font.family: Icons.fontFamily
                        opacity: 0.5
                    }
                }

                // Module type list
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: 150
                    clip: true
                    contentWidth: availableWidth

                    Column {
                        id: moduleTypeList
                        width: parent ? parent.width : 290
                        spacing: Theme.spacingXS
                        topPadding: Theme.spacingSM
                        bottomPadding: Theme.spacingSM
                        leftPadding: 0
                        rightPadding: 0

                        Repeater {
                            model: mainViewRoot.moduleTypes

                            delegate: ModuleTypeCard {
                                width: moduleTypeList.width - Theme.spacingMD * 2
                                anchors.horizontalCenter: parent.horizontalCenter
                                moduleType: modelData.type
                                moduleTitle: modelData.title
                                moduleIcon: modelData.icon
                                moduleDescription: modelData.desc
                                visible: mainViewRoot.searchFilter === "" ||
                                         modelData.title.toLowerCase().indexOf(mainViewRoot.searchFilter) >= 0 ||
                                         modelData.type.toLowerCase().indexOf(mainViewRoot.searchFilter) >= 0
                                onModuleTypeClicked: function(type) {
                                    addModuleToCanvas(type)
                                }
                            }
                        }
                    }
                }

                // Variable Manager Panel (system infrastructure, not a module)
                 VariableManagerPanel {
                     id: varPanel
                     Layout.fillWidth: true
                     Layout.margins: Theme.spacingXS
                     Layout.bottomMargin: Theme.spacingXS
                     Layout.minimumHeight: 36
                     Layout.maximumHeight: 300
                 }

                // Knowledge Manager Panel (system infrastructure)
                 KnowledgeManagerPanel {
                     id: kbPanel
                     Layout.fillWidth: true
                     Layout.margins: Theme.spacingXS
                     Layout.bottomMargin: Theme.spacingXS
                     Layout.minimumHeight: 36
                     Layout.maximumHeight: 260
                 }

                // Tool Manager Panel (system infrastructure)
                 ToolManagerPanel {
                     id: toolPanel
                     Layout.fillWidth: true
                     Layout.margins: Theme.spacingXS
                     Layout.bottomMargin: Theme.spacingSM
                     Layout.minimumHeight: 36
                     Layout.maximumHeight: 260
                 }
            }
        }

        // ═══════════════════════════════════════
        // CENTER: Vertical Card Canvas
        // ═══════════════════════════════════════
        Rectangle {
            id: canvasArea
            SplitView.minimumWidth: 300
            SplitView.fillWidth: true
            SplitView.fillHeight: true
            // Darken background when modules are present to make cards stand out
            color: {
                var hasCards = moduleCardModel && moduleCardModel.rowCount() > 0
                return hasCards ? Theme.surfaceVariant : Theme.background
            }
            Behavior on color { enabled: !Theme.animReducedMotion; ColorAnimation { duration: Theme.animNormal } }

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Canvas header
                Rectangle {
                    Layout.fillWidth: true
                    height: Theme.heightLG
                    color: Theme.surface

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacingLG
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacingSM

                        Rectangle {
                            width: 3; height: 18; radius: 2
                            color: Theme.accent
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: Icons.diamond + " " + qsTr("提示词拼图")
                            color: Theme.onBackground
                            font.pixelSize: Theme.fontMD
                            font.weight: Font.DemiBold
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // Syntax status indicator + Undo/Redo buttons
                    Row {
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.spacingLG
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacingXS

                        // Undo button
                        IconButton {
                            icon: Icons.undo
                            btnSize: 1
                            tooltip: qsTr("撤销 (Ctrl+Z)")
                            enabled: undoManager && undoManager.canUndo
                            onClicked: performUndo()
                        }

                        // Redo button
                        IconButton {
                            icon: Icons.redo
                            btnSize: 1
                            tooltip: qsTr("重做 (Ctrl+Y)")
                            enabled: undoManager && undoManager.canRedo
                            onClicked: performRedo()
                        }

                        // Separator
                        Rectangle {
                            width: 1
                            height: 16
                            color: Theme.divider
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        // Version button — flat icon
                        IconButton {
                            icon: Icons.sparkle
                            btnSize: 1
                            tooltip: qsTr("版本管理")
                            onClicked: versionPopup.open()
                        }

                        // Settings button — flat icon
                        IconButton {
                            icon: Icons.settings
                            btnSize: 1
                            tooltip: qsTr("模型配置")
                            onClicked: modelConfigDialog.open()
                        }

                        // Syntax status — aligned with icon buttons
                        Rectangle {
                            width: 28
                            height: 28
                            radius: 14
                            color: {
                                var total = mainViewRoot.totalErrorCount()
                                if (total === 0) return Theme.secondary
                                return Theme.error
                            }
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                anchors.centerIn: parent
                                text: {
                                    var total = mainViewRoot.totalErrorCount()
                                    if (total === 0) return Icons.accept
                                    return total.toString()
                                }
                                font.family: Icons.fontFamily
                                color: "#ffffff"
                                font.pixelSize: Theme.fontXS
                                font.bold: true
                            }

                            Behavior on color { enabled: !Theme.animReducedMotion; ColorAnimation { duration: Theme.animFast } }

                            HoverHandler { id: syntaxStatusHover }
                            TapHandler {
                                onTapped: syntaxCheckTimer.start()
                            }

                            ToolTip {
                                visible: syntaxStatusHover.hovered
                                text: {
                                    var total = mainViewRoot.totalErrorCount()
                                    if (total === 0) return qsTr("语法检查: 无问题")
                                    return qsTr("语法检查: %1个问题").arg(total)
                                }
                                delay: 300
                            }
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Theme.divider }

                // Card ListView
                ListView {
                    id: cardListView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: Theme.spacingSM
                    topMargin: Theme.spacingMD
                    bottomMargin: Theme.spacingMD
                    leftMargin: Theme.spacingLG
                    rightMargin: Theme.spacingLG
                    boundsBehavior: Flickable.StopAtBounds
                    flickDeceleration: 3000
                    maximumFlickVelocity: 3000

                    model: moduleCardModel

                    add: Transition {
                        enabled: !Theme.animReducedMotion
                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.animNormal; easing.type: Theme.animEasing }
                        NumberAnimation { property: "scale"; from: 0.95; to: 1; duration: Theme.animNormal; easing.type: Theme.animEasing }
                    }
                    remove: Transition {
                        enabled: !Theme.animReducedMotion
                        NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.animFast; easing.type: Theme.animEasing }
                        NumberAnimation { property: "scale"; from: 1; to: 0.95; duration: Theme.animFast; easing.type: Theme.animEasing }
                    }
                    addDisplaced: Transition {
                        enabled: !Theme.animReducedMotion
                        NumberAnimation { property: "y"; duration: Theme.animNormal; easing.type: Theme.animEasing }
                    }
                    removeDisplaced: Transition {
                        enabled: !Theme.animReducedMotion
                        NumberAnimation { property: "y"; duration: Theme.animNormal; easing.type: Theme.animEasing }
                    }
                    populate: Transition {
                        enabled: !Theme.animReducedMotion
                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.animSlow; easing.type: Theme.animEasing }
                    }

                    delegate: ModuleCard {
                        width: cardListView.width - Theme.spacingLG * 2
                        blockId: model.blockId
                        blockType: model.blockType
                        title: model.title
                        content: model.content
                        isExpanded: model.isExpanded
                        typeIcon: model.typeIcon
                        typeLabel: model.typeLabel
                        editMode: model.editMode ? "manual" : "ai"
                        cardIndex: index
                        syntaxErrors: mainViewRoot.getErrorsForCard(model.blockId)

                        onDeleteRequested: function(bid) {
                            removeModuleFromCanvas(bid)
                        }
                        onModuleContentChanged: function(bid, newContent) {
                            updateCardContent(bid, newContent)
                        }
                        onMoveUpRequested: function(fromIdx) {
                            moveCard(fromIdx, fromIdx - 1)
                        }
                        onMoveDownRequested: function(fromIdx) {
                            moveCard(fromIdx, fromIdx + 1)
                        }
                        onDragMoveRequested: function(fromIdx, toIdx) {
                            moveCard(fromIdx, toIdx)
                        }
                    }

                    // Empty state — hidden when modules are present
                    Label {
                        anchors.centerIn: parent
                        z: -1
                        visible: !moduleCardModel || moduleCardModel.rowCount() === 0
                        text: Icons.circleFilled + " " + qsTr("双击左侧模块添加到画布")
                        color: Theme.onSurfaceVariant
                        font.pixelSize: Theme.fontLG
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                // Bottom bar: token count
                TokenCounter {
                    Layout.fillWidth: true
                    text: mainViewRoot.previewText
                    modelName: "gpt-4"
                }
            }
        }

        // ═══════════════════════════════════════
        // RIGHT: Preview & Test Panel
        // ═══════════════════════════════════════
        Rectangle {
            id: rightPanel
            SplitView.minimumWidth: 300
            SplitView.preferredWidth: mainViewRoot._rightWidth
            SplitView.fillHeight: true
            color: Theme.surface
            border.color: Theme.panelBorder
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Tab bar
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.heightXS
                    Layout.maximumHeight: Theme.heightXS
                    spacing: 0

                    Repeater {
                        model: [
                            { label: qsTr("预览"), icon: Icons.circleThin },
                            { label: qsTr("测试"), icon: Icons.accept },
                            { label: qsTr("优化"), icon: Icons.sparkle }
                        ]
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: mainViewRoot.rightPanelTab === index ? Theme.surface : Theme.surfaceVariant
                            opacity: mainViewRoot.rightPanelTab === index ? 1 : 0.6

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: Theme.spacingXS
                                Text {
                                    text: modelData.icon
                                    font.pixelSize: Theme.fontS
                                    font.family: Icons.fontFamily
                                }
                                Text {
                                    text: modelData.label
                                    color: mainViewRoot.rightPanelTab === index ? Theme.primary : Theme.onSurfaceVariant
                                    font.pixelSize: Theme.fontS
                                    font.weight: mainViewRoot.rightPanelTab === index ? Font.Bold : Font.Normal
                                }
                            }

                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 24
                                height: 2
                                radius: 1
                                color: Theme.primary
                                opacity: mainViewRoot.rightPanelTab === index ? 1 : 0
                                Behavior on opacity { enabled: !Theme.animReducedMotion; NumberAnimation { duration: Theme.animFast } }
                            }

                            HoverHandler { id: tabHover }
                            TapHandler { onTapped: mainViewRoot.rightPanelTab = index }
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Theme.divider }

                StackLayout {
                    id: mainTabStack
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: mainViewRoot.rightPanelTab

                    onCurrentIndexChanged: {
                        var item = children[currentIndex]
                        if (item) {
                            item.opacity = 0
                            fadeInMainTab.target = item
                            fadeInMainTab.start()
                        }
                    }

                    NumberAnimation {
                        id: fadeInMainTab
                        property: "opacity"
                        from: 0; to: 1
                        duration: Theme.animFast
                        easing.type: Theme.animEasing
                    }

                    // Preview tab
                    Rectangle {
                        color: Theme.surface

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.containerPadding
                            spacing: Theme.spacingSM

                            // Copy button header
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Theme.spacingSM

                                Text {
                                    text: qsTr("合成预览")
                                    color: Theme.onBackground
                                    font.pixelSize: Theme.fontSM
                                    font.weight: Font.DemiBold
                                }

                                Item { Layout.fillWidth: true }

                                // Copy button
                                Rectangle {
                                    width: copyBtnRow.width + Theme.spacingLG
                                    height: Theme.heightXS
                                    radius: Theme.radiusSM
                                    color: copyHover.hovered ? Theme.primaryMuted : "transparent"
                                    border.color: Theme.primary
                                    border.width: 1

                                    Row {
                                        id: copyBtnRow
                                        anchors.centerIn: parent
                                        spacing: Theme.spacingXS

                                        Text {
                                            text: Icons.list
                                            font.pixelSize: Theme.fontS
                                            font.family: Icons.fontFamily
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                        Text {
                                            text: qsTr("复制")
                                            color: Theme.primary
                                            font.pixelSize: Theme.fontXS
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    HoverHandler { id: copyHover }
                                    TapHandler {
                                        onTapped: {
                                            previewTextArea.selectAll()
                                            previewTextArea.copy()
                                        }
                                    }

                                    Behavior on color { enabled: !Theme.animReducedMotion; ColorAnimation { duration: Theme.animFast } }
                                }

                                // Paste button
                                Rectangle {
                                    width: pasteBtnRow.width + Theme.spacingLG
                                    height: Theme.heightXS
                                    radius: Theme.radiusSM
                                    color: pasteHover.hovered ? Theme.primaryMuted : "transparent"
                                    border.color: Theme.secondary
                                    border.width: 1

                                    Row {
                                        id: pasteBtnRow
                                        anchors.centerIn: parent
                                        spacing: Theme.spacingXS

                                        Text {
                                            text: Icons.list
                                            font.pixelSize: Theme.fontS
                                            font.family: Icons.fontFamily
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                        Text {
                                            text: qsTr("粘贴")
                                            color: Theme.secondary
                                            font.pixelSize: Theme.fontXS
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    HoverHandler { id: pasteHover }
                                    TapHandler {
                                        onTapped: {
                                            previewTextArea.paste()
                                        }
                                    }

                                    Behavior on color { enabled: !Theme.animReducedMotion; ColorAnimation { duration: Theme.animFast } }
                                }

                                // Import button
                                Rectangle {
                                    width: importBtnRow.width + Theme.spacingLG
                                    height: Theme.heightXS
                                    radius: Theme.radiusSM
                                    color: importBtnHover2.hovered ? Theme.primaryMuted : "transparent"
                                    border.color: Theme.accent
                                    border.width: 1

                                    Row {
                                        id: importBtnRow
                                        anchors.centerIn: parent
                                        spacing: Theme.spacingXS

                                        Text {
                                            text: Icons.up
                                            font.pixelSize: Theme.fontS
                                            font.family: Icons.fontFamily
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                        Text {
                                            text: qsTr("导入")
                                            color: Theme.accent
                                            font.pixelSize: Theme.fontXS
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    HoverHandler { id: importBtnHover2 }
                                    TapHandler {
                                        onTapped: {
                                            importPopup.open()
                                        }
                                    }

                                    Behavior on color { enabled: !Theme.animReducedMotion; ColorAnimation { duration: Theme.animFast } }
                                }

                                // Export button
                                Rectangle {
                                    Layout.rightMargin: Theme.spacingSM
                                    width: exportBtnRow.width + Theme.spacingLG
                                    height: Theme.heightXS
                                    radius: Theme.radiusSM
                                    color: exportBtnHover2.hovered ? Theme.primaryMuted : "transparent"
                                    border.color: Theme.accent
                                    border.width: 1

                                    Row {
                                        id: exportBtnRow
                                        anchors.centerIn: parent
                                        spacing: Theme.spacingXS

                                        Text {
                                            text: Icons.down
                                            font.pixelSize: Theme.fontS
                                            font.family: Icons.fontFamily
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                        Text {
                                            text: qsTr("导出")
                                            color: Theme.accent
                                            font.pixelSize: Theme.fontXS
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    HoverHandler { id: exportBtnHover2 }
                                    TapHandler {
                                        onTapped: {
                                            mainViewRoot.updateExportData()
                                            exportPopup.promptText = mainViewRoot.previewText
                                            exportPopup.cardListJson = mainViewRoot.cardListJson
                                            exportPopup.variablesJson = mainViewRoot.variablesJson
                                            exportPopup.projectJson = mainViewRoot.projectJson
                                            exportPopup.open()
                                        }
                                    }

                                    Behavior on color { enabled: !Theme.animReducedMotion; ColorAnimation { duration: Theme.animFast } }
                                }
                            }

                            // Preview text
                            ScrollView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true

                                TextArea {
                                    id: previewTextArea
                                    readOnly: false
                                    text: mainViewRoot.previewText
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
                    }

                    // Test tab
                    Rectangle {
                        color: Theme.surface

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 0

                            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.divider }

                            // Sub-tab bar (快速/批量/红队)
                            RowLayout {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 26
                                Layout.maximumHeight: 26
                                spacing: 0

                                Repeater {
                                    model: [
                                        { label: qsTr("快速"), icon: Icons.sparkle },
                                        { label: qsTr("批量"), icon: Icons.chart },
                                        { label: qsTr("红队"), icon: Icons.sparkle }
                                    ]
                                    delegate: Rectangle {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        color: mainViewRoot.testSubTab === index ? Theme.surface : Theme.surfaceVariant
                                        opacity: mainViewRoot.testSubTab === index ? 1 : 0.6

                                        RowLayout {
                                            anchors.centerIn: parent
                                            spacing: Theme.spacingXXS

                                            Text {
                                                text: modelData.icon
                                                font.pixelSize: Theme.fontXS
                                                font.family: Icons.fontFamily
                                            }
                                            Text {
                                                text: modelData.label
                                                color: mainViewRoot.testSubTab === index ? Theme.primary : Theme.onSurfaceVariant
                                                font.pixelSize: Theme.fontS
                                                font.weight: mainViewRoot.testSubTab === index ? Font.Bold : Font.Normal
                                            }
                                        }

                                        Rectangle {
                                            anchors.bottom: parent.bottom
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            width: 20
                                            height: 2
                                            radius: 1
                                            color: Theme.primary
                                            opacity: mainViewRoot.testSubTab === index ? 1 : 0
                                            Behavior on opacity { enabled: !Theme.animReducedMotion; NumberAnimation { duration: Theme.animFast } }
                                        }

                                        HoverHandler { id: subTabHover }
                                        TapHandler { onTapped: mainViewRoot.testSubTab = index }
                                    }
                                }
                            }

                            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.divider }

                            // Test content (fills remaining space)
                            StackLayout {
                                id: testSubTabStack
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                currentIndex: mainViewRoot.testSubTab

                                onCurrentIndexChanged: {
                                    var item = children[currentIndex]
                                    if (item) {
                                        item.opacity = 0
                                        fadeInTestSubTab.target = item
                                        fadeInTestSubTab.start()
                                    }
                                }

                                NumberAnimation {
                                    id: fadeInTestSubTab
                                    property: "opacity"
                                    from: 0; to: 1
                                    duration: Theme.animFast
                                    easing.type: Theme.animEasing
                                }

                                // Quick test
                                QuickTestPanel {
                                    promptText: mainViewRoot.previewText
                                    editedPreviewText: previewTextArea.text
                                }

                                // Batch test
                                BatchTestPanel {
                                    id: batchTestPanel
                                    promptText: mainViewRoot.previewText
                                }

                                // Red team test
                                RedTeamPanel {
                                    id: redTeamPanel
                                    promptText: mainViewRoot.previewText
                                }
                            }

                            // Export button (always visible at bottom of test tab)
                            RowLayout {
                                Layout.fillWidth: true
                                Layout.preferredHeight: Theme.heightMD
                                Layout.leftMargin: Theme.spacingSM
                                Layout.rightMargin: Theme.spacingSM
                                Layout.bottomMargin: Theme.spacingSM
                                spacing: Theme.spacingSM

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    Layout.rightMargin: Theme.spacingXS
                                    width: testExportBtnRow.width + Theme.spacingLG
                                    height: Theme.heightXS
                                    radius: Theme.radiusSM
                                    color: testExportBtnHover.hovered ? Theme.primaryMuted : "transparent"
                                    border.color: Theme.accent
                                    border.width: 1

                                    Row {
                                        id: testExportBtnRow
                                        anchors.centerIn: parent
                                        spacing: Theme.spacingXS

                                        Text {
                                            text: Icons.down
                                            font.pixelSize: Theme.fontS
                                            font.family: Icons.fontFamily
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                        Text {
                                            text: qsTr("导出")
                                            color: Theme.accent
                                            font.pixelSize: Theme.fontXS
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    HoverHandler { id: testExportBtnHover }
                                    TapHandler {
                                        onTapped: {
                                            mainViewRoot.updateExportData()
                                            exportPopup.promptText = mainViewRoot.previewText
                                            exportPopup.cardListJson = mainViewRoot.cardListJson
                                            exportPopup.variablesJson = mainViewRoot.variablesJson
                                            exportPopup.projectJson = mainViewRoot.projectJson
                                            exportPopup.open()
                                        }
                                    }

                                    Behavior on color { enabled: !Theme.animReducedMotion; ColorAnimation { duration: Theme.animFast } }
                                }
                            }
                        }
                    }

                    // Optimization tab (single-turn conversation optimization)
                    Rectangle {
                        color: Theme.surface
                        SingleTurnPanel {
                            anchors.fill: parent
                        }
                    }
                }
            }
        }
    }

    // ══════════════════════════════════════════════
    // FUNCTIONS
    // ══════════════════════════════════════════════

    function addModuleToCanvas(blockType) {
        pushUndoState()
        if (moduleCardModel) {
            moduleCardModel.addCard(blockType)
            // Scroll to the newly added card at the bottom
            Qt.callLater(function() {
                cardListView.positionViewAtEnd()
            })
        }
        previewUpdateTimer.start()
    }

    function removeModuleFromCanvas(bid) {
        pushUndoState()
        if (moduleCardModel) {
            moduleCardModel.removeCard(bid)
        }
        if (mainViewRoot.selectedCardId === bid) {
            mainViewRoot.selectedCardId = ""
        }
        previewUpdateTimer.start()
    }

    // Content change undo debounce timer
    Timer {
        id: contentUndoTimer
        interval: 800
        repeat: false
        onTriggered: pushUndoState()
    }

    function updateCardContent(bid, newContent) {
        if (moduleCardModel) {
            moduleCardModel.updateCardContent(bid, newContent)
        }
        previewUpdateTimer.start()
        contentUndoTimer.start()
        syntaxCheckTimer.start()
    }

    function moveCard(fromIdx, toIdx) {
        if (!moduleCardModel) return
        var count = moduleCardModel.rowCount()
        if (toIdx < 0 || toIdx >= count) return
        pushUndoState()
        moduleCardModel.moveCard(fromIdx, toIdx)
        previewUpdateTimer.start()
    }

    function computeTokenCount() {
        var total = 0
        if (!moduleCardModel) return 0
        var count = moduleCardModel.rowCount()
        for (var i = 0; i < count; i++) {
            var idx = moduleCardModel.index(i, 0)
            var c = moduleCardModel.data(idx, mainViewRoot._contentRole)
            if (c) total += Math.ceil(c.length / 4)
        }
        return total
    }

    function compilePreview() {
        var parts = []
        if (!moduleCardModel) return qsTr("暂无内容，请添加模块并编辑")
        var count = moduleCardModel.rowCount()
        for (var i = 0; i < count; i++) {
            var idx = moduleCardModel.index(i, 0)
            var content = moduleCardModel.data(idx, mainViewRoot._contentRole)
            if (content && content.trim().length > 0) {
                parts.push(content.trim())
            }
        }
        if (parts.length === 0) return qsTr("暂无内容，请添加模块并编辑")
        var result = parts.join("\n\n")
        // Replace {{varName}} with variableModel defaults
        var varRegex = /\{\{(\w+)\}\}/g
        result = result.replace(varRegex, function(match, name) {
            // Try variableModel for defaults
            if (variableModel) {
                var vCount = variableModel.rowCount()
                for (var j = 0; j < vCount; j++) {
                    var vIdx = variableModel.index(j, 0)
                    var vName = variableModel.data(vIdx, mainViewRoot._varNameRole)
                    if (vName === name) {
                        return variableModel.data(vIdx, mainViewRoot._varDefaultValueRole) || match
                    }
                }
            }
            return match  // Keep {{varName}} if no value found
        })
        return result
    }

    function generatePreviewText() {
        return mainViewRoot.previewText
    }

    function updateExportData() {
        if (!moduleCardModel) return
        var cards = []
        var vars = {}
        var count = moduleCardModel.rowCount()
        for (var i = 0; i < count; i++) {
            var idx = moduleCardModel.index(i, 0)
            var card = {
                "blockId": moduleCardModel.data(idx, 257),
                "blockType": moduleCardModel.data(idx, 258),
                "title": moduleCardModel.data(idx, 259),
                "content": moduleCardModel.data(idx, 260),
                "orderIndex": i
            }
            cards.push(card)
            // Extract variables from content
            var content = card.content || ""
            var regex = /\{\{(\w+)\}\}/g
            var match
            while ((match = regex.exec(content)) !== null) {
                vars[match[1]] = {"name": match[1], "var_type": "text", "default_value": "", "scope": "global"}
            }
        }
        mainViewRoot.cardListJson = JSON.stringify(cards)
        mainViewRoot.variablesJson = JSON.stringify(Object.values(vars))
        mainViewRoot.projectJson = JSON.stringify({
            "name": "PromptBlocks Project",
            "version": "1.0",
            "blocks": cards.map(function(card) {
                return {
                    "block_type": card.blockType,
                    "title": card.title,
                    "compiled_code": card.content,
                    "order_index": card.orderIndex
                }
            }),
            "variables": Object.values(vars)
        })
    }

    function getVariablesForTest() {
        // Build variable list: variableModel takes priority over card content extraction
        var varMap = {}

        // Step 1: Extract {{varName}} patterns from card contents (lower priority)
        if (moduleCardModel) {
            var count = moduleCardModel.rowCount()
            for (var i = 0; i < count; i++) {
                var idx = moduleCardModel.index(i, 0)
                var content = moduleCardModel.data(idx, 260) || ""  // ContentRole
                var regex = /\{\{(\w+)\}\}/g
                var match
                while ((match = regex.exec(content)) !== null) {
                    var varName = match[1]
                    if (!varMap[varName]) {
                        varMap[varName] = {
                            "name": varName,
                            "var_type": "text",
                            "default_value": "",
                            "scope": "global"
                        }
                    }
                }
            }
        }

        // Step 2: variableModel data OVERRIDES card-extracted data (higher priority)
        // This ensures user-set default values and types are preserved
        if (typeof variableModel !== "undefined" && variableModel) {
            try {
                var vmVars = variableModel.getVariables()
                for (var j = 0; j < vmVars.length; j++) {
                    var v = vmVars[j]
                    varMap[v.name] = {
                        "name": v.name,
                        "var_type": v.varType || "text",
                        "default_value": v.defaultValue || "",
                        "scope": v.scope || "global"
                    }
                }
            } catch (e) {
                // Ignore errors from variableModel
            }
        }

        return Object.values(varMap)
    }

    // Keyboard shortcuts
    Shortcut {
        sequence: "Ctrl+Z"
        onActivated: performUndo()
    }

    Shortcut {
        sequence: "Ctrl+Y"
        onActivated: performRedo()
    }

    // ViewModel connections (moduleCardModel is QAbstractListModel, no custom signals needed)

    // Import completed → refresh project list
    Connections {
        target: importViewModel

        function onImportCompleted(projectId) {
            // Refresh module card model with the new project
            if (moduleCardModel) {
                moduleCardModel.setProjectId(projectId)
                moduleCardModel.loadFromDb()
            }
            previewUpdateTimer.start()
        }
    }

    // Optimization completed → update popup data (popup is already open showing progress)
    Connections {
        target: promptOptimizer

        function onOptimizationCompleted(resultJson) {
            // Popup handles its own data via its own Connections.
            // Just update the project ID for the apply action.
            optimizationResultPopup.currentProjectId = moduleCardModel ? moduleCardModel.getProjectId() : ""
        }

        function onOptimizationError(message) {
            console.log("[MainView] Optimization error:", message)
            // Show a brief error notification
            errorNotification.text = message
            errorNotification._notificationVisible = true
            errorNotificationTimer.start()
        }
    }

    // Export popup
    ExportPanel {
        id: exportPopup
        anchors.centerIn: parent
    }

    // Import popup
    ImportPanel {
        id: importPopup
        anchors.centerIn: parent
    }

    // Optimization result popup
    OptimizationResultPopup {
        id: optimizationResultPopup
        anchors.centerIn: parent

        onRetryingRequested: {
            // Re-trigger optimization with the last parameters
            if (promptOptimizer && promptOptimizer.isOptimizing === false) {
                var projectId = moduleCardModel ? moduleCardModel.getProjectId() : ""
                var promptText = mainViewRoot.previewText
                // Get last test result from whichever panel is active
                var lastResult = ""
                if (batchTestPanel && batchTestPanel.lastResultJson) {
                    lastResult = batchTestPanel.lastResultJson
                } else if (quickTestPanel && quickTestPanel.lastResultJson) {
                    lastResult = quickTestPanel.lastResultJson
                } else if (redTeamPanel && redTeamPanel.lastResultJson) {
                    lastResult = redTeamPanel.lastResultJson
                }
                promptOptimizer.optimize(promptText, lastResult, projectId)
            }
        }
    }

    // Error notification toast
    Rectangle {
        id: errorNotification
        property alias text: errorNotificationText.text
        property bool _notificationVisible: false
        visible: _notificationVisible
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 20
        y: _notificationVisible ? 0 : -40
        opacity: _notificationVisible ? 1 : 0
        width: errorNotificationText.implicitWidth + 32
        height: errorNotificationText.implicitHeight + 16
        radius: 8
        color: Theme.error
        z: 9999

        Behavior on y { enabled: !Theme.animReducedMotion; NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasing } }
        Behavior on opacity { enabled: !Theme.animReducedMotion; NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }

        Text {
            id: errorNotificationText
            anchors.centerIn: parent
            color: Theme.onPrimary
            font.pixelSize: Theme.fontSM
            wrapMode: Text.Wrap
            maximumLineCount: 3
        }

        Timer {
            id: errorNotificationTimer
            interval: 4000
            onTriggered: errorNotification._notificationVisible = false
        }
    }

    // Version panel popup
    VersionPanel {
        id: versionPopup
        anchors.centerIn: parent
    }

    // Model config dialog
    ModelConfigDialog {
        id: modelConfigDialog
        anchors.centerIn: parent
    }

    // Initial preview
    Component.onCompleted: {
        // Load module types from Python (single source of truth)
        if (moduleCardModel) {
            mainViewRoot.moduleTypes = moduleCardModel.getModuleTypes()
        }
        previewUpdateTimer.start()
    }

    // Save split widths on destruction
    Component.onDestruction: {
        mainViewRoot.saveSplitWidths()
    }

    function saveSplitWidths() {
        if (appConfig) {
            appConfig.setValue("splitLeftWidth", leftSidebar.width)
            appConfig.setValue("splitRightWidth", rightPanel.width)
        }
    }
}
