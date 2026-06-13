import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

Rectangle {
    id: kbManager

    signal knowledgeAdded(string name)
    signal knowledgeRemoved(string name)

    property bool isExpanded: false

    height: isExpanded ? expandedHeight : collapsedHeight
    implicitHeight: isExpanded ? expandedHeight : collapsedHeight
    readonly property int collapsedHeight: Theme.heightSM
    readonly property int expandedHeight: 220

    color: Theme.surface
    border.color: Theme.panelBorder
    border.width: 1
    radius: Theme.radiusSM

    Behavior on height { enabled: !Theme.animReducedMotion; NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header row
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.heightSM
            Layout.leftMargin: Theme.spacingSM
            Layout.rightMargin: Theme.spacingSM

            Rectangle {
                width: 3; height: 14; radius: 2
                color: Theme.moduleTypeColors["knowledge_rag"].accent
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                text: Icons.menu + " 知识库配置"
                color: Theme.onBackground
                font.pixelSize: Theme.fontSM
                font.weight: Font.DemiBold
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                text: "(" + kbList.count + ")"
                color: Theme.onSurfaceVariant
                font.pixelSize: Theme.fontXS
                Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }

            Text {
                text: kbManager.isExpanded ? Icons.chevronUp : Icons.chevronDown
                font.pixelSize: Theme.fontXXS
                color: Theme.onSurfaceVariant
                Layout.alignment: Qt.AlignVCenter
            }

            TapHandler {
                onTapped: kbManager.isExpanded = !kbManager.isExpanded
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.divider }

        // Expanded content
        ColumnLayout {
            visible: kbManager.isExpanded
            opacity: kbManager.isExpanded ? 1 : 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Theme.spacingXS

            Behavior on opacity { enabled: !Theme.animReducedMotion; NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }

            // Add knowledge form
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 68
                Layout.margins: Theme.spacingS
                color: Theme.surfaceVariant
                radius: Theme.radiusSM
                border.color: Theme.border
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingS
                    spacing: Theme.spacingXS

                    // Name + SourceType row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacingXS

                        TextField {
                            id: kbNameInput
                            Layout.fillWidth: true
                            Layout.preferredHeight: 24
                            placeholderText: "\u77E5\u8BC6\u5E93\u540D\u79F0"
                            font.pixelSize: Theme.fontXS
                            color: Theme.onBackground
                            background: Rectangle {
                                color: Theme.background
                                radius: 2
                                border.color: kbNameInput.activeFocus ? Theme.primary : Theme.border
                                border.width: 1
                            }
                        }

                        ComboBox {
                            id: kbTypeCombo
                            Layout.preferredWidth: 72
                            Layout.preferredHeight: 24
                            model: ["file", "url", "api", "database"]
                            currentIndex: 0
                            font.pixelSize: Theme.fontXS

                            background: Rectangle {
                                color: Theme.background
                                radius: 2
                                border.color: Theme.border
                                border.width: 1
                            }

                            contentItem: Text {
                                text: kbTypeCombo.currentText
                                font.pixelSize: Theme.fontXS
                                color: Theme.onBackground
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        Rectangle {
                            id: addKbBtn
                            width: Theme.heightXS
                            height: 24
                            radius: 2
                            color: addKbBtnMA.containsMouse ? Theme.primary : Theme.primaryMuted

                            Text {
                                anchors.centerIn: parent
                                text: "+"
                                color: addKbBtnMA.containsMouse ? Theme.onPrimary : Theme.primary
                                font.pixelSize: Theme.fontMD
                                font.bold: true
                            }

                            MouseArea {
                                id: addKbBtnMA
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var name = kbNameInput.text.trim()
                                    if (name.length > 0 && knowledgeModel) {
                                        var stype = kbTypeCombo.currentText
                                        var desc = kbDescInput.text.trim()
                                        var url = kbUrlInput.text.trim()
                                        knowledgeModel.addKnowledge(name, stype, desc, url, "")
                                        kbNameInput.text = ""
                                        kbDescInput.text = ""
                                        kbUrlInput.text = ""
                                        kbManager.knowledgeAdded(name)
                                    }
                                }
                            }
                        }
                    }

                    // Description + URL row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacingXS

                        TextField {
                            id: kbDescInput
                            Layout.fillWidth: true
                            Layout.preferredHeight: 24
                            placeholderText: "\u8BF4\u660E\uFF08\u53EF\u9009\uFF09"
                            font.pixelSize: Theme.fontXS
                            color: Theme.onBackground
                            background: Rectangle {
                                color: Theme.background
                                radius: 2
                                border.color: kbDescInput.activeFocus ? Theme.primary : Theme.border
                                border.width: 1
                            }
                        }

                        TextField {
                            id: kbUrlInput
                            Layout.preferredWidth: 100
                            Layout.preferredHeight: 24
                            placeholderText: "\u53C2\u8003URL"
                            font.pixelSize: Theme.fontXS
                            color: Theme.onBackground
                            background: Rectangle {
                                color: Theme.background
                                radius: 2
                                border.color: kbUrlInput.activeFocus ? Theme.primary : Theme.border
                                border.width: 1
                            }
                        }
                    }
                }
            }

            // Knowledge list with empty state
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: Theme.spacingS

                ListView {
                    id: kbList
                    anchors.fill: parent
                    clip: true
                    spacing: Theme.spacingXXS
                    model: knowledgeModel
                    visible: kbList.count > 0

                    delegate: Rectangle {
                        width: kbList.width - 4
                        height: 26
                        radius: Theme.radiusSM
                        color: kbItemHover.hovered ? Theme.primaryMuted : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.spacingS
                            anchors.rightMargin: Theme.spacingXS
                            spacing: Theme.spacingXS

                            Text {
                                text: model.sourceType === "file" ? Icons.list :
                                      model.sourceType === "url" ? Icons.circleThin :
                                      model.sourceType === "api" ? Icons.link : Icons.list
                                font.pixelSize: Theme.fontXS
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Text {
                                text: model.name
                                color: Theme.onBackground
                                font.pixelSize: Theme.fontXS
                                font.family: Theme.fontFamily
                                font.bold: true
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                elide: Text.ElideRight
                            }

                            Text {
                                text: model.sourceType
                                color: Theme.onSurfaceVariant
                                font.pixelSize: Theme.fontS
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Rectangle {
                                width: 18
                                height: 18
                                radius: 9
                                color: delKbHover.hovered ? Theme.error : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: Icons.close
                                    color: delKbHover.hovered ? Theme.onPrimary : Theme.onSurfaceVariant
                                    font.pixelSize: Theme.fontXXS
                                }

                                HoverHandler { id: delKbHover }
                                TapHandler {
                                    onTapped: {
                                        if (knowledgeModel) {
                                            knowledgeModel.removeKnowledge(model.knowledgeId)
                                            kbManager.knowledgeRemoved(model.name)
                                        }
                                    }
                                }
                            }
                        }

                        HoverHandler { id: kbItemHover }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: kbList.count === 0
                    text: "\u6682\u65E0\u77E5\u8BC6\u5E93\u3002\u6A21\u4EFF agent \u642D\u5EFA\uFF0C\n\u6DFB\u52A0\u77E5\u8BC6\u6E90\u4F9BAI\u751F\u6210\u65F6\u53C2\u8003\u3002"
                    color: Theme.onSurfaceVariant
                    font.pixelSize: Theme.fontXS
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
}
