import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

Rectangle {
    id: variablePanel
    color: "transparent"

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header
        Rectangle {
            Layout.fillWidth: true
            height: Theme.heightSM
            color: Theme.surfaceVariant
            radius: Theme.radiusSM

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.spacingMD
                anchors.rightMargin: Theme.spacingSM
                spacing: Theme.spacingSM

                Text {
                    text: Icons.diamond +" "+ qsTr("变量管理")
                    color: Theme.onBackground
                    font.pixelSize: Theme.fontSM
                    font.weight: Font.DemiBold
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    width: 22
                    height: 22
                    radius: 11
                    color: addHover.hovered ? Theme.primary : Theme.primaryMuted

                    Text {
                        anchors.centerIn: parent
                        text: "+"
                        color: Theme.primary
                        font.pixelSize: Theme.fontMD
                        font.bold: true
                    }

                    HoverHandler { id: addHover }
                    TapHandler {
                        onTapped: {
                            // Placeholder: add a new demo variable
                            variableListModel.append({
                                "varName": "new_var_" + variableListModel.count,
                                "varType": "text",
                                "defaultValue": "",
                                "scope": "global"
                            })
                        }
                    }
                }
            }
        }

        // Variable list
        ListView {
            id: variableListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: Theme.spacingXS
            clip: true
            spacing: Theme.spacingXXS

            model: variableListModel
            delegate: Rectangle {
                width: variableListView.width
                height: Theme.heightMD
                radius: Theme.radiusSM
                color: rowHover.hovered ? Theme.surfaceRaised : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spacingSM
                    anchors.rightMargin: Theme.spacingSM
                    spacing: Theme.spacingXS

                    // Type icon
                    Text {
                        text: model.varType === "text" ? Icons.edit :
                              model.varType === "number" ? Icons.tag :
                              model.varType === "list" ? Icons.list :
                              model.varType === "boolean" ? Icons.accept : Icons.edit
                        font.pixelSize: Theme.fontSM
                        Layout.alignment: Qt.AlignVCenter
                    }

                    // Variable name
                    Text {
                        text: model.varName
                        color: Theme.onBackground
                        font.pixelSize: Theme.fontSM
                        font.family: Theme.codeFontFamily
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    // Scope badge
                    Rectangle {
                        width: scopeLabel.implicitWidth + 8
                        height: 16
                        radius: 8
                        color: model.scope === "global" ? Theme.primaryMuted :
                               model.scope === "project" ? Theme.accentMuted : Theme.surfaceVariant

                        Text {
                            id: scopeLabel
                            anchors.centerIn: parent
                            text: model.scope === "global" ? qsTr("全局") :
                                  model.scope === "project" ? qsTr("项目") : qsTr("局部")
                            color: Theme.onSurfaceVariant
                            font.pixelSize: Theme.fontXS
                        }
                    }

                    // Edit button
                    Rectangle {
                        width: 20
                        height: 20
                        radius: 10
                        color: editHover.hovered ? Theme.surfaceVariant : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: Icons.edit
                            font.pixelSize: Theme.fontXS
                            color: Theme.onSurfaceVariant
                        }

                        HoverHandler { id: editHover }
                        TapHandler {
                            onTapped: console.log("[VariablePanel] Edit:", model.varName)
                        }
                    }

                    // Delete button
                    Rectangle {
                        width: 20
                        height: 20
                        radius: 10
                        color: delHover.hovered ? Theme.error : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: Icons.close
                            font.pixelSize: Theme.fontXS
                            color: delHover.hovered ? Theme.onPrimary : Theme.onSurfaceVariant
                        }

                        HoverHandler { id: delHover }
                        TapHandler {
                            onTapped: variableListModel.remove(index)
                        }
                    }
                }

                HoverHandler { id: rowHover }
            }
        }

        // Empty state
        Label {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: variableListModel.count === 0
            text: qsTr("暂无变量\n点击 + 添加")
            color: Theme.onSurfaceVariant
            font.pixelSize: Theme.fontSM
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            opacity: 0.5
        }
    }

    // Static demo data
    ListModel {
        id: variableListModel
        ListElement { varName: "role"; varType: "text"; defaultValue: ""; scope: "global" }
        ListElement { varName: "task"; varType: "text"; defaultValue: ""; scope: "global" }
        ListElement { varName: "language"; varType: "text"; defaultValue: "zh-CN"; scope: "project" }
        ListElement { varName: "max_tokens"; varType: "number"; defaultValue: "4096"; scope: "global" }
        ListElement { varName: "temperature"; varType: "number"; defaultValue: "0.7"; scope: "project" }
    }
}
