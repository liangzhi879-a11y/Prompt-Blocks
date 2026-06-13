import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

Rectangle {
    id: titleBar
    height: Theme.heightSM
    color: Theme.surface

    property string title: "PromptBlocks"
    property bool isMaximized: false

    signal minimizeRequested()
    signal maximizeRequested()
    signal closeRequested()

    DragHandler {
        target: null
        onActiveChanged: {
            if (active) {
                titleBar.Window.window.startSystemMove()
            }
        }
    }

    TapHandler {
        onDoubleTapped: titleBar.maximizeRequested()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        spacing: Theme.spacingSM

        Image {
            source: "file:///" + appLogoPath
            sourceSize.width: 24
            sourceSize.height: 24
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            fillMode: Image.PreserveAspectFit
        }

        Text {
            text: titleBar.title
            color: Theme.onBackground
            font.pixelSize: Theme.fontMD
            font.bold: true
            font.family: Theme.fontFamily
        }

        Item { Layout.fillWidth: true }

        IconButton {
            icon: Icons.minimize
            tooltip: qsTr("最小化")
            onClicked: titleBar.minimizeRequested()
        }

        // Maximize / Restore — custom-drawn for consistent stroke weight
        Item {
            width: 32; height: 32

            Rectangle {
                anchors.fill: parent
                radius: 16
                color: maxBgHover.hovered ? Theme.cardHover : "transparent"
                scale: maxTap.pressed ? 0.9 : 1.0

                Behavior on color {
                    enabled: !Theme.animReducedMotion
                    ColorAnimation { duration: Theme.animFast }
                }
                Behavior on scale {
                    enabled: !Theme.animReducedMotion
                    NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing }
                }

                // Maximize — outlined square
                Rectangle {
                    anchors.centerIn: parent
                    width: 10; height: 10
                    color: "transparent"
                    border.color: Theme.onSurfaceVariant
                    border.width: 1.5
                    visible: !titleBar.isMaximized
                }

                // Restore — two overlapping outlined squares
                Item {
                    anchors.centerIn: parent
                    width: 12; height: 12
                    visible: titleBar.isMaximized

                    Rectangle {
                        x: 0; y: 3
                        width: 9; height: 9
                        color: Theme.surface
                        border.color: Theme.onSurfaceVariant
                        border.width: 1.5
                    }
                    Rectangle {
                        x: 3; y: 0
                        width: 9; height: 9
                        color: Theme.surface
                        border.color: Theme.onSurfaceVariant
                        border.width: 1.5
                    }
                }
            }

            HoverHandler { id: maxBgHover }
            TapHandler { id: maxTap; onTapped: titleBar.maximizeRequested() }

            ToolTip {
                visible: maxBgHover.hovered
                text: titleBar.isMaximized ? qsTr("还原") : qsTr("最大化")
                delay: 500
            }
        }

        IconButton {
            icon: Icons.close
            btnStyle: 2
            tooltip: qsTr("关闭")
            onClicked: titleBar.closeRequested()
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Theme.borderLight
    }
}
