import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "views"
import "components"

ApplicationWindow {
    id: root
    title: "PromptBlocks"
    width: 1280
    height: 800
    minimumWidth: 960
    minimumHeight: 600
    visible: true
    flags: Qt.FramelessWindowHint | Qt.Window
    color: Theme.surface

    // ── Global default font ──
    // IMPORTANT: do NOT set font.family here. The application's default font
    // (set in app.py via QFont.setFamilies(["Segoe UI", "Phosphor", ...]))
    // is inherited by all child controls and gives us per-character font
    // fallback. This means Phosphor icons (PUA range) render correctly even
    // when mixed with regular Chinese/English text.

    property bool llmConfigured: appConfig ? appConfig.isLLMConfigured : false

    // ── Content shell ──
    // Window shadow is provided by Windows DWM via the WS_THICKFRAME
    // approach in app.py's _enable_dwm_shadow(). The window style is
    // set to WS_THICKFRAME | WS_CAPTION, and WM_NCCALCSIZE removes
    // the title bar while keeping the frame — so DWM draws the shadow
    // automatically outside the window geometry.
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        TitleBar {
            id: titleBar
            Layout.fillWidth: true
            title: "PromptBlocks"
            isMaximized: root.visibility === Window.Maximized
            onMinimizeRequested: root.showMinimized()
            onMaximizeRequested: {
                if (root.visibility === Window.Maximized) {
                    root.showNormal()
                } else {
                    root.showMaximized()
                }
            }
            onCloseRequested: Qt.quit()
        }

        StackView {
            id: mainStack
            Layout.fillWidth: true
            Layout.fillHeight: true
            initialItem: llmConfigured ? mainView : setupWizard

            replaceEnter: Transition {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.animNormal; easing.type: Theme.animEasing }
            }
            replaceExit: Transition {
                NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.animFast; easing.type: Easing.InQuad }
            }
        }
    }

    // ── Window edge resize ──
    // Resize is handled by the Win32 WM_NCHITTEST subclass in app.py,
    // which tells the system to manage resize borders natively.
    // The QML resizeArea is no longer needed.

    Component {
        id: mainView
        MainView {}
    }

    Component {
        id: setupWizard
        SetupWizard {
            onFinished: {
                mainStack.replace(mainView)
            }
        }
    }
}
