import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

Popup {
    id: importPanel
    width: 380
    height: 480
    padding: Theme.spacingMD
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    property string selectedFile: ""
    property bool isValidated: false
    property bool isImporting: false
    property string validationName: ""
    property int validationBlockCount: 0
    property int validationVariableCount: 0

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
                text: qsTr("导入工程")
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
                color: closeHover.hovered ? Theme.surfaceRaised : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: Icons.close
                    color: Theme.onSurfaceVariant
                    font.pixelSize: Theme.fontMD
                }

                HoverHandler { id: closeHover }
                TapHandler { onTapped: importPanel.close() }
            }
        }

        // File selection area
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingXS

            Text {
                text: qsTr("选择文件")
                color: Theme.onSurface
                font.pixelSize: Theme.fontSM
                font.bold: true
                font.family: Theme.fontFamily
            }

            Rectangle {
                Layout.fillWidth: true
                height: Theme.heightMD
                radius: Theme.radiusSM
                color: Theme.background
                border.color: fileHover.hovered ? Theme.primary : Theme.border
                border.width: 1

                Text {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingSM
                    text: importPanel.selectedFile.length > 0
                          ? importPanel.selectedFile
                          : qsTr("点击选择 .promptx 文件")
                    color: importPanel.selectedFile.length > 0 ? Theme.onBackground : Theme.onSurfaceVariant
                    font.pixelSize: Theme.fontSM
                    font.family: Theme.fontFamily
                    elide: Text.ElideMiddle
                    verticalAlignment: Text.AlignVCenter
                }

                HoverHandler { id: fileHover }
                TapHandler {
                    onTapped: {
                        if (importViewModel) {
                            importViewModel.selectFile()
                        }
                    }
                }
            }
        }

        // Preview area (visible after validation)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingXS
            visible: importPanel.isValidated

            Text {
                text: qsTr("验证结果")
                color: Theme.onBackground
                font.pixelSize: Theme.fontSM
                font.bold: true
                font.family: Theme.fontFamily
            }

            Rectangle {
                Layout.fillWidth: true
                height: previewCol.implicitHeight + Theme.spacingMD * 2
                radius: Theme.radiusSM
                color: Theme.successContainer
                border.color: Theme.secondary
                border.width: 1

                ColumnLayout {
                    id: previewCol
                    anchors.fill: parent
                    anchors.margins: Theme.spacingSM
                    spacing: Theme.spacingXS

                    RowLayout {
                        spacing: Theme.spacingSM
                        Text {
                            text: qsTr("项目名称:")
                            color: Theme.onSurface
                            font.pixelSize: Theme.fontXS
                        }
                        Text {
                            text: importPanel.validationName
                            color: Theme.secondary
                            font.pixelSize: Theme.fontXS
                            font.bold: true
                        }
                    }

                    RowLayout {
                        spacing: Theme.spacingSM
                        Text {
                            text: qsTr("模块数量:")
                            color: Theme.onSurface
                            font.pixelSize: Theme.fontXS
                        }
                        Text {
                            text: importPanel.validationBlockCount.toString()
                            color: Theme.secondary
                            font.pixelSize: Theme.fontXS
                            font.bold: true
                        }
                    }

                    RowLayout {
                        spacing: Theme.spacingSM
                        Text {
                            text: qsTr("变量数量:")
                            color: Theme.onSurface
                            font.pixelSize: Theme.fontXS
                        }
                        Text {
                            text: importPanel.validationVariableCount.toString()
                            color: Theme.secondary
                            font.pixelSize: Theme.fontXS
                            font.bold: true
                        }
                    }
                }
            }
        }

        // Error message area
        Rectangle {
            Layout.fillWidth: true
            height: errorMsg.text.length > 0 ? errorMsg.implicitHeight + 12 : 0
            radius: Theme.radiusSM
            color: Theme.errorContainer
            border.color: Theme.error
            border.width: 1
            visible: errorMsg.text.length > 0
            clip: true

            Text {
                id: errorMsg
                width: parent.width - Theme.spacingSM * 2
                x: Theme.spacingSM
                y: Theme.spacingSM / 2
                text: ""
                color: Theme.error
                font.pixelSize: Theme.fontXS
                font.family: Theme.fontFamily
                wrapMode: Text.WordWrap
            }
        }

        // Loading indicator
        Row {
            Layout.fillWidth: true
            visible: importPanel.isImporting
            spacing: Theme.spacingS

            Text {
                text: Icons.hourglass
                font.pixelSize: Theme.fontSM
                anchors.verticalCenter: parent.verticalCenter

                SequentialAnimation on opacity {
                    running: importPanel.isImporting
                    loops: Animation.Infinite
                    NumberAnimation { from: 1.0; to: 0.3; duration: Theme.animSlow }
                    NumberAnimation { from: 0.3; to: 1.0; duration: Theme.animSlow }
                }
            }
            Text {
                text: qsTr("正在导入，请稍候...")
                color: Theme.primary
                font.pixelSize: Theme.fontXS
                anchors.verticalCenter: parent.verticalCenter
                opacity: 0.7
            }
        }

        Item { Layout.fillHeight: true }

        // Action buttons
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingSM

            // Validate button
            Rectangle {
                Layout.fillWidth: true
                height: Theme.heightSM
                radius: Theme.radiusSM
                color: validateBtnHover.hovered ? Theme.accentMuted : "transparent"
                border.color: Theme.accent
                border.width: 1
                opacity: importPanel.selectedFile.length > 0 && !importPanel.isImporting ? 1 : 0.4

                Text {
                    anchors.centerIn: parent
                    text: Icons.accept + " " + qsTr("验证")
                    color: Theme.accent
                    font.pixelSize: Theme.fontSM
                    font.bold: true
                    font.family: Theme.fontFamily
                }

                HoverHandler { id: validateBtnHover }
                TapHandler {
                    onTapped: {
                        if (importViewModel && importPanel.selectedFile.length > 0) {
                            importViewModel.validatePromptxFile(importPanel.selectedFile)
                        }
                    }
                }

                Behavior on color { enabled: !Theme.animReducedMotion; ColorAnimation { duration: Theme.animFast } }
            }

            // Import button
            Rectangle {
                Layout.fillWidth: true
                height: Theme.heightSM
                radius: Theme.radiusSM
                color: importBtnHover.hovered ? Qt.darker(Theme.primary, 1.1) : Theme.primary
                opacity: importPanel.isValidated && !importPanel.isImporting ? 1 : 0.4

                Text {
                    anchors.centerIn: parent
                    text: qsTr("导入")
                    color: Theme.onPrimary
                    font.pixelSize: Theme.fontSM
                    font.bold: true
                    font.family: Theme.fontFamily
                }

                HoverHandler { id: importBtnHover }
                TapHandler {
                    onTapped: {
                        if (importPanel.isValidated && importPanel.selectedFile.length > 0 && !importPanel.isImporting) {
                            importPanel.isImporting = true
                            errorMsg.text = ""
                            importViewModel.importFromPromptx(importPanel.selectedFile)
                        }
                    }
                }

                Behavior on color { enabled: !Theme.animReducedMotion; ColorAnimation { duration: Theme.animFast } }
            }
        }
    }

    // Connections to importViewModel
    Connections {
        target: importViewModel

        function onSelectedFileChanged(path) {
            importPanel.selectedFile = path
            importPanel.isValidated = false
            errorMsg.text = ""
        }

        function onValidationCompleted(resultJson) {
            try {
                var result = JSON.parse(resultJson)
                if (result.valid) {
                    importPanel.validationName = result.name || ""
                    importPanel.validationBlockCount = result.blockCount || 0
                    importPanel.validationVariableCount = result.variableCount || 0
                    importPanel.isValidated = true
                    errorMsg.text = ""
                } else {
                    importPanel.isValidated = false
                    errorMsg.text = (result.errors || []).join("\n")
                }
            } catch (e) {
                importPanel.isValidated = false
                errorMsg.text = qsTr("解析验证结果失败")
            }
        }

        function onImportCompleted(projectId) {
            importPanel.isImporting = false
            importPanel.close()
        }

        function onImportError(message) {
            importPanel.isImporting = false
            errorMsg.text = message
        }
    }

    onClosed: {
        importPanel.selectedFile = ""
        importPanel.isValidated = false
        importPanel.isImporting = false
        importPanel.validationName = ""
        importPanel.validationBlockCount = 0
        importPanel.validationVariableCount = 0
        errorMsg.text = ""
    }
}
