import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

// Single test result card component
Rectangle {
    id: resultCardRoot
    color: Theme.background
    radius: Theme.radiusSM
    border.color: Theme.border
    border.width: 1

    property var resultData: null
    property bool isExpanded: false

    implicitHeight: isExpanded ? expandedContent.height + 16 : collapsedRow.height + 16

    // Collapsed row
    RowLayout {
        id: collapsedRow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.spacingSM
        spacing: Theme.spacingSM

        // Status icon
        Text {
            text: resultData && resultData.success ? Icons.accept : Icons.close
            font.pixelSize: Theme.fontMD
        }

        // Input data preview
        Text {
            Layout.fillWidth: true
            text: resultData ? resultData.input_data.substring(0, 60) + (resultData.input_data.length > 60 ? "..." : "") : ""
            color: Theme.onSurface
            font.pixelSize: Theme.fontSM
            elide: Text.ElideRight
        }

        // Latency
        Text {
            text: resultData ? qsTr("%1 ms").arg(Math.round(resultData.latency_ms)) : ""
            color: Theme.onSurfaceVariant
            font.pixelSize: Theme.fontXS
        }

        // Validation badge
        Badge {
            visible: resultData && resultData.validation
            text: resultData && resultData.validation && resultData.validation.is_valid ? qsTr("通过") : qsTr("未通过")
            badgeStyle: resultData && resultData.validation && resultData.validation.is_valid ? 1 : 3
            badgeSize: 0
        }

        // Expand toggle
        Button {
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            text: resultCardRoot.isExpanded ? Icons.chevronUp : Icons.chevronDown
            flat: true
            onClicked: resultCardRoot.isExpanded = !resultCardRoot.isExpanded
            background: Rectangle { color: "transparent" }
            contentItem: Text {
                text: parent.text
                color: Theme.onSurfaceVariant
                font.pixelSize: Theme.fontXS
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    // Expanded content
    Column {
        id: expandedContent
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.spacingSM
        anchors.topMargin: 36
        visible: resultCardRoot.isExpanded
        spacing: Theme.spacingXS

        // Input data
        Column {
            width: parent.width
            spacing: Theme.spacingXXS

            Text {
                text: qsTr("Input:")
                color: Theme.primary
                font.pixelSize: Theme.fontSM
                font.bold: true
            }
            ScrollView {
                width: parent.width
                height: Math.min(inputText.implicitHeight + 8, 80)
                TextArea {
                    id: inputText
                    text: resultData ? resultData.input_data : ""
                    readOnly: true
                    color: Theme.onSurface
                    font.pixelSize: Theme.fontSM
                    wrapMode: TextArea.WordWrap
                    background: Rectangle {
                        color: Theme.codeBackground
                        radius: 3
                    }
                }
            }
        }

        // Actual output
        Column {
            width: parent.width
            spacing: Theme.spacingXXS

            Text {
                text: qsTr("Output:")
                color: Theme.secondary
                font.pixelSize: Theme.fontSM
                font.bold: true
            }
            ScrollView {
                width: parent.width
                height: Math.min(outputText.implicitHeight + 8, 150)
                TextArea {
                    id: outputText
                    text: resultData ? formatOutput(resultData.actual_output) : ""
                    readOnly: true
                    color: Theme.secondary
                    font.pixelSize: Theme.fontSM
                    font.family: Theme.codeFontFamily
                    wrapMode: TextArea.WordWrap
                    background: Rectangle {
                        color: Theme.codeBackground
                        radius: 3
                    }
                }
            }
        }

        // Error (if any)
        Rectangle {
            visible: resultData && resultData.error
            width: parent.width
            height: errorText.implicitHeight + 12
            color: Theme.errorContainer
            radius: Theme.radiusSM

            Text {
                id: errorText
                anchors.fill: parent
                anchors.margins: Theme.spacingXS
                text: resultData && resultData.error ? "Error: " + resultData.error : ""
                color: Theme.error
                font.pixelSize: Theme.fontSM
                wrapMode: Text.WordWrap
            }
        }

        // Schema validation result
        Column {
            visible: resultData && resultData.validation
            width: parent.width
            spacing: Theme.spacingXXS

            Row {
                spacing: Theme.spacingXS
                Text {
                    text: qsTr("Schema Validation:")
                    color: Theme.accent
                    font.pixelSize: Theme.fontSM
                    font.bold: true
                }
                Badge {
                    text: resultData && resultData.validation && resultData.validation.is_valid ? qsTr("通过") : qsTr("未通过")
                    badgeStyle: resultData && resultData.validation && resultData.validation.is_valid ? 1 : 3
                    badgeSize: 0
                }
            }

            // Missing fields
            Column {
                visible: resultData && resultData.validation && resultData.validation.missing_fields && resultData.validation.missing_fields.length > 0
                width: parent.width
                spacing: 1

                Text {
                    text: qsTr("Missing fields:")
                    color: Theme.warning
                    font.pixelSize: Theme.fontXS
                }
                Repeater {
                    model: resultData && resultData.validation ? resultData.validation.missing_fields : []
                    Text {
                        text: "  " + Icons.bullet + " " + modelData
                        color: Theme.warning
                        font.pixelSize: Theme.fontXS
                    }
                }
            }

            // Type errors
            Column {
                visible: resultData && resultData.validation && resultData.validation.type_errors && resultData.validation.type_errors.length > 0
                width: parent.width
                spacing: 1

                Text {
                    text: qsTr("Type errors:")
                    color: Theme.error
                    font.pixelSize: Theme.fontXS
                }
                Repeater {
                    model: resultData && resultData.validation ? resultData.validation.type_errors : []
                    Text {
                        text: "  " + Icons.bullet + " " + modelData
                        color: Theme.error
                        font.pixelSize: Theme.fontXS
                    }
                }
            }

            // All errors
            Column {
                visible: resultData && resultData.validation && resultData.validation.errors && resultData.validation.errors.length > 0 && !(resultData.validation.missing_fields.length > 0 || resultData.validation.type_errors.length > 0)
                width: parent.width
                spacing: 1

                Text {
                    text: qsTr("Errors:")
                    color: Theme.error
                    font.pixelSize: Theme.fontXS
                }
                Repeater {
                    model: resultData && resultData.validation ? resultData.validation.errors : []
                    Text {
                        text: "  " + Icons.bullet + " " + modelData
                        color: Theme.error
                        font.pixelSize: Theme.fontXS
                        wrapMode: Text.WordWrap
                        width: resultCardRoot.width - 32
                    }
                }
            }
        }

        // Latency
        Text {
            text: resultData ? qsTr("Latency: %1 ms").arg(Math.round(resultData.latency_ms)) : ""
            color: Theme.onSurfaceVariant
            font.pixelSize: Theme.fontXS
        }
    }

    function formatOutput(text) {
        if (!text) return ""
        try {
            var parsed = JSON.parse(text)
            return JSON.stringify(parsed, null, 2)
        } catch(e) {
            return text
        }
    }
}
