"""PromptBlocks application entry point."""

import os
import sys
import traceback

# Force UTF-8 mode before any imports that may read text files (e.g. litellm)
os.environ["PYTHONUTF8"] = "1"

# Set tiktoken cache to user's AppData directory (writable in packaged environments)
if sys.platform == "win32":
    _tiktoken_cache = os.path.join(
        os.environ.get("LOCALAPPDATA", os.path.expanduser("~")),
        "tiktoken_cache",
    )
    os.environ.setdefault("TIKTOKEN_CACHE_DIR", _tiktoken_cache)


def _fix_frozen_path() -> None:
    """Fix ``sys._MEIPASS`` encoding when using the runw.exe bootloader.

    PyInstaller's ``runw.exe`` bootloader resolves the application directory
    via ANSI Win32 APIs (``GetModuleFileNameA``), which corrupts non-ASCII
    characters (e.g. Chinese) in the install path.  ``run.exe`` uses the
    Unicode variant and works correctly, but shows a console window.

    This function re-resolves the path using the Unicode API
    (``GetModuleFileNameW``) and patches ``sys._MEIPASS`` /
    ``sys.executable`` so that all subsequent ``Path(__file__)`` lookups
    work correctly.  This allows us to use ``console=False`` (runw.exe)
    for a clean, no-console startup experience.
    """
    if not getattr(sys, "frozen", False):
        return
    if sys.platform != "win32":
        return
    try:
        import ctypes
        buf = ctypes.create_unicode_buffer(512)
        ctypes.windll.kernel32.GetModuleFileNameW(None, buf, 512)
        real_exe = buf.value
        # _MEIPASS points to the _internal subdirectory next to the EXE
        real_meipass = os.path.join(os.path.dirname(real_exe), "_internal")
        # Patch _MEIPASS to the correct Unicode path
        if hasattr(sys, "_MEIPASS"):
            sys._MEIPASS = real_meipass
        # Also fix sys.executable for consistency
        sys.executable = real_exe
    except Exception:
        pass


# Fix Unicode path before any imports that rely on sys._MEIPASS
_fix_frozen_path()

from promptblocks.app import PromptBlocksApp


def main() -> int:
    try:
        app = PromptBlocksApp(sys.argv)
        return app.run()
    except Exception:
        tb = traceback.format_exc()
        if sys.stderr:
            sys.stderr.write(tb)
        # Write crash log
        log_path = os.path.join(os.path.expanduser("~"), "PromptBlocks_crash.log")
        with open(log_path, "w", encoding="utf-8") as f:
            f.write(tb)
        # Show error dialog so the user knows something went wrong
        try:
            from PySide6.QtWidgets import QApplication, QMessageBox
            _app = QApplication.instance() or QApplication(sys.argv)
            msg = QMessageBox()
            msg.setIcon(QMessageBox.Critical)
            msg.setWindowTitle("PromptBlocks - 启动失败")
            msg.setText("PromptBlocks 启动时发生错误，程序将退出。")
            msg.setInformativeText(f"错误日志已保存至：{log_path}")
            msg.setDetailedText(tb)
            msg.exec()
        except Exception:
            pass
        return 1


if __name__ == "__main__":
    sys.exit(main())
