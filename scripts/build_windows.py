"""PromptBlocks Windows 安装包构建脚本

1. 调用 PyInstaller 生成 dist/PromptBlocks/ 目录
2. 使用 NSIS 创建安装包（如果 NSIS 可用）
3. 如果 NSIS 不可用，仅生成 PyInstaller 输出
"""

import shutil
import subprocess
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
DIST_DIR = PROJECT_ROOT / "dist"
APP_DIST_DIR = DIST_DIR / "PromptBlocks"
NSIS_SCRIPT = PROJECT_ROOT / "installer" / "promptblocks_installer.nsi"
INSTALLER_OUTPUT = DIST_DIR / "PromptBlocks_Setup.exe"


def check_nsis() -> str | None:
    """检查 NSIS 是否已安装，返回 makensis 路径或 None。"""
    # 常见 NSIS 安装路径
    common_paths = [
        r"C:\Program Files (x86)\NSIS\makensis.exe",
        r"C:\Program Files\NSIS\makensis.exe",
    ]
    for path in common_paths:
        if Path(path).exists():
            return path

    # 尝试从 PATH 中查找
    try:
        result = subprocess.run(
            ["makensis", "/version"],
            capture_output=True,
            text=True,
            timeout=10,
        )
        if result.returncode == 0:
            return "makensis"
    except (FileNotFoundError, subprocess.TimeoutExpired):
        pass

    return None


def build_pyinstaller() -> None:
    """调用 PyInstaller 打包。"""
    print("=" * 60)
    print("步骤 1: 调用 PyInstaller 打包")
    print("=" * 60)

    build_script = PROJECT_ROOT / "scripts" / "build.py"
    subprocess.check_call(
        [sys.executable, str(build_script), "--spec"],
        cwd=str(PROJECT_ROOT),
    )

    if not APP_DIST_DIR.exists():
        print(f"错误: PyInstaller 输出目录不存在 {APP_DIST_DIR}")
        sys.exit(1)

    print(f"PyInstaller 打包完成: {APP_DIST_DIR}")


def prepare_installer_files() -> None:
    """准备安装包所需的额外文件。"""
    # 复制 alembic.ini 到 dist 目录（如果存在）
    alembic_ini = PROJECT_ROOT / "alembic.ini"
    if alembic_ini.exists():
        dest = APP_DIST_DIR / "alembic.ini"
        shutil.copy2(alembic_ini, dest)
        print(f"已复制 alembic.ini -> {dest}")


def build_nsis_installer(makensis_path: str) -> None:
    """使用 NSIS 创建安装包。"""
    print("\n" + "=" * 60)
    print("步骤 2: 使用 NSIS 创建安装包")
    print("=" * 60)

    if not NSIS_SCRIPT.exists():
        print(f"错误: NSIS 脚本不存在 {NSIS_SCRIPT}")
        sys.exit(1)

    cmd = [makensis_path, str(NSIS_SCRIPT)]
    print(f"运行: {' '.join(cmd)}")
    subprocess.check_call(cmd, cwd=str(PROJECT_ROOT))

    if INSTALLER_OUTPUT.exists():
        print(f"\n安装包创建成功: {INSTALLER_OUTPUT}")
    else:
        print("\n警告: NSIS 运行完成但未找到安装包输出")


def main() -> None:
    """主入口：构建 Windows 安装包。"""
    # 步骤 1: PyInstaller 打包
    build_pyinstaller()

    # 步骤 1.5: 准备额外文件
    prepare_installer_files()

    # 步骤 2: NSIS 安装包（如果可用）
    makensis_path = check_nsis()
    if makensis_path:
        build_nsis_installer(makensis_path)
    else:
        print("\n" + "=" * 60)
        print("NSIS 未安装，跳过安装包创建")
        print("如需创建安装包，请安装 NSIS: https://nsis.sourceforge.io/")
        print(f"PyInstaller 输出位于: {APP_DIST_DIR}")
        print("=" * 60)


if __name__ == "__main__":
    main()
