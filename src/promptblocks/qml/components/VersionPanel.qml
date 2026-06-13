import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

Popup {
    id: versionPanel
    width: 440
    height: 520
    padding: Theme.spacingMD
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    property string diffText: ""
    property bool showDiff: false

    background: Rectangle {
        color: Theme.surface
        radius: Theme.radiusMD
        border.color: Theme.border
        border.width: 1
    }

    contentItem: ColumnLayout {
        spacing: Theme.spacingMD

        // Header
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: qsTr("版本管理")
                color: Theme.onBackground
                font.pixelSize: Theme.fontLG
                font.bold: true
                font.family: Theme.fontFamily
            }

            Item { Layout.fillWidth: true }

            // Close button
            Rectangle {
                width: 24
                height: 24
                radius: 12
                color: closeHover.hovered ? Theme.error : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: Icons.close
                    font.family: Icons.fontFamily
                    color: closeHover.hovered ? Theme.onPrimary : Theme.onSurfaceVariant
                    font.pixelSize: Theme.fontS
                }

                HoverHandler { id: closeHover }
                TapHandler { onTapped: versionPanel.close() }
            }
        }

        // Version list
        ListView {
            id: versionListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: Theme.spacingXS

            model: versionViewModel ? versionViewModel.versions : []

            delegate: Rectangle {
                width: versionListView.width
                height: 48
                radius: Theme.radiusSM
                color: versionRowHover.hovered ? Theme.surfaceVariant : Theme.cardBackground
                border.color: Theme.cardBorder
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spacingSM
                    anchors.rightMargin: Theme.spacingSM
                    spacing: Theme.spacingSM

                    // Version number badge
                    Rectangle {
                        width: 36
                        height: 22
                        radius: 11
                        color: Theme.primaryMuted

                        Text {
                            anchors.centerIn: parent
                            text: "v" + modelData.version_number
                            color: Theme.primary
                            font.pixelSize: Theme.fontXS
                            font.bold: true
                            font.family: Theme.fontFamily
                        }
                    }

                    Column {
                        Layout.fillWidth: true
                        spacing: Theme.spacingXXS

                        Text {
                            text: modelData.description || qsTr("无描述")
                            color: Theme.onSurface
                            font.pixelSize: Theme.fontSM
                            elide: Text.ElideRight
                            width: parent.width
                            font.family: Theme.fontFamily
                        }
                        Text {
                            text: modelData.created_at ? Qt.formatDateTime(new Date(modelData.created_at), "yyyy-MM-dd HH:mm") : ""
                            color: Theme.onSurfaceVariant
                            font.pixelSize: Theme.fontXS
                            font.family: Theme.fontFamily
                        }
                    }

                    // Restore button
                    Rectangle {
                        width: 48
                        height: 24
                        radius: Theme.radiusSM
                        color: restoreHover.hovered ? Theme.secondary : "transparent"
                        border.color: Theme.secondary
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: qsTr("恢复")
                            color: restoreHover.hovered ? Theme.onPrimary : Theme.secondary
                            font.pixelSize: Theme.fontXS
                            font.family: Theme.fontFamily
                        }

                        HoverHandler { id: restoreHover }
                        TapHandler {
                            onTapped: {
                                if (versionViewModel) {
                                    versionViewModel.restoreVersion(modelData.id)
                                }
                            }
                        }

                        Behavior on color { enabled: !Theme.animReducedMotion; ColorAnimation { duration: Theme.animFast } }
                    }

                    // Diff button
                    Rectangle {
                        width: 48
                        height: 24
                        radius: Theme.radiusSM
                        color: diffHover.hovered ? Theme.accent : "transparent"
                        border.color: Theme.accent
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: qsTr("对比")
                            color: diffHover.hovered ? Theme.onPrimary : Theme.accent
                            font.pixelSize: Theme.fontXS
                            font.family: Theme.fontFamily
                        }

                        HoverHandler { id: diffHover }
                        TapHandler {
                            onTapped: {
                                if (versionViewModel && versionListView.count >= 2) {
                                    var idx = index
                                    var nextIdx = Math.min(idx + 1, versionListView.count - 1)
                                    if (idx === nextIdx) nextIdx = idx - 1
                                    if (nextIdx >= 0) {
                                        var v1 = versionViewModel.versions[idx]
                                        var v2 = versionViewModel.versions[nextIdx]
                                        versionPanel.diffText = versionViewModel.diffVersions(v1.id, v2.id)
                                        versionPanel.showDiff = true
                                    }
                                }
                            }
                        }

                        Behavior on color { enabled: !Theme.animReducedMotion; ColorAnimation { duration: Theme.animFast } }
                    }
                }

                HoverHandler { id: versionRowHover }
            }

            // Empty state
            Label {
                anchors.centerIn: parent
                visible: !versionViewModel || versionViewModel.versions.length === 0
                text: qsTr("暂无版本记录")
                color: Theme.onSurfaceVariant
                font.pixelSize: Theme.fontSM
                horizontalAlignment: Text.AlignHCenter
            }
        }

        // Diff view
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: versionPanel.showDiff
            Layout.preferredHeight: versionPanel.showDiff ? 200 : 0
            color: Theme.background
            radius: Theme.radiusSM
            border.color: Theme.border
            border.width: 1
            visible: versionPanel.showDiff
            clip: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    height: Theme.heightXS

                    Text {
                        text: qsTr("版本对比")
                        color: Theme.onSurface
                        font.pixelSize: Theme.fontSM
                        font.bold: true
                        font.family: Theme.fontFamily
                        Layout.leftMargin: Theme.spacingSM
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: 20
                        height: 20
                        radius: 10
                        color: Theme.surfaceVariant

                        Text {
                            anchors.centerIn: parent
                            text: Icons.close
                            font.family: Icons.fontFamily
                            font.pixelSize: Theme.fontXS
                            color: Theme.onSurfaceVariant
                        }

                        TapHandler { onTapped: versionPanel.showDiff = false }
                    }

                    Layout.rightMargin: Theme.spacingSM
                }

                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    TextArea {
                        text: versionPanel.diffText
                        readOnly: true
                        color: Theme.onBackground
                        font.pixelSize: Theme.fontXS
                        font.family: Theme.codeFontFamily
                        wrapMode: TextArea.WordWrap
                        selectByMouse: true
                        background: Rectangle { color: "transparent" }
                    }
                }
            }

            Behavior on Layout.preferredHeight { enabled: !Theme.animReducedMotion; NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasing } }
        }
    }

    Connections {
        target: versionViewModel
        function onVersionCreated() {
            versionListView.model = null
            versionListView.model = Qt.binding(function() { return versionViewModel ? versionViewModel.versions : [] })
        }
        function onVersionRestored() {
            versionListView.model = null
            versionListView.model = Qt.binding(function() { return versionViewModel ? versionViewModel.versions : [] })
        }
    }
}
