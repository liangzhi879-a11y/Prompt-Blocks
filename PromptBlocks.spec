# -*- mode: python ; coding: utf-8 -*-
"""PromptBlocks PyInstaller spec 文件

精细控制 PySide6 + QML 应用的打包过程。
包含 QML 插件、资源文件、Alembic 迁移脚本等。
"""

import sys
from pathlib import Path

PROJECT_ROOT = Path(SPECPATH)
SRC_DIR = PROJECT_ROOT / "src" / "promptblocks"
QML_DIR = SRC_DIR / "qml"
RESOURCES_DIR = SRC_DIR / "resources"
ASSETS_DIR = SRC_DIR / "assets"
ALEMBIC_DIR = PROJECT_ROOT / "alembic"
ICON_PATH = PROJECT_ROOT / "logo-design" / "PB-logo-3种尺寸.ico"

block_cipher = None


def collect_qml_files():
    """收集所有 QML 文件。

    在 PyInstaller 中 ``__file__`` 位于 ``_internal/promptblocks/``，
    因此 QML 目录必须放在 ``promptblocks/qml`` 下，
    这样 ``Path(__file__).parent / "qml"`` 才能正确解析。
    """
    datas = []
    if QML_DIR.exists():
        datas.append((str(QML_DIR), "promptblocks/qml"))
    return datas


def collect_resource_files():
    """收集资源文件（图标等）。

    同理，资源目录必须放在 ``promptblocks/resources`` 下，
    与 ``Path(__file__).parent / "resources"`` 保持一致。
    """
    datas = []
    if RESOURCES_DIR.exists():
        datas.append((str(RESOURCES_DIR), "promptblocks/resources"))
    return datas


def collect_alembic_files():
    """收集 Alembic 迁移脚本。"""
    datas = []
    if ALEMBIC_DIR.exists():
        datas.append((str(ALEMBIC_DIR), "alembic"))
    return datas


def collect_assets_files():
    """收集 assets 文件（Phosphor 图标字体等）。

    必须放在 ``promptblocks/assets`` 下，与
    ``Path(__file__).parent / "assets"`` 保持一致，
    否则界面内的 Phosphor 图标字体无法注册，图标显示异常。
    """
    datas = []
    if ASSETS_DIR.exists():
        datas.append((str(ASSETS_DIR), "promptblocks/assets"))
    return datas


def collect_litellm_data():
    """收集 litellm 的数据文件（模型定价、tokenizer、容器端点等）。

    递归收集所有 JSON 文件，但排除：
    - proxy/guardrails 子目录（含特殊字符文件名，且客户端不需要）
    - 文件名含括号等特殊字符的文件（PyInstaller COLLECT 无法处理）
    """
    datas = []
    try:
        import litellm
        litellm_dir = Path(litellm.__file__).parent
        for json_file in litellm_dir.rglob("*.json"):
            rel = json_file.relative_to(litellm_dir)
            # Skip proxy/guardrails (not needed at runtime, has problematic filenames)
            rel_str = str(rel)
            if "guardrails" in rel_str:
                continue
            # Skip filenames with special characters that break PyInstaller COLLECT
            if any(c in json_file.name for c in "()[]{}"):
                continue
            datas.append((str(json_file), str(Path("litellm") / rel.parent)))
    except ImportError:
        pass
    return datas


def collect_pyside6_plugins():
    """收集 PySide6 QML 插件和平台插件。"""
    datas = []
    binaries = []
    try:
        import PySide6

        pyside6_dir = Path(PySide6.__file__).parent

        # QML 插件目录
        qml_plugin_dir = pyside6_dir / "qml"
        if qml_plugin_dir.exists():
            datas.append((str(qml_plugin_dir), "PySide6/qml"))

        # 平台插件
        plugins_dir = pyside6_dir / "plugins"
        if plugins_dir.exists():
            datas.append((str(plugins_dir), "PySide6/plugins"))

        # OpenGL 相关 DLL
        for dll_name in ["opengl32sw.dll", "d3dcompiler_47.dll"]:
            dll_path = pyside6_dir / dll_name
            if dll_path.exists():
                binaries.append((str(dll_path), "."))

    except ImportError:
        pass

    return datas, binaries


# 收集所有数据文件
all_datas = []
all_binaries = []

all_datas.extend(collect_qml_files())
all_datas.extend(collect_resource_files())
all_datas.extend(collect_assets_files())
all_datas.extend(collect_alembic_files())
all_datas.extend(collect_litellm_data())

qml_datas, qml_binaries = collect_pyside6_plugins()
all_datas.extend(qml_datas)
all_binaries.extend(qml_binaries)

# 隐式导入
hiddenimports = [
    "PySide6.QtQml",
    "PySide6.QtQuick",
    "PySide6.QtQuickControls2",
    "PySide6.QtWidgets",
    "PySide6.QtSql",
    "PySide6.QtSvg",
    "PySide6.QtNetwork",
    "sqlalchemy.dialects.sqlite",
    "sqlalchemy.sql.default_comparator",
    "alembic",
    "alembic.config",
    "alembic.op",
    "alembic.context",
    "promptblocks",
    "promptblocks.app",
    "promptblocks.config",
    "promptblocks.db",
    "promptblocks.db.engine",
    "promptblocks.db.models",
    "promptblocks.db.session",
    "promptblocks.db.crud",
    "promptblocks.viewmodels",
    "promptblocks.viewmodels.canvas_viewmodel",
    "promptblocks.viewmodels.test_viewmodel",
    "promptblocks.viewmodels.block_viewmodel",
    "promptblocks.viewmodels.connection_viewmodel",
    "promptblocks.viewmodels.project_viewmodel",
    "promptblocks.compilers",
    "promptblocks.compilers.registry",
    "promptblocks.compilers.guidance_compiler",
    "promptblocks.compilers.schema_compiler",
    "promptblocks.compilers.llm_client",
    "promptblocks.compilers.cache",
    "promptblocks.synthesis",
    "promptblocks.synthesis.synthesizer",
    "promptblocks.synthesis.ir",
    "promptblocks.testing",
    "promptblocks.testing.runner",
    "promptblocks.testing.validator",
    "promptblocks.qmlhelpers",
    "promptblocks.qmlhelpers.code_highlighter",
    # litellm sub-modules not detected by static analysis
    "litellm.litellm_core_utils",
    "litellm.litellm_core_utils.tokenizers",
    # tiktoken plugin for encoding registration
    "tiktoken_ext",
    "tiktoken_ext.openai_public",
]

# 排除不需要的模块
excludes = [
    "tkinter",
    "unittest",
    "test",
    "tests",
    "setuptools",
    "pip",
    "wheel",
    "distutils",
    "lib2to3",
    "pydoc",
    "doctest",
    "xmlrpc",
    "py_compile",
    "compileall",
    "zipimport",
    "winsound",
]

# 图标参数
icon_arg = str(ICON_PATH) if ICON_PATH.exists() else None

a = Analysis(
    [str(SRC_DIR / "main.py")],
    pathex=[str(PROJECT_ROOT / "src")],
    binaries=all_binaries,
    datas=all_datas,
    hiddenimports=hiddenimports,
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=excludes,
    noarchive=False,
    cipher=block_cipher,
)

pyz = PYZ(a.pure, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name="PromptBlocks",
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    console=True,
    icon=icon_arg,
    version="version_info.txt" if (PROJECT_ROOT / "version_info.txt").exists() else None,
)

coll = COLLECT(
    exe,
    a.binaries,
    a.datas,
    strip=False,
    upx=True,
    upx_exclude=[],
    name="PromptBlocks",
)
