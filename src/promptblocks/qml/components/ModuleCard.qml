import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

Rectangle {
    id: moduleCard

    property string blockId: ""
    property string blockType: "identity_role"
    property string title: "Module"
    property string content: ""
    property bool isExpanded: false
    property color typeColor: (Theme.moduleTypeColors[blockType] || {}).bg || Theme.primary
    property color typeTextColor: (Theme.moduleTypeColors[blockType] || {}).accent || Theme.onBackground
    property string typeIcon: Icons.person
    property string typeLabel: "ID"
    property int cardIndex: 0
    property var syntaxErrors: []

    // Dual-mode state: "ai" or "manual"
    property string editMode: "ai"

    // AI generation result
    property string aiGeneratedContent: ""

    // Hover state
    property bool _isHovered: false

    // AI generation loading state
    property bool _isGenerating: false

    // Flag to prevent circular updates between manualEditor.text and content
    property bool _syncingContent: false

    // Sync manualEditor.text when content changes from model side (e.g. undo/redo)
    onContentChanged: {
        if (!_syncingContent && manualEditor.text !== content) {
            _syncingContent = true
            manualEditor.text = content
            _syncingContent = false
        }
    }

    // Drag-reorder support
    property bool isDragging: cardDragHandler.active
    property int dragTargetIndex: -1

    signal deleteRequested(string blockId)
    signal moduleContentChanged(string blockId, string content)
    signal moveUpRequested(int fromIndex)
    signal moveDownRequested(int fromIndex)
    signal compileRequested(string blockId)
    signal dragMoveRequested(int fromIndex, int toIndex)

    // ── Drag insertion indicator (subtle thin line at target position) ──
    Rectangle {
        id: dropIndicator
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - 32
        height: 2
        radius: 1
        color: Theme.primary
        opacity: 0.55
        z: 200
        visible: isDragging && dragTargetIndex >= 0
        y: {
            if (!isDragging || dragTargetIndex < 0) return 0
            // Show indicator at the target position, above or below the current card
            var lv = moduleCard.ListView.view
            if (!lv) return 0
            var targetItem = lv.itemAtIndex(dragTargetIndex)
            if (!targetItem) return 0
            // If target is below current, show at bottom of target; if above, show at top
            if (dragTargetIndex > cardIndex)
                return mapFromItem(targetItem, 0, targetItem.height).y
            else
                return mapFromItem(targetItem, 0, 0).y - 2
        }

        Behavior on y { enabled: !Theme.animReducedMotion; NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }
        Behavior on opacity { enabled: !Theme.animReducedMotion; NumberAnimation { duration: Theme.animFast } }
    }

    width: parent ? parent.width : 400
    height: isExpanded ? implicitExpandedHeight : implicitCollapsedHeight

    readonly property int implicitCollapsedHeight: 52
    readonly property int implicitExpandedHeight: 280

    radius: Theme.radiusMD
    color: _isHovered ? Theme.cardHover : Theme.cardBackground
    border.color: dropArea.containsDrag ? Theme.primary : Theme.cardBorder
    border.width: dropArea.containsDrag ? 2 : 1

    HoverHandler { onHoveredChanged: moduleCard._isHovered = hovered }

    Behavior on color { enabled: !Theme.animReducedMotion; ColorAnimation { duration: Theme.animFast } }

    // Drag visual feedback
    scale: isDragging ? 1.04 : 1.0
    opacity: isDragging ? 0.8 : 1.0
    z: isDragging ? 100 : 0

    Behavior on height { enabled: !Theme.animReducedMotion; NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }
    Behavior on scale { enabled: !Theme.animReducedMotion; NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }
    Behavior on opacity { enabled: !Theme.animReducedMotion; NumberAnimation { duration: Theme.animFast } }
    Behavior on border.color { enabled: !Theme.animReducedMotion; ColorAnimation { duration: Theme.animFast } }
    Behavior on border.width { enabled: !Theme.animReducedMotion; NumberAnimation { duration: Theme.animFast } }

    // Drag handler on the header area for reordering
    DragHandler {
        id: cardDragHandler
        target: null  // We handle the move manually
        xAxis.enabled: false  // Only vertical drag
        yAxis.enabled: true
        dragThreshold: Qt.styleHints.startDragDistance

        onActiveChanged: {
            if (active) {
                // Drag started —mark this card
                moduleCard.ListView.view.currentIndex = moduleCard.cardIndex
                moduleCard.dragTargetIndex = -1
            } else {
                // Drag ended —perform the actual move
                if (moduleCard.dragTargetIndex >= 0 && moduleCard.dragTargetIndex !== moduleCard.cardIndex) {
                    moduleCard.dragMoveRequested(moduleCard.cardIndex, moduleCard.dragTargetIndex)
                }
                moduleCard.dragTargetIndex = -1
            }
        }

        onTranslationChanged: {
            if (active) {
                var listView = moduleCard.ListView.view
                if (!listView) return
                var newPos = moduleCard.y + translation.y
                // Determine target index at the center of the dragged card
                var newIdx = listView.indexAt(moduleCard.x + moduleCard.width / 2, newPos + moduleCard.height / 2)
                if (newIdx >= 0 && newIdx < listView.count) {
                    // Only preview, don't actually move yet
                    moduleCard.dragTargetIndex = newIdx
                }
            }
        }
    }

    // Drop area for receiving dragged cards
    DropArea {
        id: dropArea
        anchors.fill: parent
        keys: ["cardDrag"]

        onEntered: function(drag) {
            moduleCard.dragTargetIndex = moduleCard.cardIndex
        }
        onPositionChanged: function(drag) {
            moduleCard.dragTargetIndex = moduleCard.cardIndex
        }
        onExited: {
            // Keep the last known position
        }
        onDropped: function(drop) {
            drop.accept = true
        }
    }

    // Error left border indicator
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 3
        color: moduleCard.syntaxErrors.length > 0 ? Theme.error : "transparent"
        radius: 1

        Behavior on color { enabled: !Theme.animReducedMotion; ColorAnimation { duration: Theme.animFast } }
    }

    // Shadow effect (simulated)
    Rectangle {
        anchors.fill: parent
        anchors.margins: -1
        radius: parent.radius + 1
        color: "transparent"
        border.color: Theme.shadowColor
        border.width: 1
        z: -1
    }

    // Drag shadow effect
    Rectangle {
        anchors.fill: parent
        anchors.margins: -4
        radius: parent.radius + 2
        color: "transparent"
        border.color: Theme.shadowDrag
        border.width: isDragging ? 4 : 0
        z: -1
        visible: isDragging

        Behavior on border.width { enabled: !Theme.animReducedMotion; NumberAnimation { duration: Theme.animFast } }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Header bar ──
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.heightMD
            radius: Theme.radiusMD
            color: typeColor

            // Square off bottom corners
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: Theme.radiusMD
                color: typeColor
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.spacingSM
                anchors.rightMargin: Theme.spacingS
                spacing: Theme.spacingS

                // Drag handle grip
                Rectangle {
                    width: 16
                    height: 24
                    Layout.alignment: Qt.AlignVCenter
                    color: "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: Icons.dragHandle  // Vertical ellipsis (⋮) — universal drag-grip glyph
                        font.family: Icons.fontFamily
                        color: moduleCard.typeTextColor
                        opacity: 0.6
                        font.pixelSize: Theme.fontLG
                    }

                    HoverHandler {
                        cursorShape: Qt.OpenHandCursor
                    }

                    TapHandler {
                        onLongPressed: {
                            // Visual hint that drag is available
                        }
                    }
                }

                // Type badge
                Rectangle {
                    width: 32
                    height: 20
                    radius: 10
                    color: Qt.rgba(moduleCard.typeTextColor.r, moduleCard.typeTextColor.g, moduleCard.typeTextColor.b, 0.18)
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        anchors.centerIn: parent
                        text: moduleCard.typeLabel
                        color: moduleCard.typeTextColor
                        font.pixelSize: Theme.fontXS
                        font.bold: true
                        font.family: Theme.fontFamily
                    }
                }

                // Type icon
                Text {
                    text: moduleCard.typeIcon
                    font.pixelSize: Theme.fontMD
                    color: moduleCard.typeTextColor
                    opacity: 0.85
                    Layout.alignment: Qt.AlignVCenter
                }

                // Title
                Text {
                    text: moduleCard.title
                    color: moduleCard.typeTextColor
                    font.pixelSize: Theme.fontSM
                    font.bold: true
                    font.family: Theme.fontFamily
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                // Move up button — flat style
                IconButton {
                    icon: Icons.chevronUp
                    btnSize: 0
                    Layout.alignment: Qt.AlignVCenter
                    onClicked: moduleCard.moveUpRequested(moduleCard.cardIndex)
                }

                // Move down button — flat style
                IconButton {
                    icon: Icons.chevronDown
                    btnSize: 0
                    Layout.alignment: Qt.AlignVCenter
                    onClicked: moduleCard.moveDownRequested(moduleCard.cardIndex)
                }

                // Expand/collapse toggle — flat style
                IconButton {
                    icon: moduleCard.isExpanded ? Icons.chevronUp : Icons.chevronDown
                    btnSize: 0
                    Layout.alignment: Qt.AlignVCenter
                    onClicked: {
                        if (moduleCardModel) {
                            moduleCardModel.setExpanded(moduleCard.blockId, !moduleCard.isExpanded)
                        }
                    }
                }

                // Delete button — flat style
                IconButton {
                    icon: Icons.close
                    btnSize: 0
                    btnStyle: 2
                    Layout.alignment: Qt.AlignVCenter
                    onClicked: moduleCard.deleteRequested(moduleCard.blockId)
                }
            }
        }

        // ── Content area ──
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Theme.cardBackground
            radius: Theme.radiusMD

            // Collapsed preview
            Text {
                anchors.fill: parent
                anchors.margins: Theme.spacingMD
                visible: !moduleCard.isExpanded
                text: moduleCard.content.length > 0 ? moduleCard.content : qsTr("点击展开编辑内容...")
                color: moduleCard.content.length > 0 ? Theme.onSurface : Theme.onSurfaceVariant
                font.pixelSize: Theme.fontSM
                font.family: Theme.fontFamily
                elide: Text.ElideRight
                maximumLineCount: 2
                wrapMode: Text.WordWrap
                opacity: moduleCard.content.length > 0 ? 0.8 : 0.5
                verticalAlignment: Text.AlignVCenter
            }

            // Expanded dual-mode editor
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.spacingSM
                visible: moduleCard.isExpanded
                spacing: Theme.spacingSM

                // ── Mode toggle bar ──
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    radius: Theme.radiusSM
                    color: Theme.surfaceVariant

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.spacingXXS
                        spacing: 0

                        // AI mode button
                        Rectangle {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            radius: Theme.radiusSM
                            color: moduleCard.editMode === "ai" ? Theme.primary : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: qsTr("AI\u751F\u6210")
                                color: moduleCard.editMode === "ai" ? "#ffffff" : Theme.onSurfaceVariant
                                font.pixelSize: Theme.fontSM
                                font.bold: moduleCard.editMode === "ai"
                                font.family: Theme.fontFamily
                            }

                            HoverHandler { id: aiModeHover }
                            TapHandler {
                                onTapped: {
                                    if (moduleCardModel) {
                                        moduleCardModel.setEditMode(moduleCard.blockId, false)  // false = ai mode
                                    }
                                    if (typeof editorViewModel !== "undefined")
                                        editorViewModel.setMode("ai")
                                }
                            }

                            Behavior on color { enabled: !Theme.animReducedMotion; ColorAnimation { duration: Theme.animFast } }
                        }

                        // Manual mode button
                        Rectangle {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            radius: Theme.radiusSM
                            color: moduleCard.editMode === "manual" ? Theme.primary : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: qsTr("\u624B\u52A8\u7F16\u8F91")
                                color: moduleCard.editMode === "manual" ? "#ffffff" : Theme.onSurfaceVariant
                                font.pixelSize: Theme.fontSM
                                font.bold: moduleCard.editMode === "manual"
                                font.family: Theme.fontFamily
                            }

                            HoverHandler { id: manualModeHover }
                            TapHandler {
                                onTapped: {
                                    if (moduleCardModel) {
                                        moduleCardModel.setEditMode(moduleCard.blockId, true)  // true = manual mode
                                    }
                                    if (typeof editorViewModel !== "undefined")
                                        editorViewModel.setMode("manual")
                                }
                            }

                            Behavior on color { enabled: !Theme.animReducedMotion; ColorAnimation { duration: Theme.animFast } }
                        }
                    }
                }

                // ── AI Generation Mode ──
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: Theme.spacingSM
                    visible: moduleCard.editMode === "ai"
                    opacity: moduleCard.editMode === "ai" ? 1.0 : 0.0

                    Behavior on opacity { enabled: !Theme.animReducedMotion; NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasing } }

                    // AI prompt input row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacingSM

                        TextField {
                            id: aiPromptInput
                            Layout.fillWidth: true
                            placeholderText: qsTr("\u7528\u4E00\u53E5\u8BDD\u63CF\u8FF0\u4F60\u60F3\u8981\u7684\u63D0\u793A\u8BCD\u7247\u6BB5...")
                            font.pixelSize: Theme.fontSM
                            color: Theme.onBackground
                            font.family: Theme.fontFamily
                            background: Rectangle {
                                color: Theme.background
                                radius: Theme.radiusSM
                                border.color: aiPromptInput.activeFocus ? Theme.primary : Theme.border
                                border.width: 1
                            }
                        }

                        // Generate button
                        PBButton {
                            text: moduleCard._isGenerating ? qsTr("生成中...") : qsTr("生成")
                            btnStyle: 0
                            btnSize: 0  // sizeSm → 28px height, fontSM text
                            Layout.alignment: Qt.AlignVCenter
                            Layout.preferredHeight: Theme.heightXS
                            enabled: !moduleCard._isGenerating
                            onClicked: {
                                if (typeof editorViewModel !== "undefined") {
                                    moduleCard._isGenerating = true
                                    editorViewModel.generateFromAIForBlock(aiPromptInput.text, moduleCard.blockType, moduleCard.blockId)
                                }
                                moduleCard.compileRequested(moduleCard.blockId)
                            }
                        }
                    }

                    // AI generated content preview
                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        TextArea {
                            id: aiPreviewArea
                            text: moduleCard.aiGeneratedContent.length > 0
                                  ? moduleCard.aiGeneratedContent
                                  : qsTr("AI\u751F\u6210\u7684\u5185\u5BB9\u5C06\u663E\u793A\u5728\u8FD9\u91CC...")
                            color: moduleCard.aiGeneratedContent.length > 0 ? Theme.onBackground : Theme.onSurfaceVariant
                            font.pixelSize: Theme.fontSM
                            font.family: Theme.fontFamily
                            wrapMode: TextArea.WordWrap
                            readOnly: true
                            selectByMouse: true
                            background: Rectangle {
                                color: Theme.background
                                radius: Theme.radiusSM
                                border.color: Theme.border
                                border.width: 1
                            }
                        }
                    }

                    // Apply + 转到手动编辑 buttons
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Theme.heightXS
                        spacing: Theme.spacingSM
                        visible: moduleCard.aiGeneratedContent.length > 0

                        // Apply button
                        PBButton {
                            text: qsTr("\u5E94\u7528")
                            btnStyle: 0
                            btnSize: 0
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            onClicked: {
                                if (moduleCard.aiGeneratedContent.length > 0) {
                                    if (moduleCardModel) {
                                        moduleCardModel.updateCardContent(moduleCard.blockId, moduleCard.aiGeneratedContent)
                                    }
                                    moduleCard.moduleContentChanged(moduleCard.blockId, moduleCard.aiGeneratedContent)
                                }
                            }
                        }

                        // "转到手动编辑" button
                        PBButton {
                            text: qsTr("\u8F6C\u624B\u52A8\u7F16\u8F91")
                            btnStyle: 3
                            btnSize: 0
                            Layout.fillHeight: true
                            onClicked: {
                                if (moduleCard.aiGeneratedContent.length > 0) {
                                    // Copy AI content to manual editor
                                    manualEditor.text = moduleCard.aiGeneratedContent
                                    // Switch to manual mode
                                    if (moduleCardModel) {
                                        moduleCardModel.setEditMode(moduleCard.blockId, true)
                                    }
                                    if (typeof editorViewModel !== "undefined")
                                        editorViewModel.setMode("manual")
                                }
                            }
                        }
                    }
                }

                // ── Manual Edit Mode ──
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: Theme.spacingSM
                    visible: moduleCard.editMode === "manual"
                    opacity: moduleCard.editMode === "manual" ? 1.0 : 0.0

                    Behavior on opacity { enabled: !Theme.animReducedMotion; NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasing } }

                    // Editor toolbar
                    EditorToolbar {
                        Layout.fillWidth: true
                        onInsertRequested: function(snippet) {
                            manualEditor.insert(manualEditor.cursorPosition, snippet)
                            manualEditor.forceActiveFocus()
                        }
                        onPipelineRequested: {
                            pipelinePopup.previewInputText = moduleCard.content
                            pipelinePopup.open()
                        }
                    }

                    // Manual text editor
                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        TextArea {
                            id: manualEditor
                            text: moduleCard.content
                            color: Theme.onBackground
                            font.pixelSize: Theme.fontSM
                            font.family: Theme.fontFamily
                            wrapMode: TextArea.WordWrap
                            selectByMouse: true
                            background: Rectangle {
                                color: Theme.background
                                radius: Theme.radiusSM
                                border.color: manualEditor.activeFocus ? Theme.primary : Theme.border
                                border.width: 1
                            }
                            onTextChanged: {
                                if (!_syncingContent && text !== moduleCard.content) {
                                    moduleCard.moduleContentChanged(moduleCard.blockId, text)
                                }
                                // Detect {{ trigger for variable autocomplete
                                var pos = cursorPosition
                                if (pos >= 2 && text.substring(pos - 2, pos) === "{{") {
                                    autoCompletePopup._insertPos = pos
                                    autoCompletePopup._filterStart = pos
                                    autoCompletePopup.filterText = ""
                                    // Position popup below cursor
                                    var cursorRect = manualEditor.cursorRectangle
                                    autoCompletePopup.x = manualEditor.mapToItem(moduleCard, cursorRect.x, 0).x
                                    autoCompletePopup.y = manualEditor.mapToItem(moduleCard, 0, cursorRect.y + cursorRect.height).y + 4
                                    autoCompletePopup.targetEditor = manualEditor
                                    autoCompletePopup.open()
                                    autoCompletePopup.forceFilterFocus()
                                } else if (autoCompletePopup.opened && pos > autoCompletePopup._filterStart) {
                                    // Update filter text as user types after {{
                                    var filterText = text.substring(autoCompletePopup._filterStart, pos)
                                    autoCompletePopup.filterText = filterText
                                }
                            }

                            // Close popup on cursor movement away from trigger
                            onCursorPositionChanged: {
                                if (autoCompletePopup.opened) {
                                    var pos = cursorPosition
                                    // If cursor moved before the {{ or too far away, close
                                    if (pos < autoCompletePopup._filterStart - 2 || pos > autoCompletePopup._filterStart + 30) {
                                        autoCompletePopup.close()
                                    }
                                }
                            }

                            Keys.onEscapePressed: function(event) {
                                if (autoCompletePopup.opened) {
                                    autoCompletePopup.close()
                                    event.accepted = true
                                }
                            }
                        }
                    }
                }
            }
        }

        // Error summary bar (clickable to expand)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: errorList.visible ? Math.min(errorList.contentHeight + 32, 120) : 28
            radius: Theme.radiusSM
            color: Theme.errorContainer
            visible: moduleCard.syntaxErrors.length > 0
            clip: true

            Behavior on Layout.preferredHeight { enabled: !Theme.animReducedMotion; NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasing } }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.spacingS
                spacing: Theme.spacingXXS

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingXS

                    Text {
                        text: Icons.warning
                        color: Theme.error
                        font.pixelSize: Theme.fontXS
                        font.family: Icons.fontFamily
                    }

                    Badge {
                        text: moduleCard.syntaxErrors.length.toString()
                        badgeStyle: 3
                        badgeSize: 0
                    }

                    Text {
                        text: qsTr(" 个语法问题")
                        color: Theme.error
                        font.pixelSize: Theme.fontXS
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: errorList.visible ? Icons.chevronUp : Icons.chevronDown
                        font.pixelSize: Theme.fontXXS
                        font.family: Icons.fontFamily
                        color: Theme.error
                    }

                    TapHandler {
                        onTapped: errorList.visible = !errorList.visible
                    }
                }

                ListView {
                    id: errorList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: false
                    clip: true
                    model: moduleCard.syntaxErrors
                    delegate: Text {
                        width: errorList.width
                        text: "  " + Icons.bullet + " " + modelData.message
                        color: Theme.error
                        font.pixelSize: Theme.fontXS
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }

    // Pipeline editor popup
    PipelineEditor {
        id: pipelinePopup
        parent: ApplicationWindow.overlay
        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)
    }

    // Variable autocomplete popup
    Popup {
        id: autoCompletePopup
        property string filterText: ""
        property var targetEditor: null
        property int _insertPos: 0
        property int _filterStart: 0

        width: 220
        height: Math.min(varListView.contentHeight + searchField.height + 24, 200)
        padding: 4
        modal: false
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: Theme.surface
            radius: Theme.radiusMD
            border.color: Theme.border
            border.width: 1

            Rectangle {
                anchors.fill: parent
                anchors.margins: -2
                radius: parent.radius + 2
                color: "transparent"
                border.color: Theme.shadowColor
                border.width: 2
                z: -1
            }
        }

        contentItem: ColumnLayout {
            spacing: Theme.spacingXXS

                TextField {
                    id: searchField
                    Layout.fillWidth: true
                    Layout.topMargin: Theme.spacingXS
                    Layout.leftMargin: Theme.spacingXS
                    Layout.rightMargin: Theme.spacingXS
                    Layout.preferredHeight: Theme.heightXS
                placeholderText: qsTr("搜索变量...")
                font.pixelSize: Theme.fontSM
                color: Theme.onBackground
                text: autoCompletePopup.filterText
                onTextChanged: autoCompletePopup.filterText = text

                background: Rectangle {
                    color: Theme.background
                    radius: Theme.radiusSM
                    border.color: searchField.activeFocus ? Theme.primary : Theme.border
                    border.width: 1
                }

                Keys.onEscapePressed: function(event) {
                    autoCompletePopup.close()
                    event.accepted = true
                }

                onAccepted: {
                    // Insert first matching variable if available
                    var vars = autoCompletePopup.getFilteredVariables()
                    if (vars.length > 0) {
                        autoCompletePopup.insertVariable(vars[0].name)
                    }
                }
            }

            ListView {
                id: varListView
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: Theme.spacingXS
                clip: true
                spacing: Theme.spacingXXS

                model: autoCompletePopup.getFilteredVariables()
                delegate: Rectangle {
                    width: varListView.width - 8
                    height: 30
                    radius: Theme.radiusSM
                    color: itemHover.hovered ? Theme.primaryMuted : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.spacingSM
                        anchors.rightMargin: Theme.spacingSM
                        spacing: Theme.spacingS

                        Text {
                            text: modelData.var_type === "text" ? Icons.edit :
                                  modelData.var_type === "number" ? Icons.tag :
                                  modelData.var_type === "list" ? Icons.clipboard :
                                  modelData.var_type === "boolean" ? Icons.accept : Icons.edit
                            font.pixelSize: Theme.fontS
                            font.family: Icons.fontFamily
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Text {
                            text: modelData.name
                            color: Theme.onBackground
                            font.pixelSize: Theme.fontSM
                            font.family: Theme.codeFontFamily
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: modelData.var_type
                            color: Theme.onSurfaceVariant
                            font.pixelSize: Theme.fontXS
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }

                    HoverHandler { id: itemHover }
                    TapHandler {
                        onTapped: {
                            autoCompletePopup.insertVariable(modelData.name)
                            autoCompletePopup.close()
                        }
                    }
                }
            }
        }

        function forceFilterFocus() {
            searchField.forceActiveFocus()
        }

        function getFilteredVariables() {
            var result = []
            var filter = autoCompletePopup.filterText.toLowerCase()

            // Only get variables from VariableModel (the single source of truth)
            // Variables from card content are NOT valid - card content is just text, not variable definitions
            if (typeof variableModel !== "undefined" && variableModel) {
                var count = variableModel.rowCount()
                for (var i = 0; i < count; i++) {
                    var name = variableModel.data(variableModel.index(i, 0), 257)  // NameRole
                    var varType = variableModel.data(variableModel.index(i, 0), 258) || "text"  // VarTypeRole
                    if (name && (filter === "" || name.toLowerCase().indexOf(filter) >= 0)) {
                        result.push({"name": name, "var_type": varType})
                    }
                }
            }

            return result
        }

        function insertVariable(varName) {
            if (!autoCompletePopup.targetEditor) return
            var editor = autoCompletePopup.targetEditor
            var curText = editor.text
            var filterStart = autoCompletePopup._filterStart
            var insertPos = autoCompletePopup._insertPos

            // Replace from {{ to current cursor with {{varName}}
            var beforeTrigger = curText.substring(0, filterStart - 2)  // text before {{
            var afterCursor = curText.substring(insertPos)  // text after cursor
            editor.text = beforeTrigger + "{{" + varName + "}}" + afterCursor
            editor.cursorPosition = beforeTrigger.length + varName.length + 4
            editor.forceActiveFocus()
        }
    }

    // Listen for AI generation completion to update aiGeneratedContent
    Connections {
        target: typeof editorViewModel !== "undefined" ? editorViewModel : null
        function onAiGenerationCompleted() {
            // Only update if this card initiated the generation
            if (typeof editorViewModel !== "undefined"
                && editorViewModel.currentBlockId === moduleCard.blockId
                && editorViewModel.currentContent.length > 0) {
                moduleCard.aiGeneratedContent = editorViewModel.currentContent
            }
            if (typeof editorViewModel !== "undefined"
                && editorViewModel.currentBlockId === moduleCard.blockId) {
                moduleCard._isGenerating = false
            }
        }
    }
}
