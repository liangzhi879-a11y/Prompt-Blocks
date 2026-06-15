"""PromptBlocks application class managing QApplication and QML engine."""

import os
import time
from pathlib import Path

from PySide6.QtCore import QUrl, Qt
from PySide6.QtGui import QFont, QFontDatabase, QIcon, QPainter, QPixmap, QColor
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtWidgets import QApplication


class PromptBlocksApp:
    """Main application class that initializes and runs the PromptBlocks desktop app."""

    def __init__(self, argv: list[str]) -> None:
        _t0 = time.perf_counter()

        # Force UTF-8 mode for litellm JSON loading in packaged environments
        os.environ["PYTHONUTF8"] = "1"

        # Basic style — full customization (Fluent Design via Theme.qml)
        os.environ.setdefault("QT_QUICK_CONTROLS_STYLE", "Basic")
        # Enable QML disk cache for faster subsequent launches.
        # During development, clear cache manually if QML changes aren't picked up.
        os.environ.pop("QML_DISABLE_DISK_CACHE", None)
        self._app = QApplication(argv)
        self._app.setApplicationName("PromptBlocks")
        self._app.setOrganizationName("PromptBlocks")
        self._app.setWindowIcon(self._create_app_icon())

        # ── Register Phosphor icon font ──
        _assets_dir = Path(__file__).parent / "assets" / "fonts"
        for _ttf_name in ("Phosphor-Regular.ttf", "Phosphor-Bold.ttf", "Phosphor-Fill.ttf"):
            _ttf_path = _assets_dir / _ttf_name
            if _ttf_path.exists():
                _id = QFontDatabase.addApplicationFont(str(_ttf_path))
                if _id < 0:
                    print(f"[warn] Failed to register {_ttf_name}", flush=True)

        # Global sans-serif default font
        default_font = QFont()
        default_font.setFamilies(["Segoe UI", "Phosphor", "Microsoft YaHei", "sans-serif"])
        default_font.setPixelSize(14)
        self._app.setFont(default_font)

        # Install Qt message handler AFTER QApplication to capture QML console.log
        from PySide6.QtCore import qInstallMessageHandler
        import sys as _sys
        def _qt_handler(mode, ctx, msg):
            if _sys.stderr:
                _sys.stderr.write(f"[Qt] {msg}\n")
                _sys.stderr.flush()
        qInstallMessageHandler(_qt_handler)
        self._qt_handler = _qt_handler  # prevent GC

        self._engine = QQmlApplicationEngine()

        # ── Lazy imports: defer heavy module loading until needed ──
        # Models and ViewModels are imported here (inside __init__) rather
        # than at module top-level so that `python -c "import promptblocks"`
        # doesn't pull in litellm / sqlalchemy / the entire codebase.
        from promptblocks.config import AppConfig
        from promptblocks.models.module_card_model import ModuleCardModel
        from promptblocks.models.variable_model import VariableModel
        from promptblocks.models.knowledge_model import KnowledgeModel
        from promptblocks.models.tool_model import ToolModel
        from promptblocks.processors.pipeline_processor import PipelineProcessor
        from promptblocks.undo.undo_stack import UndoManager
        from promptblocks.qmlhelpers.syntax_checker import SyntaxChecker

        # Create models (QAbstractListModel-based)
        self._module_card_model = ModuleCardModel()
        self._variable_model = VariableModel()
        self._knowledge_model = KnowledgeModel()
        self._tool_model = ToolModel()

        # Create undo manager, pipeline processor, syntax checker
        self._undo_manager = UndoManager()
        self._pipeline_processor = PipelineProcessor()
        self._syntax_checker = SyntaxChecker()

        # Create config (lightweight, no heavy deps)
        self._config = AppConfig()

        # Defer heavy ViewModel creation — these import litellm etc.
        from promptblocks.viewmodels.editor_viewmodel import EditorViewModel
        from promptblocks.viewmodels.test_viewmodel import TestViewModel
        from promptblocks.viewmodels.single_turn_viewmodel import SingleTurnViewModel
        from promptblocks.viewmodels.project_viewmodel import ProjectViewModel
        from promptblocks.viewmodels.block_viewmodel import BlockViewModel
        from promptblocks.viewmodels.version_viewmodel import VersionViewModel
        from promptblocks.viewmodels.export_viewmodel import ExportViewModel
        from promptblocks.viewmodels.import_viewmodel import ImportViewModel
        from promptblocks.viewmodels.optimizer_viewmodel import PromptOptimizer

        self._editor_viewmodel = EditorViewModel(
            app_config=self._config,
            module_card_model=self._module_card_model,
            variable_model=self._variable_model,
            knowledge_model=self._knowledge_model,
            tool_model=self._tool_model,
        )
        self._test_viewmodel = TestViewModel(app_config=self._config)
        self._single_turn_viewmodel = SingleTurnViewModel(app_config=self._config)
        self._project_viewmodel = ProjectViewModel()
        self._block_viewmodel = BlockViewModel()
        self._version_viewmodel = VersionViewModel()
        self._export_viewmodel = ExportViewModel()
        self._import_viewmodel = ImportViewModel()
        self._optimizer_viewmodel = PromptOptimizer(app_config=self._config)

        _t1 = time.perf_counter()
        print(f"[perf] PromptBlocksApp.__init__ took {_t1 - _t0:.2f}s", flush=True)

    def _create_app_icon(self) -> QIcon:
        """Load the brand icon for taskbar, Alt+Tab, and window title.

        Priority: bundled ICO -> dev SVG -> programmatic fallback.
        """
        # Priority 1: bundled ICO (works in both dev and PyInstaller EXE)
        ico_path = Path(__file__).parent / "resources" / "icons" / "app.ico"
        icon = QIcon(str(ico_path.resolve()))
        if not icon.isNull():
            return icon

        # Priority 2: project-root SVG (dev only, skip if path contains non-ASCII)
        svg_path = Path(__file__).parent.parent.parent / "logo-design" / "PB-logo.svg"
        try:
            svg_str = str(svg_path.resolve())
            if svg_str.isascii():
                icon = QIcon(svg_str)
                if not icon.isNull():
                    return icon
        except Exception:
            pass

        # Fallback: programmatic icon
        sizes = [16, 24, 32, 48, 64, 128, 256]
        icon = QIcon()
        bg_color = QColor("#0E3A5C")
        fg_color = QColor("#F9F9F9")

        for size in sizes:
            pixmap = QPixmap(size, size)
            pixmap.fill(Qt.transparent)

            painter = QPainter(pixmap)
            painter.setRenderHint(QPainter.Antialiasing, True)

            painter.setBrush(bg_color)
            painter.setPen(Qt.NoPen)
            corner_radius = max(2, size // 8)
            painter.drawRoundedRect(0, 0, size, size, corner_radius, corner_radius)

            font = painter.font()
            font.setFamilies(["Segoe UI", "Segoe UI Symbol", "Microsoft YaHei", "sans-serif"])
            font.setPixelSize(max(8, int(size * 0.6)))
            font.setBold(True)
            painter.setFont(font)
            painter.setPen(fg_color)
            painter.drawText(pixmap.rect(), Qt.AlignCenter, "PB")

            painter.end()
            icon.addPixmap(pixmap)

        return icon

    def run(self) -> int:
        """Initialize database, check config, load QML, and run the event loop."""
        _t0 = time.perf_counter()

        # Step 1: Initialize database (auto-migrate)
        from promptblocks.db.engine import init_db
        init_db()
        _t1 = time.perf_counter()
        print(f"[perf] init_db took {_t1 - _t0:.2f}s", flush=True)

        # Step 1.5: Ensure a default project exists and set project_id on viewmodels
        self._ensure_default_project()

        # Step 2: Expose models and viewmodels to QML
        ctx = self._engine.rootContext()
        ctx.setContextProperty("appConfig", self._config)
        ctx.setContextProperty("moduleCardModel", self._module_card_model)
        ctx.setContextProperty("variableModel", self._variable_model)
        ctx.setContextProperty("knowledgeModel", self._knowledge_model)
        ctx.setContextProperty("toolModel", self._tool_model)
        ctx.setContextProperty("undoManager", self._undo_manager)
        ctx.setContextProperty("pipelineProcessor", self._pipeline_processor)
        ctx.setContextProperty("syntaxChecker", self._syntax_checker)
        ctx.setContextProperty("editorViewModel", self._editor_viewmodel)
        ctx.setContextProperty("singleTurnViewModel", self._single_turn_viewmodel)
        ctx.setContextProperty("testViewModel", self._test_viewmodel)
        ctx.setContextProperty("projectViewModel", self._project_viewmodel)
        ctx.setContextProperty("blockViewModel", self._block_viewmodel)
        ctx.setContextProperty("versionViewModel", self._version_viewmodel)
        ctx.setContextProperty("exportViewModel", self._export_viewmodel)
        ctx.setContextProperty("importViewModel", self._import_viewmodel)
        ctx.setContextProperty("promptOptimizer", self._optimizer_viewmodel)

        # Expose logo path for QML Image source
        logo_path = Path(__file__).parent.parent.parent / "logo-design" / "PB-logo.svg"
        ctx.setContextProperty("appLogoPath", str(logo_path.resolve()).replace("\\", "/"))

        # Step 3: Add QML import paths for views and components
        qml_dir = Path(__file__).parent / "qml"
        views_dir = qml_dir / "views"
        components_dir = qml_dir / "components"
        self._engine.addImportPath(str(qml_dir))
        self._engine.addImportPath(str(views_dir))
        self._engine.addImportPath(str(components_dir))

        # Step 4: Load main QML
        main_qml = qml_dir / "main.qml"
        self._engine.load(QUrl.fromLocalFile(str(main_qml)))

        if not self._engine.rootObjects():
            from PySide6.QtWidgets import QMessageBox
            QMessageBox.critical(
                None,
                "PromptBlocks - 加载失败",
                f"无法加载 QML 界面文件。\n\n路径：{main_qml}\n\n"
                "请确认 qml 目录已随程序一起分发。",
            )
            return -1

        _t2 = time.perf_counter()
        print(f"[perf] QML load took {_t2 - _t1:.2f}s", flush=True)

        # Enable Windows DWM native shadow for frameless window
        self._enable_dwm_shadow()

        # Ensure threads are stopped cleanly on exit
        self._app.aboutToQuit.connect(self._cleanup_on_exit)

        return self._app.exec()

    def _cleanup_on_exit(self) -> None:
        """Stop all running worker threads before the event loop exits."""
        for vm in (self._test_viewmodel, self._single_turn_viewmodel):
            if hasattr(vm, "stopTests"):
                vm.stopTests()
        if hasattr(self._optimizer_viewmodel, "stopOptimization"):
            self._optimizer_viewmodel.stopOptimization()

    def _ensure_default_project(self) -> None:
        """Ensure a default project exists and set its ID on viewmodels that need it."""
        from promptblocks.db.crud import ProjectCRUD
        from promptblocks.db.session import get_session

        with get_session() as session:
            try:
                projects = ProjectCRUD.get_all(session)
                if projects:
                    project_id = projects[0].id
                else:
                    project = ProjectCRUD.create(session, name="Default Project")
                    session.commit()
                    project_id = project.id
                self._version_viewmodel.setProjectId(project_id)
                self._module_card_model.setProjectId(project_id)
                self._variable_model.setProjectId(project_id)
                self._knowledge_model.setProjectId(project_id)
                self._tool_model.setProjectId(project_id)
                # Load persisted data from DB
                self._module_card_model.loadFromDb()
                self._variable_model.loadFromDb()
                self._knowledge_model.loadFromDb()
                self._tool_model.loadFromDb()
            except Exception:
                session.rollback()

    def _enable_dwm_shadow(self) -> None:
        """Enable Windows DWM native drop shadow for the frameless window.

        Qt.FramelessWindowHint creates a WS_POPUP window, which DWM refuses
        to shadow.  The fix requires THREE steps after the window is created:

          1. Replace WS_POPUP with WS_THICKFRAME | WS_CAPTION — DWM only
             shadows windows that have a frame style.
          2. Call DwmExtendFrameIntoClientArea with MARGINS(-1,-1,-1,-1) —
             this extends the DWM composition frame over the entire client
             area, which is what actually triggers the shadow rendering.
          3. Subclass the window procedure to handle WM_NCCALCSIZE (remove
             the system title bar), WM_NCHITTEST (drag / resize), and
             WM_SIZE (maximize frame fix).
        """
        import sys
        import ctypes
        from ctypes import wintypes

        if sys.platform != "win32":
            return

        try:
            hwnd = None
            for obj in self._engine.rootObjects():
                # rootObjects() returns QQuickWindow instances directly;
                # they have winId() but no window() method.
                if hasattr(obj, 'winId'):
                    hwnd = int(obj.winId())
                    break
            if not hwnd:
                return

            user32 = ctypes.windll.user32
            dwmapi = ctypes.windll.dwmapi

            # Fix ctypes function signatures for 64-bit Windows.
            # GetWindowLongPtrW / CallWindowProcW deal with pointer-sized values,
            # and Get/SetWindowLongW use 32-bit DWORD styles (must be unsigned).
            user32.GetWindowLongPtrW.restype = ctypes.c_void_p
            user32.GetWindowLongPtrW.argtypes = [ctypes.c_void_p, ctypes.c_int]
            user32.SetWindowLongPtrW.restype = ctypes.c_void_p
            user32.SetWindowLongPtrW.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p]
            user32.GetWindowLongW.restype = ctypes.c_uint
            user32.SetWindowLongW.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_uint]
            user32.SetWindowLongW.restype = ctypes.c_uint
            user32.CallWindowProcW.restype = ctypes.c_ssize_t
            user32.CallWindowProcW.argtypes = [
                ctypes.c_void_p, ctypes.c_void_p, ctypes.c_uint,
                ctypes.c_void_p, ctypes.c_void_p,
            ]
            user32.GetWindowRect.argtypes = [ctypes.c_void_p, ctypes.POINTER(wintypes.RECT)]
            user32.MonitorFromWindow.argtypes = [ctypes.c_void_p, ctypes.c_uint]
            user32.MonitorFromWindow.restype = ctypes.c_void_p
            user32.GetMonitorInfoW.argtypes = [ctypes.c_void_p, ctypes.c_void_p]
            user32.GetMonitorInfoW.restype = ctypes.c_bool
            user32.IsZoomed.argtypes = [ctypes.c_void_p]
            user32.IsZoomed.restype = ctypes.c_bool
            user32.SetWindowPos.argtypes = [
                ctypes.c_void_p, ctypes.c_void_p,
                ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int,
                ctypes.c_uint,
            ]

            # ── Step 1: Replace WS_POPUP with WS_THICKFRAME | WS_CAPTION ──
            GWL_STYLE = -16
            WS_THICKFRAME = 0x00040000
            WS_CAPTION = 0x00C00000
            WS_POPUP = 0x80000000
            WS_SYSMENU = 0x00080000
            WS_MINIMIZEBOX = 0x00020000
            WS_MAXIMIZEBOX = 0x00010000
            WS_VISIBLE = 0x10000000
            WS_CLIPSIBLINGS = 0x04000000
            WS_CLIPCHILDREN = 0x02000000

            style = user32.GetWindowLongW(hwnd, GWL_STYLE)
            style &= ~WS_POPUP
            style |= WS_THICKFRAME | WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX | WS_MAXIMIZEBOX
            style |= WS_VISIBLE | WS_CLIPSIBLINGS | WS_CLIPCHILDREN
            user32.SetWindowLongW(hwnd, GWL_STYLE, style)

            # ── Step 2: Extend DWM frame over entire client area ──
            # This is the crucial call that makes DWM draw the shadow.
            # MARGINS(-1) tells DWM "the glass frame covers everything",
            # which triggers shadow rendering around the window.
            class MARGINS(ctypes.Structure):
                _fields_ = [
                    ("cxLeftWidth", ctypes.c_int),
                    ("cxRightWidth", ctypes.c_int),
                    ("cyTopHeight", ctypes.c_int),
                    ("cyBottomHeight", ctypes.c_int),
                ]
            margins = MARGINS(-1, -1, -1, -1)
            hr = dwmapi.DwmExtendFrameIntoClientArea(hwnd, ctypes.byref(margins))
            print(f"[dwm] DwmExtendFrameIntoClientArea returned 0x{hr & 0xFFFFFFFF:08X}", flush=True)

            # ── Step 3: Subclass window procedure ──
            WM_NCCALCSIZE = 0x0083
            WM_NCHITTEST = 0x0084
            WM_SIZE = 0x0005
            HTCAPTION = 2
            HTCLIENT = 1
            HTTOPLEFT = 13
            HTTOP = 12
            HTTOPRIGHT = 14
            HTLEFT = 10
            HTRIGHT = 11
            HTBOTTOMLEFT = 16
            HTBOTTOM = 15
            HTBOTTOMRIGHT = 17
            SIZE_MAXIMIZED = 2

            # Caption height — matches TitleBar height (Theme.heightSM ≈ 40)
            CAPTION_HEIGHT = ctypes.c_int(40)

            GWLP_WNDPROC = -4
            # Use c_ssize_t (intptr_t) instead of c_long for 64-bit compatibility
            WNDPROC = ctypes.WINFUNCTYPE(
                ctypes.c_ssize_t, ctypes.c_void_p, ctypes.c_uint,
                ctypes.c_void_p, ctypes.c_void_p,
            )

            original_wndproc = ctypes.c_ssize_t(
                user32.GetWindowLongPtrW(hwnd, GWLP_WNDPROC)
            ).value

            @WNDPROC
            def subclass_proc(hWnd, uMsg, wParam, lParam):
                # WM_NCCALCSIZE: zero out non-client area so no system
                # title bar is drawn, but the thick frame stays (shadow).
                if uMsg == WM_NCCALCSIZE and wParam:
                    if user32.IsZoomed(hWnd):
                        # Maximized: fill monitor work area (no gaps)
                        class NCCALCSIZE_PARAMS(ctypes.Structure):
                            _fields_ = [
                                ("rgrc0", wintypes.RECT),
                                ("rgrc1", wintypes.RECT),
                                ("rgrc2", wintypes.RECT),
                                ("lppos", ctypes.c_void_p),
                            ]
                        params = ctypes.cast(lParam, ctypes.POINTER(NCCALCSIZE_PARAMS)).contents
                        monitor = user32.MonitorFromWindow(hWnd, 2)
                        class MONITORINFO(ctypes.Structure):
                            _fields_ = [
                                ("cbSize", ctypes.c_uint),
                                ("rcMonitor", wintypes.RECT),
                                ("rcWork", wintypes.RECT),
                                ("dwFlags", ctypes.c_uint),
                            ]
                        mi = MONITORINFO()
                        mi.cbSize = ctypes.sizeof(MONITORINFO)
                        user32.GetMonitorInfoW(monitor, ctypes.byref(mi))
                        params.rgrc0 = mi.rcWork
                    # Return 0 → "entire window is client area, no NC area"
                    return 0

                # WM_NCHITTEST: only handle resize borders.
                # Do NOT return HTCAPTION — the QML TitleBar already handles
                # dragging via DragHandler + startSystemMove().  Returning
                # HTCAPTION would swallow clicks and break the min/max/close
                # buttons.
                if uMsg == WM_NCHITTEST:
                    result = user32.CallWindowProcW(
                        original_wndproc, hWnd, uMsg, wParam, lParam,
                    )
                    # Allow resize border hit-test results from the thick frame
                    if result in (HTTOPLEFT, HTTOP, HTTOPRIGHT,
                                  HTLEFT, HTRIGHT,
                                  HTBOTTOMLEFT, HTBOTTOM, HTBOTTOMRIGHT):
                        return result
                    return result

                # WM_SIZE: when maximized, force frame redraw
                if uMsg == WM_SIZE and wParam == SIZE_MAXIMIZED:
                    user32.SetWindowPos(
                        hWnd, 0, 0, 0, 0, 0,
                        0x0001 | 0x0002 | 0x0004 | 0x0020,
                    )

                return user32.CallWindowProcW(
                    original_wndproc, hWnd, uMsg, wParam, lParam,
                )

            # Install subclass — cast callback to c_void_p for 64-bit compatibility
            proc_addr = ctypes.cast(subclass_proc, ctypes.c_void_p).value
            user32.SetWindowLongPtrW(hwnd, GWLP_WNDPROC, proc_addr)

            # ── Step 4: Force frame recalculation ──
            SWP_FRAMECHANGED = 0x0020
            SWP_NOMOVE = 0x0002
            SWP_NOSIZE = 0x0001
            SWP_NOZORDER = 0x0004
            user32.SetWindowPos(
                hwnd, 0, 0, 0, 0, 0,
                SWP_FRAMECHANGED | SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER,
            )

            # Prevent garbage collection of the callback
            self._subclass_proc = subclass_proc
            self._original_wndproc = original_wndproc

            print(f"[ok] DWM shadow enabled for hwnd={hwnd}", flush=True)

        except Exception as exc:
            print(f"[warn] DWM shadow setup failed: {exc}", flush=True)
