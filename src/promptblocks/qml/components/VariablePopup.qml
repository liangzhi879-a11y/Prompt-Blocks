import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

Popup {
    id: variablePopup

    property string filterText: ""
    property var targetEditor: null

    width: 240
    height: Math.min(variableListView.contentHeight + searchField.height + searchField.anchors.topMargin + columnLayout.spacing + 16, 200)
    padding: 4

    modal: false
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    background: Rectangle {
        color: Theme.surface
        radius: Theme.radiusMD
        border.color: Theme.border
        border.width: 1

        // Shadow simulation
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
        id: columnLayout
        spacing: Theme.spacingXS

        TextField {
            id: searchField
            Layout.fillWidth: true
            Layout.topMargin: 4
            Layout.leftMargin: 4
            Layout.rightMargin: 4
            Layout.preferredHeight: Theme.heightXS
            placeholderText: qsTr("搜索变量...")
            font.pixelSize: Theme.fontSM
            color: Theme.onBackground
            text: variablePopup.filterText
            onTextChanged: variablePopup.filterText = text

            background: Rectangle {
                color: Theme.background
                radius: Theme.radiusSM
                border.color: searchField.activeFocus ? Theme.primary : Theme.border
                border.width: 1
            }
        }

        ListView {
            id: variableListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 4
            clip: true
            spacing: Theme.spacingXXS

            model: variablePopup.getFilteredModel()
            delegate: Rectangle {
                width: variableListView.width - 8
                height: 32
                radius: Theme.radiusSM
                color: itemHover.hovered ? Theme.primaryMuted : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: Theme.spacingS

                    // Type icon
                    Text {
                        text: modelData.var_type === "text" ? Icons.edit :
                              modelData.var_type === "number" ? Icons.tag :
                              modelData.var_type === "list" ? Icons.list :
                              modelData.var_type === "boolean" ? "\u{2714}" : Icons.edit
                        font.pixelSize: Theme.fontSM
                        Layout.alignment: Qt.AlignVCenter
                    }

                    // Variable name
                    Text {
                        text: modelData.name
                        color: Theme.onBackground
                        font.pixelSize: Theme.fontSM
                        font.family: Theme.codeFontFamily
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    // Scope badge
                    Rectangle {
                        width: scopeText.implicitWidth + 10
                        height: 18
                        radius: 9
                        color: modelData.scope === "global" ? Theme.primaryMuted :
                               modelData.scope === "project" ? Theme.accentMuted : Theme.surfaceVariant

                        Text {
                            id: scopeText
                            anchors.centerIn: parent
                            text: modelData.scope === "global" ? qsTr("全局") :
                                  modelData.scope === "project" ? qsTr("项目") : qsTr("局部")
                            color: Theme.onSurfaceVariant
                            font.pixelSize: Theme.fontXS
                        }
                    }
                }

                HoverHandler { id: itemHover }
                TapHandler {
                    onTapped: {
                        variablePopup.insertVariable(modelData.name)
                        variablePopup.close()
                    }
                }
            }
        }
    }

    // Static demo variables for now
    ListModel {
        id: staticVariableModel
        ListElement { name: "role"; var_type: "text"; scope: "global" }
        ListElement { name: "task"; var_type: "text"; scope: "global" }
        ListElement { name: "language"; var_type: "text"; scope: "project" }
        ListElement { name: "max_tokens"; var_type: "number"; scope: "global" }
        ListElement { name: "temperature"; var_type: "number"; scope: "project" }
        ListElement { name: "output_format"; var_type: "text"; scope: "local" }
        ListElement { name: "examples"; var_type: "list"; scope: "global" }
        ListElement { name: "verbose"; var_type: "boolean"; scope: "project" }
    }

    function getFilteredModel() {
        var result = []
        var filter = variablePopup.filterText.toLowerCase()
        for (var i = 0; i < staticVariableModel.count; i++) {
            var item = staticVariableModel.get(i)
            if (filter === "" || item.name.toLowerCase().indexOf(filter) >= 0) {
                result.push({
                    "name": item.name,
                    "var_type": item.var_type,
                    "scope": item.scope
                })
            }
        }
        return result
    }

    function insertVariable(varName) {
        if (variablePopup.targetEditor) {
            var editor = variablePopup.targetEditor
            var curText = editor.text
            var cursorPos = editor.cursorPosition

            // Find the opening {{ before cursor
            var beforeCursor = curText.substring(0, cursorPos)
            var afterCursor = curText.substring(cursorPos)
            var openIdx = beforeCursor.lastIndexOf("{{")
            if (openIdx >= 0) {
                // Replace from {{ to cursor with {{varName}}
                editor.text = curText.substring(0, openIdx) + "{{" + varName + "}}" + afterCursor
                editor.cursorPosition = openIdx + varName.length + 4
            } else {
                // Just insert at cursor
                var insertText = "{{" + varName + "}}"
                editor.text = beforeCursor + insertText + afterCursor
                editor.cursorPosition = cursorPos + insertText.length
            }
        }
    }
}
