"""PromptBlocks 桌面应用打包脚本

使用 PyInstaller 将 PySide6 + QML 应用打包为独立可执行文件。
支持通过命令行参数选择使用 spec 文件或命令行参数打包。
"""

import subprocess
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
SPEC_FILE = PROJECT_ROOT / "PromptBlocks.spec"


def check_pyinstaller() -> None:
    """检查 PyInstaller 是否已安装，未安装则自动安装。"""
    try:
        import PyInstaller  # noqa: F401
    except ImportError:
        print("PyInstaller 未安装，正在安装...")
        subprocess.check_call(
            [sys.executable, "-m", "pip", "install", "pyinstaller"]
        )


def build_with_spec() -> None:
    """使用 spec 文件打包，提供更精细的控制。"""
    if not SPEC_FILE.exists():
        print(f"错误: 未找到 spec 文件 {SPEC_FILE}")
        sys.exit(1)
    print(f"使用 spec 文件打包: {SPEC_FILE}")
    subprocess.check_call(
        [sys.executable, "-m", "PyInstaller", "--clean", "--noconfirm", str(SPEC_FILE)],
        cwd=str(PROJECT_ROOT),
    )


def build_with_cli() -> None:
    """使用命令行参数打包。"""
    src_dir = PROJECT_ROOT / "src" / "promptblocks"
    qml_dir = src_dir / "qml"
    resources_dir = src_dir / "resources"
    icon_path = resources_dir / "icons" / "app.ico"
    entry_point = src_dir / "main.py"

    cmd = [
        sys.executable,
        "-m",
        "PyInstaller",
        "--name",
        "PromptBlocks",
        "--windowed",
        "--noconfirm",
        "--clean",
    ]

    # 图标（如果存在）
    if icon_path.exists():
        cmd.extend(["--icon", str(icon_path)])

    # QML 文件
    cmd.extend(["--add-data", f"{qml_dir};qml"])

    # 资源文件
    if resources_dir.exists():
        cmd.extend(["--add-data", f"{resources_dir};resources"])

    # Alembic 迁移脚本
    alembic_dir = PROJECT_ROOT / "alembic"
    if alembic_dir.exists():
        cmd.extend(["--add-data", f"{alembic_dir};alembic"])

    # 隐式导入
    hidden_imports = [
        "PySide6.QtQml",
        "PySide6.QtQuick",
        "PySide6.QtQuickControls2",
        "PySide6.QtWidgets",
        "PySide6.QtSql",
        "sqlalchemy.dialects.sqlite",
        "alembic",
        "alembic.config",
        "alembic.op",
        "alembic.context",
    ]
    for mod in hidden_imports:
        cmd.extend(["--hidden-import", mod])

    # 排除不需要的模块以减小体积
    excludes = [
        "tkinter",
        "unittest",
        "test",
        "tests",
        "setuptools",
        "pip",
        "wheel",
    ]
    for mod in excludes:
        cmd.extend(["--exclude-module", mod])

    # 入口点
    cmd.append(str(entry_point))

    print("使用命令行参数打包:")
    print(" ".join(cmd))
    subprocess.check_call(cmd, cwd=str(PROJECT_ROOT))


def main() -> None:
    """主入口：解析参数并执行打包。"""
    check_pyinstaller()

    use_spec = "--spec" in sys.argv
    if use_spec:
        build_with_spec()
    else:
        build_with_cli()

    dist_dir = PROJECT_ROOT / "dist" / "PromptBlocks"
    if dist_dir.exists():
        print(f"\n打包成功！输出目录: {dist_dir}")
    else:
        # 单文件模式输出在 dist/ 下
        exe_path = PROJECT_ROOT / "dist" / "PromptBlocks.exe"
        if exe_path.exists():
            print(f"\n打包成功！可执行文件: {exe_path}")
        else:
            print("\n警告: 打包完成但未找到预期输出文件")


if __name__ == "__main__":
    main()
