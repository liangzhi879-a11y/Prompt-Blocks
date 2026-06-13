import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

// Dialog for managing variable presets (saved via QSettings)
Dialog {
    id: presetDialog
    title: qsTr("变量预设管理")
    modal: true
    width: 320
    height: 380

    property var currentValues: ({})
    signal loadPreset(var values)

    anchors.centerIn: parent

    background: Rectangle {
        color: Theme.surface
        radius: Theme.radiusMD
        border.color: Theme.border
        border.width: 1
    }

    header: Rectangle {
        height: Theme.heightLG
        color: Theme.surfaceVariant
        radius: Theme.radiusMD

        // Square off bottom corners
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: Theme.radiusMD
            color: Theme.surfaceVariant
        }

        Text {
            anchors.centerIn: parent
            text: Icons.square + " " + qsTr("变量预设管理")
            color: Theme.onBackground
            font.pixelSize: Theme.fontMD
            font.weight: Font.DemiBold
        }
    }

    contentItem: ColumnLayout {
        spacing: Theme.spacingSM

        // Preset name input for saving
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingSM

            TextField {
                id: presetNameField
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                placeholderText: qsTr("输入预设名称...")
                color: Theme.onBackground
                font.pixelSize: Theme.fontSM

                background: Rectangle {
                    color: Theme.background
                    radius: Theme.radiusSM
                    border.color: presetNameField.activeFocus ? Theme.primary : Theme.border
                    border.width: 1
                }
            }

            Rectangle {
                width: saveBtnText.width + 16
                height: 32
                radius: Theme.radiusSM
                color: saveBtnHover.hovered ? Theme.primary : Theme.primaryMuted
                border.color: Theme.primary
                border.width: 1

                Text {
                    id: saveBtnText
                    anchors.centerIn: parent
                    text: qsTr("保存当前")
                    color: saveBtnHover.hovered ? Theme.onPrimary : Theme.primary
                    font.pixelSize: Theme.fontXS
                    font.bold: true
                }

                HoverHandler { id: saveBtnHover }
                TapHandler {
                    onTapped: saveCurrentPreset()
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.divider }

        // Preset list
        ListView {
            id: presetListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: Theme.spacingXS

            model: presetListModel
            delegate: Rectangle {
                width: presetListView.width
                height: Theme.heightMD
                radius: Theme.radiusSM
                color: itemHover.hovered ? Theme.primaryMuted : Theme.background
                border.color: Theme.border
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spacingSM
                    anchors.rightMargin: Theme.spacingSM
                    spacing: Theme.spacingSM

                    Text {
                        text: Icons.folder
                        font.pixelSize: Theme.fontMD
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        text: model.name
                        color: Theme.onBackground
                        font.pixelSize: Theme.fontSM
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    // Load button
                    Rectangle {
                        width: loadText.width + 10
                        height: 24
                        radius: Theme.radiusSM
                        color: loadItemHover.hovered ? Theme.secondary : "transparent"
                        border.color: Theme.secondary
                        border.width: 1

                        Text {
                            id: loadText
                            anchors.centerIn: parent
                            text: qsTr("加载")
                            color: loadItemHover.hovered ? Theme.onPrimary : Theme.secondary
                            font.pixelSize: Theme.fontXS
                        }

                        HoverHandler { id: loadItemHover }
                        TapHandler {
                            onTapped: {
                                var values = JSON.parse(model.values)
                                presetDialog.loadPreset(values)
                                presetDialog.close()
                            }
                        }
                    }

                    // Delete button
                    Rectangle {
                        width: delText.width + 10
                        height: 24
                        radius: Theme.radiusSM
                        color: delItemHover.hovered ? Theme.error : "transparent"
                        border.color: Theme.error
                        border.width: 1

                        Text {
                            id: delText
                            anchors.centerIn: parent
                            text: qsTr("删除")
                            color: delItemHover.hovered ? Theme.onPrimary : Theme.error
                            font.pixelSize: Theme.fontXS
                        }

                        HoverHandler { id: delItemHover }
                        TapHandler {
                            onTapped: deletePreset(model.name)
                        }
                    }
                }

                HoverHandler { id: itemHover }
            }

            // Empty state
            Text {
                visible: presetListModel.count === 0
                anchors.centerIn: parent
                text: qsTr("暂无保存的预设")
                color: Theme.onSurfaceVariant
                font.pixelSize: Theme.fontSM
                opacity: 0.6
            }
        }
    }

    footer: Rectangle {
        height: 48
        color: Theme.surfaceVariant

        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 1
            color: Theme.surfaceVariant
            radius: Theme.radiusMD

            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: Theme.divider
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: Theme.spacingSM
                spacing: Theme.spacingSM

                Item { Layout.fillWidth: true }

                Rectangle {
                    width: closeText.width + 20
                    height: 30
                    radius: Theme.radiusSM
                    color: closeHover.hovered ? Theme.surfaceRaised : "transparent"
                    border.color: Theme.border
                    border.width: 1

                    Text {
                        id: closeText
                        anchors.centerIn: parent
                        text: qsTr("关闭")
                        color: Theme.onSurface
                        font.pixelSize: Theme.fontSM
                    }

                    HoverHandler { id: closeHover }
                    TapHandler {
                        onTapped: presetDialog.close()
                    }
                }
            }
        }
    }

    // Internal model for presets
    ListModel {
        id: presetListModel
    }

    // Use a simple JS object as storage (simulating QSettings)
    // In production, this would use Qt.labs.settings or QSettings via Python
    property var _storage: ({})

    Component.onCompleted: {
        loadPresetsFromStorage()
    }

    function loadPresetsFromStorage() {
        presetListModel.clear()
        try {
            var stored = Qt.application ? Qt.application.name : ""
            // Simple localStorage simulation using a JavaScript object
            // In real app, use QSettings from Python side
            var keys = Object.keys(presetDialog._storage)
            for (var i = 0; i < keys.length; i++) {
                var name = keys[i]
                presetListModel.append({
                    "name": name,
                    "values": presetDialog._storage[name]
                })
            }
        } catch (e) {
            console.log("[VariablePresetDialog] Failed to load presets:", e)
        }
    }

    function saveCurrentPreset() {
        var name = presetNameField.text.trim()
        if (name.length === 0) {
            name = qsTr("预设_") + new Date().toLocaleTimeString()
        }
        var valuesStr = JSON.stringify(presetDialog.currentValues)
        presetDialog._storage[name] = valuesStr

        presetNameField.text = ""
        loadPresetsFromStorage()
    }

    function deletePreset(name) {
        delete presetDialog._storage[name]
        loadPresetsFromStorage()
    }
}
