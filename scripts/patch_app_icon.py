"""Patch app.py _create_app_icon to use bundled ICO."""
from pathlib import Path

app_path = Path(__file__).parent.parent / "src" / "promptblocks" / "app.py"
content = app_path.read_text(encoding="utf-8")

# Replace the method
old_method = '''    def _create_app_icon(self) -> QIcon:
        """Load the brand SVG logo and render it into a QIcon.

        Uses PB-logo.svg (a #0E3A5C deep-navy puzzle-piece mark) for the
        taskbar, Alt+Tab, and window title contexts.  Renders at multiple
        resolutions for crisp Hi-DPI display.
        """
        logo_path = Path(__file__).parent.parent.parent / "logo-design" / "PB-logo.svg"
        icon = QIcon(str(logo_path.resolve()))

        # Fallback: render SVG to pixmap if QIcon direct load fails
        if icon.isNull():'''

new_method = '''    def _create_app_icon(self) -> QIcon:
        """Load the brand icon for taskbar, Alt+Tab, and window title.

        Priority: bundled ICO -> dev SVG -> programmatic fallback.
        """
        # Priority 1: bundled ICO (works in both dev and PyInstaller EXE)
        ico_path = Path(__file__).parent / "resources" / "icons" / "app.ico"
        icon = QIcon(str(ico_path.resolve()))
        if not icon.isNull():
            return icon

        # Priority 2: project-root SVG (dev only)
        svg_path = Path(__file__).parent.parent.parent / "logo-design" / "PB-logo.svg"
        icon = QIcon(str(svg_path.resolve()))
        if not icon.isNull():
            return icon

        # Fallback: programmatic icon
        if icon.isNull():'''

content = content.replace(old_method, new_method)
app_path.write_text(content, encoding="utf-8")
print("app.py updated!")
