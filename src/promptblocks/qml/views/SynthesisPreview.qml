import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

Rectangle {
    id: synthesisRoot
    color: Theme.surface

    property string synthesisResult: ""
    property string currentProjectId: ""
    property string _copyBtnText: qsTr("复制")

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingSM
        spacing: Theme.spacingXS

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingSM

            Text {
                text: qsTr("Synthesis Preview")
                color: Theme.onBackground
                font.pixelSize: Theme.fontMD
                font.bold: true
            }

            Item { Layout.fillWidth: true }

            // Backend selector
            ComboBox {
                id: backendCombo
                model: ["guidance", "plain_text"]
                displayText: qsTr("Backend: %1").arg(currentText)
                implicitWidth: 180

                background: Rectangle {
                    color: Theme.background
                    radius: Theme.radiusSM
                    border.color: Theme.border
                }
                contentItem: Text {
                    text: backendCombo.displayText
                    color: Theme.onBackground
                    font.pixelSize: Theme.fontSM
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: Theme.spacingSM
                }
                delegate: ItemDelegate {
                    width: backendCombo.width
                    contentItem: Text {
                        text: modelData
                        color: Theme.onBackground
                        font.pixelSize: Theme.fontSM
                    }
                    background: Rectangle {
                        color: highlighted ? Theme.primaryContainer : Theme.background
                    }
                    highlighted: backendCombo.highlightedIndex === index
                }
            }

            // Synthesize button
            Button {
                text: qsTr("Synthesize")
                onClicked: {
                    if (projectViewModel && synthesisRoot.currentProjectId) {
                        projectViewModel.synthesizeProject(synthesisRoot.currentProjectId, backendCombo.currentText)
                    }
                }
                background: Rectangle {
                    color: parent.pressed ? Theme.primaryContainer : Theme.primary
                    radius: Theme.radiusSM
                }
                contentItem: Text {
                    text: parent.text
                    color: Theme.onPrimary
                    font.pixelSize: Theme.fontSM
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            // Copy button
            Button {
                text: synthesisRoot._copyBtnText
                onClicked: {
                    if (promptArea.text) {
                        copyText.text = promptArea.text
                        copyText.selectAll()
                        copyText.copy()
                        synthesisRoot._copyBtnText = qsTr("已复制")
                        copyResetTimer.start()
                    }
                }
                background: Rectangle {
                    color: parent.pressed ? Theme.surfaceVariant : Theme.secondary
                    radius: Theme.radiusSM
                }
                contentItem: Text {
                    text: parent.text
                    color: Theme.onPrimary
                    font.pixelSize: Theme.fontSM
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        // Warnings
        Column {
            Layout.fillWidth: true
            visible: warningModel.count > 0
            spacing: Theme.spacingXXS

            Repeater {
                model: ListModel { id: warningModel }

                Rectangle {
                    width: synthesisRoot.width - 16
                    height: warningText.implicitHeight + 8
                    color: Theme.warningContainer
                    radius: Theme.radiusSM

                    Text {
                        id: warningText
                        anchors.fill: parent
                        anchors.margins: Theme.spacingXS
                        text: Icons.warning + " " + model.warning
                        color: Theme.warning
                        font.pixelSize: Theme.fontSM
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }

        // Error display
        Rectangle {
            Layout.fillWidth: true
            height: errorText.implicitHeight + 12
            visible: errorText.text !== ""
            color: Theme.errorContainer
            radius: Theme.radiusSM

            Text {
                id: errorText
                anchors.fill: parent
                anchors.margins: Theme.spacingXS
                text: ""
                color: Theme.error
                font.pixelSize: Theme.fontSM
                wrapMode: Text.WordWrap
            }
        }

        // Prompt preview
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 100

            TextArea {
                id: promptArea
                readOnly: true
                color: Theme.secondary
                font.pixelSize: Theme.fontSM
                font.family: Theme.codeFontFamily
                wrapMode: TextArea.WordWrap
                placeholderText: qsTr("Click 'Synthesize' to generate prompt...")
                placeholderTextColor: Theme.onSurfaceVariant
                text: ""
                background: Rectangle {
                    color: Theme.codeBackground
                    radius: Theme.radiusSM
                }
            }
        }

        // Block contributions (collapsible)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingXXS

            Row {
                spacing: Theme.spacingXS

                Text {
                    text: qsTr("Block Contributions")
                    color: Theme.onSurface
                    font.pixelSize: Theme.fontSM
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }

                Button {
                    text: contributionsRepeater.visible ? Icons.chevronDown : Icons.play
                    flat: true
                    onClicked: contributionsRepeater.visible = !contributionsRepeater.visible
                    background: Rectangle { color: "transparent" }
                    contentItem: Text {
                        text: parent.text
                        color: Theme.onSurfaceVariant
                        font.pixelSize: Theme.fontSM
                    }
                }
            }

            Column {
                id: contributionsRepeater
                Layout.fillWidth: true
                visible: false
                spacing: Theme.spacingXS

                Repeater {
                    model: ListModel { id: contributionModel }

                    Rectangle {
                        width: synthesisRoot.width - 16
                        height: contribContent.implicitHeight + 16
                        color: Theme.background
                        radius: Theme.radiusSM
                        border.color: Theme.border
                        border.width: 1

                        Column {
                            id: contribContent
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: Theme.spacingSM
                            spacing: Theme.spacingXXS

                            Text {
                                text: model.title
                                color: Theme.primary
                                font.pixelSize: Theme.fontSM
                                font.bold: true
                            }
                            Text {
                                text: model.contribution
                                color: Theme.onSurface
                                font.pixelSize: Theme.fontXS
                                font.family: Theme.codeFontFamily
                                wrapMode: Text.WordWrap
                                width: parent.width
                            }
                        }
                    }
                }
            }
        }
    }

    // Hidden TextEdit for clipboard
    TextEdit {
        id: copyText
        visible: false
    }

    // Timer to reset copy button text
    Timer {
        id: copyResetTimer
        interval: 1500
        repeat: false
        onTriggered: synthesisRoot._copyBtnText = qsTr("复制")
    }

    // Handle synthesis result
    function handleResult(resultJson) {
        var data = JSON.parse(resultJson)
        warningModel.clear()
        contributionModel.clear()
        errorText.text = ""

        if (data.error) {
            errorText.text = data.error
        }

        if (data.success) {
            promptArea.text = data.prompt
        }

        if (data.warnings) {
            for (var i = 0; i < data.warnings.length; i++) {
                warningModel.append({"warning": data.warnings[i]})
            }
        }

        if (data.block_contributions) {
            var keys = Object.keys(data.block_contributions)
            for (var j = 0; j < keys.length; j++) {
                var key = keys[j]
                contributionModel.append({
                    "title": "Block: " + key,
                    "contribution": data.block_contributions[key] || "(empty)"
                })
            }
        }
    }

    Connections {
        target: projectViewModel
        function onSynthesisCompleted(result) {
            synthesisRoot.handleResult(result)
        }
    }
}
