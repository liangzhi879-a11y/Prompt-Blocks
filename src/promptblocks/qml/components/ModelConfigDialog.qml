import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

Popup {
    id: modelConfigDialog
    width: 420
    height: 600
    padding: Theme.spacingMD
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    property var providers: ["openai", "anthropic", "deepseek", "zai", "dashscope", "moonshot", "minimax", "volcengine", "ollama"]
    property bool useSameModel: appConfig ? appConfig.useSameModel : true

    background: Rectangle {
        color: Theme.surface
        radius: Theme.radiusMD
        border.color: Theme.border
        border.width: 1
    }

    contentItem: ColumnLayout {
        spacing: Theme.spacingMD

        // Header
        Text {
            text: qsTr("模型配置")
            color: Theme.onBackground
            font.pixelSize: Theme.fontLG
            font.bold: true
            font.family: Theme.fontFamily
        }

        // ── 编译模型 (Main) ──
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingSM

            Text {
                text: qsTr("编译模型")
                color: Theme.primary
                font.pixelSize: Theme.fontSM
                font.bold: true
                font.family: Theme.fontFamily
            }

            // Provider
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingSM

                Text {
                    text: qsTr("Provider:")
                    color: Theme.onSurface
                    font.pixelSize: Theme.fontSM
                    font.family: Theme.fontFamily
                    Layout.preferredWidth: 70
                }

                ComboBox {
                    id: mainProviderCombo
                    Layout.fillWidth: true
                    model: modelConfigDialog.providers
                    currentIndex: {
                        if (!appConfig) return 0
                        var p = appConfig.get_llm_provider()
                        var idx = modelConfigDialog.providers.indexOf(p)
                        return idx >= 0 ? idx : 0
                    }
                }
            }

            // API Key
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingSM

                Text {
                    text: qsTr("API Key:")
                    color: Theme.onSurface
                    font.pixelSize: Theme.fontSM
                    font.family: Theme.fontFamily
                    Layout.preferredWidth: 70
                }

                TextField {
                    id: mainApiKeyInput
                    Layout.fillWidth: true
                    text: appConfig ? appConfig.get_llm_api_key() : ""
                    echoMode: TextInput.Password
                    font.pixelSize: Theme.fontSM
                    placeholderText: qsTr("输入 API Key...")
                    background: Rectangle {
                        color: Theme.background
                        radius: Theme.radiusSM
                        border.color: mainApiKeyInput.activeFocus ? Theme.primary : Theme.border
                        border.width: 1
                    }
                }
            }

            // Model
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingSM

                Text {
                    text: qsTr("Model:")
                    color: Theme.onSurface
                    font.pixelSize: Theme.fontSM
                    font.family: Theme.fontFamily
                    Layout.preferredWidth: 70
                }

                TextField {
                    id: mainModelInput
                    Layout.fillWidth: true
                    text: appConfig ? appConfig.get_llm_model() : ""
                    font.pixelSize: Theme.fontSM
                    placeholderText: qsTr("留空使用默认模型")
                    background: Rectangle {
                        color: Theme.background
                        radius: Theme.radiusSM
                        border.color: mainModelInput.activeFocus ? Theme.primary : Theme.border
                        border.width: 1
                    }
                }
            }

            // Compile price per 1k tokens
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingSM

                Text {
                    text: qsTr("价格/1K:")
                    color: Theme.onSurface
                    font.pixelSize: Theme.fontSM
                    font.family: Theme.fontFamily
                    Layout.preferredWidth: 70
                }

                TextField {
                    id: compilePriceInput
                    Layout.fillWidth: true
                    text: appConfig ? appConfig.get_compile_price_per_1k().toString() : "0.03"
                    font.pixelSize: Theme.fontSM
                    placeholderText: qsTr("0.03")
                    validator: DoubleValidator { bottom: 0; decimals: 6 }
                    background: Rectangle {
                        color: Theme.background
                        radius: Theme.radiusSM
                        border.color: compilePriceInput.activeFocus ? Theme.primary : Theme.border
                        border.width: 1
                    }
                }

                Text {
                    text: qsTr("$")
                    color: Theme.onSurfaceVariant
                    font.pixelSize: Theme.fontXS
                }
            }
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.divider
        }

        // ── 使用同一模型 checkbox ──
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingSM

            Rectangle {
                width: 18
                height: 18
                radius: 4
                color: modelConfigDialog.useSameModel ? Theme.primary : "transparent"
                border.color: modelConfigDialog.useSameModel ? Theme.primary : Theme.border
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: Icons.accept
                    color: Theme.onPrimary
                    font.pixelSize: Theme.fontSM
                    visible: modelConfigDialog.useSameModel
                }

                TapHandler {
                    onTapped: modelConfigDialog.useSameModel = !modelConfigDialog.useSameModel
                }
            }

            Text {
                text: qsTr("测试模型与编译模型相同")
                color: Theme.onSurface
                font.pixelSize: Theme.fontSM
                font.family: Theme.fontFamily

                TapHandler {
                    onTapped: modelConfigDialog.useSameModel = !modelConfigDialog.useSameModel
                }
            }
        }

        // ── 测试模型 ──
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingSM
            visible: !modelConfigDialog.useSameModel
            opacity: modelConfigDialog.useSameModel ? 0.4 : 1.0

            Behavior on opacity { enabled: !Theme.animReducedMotion; NumberAnimation { duration: Theme.animFast } }

            Text {
                text: qsTr("测试模型")
                color: Theme.accent
                font.pixelSize: Theme.fontSM
                font.bold: true
                font.family: Theme.fontFamily
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingSM

                Text {
                    text: qsTr("Provider:")
                    color: Theme.onSurface
                    font.pixelSize: Theme.fontSM
                    font.family: Theme.fontFamily
                    Layout.preferredWidth: 70
                }

                ComboBox {
                    id: testProviderCombo
                    Layout.fillWidth: true
                    model: modelConfigDialog.providers
                    currentIndex: {
                        if (!appConfig) return 0
                        var p = appConfig.get_test_provider()
                        var idx = modelConfigDialog.providers.indexOf(p)
                        return idx >= 0 ? idx : 0
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingSM

                Text {
                    text: qsTr("API Key:")
                    color: Theme.onSurface
                    font.pixelSize: Theme.fontSM
                    font.family: Theme.fontFamily
                    Layout.preferredWidth: 70
                }

                TextField {
                    id: testApiKeyInput
                    Layout.fillWidth: true
                    text: appConfig ? appConfig.get_test_api_key() : ""
                    echoMode: TextInput.Password
                    font.pixelSize: Theme.fontSM
                    placeholderText: qsTr("输入 API Key...")
                    background: Rectangle {
                        color: Theme.background
                        radius: Theme.radiusSM
                        border.color: testApiKeyInput.activeFocus ? Theme.primary : Theme.border
                        border.width: 1
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingSM

                Text {
                    text: qsTr("Model:")
                    color: Theme.onSurface
                    font.pixelSize: Theme.fontSM
                    font.family: Theme.fontFamily
                    Layout.preferredWidth: 70
                }

                TextField {
                    id: testModelInput
                    Layout.fillWidth: true
                    text: appConfig ? appConfig.get_test_model() : ""
                    font.pixelSize: Theme.fontSM
                    placeholderText: qsTr("留空使用默认模型")
                    background: Rectangle {
                        color: Theme.background
                        radius: Theme.radiusSM
                        border.color: testModelInput.activeFocus ? Theme.primary : Theme.border
                        border.width: 1
                    }
                }
            }

            // Test price per 1k tokens
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingSM

                Text {
                    text: qsTr("价格/1K:")
                    color: Theme.onSurface
                    font.pixelSize: Theme.fontSM
                    font.family: Theme.fontFamily
                    Layout.preferredWidth: 70
                }

                TextField {
                    id: testPriceInput
                    Layout.fillWidth: true
                    text: appConfig ? appConfig.get_test_price_per_1k().toString() : "0.01"
                    font.pixelSize: Theme.fontSM
                    placeholderText: qsTr("0.01")
                    validator: DoubleValidator { bottom: 0; decimals: 6 }
                    background: Rectangle {
                        color: Theme.background
                        radius: Theme.radiusSM
                        border.color: testPriceInput.activeFocus ? Theme.primary : Theme.border
                        border.width: 1
                    }
                }

                Text {
                    text: qsTr("$")
                    color: Theme.onSurfaceVariant
                    font.pixelSize: Theme.fontXS
                }
            }
        }

        Item { Layout.fillHeight: true }

        // Buttons
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingSM

            Item { Layout.fillWidth: true }

            Rectangle {
                width: 80
                height: Theme.heightSM
                radius: Theme.radiusSM
                color: Theme.surfaceVariant

                Text {
                    anchors.centerIn: parent
                    text: qsTr("取消")
                    color: Theme.onSurface
                    font.pixelSize: Theme.fontSM
                    font.family: Theme.fontFamily
                }

                HoverHandler { }
                TapHandler { onTapped: modelConfigDialog.close() }
            }

            Rectangle {
                width: 80
                height: Theme.heightSM
                radius: Theme.radiusSM
                color: saveBtnHover.hovered ? Theme.primary : Theme.primaryMuted

                Text {
                    anchors.centerIn: parent
                    text: qsTr("保存")
                    color: saveBtnHover.hovered ? Theme.onPrimary : Theme.primary
                    font.pixelSize: Theme.fontSM
                    font.bold: true
                    font.family: Theme.fontFamily
                }

                HoverHandler { id: saveBtnHover }
                TapHandler {
                    onTapped: {
                        if (!appConfig) return
                        // Save main model config
                        var mainProvider = modelConfigDialog.providers[mainProviderCombo.currentIndex]
                        appConfig.set_llm_config(
                            mainProvider,
                            mainApiKeyInput.text,
                            mainModelInput.text,
                            ""  // api_base - empty for default
                        )
                        // Save compile price
                        var compilePrice = parseFloat(compilePriceInput.text)
                        if (!isNaN(compilePrice) && compilePrice >= 0) {
                            appConfig.set_compile_price(compilePrice)
                        }
                        // Save same-model flag
                        appConfig.useSameModel = modelConfigDialog.useSameModel
                        // Save test model config if different
                        if (!modelConfigDialog.useSameModel) {
                            var testProvider = modelConfigDialog.providers[testProviderCombo.currentIndex]
                            appConfig.setTestConfig(
                                testProvider,
                                testApiKeyInput.text,
                                testModelInput.text,
                                ""  // api_base - empty for default
                            )
                        }
                        // Save test price
                        var testPrice = parseFloat(testPriceInput.text)
                        if (!isNaN(testPrice) && testPrice >= 0) {
                            appConfig.set_test_price(testPrice)
                        }
                        modelConfigDialog.close()
                    }
                }

                Behavior on color { enabled: !Theme.animReducedMotion; ColorAnimation { duration: Theme.animFast } }
            }
        }
    }
}
