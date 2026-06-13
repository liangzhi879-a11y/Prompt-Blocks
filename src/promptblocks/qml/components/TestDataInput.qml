import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

// Single test data input component
Rectangle {
    id: testDataInputRoot
    color: "transparent"

    property alias inputData: inputArea.text
    signal runRequested(string inputData)

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.spacingXS

        Label {
            text: qsTr("Test Input")
            color: Theme.onBackground
            font.pixelSize: Theme.fontML
            font.bold: true
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 80

            TextArea {
                id: inputArea
                placeholderText: qsTr("Enter test data here...")
                placeholderTextColor: Theme.onSurfaceVariant
                color: Theme.onBackground
                font.pixelSize: Theme.fontSM
                wrapMode: TextArea.WordWrap
                selectByMouse: true
                background: Rectangle {
                    color: Theme.background
                    radius: Theme.radiusSM
                    border.color: inputArea.activeFocus ? Theme.primary : Theme.border
                }
            }
        }

        Button {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            text: qsTr("Run Test")
            enabled: inputArea.text.trim().length > 0 && !(testViewModel && testViewModel.isRunning)

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

            onClicked: testDataInputRoot.runRequested(inputArea.text.trim())
        }
    }
}
