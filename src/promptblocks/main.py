"""PromptBlocks application entry point."""

import os
import sys
import traceback

# Force UTF-8 mode before any imports that may read text files (e.g. litellm)
os.environ["PYTHONUTF8"] = "1"

# Set tiktoken cache to user's AppData directory (writable in packaged environments)
if sys.platform == "win32":
    _tiktoken_cache = os.path.join(os.environ.get("LOCALAPPDATA", os.path.expanduser("~")), "tiktoken_cache")
    os.environ.setdefault("TIKTOKEN_CACHE_DIR", _tiktoken_cache)


def _hide_console() -> None:
    """Hide the console window on Windows.

    We use PyInstaller's ``run.exe`` bootloader (console=True) instead of
    ``runw.exe`` because ``runw.exe`` resolves ``sys._MEIPASS`` via ANSI
    APIs, which corrupts non-ASCII (Chinese) characters in the install path.
    Hiding the console after startup gives us the best of both worlds:
    correct Unicode path handling *and* no visible console window.
    """
    if sys.platform != "win32":
        return
    try:
        import ctypes
        hwnd = ctypes.windll.kernel32.GetConsoleWindow()
        if hwnd:
            ctypes.windll.user32.ShowWindow(hwnd, 0)  # SW_HIDE
    except Exception:
        pass


from promptblocks.app import PromptBlocksApp


def main() -> int:
    _hide_console()
    try:
        app = PromptBlocksApp(sys.argv)
        return app.run()
    except Exception:
        # In console-less mode, write the traceback to a log file for diagnosis.
        tb = traceback.format_exc()
        if sys.stderr:
            sys.stderr.write(tb)
        log_path = os.path.join(os.path.expanduser("~"), "PromptBlocks_crash.log")
        with open(log_path, "w", encoding="utf-8") as f:
            f.write(tb)
        return 1


if __name__ == "__main__":
    sys.exit(main())
