"""PromptBlocks 打包验证脚本

验证 PyInstaller 打包后的应用是否完整且可独立运行：
1. 检查 dist/PromptBlocks/ 目录是否存在
2. 检查关键文件是否存在
3. 尝试启动应用并等待 5 秒，检查进程是否在运行
4. 关闭应用进程
5. 输出验证报告
"""

import subprocess
import sys
import time
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
DIST_DIR = PROJECT_ROOT / "dist"
APP_DIST_DIR = DIST_DIR / "PromptBlocks"
APP_EXE = APP_DIST_DIR / "PromptBlocks.exe"

# 需要检查的关键文件
CRITICAL_FILES = [
    "PromptBlocks.exe",
    "qml/main.qml",
    "qml/views/MainView.qml",
    "qml/views/CanvasView.qml",
    "qml/components/BlockItem.qml",
]

# 需要检查的目录
CRITICAL_DIRS = [
    "qml",
    "resources",
]


def check_dist_directory() -> dict:
    """检查 dist/PromptBlocks/ 目录是否存在。"""
    result = {"name": "dist 目录检查", "passed": False, "details": ""}
    if APP_DIST_DIR.exists() and APP_DIST_DIR.is_dir():
        result["passed"] = True
        result["details"] = f"目录存在: {APP_DIST_DIR}"
    else:
        result["details"] = f"目录不存在: {APP_DIST_DIR}"
    return result


def check_critical_files() -> list[dict]:
    """检查关键文件是否存在。"""
    results = []
    for file_path in CRITICAL_FILES:
        full_path = APP_DIST_DIR / file_path
        result = {
            "name": f"文件检查: {file_path}",
            "passed": full_path.exists(),
            "details": f"{'存在' if full_path.exists() else '不存在'}: {full_path}",
        }
        results.append(result)
    return results


def check_critical_dirs() -> list[dict]:
    """检查关键目录是否存在。"""
    results = []
    for dir_path in CRITICAL_DIRS:
        full_path = APP_DIST_DIR / dir_path
        result = {
            "name": f"目录检查: {dir_path}",
            "passed": full_path.exists() and full_path.is_dir(),
            "details": f"{'存在' if full_path.exists() else '不存在'}: {full_path}",
        }
        results.append(result)
    return results


def check_app_launch() -> dict:
    """尝试启动应用并验证进程是否在运行。"""
    result = {"name": "应用启动检查", "passed": False, "details": ""}

    if not APP_EXE.exists():
        result["details"] = f"可执行文件不存在: {APP_EXE}"
        return result

    try:
        # 启动应用
        proc = subprocess.Popen(
            [str(APP_EXE)],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            creationflags=subprocess.CREATE_NEW_PROCESS_GROUP,  # Windows 特有
        )

        # 等待 5 秒
        time.sleep(5)

        # 检查进程是否仍在运行
        poll_result = proc.poll()
        if poll_result is None:
            result["passed"] = True
            result["details"] = f"应用成功启动并运行 (PID: {proc.pid})"
            # 关闭应用
            proc.terminate()
            try:
                proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                proc.kill()
                proc.wait()
        else:
            result["details"] = f"应用启动后退出，退出码: {poll_result}"

    except FileNotFoundError:
        result["details"] = f"无法启动应用: {APP_EXE} 未找到"
    except OSError as e:
        result["details"] = f"启动应用时出错: {e}"

    return result


def print_report(results: list[dict]) -> None:
    """输出验证报告。"""
    print("\n" + "=" * 60)
    print("PromptBlocks 打包验证报告")
    print("=" * 60)

    passed = sum(1 for r in results if r["passed"])
    total = len(results)

    for r in results:
        status = "✓ 通过" if r["passed"] else "✗ 失败"
        print(f"  {status} | {r['name']}")
        if r["details"]:
            print(f"         {r['details']}")

    print("-" * 60)
    print(f"结果: {passed}/{total} 通过")
    print("=" * 60)

    if passed < total:
        print("\n部分检查未通过，请检查上方详细信息。")
    else:
        print("\n所有检查通过！打包后的应用可以独立运行。")


def main() -> None:
    """主入口：执行所有验证步骤。"""
    results = []

    # 1. 检查 dist 目录
    results.append(check_dist_directory())

    if not APP_DIST_DIR.exists():
        # 如果 dist 目录不存在，直接报告失败
        results.extend([
            {"name": "文件检查", "passed": False, "details": "跳过（dist 目录不存在）"},
            {"name": "目录检查", "passed": False, "details": "跳过（dist 目录不存在）"},
            {"name": "应用启动检查", "passed": False, "details": "跳过（dist 目录不存在）"},
        ])
        print_report(results)
        sys.exit(1)

    # 2. 检查关键文件
    results.extend(check_critical_files())

    # 3. 检查关键目录
    results.extend(check_critical_dirs())

    # 4. 尝试启动应用
    results.append(check_app_launch())

    # 5. 输出报告
    print_report(results)

    # 如果有失败项，返回非零退出码
    if any(not r["passed"] for r in results):
        sys.exit(1)


if __name__ == "__main__":
    main()
