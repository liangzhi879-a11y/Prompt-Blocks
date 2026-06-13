"""Add import ".." to all QML files in components/ and views/ that use Theme but lack the import."""
import re
from pathlib import Path

QML_DIR = Path(__file__).parent.parent / "src" / "promptblocks" / "qml"

SUB_DIRS = ["components", "views"]

for sub in SUB_DIRS:
    sub_dir = QML_DIR / sub
    if not sub_dir.exists():
        continue
    for qml_file in sub_dir.glob("*.qml"):
        content = qml_file.read_text(encoding="utf-8")
        if "Theme." not in content:
            continue
        if 'import ".."' in content:
            print(f"  SKIP (already has import): {qml_file.name}")
            continue

        # Add import ".." after the last import statement block
        lines = content.split("\n")
        last_import_idx = -1
        for i, line in enumerate(lines):
            if line.startswith("import "):
                last_import_idx = i

        if last_import_idx >= 0:
            lines.insert(last_import_idx + 1, 'import ".."')
            new_content = "\n".join(lines)
            qml_file.write_text(new_content, encoding="utf-8")
            print(f"  ADDED: {qml_file.name}")
        else:
            print(f"  WARN: No import found in {qml_file.name}")
