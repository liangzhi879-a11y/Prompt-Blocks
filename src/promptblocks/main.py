"""PromptBlocks application entry point."""

import os
import sys
import traceback

# ─ Hide console window immediately on Windows ─────────────────────────────
# We use PyInstaller's ``run.exe`` bootloader (console=True) because the
# ``runw.exe`` bootloader resolves ``sys._MEIPASS`` via ANSI Win32 APIs,
# which corrupts non-ASCII (Chinese) characters in the install path.
# Hiding the console as early as possible minimises the visible flash.
if sys.platform == "win32":
    try:
        import ctypes
        _hwnd = ctypes.windll.kernel32.GetConsoleWindow()
        if _hwnd:
            ctypes.windll.user32.ShowWindow(_hwnd, 0)  # SW_HIDE
    except Exception:
        pass

# Force UTF-8 mode before any imports that may read text files (e.g. litellm)
os.environ["PYTHONUTF8"] = "1"

# Set tiktoken cache to user's AppData directory (writable in packaged environments)
if sys.platform == "win32":
    _tiktoken_cache = os.path.join(
        os.environ.get("LOCALAPPDATA", os.path.expanduser("~")),
        "tiktoken_cache",
    )
    os.environ.setdefault("TIKTOKEN_CACHE_DIR", _tiktoken_cache)


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
