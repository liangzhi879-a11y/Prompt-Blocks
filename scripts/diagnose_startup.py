"""Diagnostic script to trace app startup layer by layer."""
import sys
from pathlib import Path
from PySide6.QtCore import QUrl
from PySide6.QtWidgets import QApplication
from PySide6.QtQml import QQmlApplicationEngine
import os

os.environ['QT_LOGGING_RULES'] = '*.debug=true;qt.qml.warnings=true'

print("=== LAYER 1: Creating QApplication ===")
app = QApplication(sys.argv)
print("OK")

print("=== LAYER 2: Creating QQmlApplicationEngine ===")
engine = QQmlApplicationEngine()
print("OK")

print("=== LAYER 3: Resolving QML paths ===")
qml_dir = (Path(__file__).parent.parent / "src" / "promptblocks" / "qml").resolve()
print(f"  qml_dir: {qml_dir}")
print(f"  exists: {qml_dir.exists()}")
print(f"  qmldir: {(qml_dir / 'qmldir').exists()}")
print(f"  Theme.qml: {(qml_dir / 'Theme.qml').exists()}")
print(f"  main.qml: {(qml_dir / 'main.qml').exists()}")
print(f"  components/: {(qml_dir / 'components').exists()}")
print(f"  views/: {(qml_dir / 'views').exists()}")

print("=== LAYER 4: Setting import paths ===")
engine.addImportPath(str(qml_dir))
engine.addImportPath(str(qml_dir / "views"))
engine.addImportPath(str(qml_dir / "components"))
print("OK")

print("=== LAYER 5: Connecting diagnostics ===")
engine.objectCreated.connect(lambda obj, url: print(f"  [Created] url={url.toString()}"))
engine.warnings.connect(lambda w: print(f"  [QML WARNING] {w.toString()}"))
print("OK")

print("=== LAYER 6: Loading main.qml ===")
main_qml = qml_dir / "main.qml"
engine.load(QUrl.fromLocalFile(str(main_qml)))

root_count = len(engine.rootObjects())
print(f"=== LAYER 7: Root objects = {root_count} ===")

if root_count == 0:
    print("FAIL: No root objects - QML failed to parse/load")
    sys.exit(1)
else:
    print("SUCCESS: Root objects created, entering event loop")
    sys.exit(app.exec())
