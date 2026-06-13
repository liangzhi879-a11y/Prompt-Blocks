; PromptBlocks Windows 安装脚本 (NSIS)
; 使用 NSIS 创建 Windows 安装包

!define APP_NAME "PromptBlocks"
!define APP_VERSION "0.1.0"
!define APP_PUBLISHER "PromptBlocks"
!define APP_URL "https://github.com/promptblocks/promptblocks"
!define APP_EXE "PromptBlocks.exe"
!define APP_REG_KEY "Software\PromptBlocks"
!define APP_UNINSTALL_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\PromptBlocks"
!define APP_FILE_EXT ".pbproj"

; 包含现代 UI
!include "MUI2.nsh"

; 安装程序属性
Name "${APP_NAME} ${APP_VERSION}"
OutFile "..\dist\PromptBlocks_Setup.exe"
InstallDir "$PROGRAMFILES\${APP_NAME}"
InstallDirRegKey HKLM "${APP_REG_KEY}" "InstallDir"
RequestExecutionLevel admin

; 界面设置
!define MUI_ABORTWARNING
!define MUI_ICON "..\src\promptblocks\resources\icons\app.ico"
!define MUI_UNICON "..\src\promptblocks\resources\icons\app.ico"

; 页面
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "..\LICENSE"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

; 卸载页面
!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

; 语言
!insertmacro MUI_LANGUAGE "SimpChinese"
!insertmacro MUI_LANGUAGE "English"

Section "MainSection" SEC01
    SetOutPath "$INSTDIR"
    SetOverwrite ifnewer

    ; 复制 PyInstaller 输出的所有文件
    File /r "..\dist\PromptBlocks\*.*"

    ; 创建桌面快捷方式
    CreateShortCut "$DESKTOP\${APP_NAME}.lnk" "$INSTDIR\${APP_EXE}" "" "$INSTDIR\${APP_EXE}" 0

    ; 创建开始菜单快捷方式
    CreateDirectory "$SMPROGRAMS\${APP_NAME}"
    CreateShortCut "$SMPROGRAMS\${APP_NAME}\${APP_NAME}.lnk" "$INSTDIR\${APP_EXE}" "" "$INSTDIR\${APP_EXE}" 0
    CreateShortCut "$SMPROGRAMS\${APP_NAME}\卸载 ${APP_NAME}.lnk" "$INSTDIR\uninstall.exe" "" "" 0

SectionEnd

Section "AssociateFiles" SEC02
    ; 关联 .pbproj 文件类型
    WriteRegStr HKCR "${APP_FILE_EXT}" "" "${APP_NAME}.Project"
    WriteRegStr HKCR "${APP_NAME}.Project" "" "PromptBlocks Project File"
    WriteRegStr HKCR "${APP_NAME}.Project\DefaultIcon" "" "$INSTDIR\${APP_EXE},0"
    WriteRegStr HKCR "${APP_NAME}.Project\shell\open\command" "" '"$INSTDIR\${APP_EXE}" "%1"'
SectionEnd

Section -Post
    ; 写入注册表
    WriteRegStr HKLM "${APP_REG_KEY}" "InstallDir" "$INSTDIR"
    WriteRegStr HKLM "${APP_UNINSTALL_KEY}" "DisplayName" "${APP_NAME}"
    WriteRegStr HKLM "${APP_UNINSTALL_KEY}" "UninstallString" '"$INSTDIR\uninstall.exe"'
    WriteRegStr HKLM "${APP_UNINSTALL_KEY}" "DisplayVersion" "${APP_VERSION}"
    WriteRegStr HKLM "${APP_UNINSTALL_KEY}" "Publisher" "${APP_PUBLISHER}"
    WriteRegStr HKLM "${APP_UNINSTALL_KEY}" "URLInfoAbout" "${APP_URL}"
    WriteRegDWORD HKLM "${APP_UNINSTALL_KEY}" "NoModify" 1
    WriteRegDWORD HKLM "${APP_UNINSTALL_KEY}" "NoRepair" 1

    ; 创建卸载程序
    WriteUninstaller "$INSTDIR\uninstall.exe"
SectionEnd

Section Uninstall
    ; 删除文件
    RMDir /r "$INSTDIR"

    ; 删除快捷方式
    Delete "$DESKTOP\${APP_NAME}.lnk"
    RMDir /r "$SMPROGRAMS\${APP_NAME}"

    ; 删除注册表
    DeleteRegKey HKLM "${APP_UNINSTALL_KEY}"
    DeleteRegKey HKLM "${APP_REG_KEY}"
    DeleteRegKey HKCR "${APP_NAME}.Project"
    DeleteRegValue HKCR "${APP_FILE_EXT}" ""

SectionEnd
