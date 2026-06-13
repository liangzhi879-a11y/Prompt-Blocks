import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import "../components"
import ".."

// Test Panel — single/batch test mode with results display
Rectangle {
    id: testPanelRoot
    color: Theme.surface

    property int testMode: 0  // 0 = single, 1 = batch
    property string currentProjectId: ""
    property var testResultsList: []

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingSM
        spacing: Theme.spacingXS

        // Header: Test mode switch
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingSM

            Text {
                text: qsTr("Test Workbench")
                color: Theme.onBackground
                font.pixelSize: Theme.fontMD
                font.bold: true
            }

            Item { Layout.fillWidth: true }

            // Mode toggle
            RowLayout {
                spacing: 0

                Rectangle {
                    width: 80
                    height: Theme.heightXS
                    radius: Theme.radiusSM
                    color: testPanelRoot.testMode === 0 ? Theme.primaryContainer : Theme.surfaceVariant

                    Text {
                        anchors.centerIn: parent
                        text: qsTr("Single")
                        color: testPanelRoot.testMode === 0 ? Theme.onBackground : Theme.onSurfaceVariant
                        font.pixelSize: Theme.fontSM
                        font.bold: testPanelRoot.testMode === 0
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: testPanelRoot.testMode = 0
                    }
                }

                Rectangle {
                    width: 80
                    height: Theme.heightXS
                    radius: Theme.radiusSM
                    color: testPanelRoot.testMode === 1 ? Theme.primaryContainer : Theme.surfaceVariant

                    Text {
                        anchors.centerIn: parent
                        text: qsTr("Batch")
                        color: testPanelRoot.testMode === 1 ? Theme.onBackground : Theme.onSurfaceVariant
                        font.pixelSize: Theme.fontSM
                        font.bold: testPanelRoot.testMode === 1
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: testPanelRoot.testMode = 1
                    }
                }
            }
        }

        // Mode content
        StackLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: testPanelRoot.testMode === 0 ? 180 : 200
            currentIndex: testPanelRoot.testMode

            // Single test mode
            TestDataInput {
                id: singleTestInput
                onRunRequested: function(inputData) {
                    if (testViewModel && testPanelRoot.currentProjectId) {
                        testViewModel.runSingleTest(testPanelRoot.currentProjectId, inputData)
                    }
                }
            }

            // Batch test mode
            Rectangle {
                color: "transparent"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: Theme.spacingXS

                    // Import CSV button
                    Button {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        text: qsTr("Import CSV")

                        background: Rectangle {
                            color: parent.pressed ? Theme.primaryContainer : Theme.surfaceVariant
                            radius: Theme.radiusSM
                        }
                        contentItem: Text {
                            text: parent.text
                            color: Theme.onBackground
                            font.pixelSize: Theme.fontSM
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: csvFileDialog.open()
                    }

                    // Imported test data list
                    ListView {
                        id: batchTestList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: Theme.spacingXXS

                        model: ListModel { id: batchTestModel }

                        delegate: Rectangle {
                            width: batchTestList.width
                            height: Theme.heightXS
                            color: Theme.background
                            radius: 3

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: Theme.spacingSM
                                anchors.rightMargin: Theme.spacingSM
                                spacing: Theme.spacingXS

                                Text {
                                    text: (index + 1) + "."
                                    color: Theme.onSurfaceVariant
                                    font.pixelSize: Theme.fontXS
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: model.inputData
                                    color: Theme.onSurface
                                    font.pixelSize: Theme.fontSM
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }

                    // Batch run button
                    Button {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 32
                        text: qsTr("Batch Run (%1 cases)").arg(batchTestModel.count)
                        enabled: batchTestModel.count > 0 && !(testViewModel && testViewModel.isRunning)

                        background: Rectangle {
                            color: parent.enabled ? (parent.pressed ? Theme.primaryContainer : Theme.primary) : Theme.border
                            radius: Theme.radiusSM
                        }
                        contentItem: Text {
                            text: parent.text
                            color: parent.enabled ? Theme.onPrimary : Theme.onSurfaceVariant
                            font.pixelSize: Theme.fontSM
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: {
                            if (testViewModel && testPanelRoot.currentProjectId && csvFileDialog.selectedFile.toString()) {
                                testViewModel.runBatchTests(testPanelRoot.currentProjectId, csvFilePath)
                            }
                        }
                    }
                }
            }
        }

        // Progress bar (visible when running)
        Rectangle {
            Layout.fillWidth: true
            height: 4
            color: Theme.background
            radius: 2
            visible: testViewModel && testViewModel.isRunning

            Rectangle {
                width: testViewModel && testViewModel.totalTests > 0
                       ? parent.width * (testViewModel.progress / testViewModel.totalTests)
                       : 0
                height: parent.height
                color: Theme.primary
                radius: 2

                Behavior on width {
                    enabled: !Theme.animReducedMotion
                    NumberAnimation { duration: Theme.animNormal }
                }
            }
        }

        // Stop button
        Button {
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.heightXS
            text: qsTr("Stop")
            visible: testViewModel && testViewModel.isRunning

            background: Rectangle {
                color: parent.pressed ? Theme.errorContainer : Theme.error
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

            onClicked: {
                if (testViewModel) testViewModel.stopTests()
            }
        }

        // Divider
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.border
        }

        // Results header
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingSM

            Text {
                text: qsTr("Test Results")
                color: Theme.onBackground
                font.pixelSize: Theme.fontML
                font.bold: true
            }

            Item { Layout.fillWidth: true }

            // Summary stats
            Text {
                visible: testPanelRoot.testResultsList.length > 0
                text: qsTr("Total: %1 | Pass: %2 | Fail: %3")
                    .arg(testPanelRoot.testResultsList.length)
                    .arg(countPass())
                    .arg(testPanelRoot.testResultsList.length - countPass())
                color: Theme.onSurfaceVariant
                font.pixelSize: Theme.fontXS
            }
        }

        // Batch summary (visible for batch results)
        Rectangle {
            Layout.fillWidth: true
            height: 48
            visible: testPanelRoot.testResultsList.length > 1
            color: Theme.background
            radius: Theme.radiusSM

            Column {
                id: summaryColumn
                anchors.fill: parent
                anchors.margins: Theme.spacingXS
                spacing: Theme.spacingXXS

                Text {
                    text: qsTr("Average Latency: %1 ms").arg(calcAvgLatency())
                    color: Theme.onSurfaceVariant
                    font.pixelSize: Theme.fontXS
                }
                Text {
                    text: qsTr("Format Compliance: %1%").arg(calcComplianceRate())
                    color: Theme.onSurfaceVariant
                    font.pixelSize: Theme.fontXS
                }
            }
        }

        // Results list
        ListView {
            id: resultsListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: Theme.spacingXS

            model: testPanelRoot.testResultsList

            delegate: TestResultCard {
                width: resultsListView.width
                resultData: modelData
            }
        }
    }

    // CSV FileDialog
    FileDialog {
        id: csvFileDialog
        title: qsTr("Select CSV File")
        nameFilters: ["CSV files (*.csv)", "All files (*)"]
        fileMode: FileDialog.OpenFile

        property string csvFilePath: ""

        onAccepted: {
            csvFilePath = selectedFile.toString().replace("file:///", "").replace("file://", "")
            loadCsvPreview(csvFilePath)
        }
    }

    // Helper functions
    function loadCsvPreview(filePath) {
        batchTestModel.clear()
        batchTestModel.append({"inputData": "Loaded from: " + filePath.split("/").pop()})
    }

    function countPass() {
        var count = 0
        for (var i = 0; i < testPanelRoot.testResultsList.length; i++) {
            var r = testPanelRoot.testResultsList[i]
            if (r.success && r.validation && r.validation.is_valid) count++
        }
        return count
    }

    function calcAvgLatency() {
        if (testPanelRoot.testResultsList.length === 0) return 0
        var total = 0
        for (var i = 0; i < testPanelRoot.testResultsList.length; i++) {
            total += testPanelRoot.testResultsList[i].latency_ms || 0
        }
        return Math.round(total / testPanelRoot.testResultsList.length)
    }

    function calcComplianceRate() {
        if (testPanelRoot.testResultsList.length === 0) return 0
        return Math.round(countPass() / testPanelRoot.testResultsList.length * 100)
    }

    // Handle test results from ViewModel
    Connections {
        target: testViewModel

        function onTestCompleted(resultJson) {
            try {
                var result = JSON.parse(resultJson)
                testPanelRoot.testResultsList = [result]
            } catch(e) {}
        }

        function onBatchCompleted(resultsJson) {
            try {
                var results = JSON.parse(resultsJson)
                testPanelRoot.testResultsList = results
            } catch(e) {}
        }

        function onTestError(message) {
            console.log("Test error:", message)
        }
    }
}
