import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: wizard
    anchors.fill: parent

    signal finished()

    property int currentStep: 0
    property string selectedProvider: "deepseek"
    property string apiKey: ""
    property string customModel: ""
    property string customApiBase: ""

    // Default models per provider (matches config.py _PROVIDER_MODELS)
    readonly property var defaultModels: ({
        "deepseek": "deepseek/deepseek-chat",
        "zai": "zai/glm-4.5",
        "dashscope": "dashscope/qwen-plus",
        "moonshot": "moonshot/moonshot-v1-auto",
        "minimax": "minimax/MiniMax-M2.5",
        "volcengine": "volcengine/doubao-seed-2-0-pro-260215",
        "openai": "openai/gpt-4o",
        "anthropic": "anthropic/claude-sonnet-4-20250514",
        "ollama": "ollama/llama3"
    })

    Rectangle {
        anchors.fill: parent
        color: Theme.background
    }

    StackView {
        id: wizardStack
        anchors.fill: parent
        anchors.margins: 20
        initialItem: welcomePage

        pushEnter: Transition {
            PropertyAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.animNormal; easing.type: Theme.animEasing }
            PropertyAnimation { property: "x"; from: 50; to: 0; duration: Theme.animNormal; easing.type: Theme.animEasing }
        }
        pushExit: Transition {
            PropertyAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.animFast; easing.type: Easing.InQuad }
            PropertyAnimation { property: "x"; from: 0; to: -50; duration: Theme.animFast; easing.type: Easing.InQuad }
        }
        popEnter: Transition {
            PropertyAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.animNormal; easing.type: Theme.animEasing }
            PropertyAnimation { property: "x"; from: -50; to: 0; duration: Theme.animNormal; easing.type: Theme.animEasing }
        }
        popExit: Transition {
            PropertyAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.animFast; easing.type: Easing.InQuad }
            PropertyAnimation { property: "x"; from: 0; to: 50; duration: Theme.animFast; easing.type: Easing.InQuad }
        }
    }

    // ── Welcome page ──
    Component {
        id: welcomePage
        ColumnLayout {
            spacing: 20
            anchors.centerIn: parent
            width: Math.min(parent.width * 0.8, 500)

            Label {
                text: qsTr("Welcome to PromptBlocks!")
                font.pixelSize: Theme.fontXXL
                font.bold: true
                color: Theme.onBackground
                Layout.alignment: Qt.AlignHCenter
            }
            Label {
                text: qsTr("Let's configure your LLM provider to get started.\n"
                    + "You can always change this later in Settings.")
                font.pixelSize: Theme.fontMD
                color: Theme.onSurface
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }
            Button {
                text: qsTr("Get Started")
                Layout.alignment: Qt.AlignHCenter
                onClicked: wizardStack.push(providerPage)
            }
        }
    }

    // ── Provider selection page ──
    Component {
        id: providerPage
        ColumnLayout {
            spacing: Theme.spacingLG
            width: Math.min(parent.width * 0.9, 520)
            anchors.centerIn: parent

            Label {
                text: qsTr("Select Your LLM Provider")
                font.pixelSize: Theme.fontXL
                font.bold: true
                color: Theme.onBackground
                Layout.alignment: Qt.AlignHCenter
            }

            // ── Domestic providers ──
            Text {
                text: qsTr("国内厂商")
                font.pixelSize: Theme.fontSM
                font.bold: true
                color: Theme.onSurfaceVariant
                Layout.topMargin: 8
            }

            Flow {
                Layout.fillWidth: true
                spacing: Theme.spacingSM
                Repeater {
                    model: [
                        { text: "DeepSeek", value: "deepseek", desc: "deepseek-chat / deepseek-reasoner" },
                        { text: "智谱AI (ChatGLM)", value: "zai", desc: "GLM-4.5 / GLM-4.7" },
                        { text: "阿里通义 (Qwen)", value: "dashscope", desc: "qwen-plus / qwen-max" },
                        { text: "月之暗面 (Kimi)", value: "moonshot", desc: "kimi-latest / moonshot-v1" },
                        { text: "MiniMax", value: "minimax", desc: "MiniMax-M2.5" },
                        { text: "字节豆包 (Doubao)", value: "volcengine", desc: "doubao-seed-2-0" }
                    ]
                    delegate: providerCard
                }
            }

            // ── International providers ──
            Text {
                text: qsTr("国际厂商")
                font.pixelSize: Theme.fontSM
                font.bold: true
                color: Theme.onSurfaceVariant
                Layout.topMargin: 12
            }

            Flow {
                Layout.fillWidth: true
                spacing: Theme.spacingSM
                Repeater {
                    model: [
                        { text: "OpenAI", value: "openai", desc: "GPT-4o / GPT-4.1" },
                        { text: "Anthropic", value: "anthropic", desc: "Claude Sonnet 4" }
                    ]
                    delegate: providerCard
                }
            }

            // ── Local ──
            Text {
                text: qsTr("本地模型")
                font.pixelSize: Theme.fontSM
                font.bold: true
                color: Theme.onSurfaceVariant
                Layout.topMargin: 12
            }

            Flow {
                Layout.fillWidth: true
                spacing: Theme.spacingSM
                Repeater {
                    model: [
                        { text: "Ollama", value: "ollama", desc: "本地运行 (llama3 / qwen / ...)" }
                    ]
                    delegate: providerCard
                }
            }

            // ── Navigation ──
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 16
                Button {
                    text: qsTr("Back")
                    onClicked: wizardStack.pop()
                }
                Item { Layout.fillWidth: true }
                Button {
                    text: qsTr("Next")
                    highlighted: true
                    onClicked: wizardStack.push(apiKeyPage)
                }
            }
        }
    }

    // ── Provider card component ──
    Component {
        id: providerCard
        Rectangle {
            id: card
            width: 150
            height: 56
            radius: Theme.radiusMD
            color: wizard.selectedProvider === modelData.value ? Theme.primaryContainer : Theme.surface
            border.color: wizard.selectedProvider === modelData.value
                ? Theme.primary
                : Theme.borderLight
            border.width: wizard.selectedProvider === modelData.value ? 2 : 1

            scale: 1.0
            Behavior on scale { enabled: !Theme.animReducedMotion; NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }
            Behavior on color { enabled: !Theme.animReducedMotion; ColorAnimation { duration: Theme.animFast } }
            Behavior on border.color { enabled: !Theme.animReducedMotion; ColorAnimation { duration: Theme.animFast } }

            Column {
                anchors.centerIn: parent
                spacing: 1
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: modelData.text
                    font.pixelSize: Theme.fontMD
                    font.bold: wizard.selectedProvider === modelData.value
                    color: wizard.selectedProvider === modelData.value ? Theme.primary : Theme.onSurface
                    font.family: Theme.fontFamily
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: modelData.desc
                    font.pixelSize: Theme.fontXS
                    color: Theme.onSurfaceVariant
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: wizard.selectedProvider = modelData.value
                onEntered: if (wizard.selectedProvider !== modelData.value) card.scale = 1.03
                onExited: if (wizard.selectedProvider !== modelData.value) card.scale = 1.0
                onPressed: card.scale = 0.97
                onReleased: card.scale = wizard.selectedProvider === modelData.value ? 1.0 : 1.03
            }
        }
    }

    // ── API Key + model + advanced page ──
    Component {
        id: apiKeyPage
        ColumnLayout {
            spacing: Theme.spacingLG
            width: Math.min(parent.width * 0.85, 480)
            anchors.centerIn: parent

            Label {
                text: qsTr("Configure %1").arg(wizard.selectedProvider)
                font.pixelSize: Theme.fontXL
                font.bold: true
                color: Theme.onBackground
                Layout.alignment: Qt.AlignHCenter
            }

            // ── Provider info ──
            Rectangle {
                Layout.fillWidth: true
                radius: Theme.radiusSM
                color: Theme.primaryContainer
                height: providerInfoText.implicitHeight + 16
                Label {
                    id: providerInfoText
                    anchors.centerIn: parent
                    width: parent.width - 24
                    text: wizard.selectedProvider === "ollama"
                        ? qsTr("Ollama runs locally on your machine. No API key required.")
                        : qsTr("Provider: %1 | Default model: %2")
                            .arg(wizard.selectedProvider)
                            .arg(wizard.defaultModels[wizard.selectedProvider] || "")
                    font.pixelSize: Theme.fontSM
                    color: Theme.primary
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            // ── API Key ──
            Label {
                text: qsTr("API Key")
                font.pixelSize: Theme.fontSM
                font.bold: true
                color: Theme.onSurface
                visible: wizard.selectedProvider !== "ollama"
            }
            TextField {
                id: apiKeyInput
                Layout.fillWidth: true
                placeholderText: "sk-..."
                echoMode: TextInput.Password
                visible: wizard.selectedProvider !== "ollama"
                onTextChanged: wizard.apiKey = text
            }

            // ── Model ──
            Label {
                text: qsTr("Default Model")
                font.pixelSize: Theme.fontSM
                font.bold: true
                color: Theme.onSurface
            }
            TextField {
                id: modelInput
                Layout.fillWidth: true
                placeholderText: wizard.defaultModels[wizard.selectedProvider] || ""
                text: wizard.customModel
                onTextChanged: wizard.customModel = text
            }

            // ── API Base URL (advanced) ──
            Rectangle {
                Layout.fillWidth: true
                radius: Theme.radiusSM
                color: Theme.surfaceVariant
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingSM
                    spacing: Theme.spacingS

                    // Toggle header
                    MouseArea {
                        Layout.fillWidth: true
                        height: advHeaderText.implicitHeight + 4
                        cursorShape: Qt.PointingHandCursor
                        RowLayout {
                            anchors.fill: parent
                            Text {
                                id: advHeaderText
                                text: qsTr("Advanced Settings")
                                font.pixelSize: Theme.fontSM
                                font.bold: true
                                color: Theme.onSurfaceVariant
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: advSection.visible ? "▲" : "▼"
                                font.pixelSize: Theme.fontSM
                                color: Theme.onSurfaceVariant
                            }
                        }
                        onClicked: advSection.visible = !advSection.visible
                    }

                    ColumnLayout {
                        id: advSection
                        visible: false
                        spacing: Theme.spacingXS

                        Text {
                            text: qsTr("API Base URL (leave empty for default)")
                            font.pixelSize: Theme.fontXS
                            color: Theme.onSurfaceVariant
                        }
                        TextField {
                            id: apiBaseInput
                            Layout.fillWidth: true
                            placeholderText: {
                                const bases = {
                                    "deepseek": "https://api.deepseek.com",
                                    "zai": "https://api.z.ai/api/paas/v4",
                                    "dashscope": "https://dashscope.aliyuncs.com/compatible-mode/v1",
                                    "moonshot": "https://api.moonshot.ai/v1",
                                    "minimax": "https://api.minimaxi.com/v1",
                                    "volcengine": "https://ark.cn-beijing.volces.com",
                                    "ollama": "http://localhost:11434"
                                }
                                return bases[wizard.selectedProvider] || ""
                            }
                            text: wizard.customApiBase
                            font.pixelSize: Theme.fontSM
                            onTextChanged: wizard.customApiBase = text
                        }
                    }
                }
            }

            // ── Navigation ──
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 12
                Button {
                    text: qsTr("Back")
                    onClicked: wizardStack.pop()
                }
                Item { Layout.fillWidth: true }
                Button {
                    text: qsTr("Complete Setup")
                    highlighted: true
                    enabled: wizard.selectedProvider === "ollama" || wizard.apiKey.trim().length > 0
                    onClicked: {
                        if (appConfig) {
                            appConfig.set_llm_config(
                                wizard.selectedProvider,
                                wizard.selectedProvider === "ollama" ? "" : wizard.apiKey.trim(),
                                wizard.customModel.trim(),
                                wizard.customApiBase.trim()
                            )
                        }
                        wizard.finished()
                    }
                }
            }
        }
    }
}
