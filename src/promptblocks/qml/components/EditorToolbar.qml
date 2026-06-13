import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

Flow {
    id: editorToolbar

    signal insertRequested(string snippet)
    signal pipelineRequested()

    spacing: Theme.spacingXXS

    PBButton {
        text: "H1"
        btnStyle: 3
        btnSize: 0
        onClicked: editorToolbar.insertRequested("# ")
    }

    PBButton {
        text: "H2"
        btnStyle: 3
        btnSize: 0
        onClicked: editorToolbar.insertRequested("## ")
    }

    PBButton {
        text: "H3"
        btnStyle: 3
        btnSize: 0
        onClicked: editorToolbar.insertRequested("### ")
    }

    PBButton {
        text: "B"
        btnStyle: 3
        btnSize: 0
        onClicked: editorToolbar.insertRequested("****")
    }

    PBButton {
        text: "I"
        btnStyle: 3
        btnSize: 0
        onClicked: editorToolbar.insertRequested("**")
    }

    PBButton {
        text: Icons.bullet + " List"
        btnStyle: 3
        btnSize: 0
        onClicked: editorToolbar.insertRequested("- ")
    }

    PBButton {
        text: "1."
        btnStyle: 3
        btnSize: 0
        onClicked: editorToolbar.insertRequested("1. ")
    }

    PBButton {
        text: "Code"
        btnStyle: 3
        btnSize: 0
        onClicked: editorToolbar.insertRequested("```\n\n```")
    }

    PBButton {
        text: "Table"
        btnStyle: 3
        btnSize: 0
        onClicked: editorToolbar.insertRequested("| \u52171 | \u52172 | \u52173 |\n|------|------|------|\n|  |  |  |")
    }

    PBButton {
        text: ">"
        btnStyle: 3
        btnSize: 0
        onClicked: editorToolbar.insertRequested("> ")
    }

    PBButton {
        text: "---"
        btnStyle: 3
        btnSize: 0
        onClicked: editorToolbar.insertRequested("\n---\n")
    }

    PBButton {
        text: "{{}}"
        btnStyle: 3
        btnSize: 0
        onClicked: editorToolbar.insertRequested("{{}}")
    }

    // Separator line
    Rectangle {
        width: 1
        height: Theme.fontXL2
        color: Theme.divider
    }

    // Variable filter button (merged into toolbar)
    PBButton {
        icon: Icons.settings
        text: qsTr("\u53D8\u91CF\u8FC7\u6EE4")
        btnStyle: 3
        btnSize: 0
        onClicked: editorToolbar.pipelineRequested()

        HoverHandler { id: pipeBtnHover }
        ToolTip {
            visible: pipeBtnHover.hovered
            text: qsTr("\u5BF9\u53D8\u91CF\u503C\u5E94\u7528\u9884\u5904\u7406\u4E0E\u540E\u5904\u7406\u8FC7\u6EE4")
            delay: 300
        }
    }
}
