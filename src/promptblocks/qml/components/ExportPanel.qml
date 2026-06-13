import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

Popup {
    id: exportPanel
    width: 320
    height: 420
    padding: Theme.spacingMD
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    property string promptText: ""
    property string cardListJson: ""
    property string variablesJson: ""
    property string projectJson: ""
    property int selectedFormat: 0
    property bool templateMode: true

    background: Rectangle {
        color: Theme.surface
        radius: Theme.radiusMD
        border.color: Theme.border
        border.width: 1
    }

    contentItem: ColumnLayout {
        spacing: Theme.spacingMD

        // Header
        Text {
            text: qsTr("导出提示词")
            color: Theme.onBackground
            font.pixelSize: Theme.fontLG
            font.bold: true
            font.family: Theme.fontFamily
        }

        // Format selection
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingXS

            Text {
                text: qsTr("导出格式")
                color: Theme.onSurface
                font.pixelSize: Theme.fontSM
                font.bold: true
                font.family: Theme.fontFamily
            }

            Repeater {
                model: [
                    { label: qsTr("直接复制"), icon: Icons.list },
                    { label: qsTr("Markdown (.md)"), icon: Icons.list },
                    { label: qsTr("纯文本 (.txt)"), icon: Icons.list },
                    { label: qsTr("JSON (.json)"), icon: "{ }" },
                    { label: qsTr("CSV变量表 (.csv)"), icon: Icons.chart },
                    { label: qsTr("工程文件 (.promptx)"), icon: Icons.folder }
                ]

                delegate: Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    radius: Theme.radiusSM
                    color: exportPanel.selectedFormat === index ? Theme.primaryMuted : "transparent"
                    border.color: exportPanel.selectedFormat === index ? Theme.primary : "transparent"
                    border.width: 1

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacingSM
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacingSM

                        Text {
                            text: modelData.icon
                            font.pixelSize: Theme.fontSM
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: modelData.label
                            color: exportPanel.selectedFormat === index ? Theme.primary : Theme.onSurface
                            font.pixelSize: Theme.fontSM
                            font.bold: exportPanel.selectedFormat === index
                            font.family: Theme.fontFamily
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    HoverHandler { id: fmtHover }
                    TapHandler { onTapped: exportPanel.selectedFormat = index }

                    Behavior on color { enabled: !Theme.animReducedMotion; ColorAnimation { duration: Theme.animFast } }
                }
            }
        }

        // Template mode toggle
        Rectangle {
            Layout.fillWidth: true
            height: Theme.heightSM
            radius: Theme.radiusSM
            color: Theme.surfaceVariant

            RowLayout {
                anchors.fill: parent
                anchors.margins: Theme.spacingXS
                spacing: 0

                Rectangle {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    radius: Theme.radiusSM
                    color: exportPanel.templateMode ? Theme.primary : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: qsTr("模板模式")
                        color: exportPanel.templateMode ? Theme.onPrimary : Theme.onSurfaceVariant
                        font.pixelSize: Theme.fontSM
                        font.bold: exportPanel.templateMode
                        font.family: Theme.fontFamily
                    }

                    HoverHandler { }
                    TapHandler { onTapped: exportPanel.templateMode = true }

                    Behavior on color { enabled: !Theme.animReducedMotion; ColorAnimation { duration: Theme.animFast } }
                }

                Rectangle {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    radius: Theme.radiusSM
                    color: !exportPanel.templateMode ? Theme.primary : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: qsTr("实例模式")
                        color: !exportPanel.templateMode ? Theme.onPrimary : Theme.onSurfaceVariant
                        font.pixelSize: Theme.fontSM
                        font.bold: !exportPanel.templateMode
                        font.family: Theme.fontFamily
                    }

                    HoverHandler { }
                    TapHandler { onTapped: exportPanel.templateMode = false }

                    Behavior on color { enabled: !Theme.animReducedMotion; ColorAnimation { duration: Theme.animFast } }
                }
            }
        }

        Item { Layout.fillHeight: true }

        // Export button
        Rectangle {
            Layout.fillWidth: true
            height: Theme.heightMD
            radius: Theme.radiusSM
            color: exportBtnHover.hovered ? Theme.primary : Theme.primaryMuted

            Text {
                anchors.centerIn: parent
                text: qsTr("导出")
                color: exportBtnHover.hovered ? Theme.onPrimary : Theme.primary
                font.pixelSize: Theme.fontMD
                font.bold: true
                font.family: Theme.fontFamily
            }

            HoverHandler { id: exportBtnHover }
            TapHandler {
                onTapped: {
                    switch (exportPanel.selectedFormat) {
                    case 0:
                        // Copy to clipboard directly
                        if (exportViewModel) {
                            exportViewModel.copyToClipboard(exportPanel.promptText)
                        }
                        exportStatusText.text = qsTr("已复制到剪贴板")
                        exportStatusToast.opacity = 1
                        exportStatusTimer.start()
                        break
                    case 1:
                        if (exportViewModel) {
                            var mdPath = exportViewModel.exportAsMarkdown(exportPanel.promptText, exportPanel.templateMode)
                            exportStatusText.text = mdPath ? qsTr("已导出: ") + mdPath : qsTr("导出取消")
                            exportStatusToast.opacity = 1
                            exportStatusTimer.start()
                        }
                        break
                    case 2:
                        if (exportViewModel) {
                            var txtPath = exportViewModel.exportAsTxt(exportPanel.promptText)
                            exportStatusText.text = txtPath ? qsTr("已导出: ") + txtPath : qsTr("导出取消")
                            exportStatusToast.opacity = 1
                            exportStatusTimer.start()
                        }
                        break
                    case 3:
                        if (exportViewModel) {
                            var jsonPath = exportViewModel.exportAsJson(exportPanel.cardListJson)
                            exportStatusText.text = jsonPath ? qsTr("已导出: ") + jsonPath : qsTr("导出取消")
                            exportStatusToast.opacity = 1
                            exportStatusTimer.start()
                        }
                        break
                    case 4:
                        if (exportViewModel) {
                            var csvPath = exportViewModel.exportAsCsv(exportPanel.variablesJson)
                            exportStatusText.text = csvPath ? qsTr("已导出: ") + csvPath : qsTr("导出取消")
                            exportStatusToast.opacity = 1
                            exportStatusTimer.start()
                        }
                        break
                    case 5:
                        if (exportViewModel) {
                            var pxPath = exportViewModel.exportAsPromptx(exportPanel.projectJson)
                            exportStatusText.text = pxPath ? qsTr("已导出: ") + pxPath : qsTr("导出取消")
                            exportStatusToast.opacity = 1
                            exportStatusTimer.start()
                        }
                        break
                    }
                    exportPanel.close()
                }
            }

            Behavior on color { enabled: !Theme.animReducedMotion; ColorAnimation { duration: Theme.animFast } }
        }
    }

    // Status toast (overlay)
    Rectangle {
        id: exportStatusToast
        x: (parent.width - width) / 2
        y: parent.height - height - 10
        width: exportStatusText.width + Theme.spacingLG
        height: Theme.heightXS
        radius: Theme.radiusSM
        color: Theme.surfaceRaised
        opacity: 0
        visible: opacity > 0

        Text {
            id: exportStatusText
            anchors.centerIn: parent
            color: Theme.onSurface
            font.pixelSize: Theme.fontXS
            font.family: Theme.fontFamily
        }

        Behavior on opacity { enabled: !Theme.animReducedMotion; NumberAnimation { duration: Theme.animFast } }
    }

    Timer {
        id: exportStatusTimer
        interval: 2000
        repeat: false
        onTriggered: exportStatusToast.opacity = 0
    }

    onOpened: exportStatusToast.opacity = 0
}
