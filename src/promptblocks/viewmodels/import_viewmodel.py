"""ImportViewModel — handles prompt import from .promptx files."""

import json
import os

from PySide6.QtCore import Property, QObject, Signal, Slot
from promptblocks.db.crud import BlockCRUD, ProjectCRUD, VariableCRUD
from promptblocks.db.models import Block
from promptblocks.db.session import get_session


_REQUIRED_FIELDS = ("name", "version")
# "blocks" is strongly recommended but not strictly required for backward compat


class ImportViewModel(QObject):
    importCompleted = Signal(str)       # project_id
    importError = Signal(str)           # error message
    validationCompleted = Signal(str)   # validation result JSON
    selectedFileChanged = Signal(str)   # selected file path

    def __init__(self, parent=None):
        super().__init__(parent)
        self._selected_file: str = ""

    # ── selectedFile property ──

    def _read_selected_file(self) -> str:
        return self._selected_file

    selectedFile = Property(str, _read_selected_file, notify=selectedFileChanged)

    # ── File selection ──

    @Slot()
    def selectFile(self):
        """Open a file dialog to select a .promptx file."""
        from PySide6.QtWidgets import QFileDialog
        file_path, _ = QFileDialog.getOpenFileName(
            None, "选择 .promptx 文件", "", "PromptBlocks 工程文件 (*.promptx);;所有文件 (*)"
        )
        if file_path:
            self._selected_file = file_path
            self.selectedFileChanged.emit(file_path)

    # ── Validation ──

    @Slot(str, result=str)
    def validatePromptxFile(self, path: str) -> str:
        """Validate a .promptx file without importing. Returns JSON result."""
        result = {"valid": False, "name": "", "blockCount": 0, "variableCount": 0, "errors": []}

        if not os.path.isfile(path):
            result["errors"].append(f"文件不存在: {path}")
            json_result = json.dumps(result, ensure_ascii=False)
            self.validationCompleted.emit(json_result)
            return json_result

        try:
            with open(path, "r", encoding="utf-8") as f:
                data = json.load(f)
        except (json.JSONDecodeError, UnicodeDecodeError):
            result["errors"].append("文件格式错误：无法解析JSON")
            json_result = json.dumps(result, ensure_ascii=False)
            self.validationCompleted.emit(json_result)
            return json_result

        if not isinstance(data, dict):
            result["errors"].append("文件格式错误：顶层结构不是对象")
            json_result = json.dumps(result, ensure_ascii=False)
            self.validationCompleted.emit(json_result)
            return json_result

        for field in _REQUIRED_FIELDS:
            if field not in data:
                result["errors"].append(f"文件格式错误：缺少必需字段 '{field}'")

        # Check blocks: must be present as an array
        if "blocks" not in data:
            if "cards" in data and isinstance(data["cards"], int):
                result["errors"].append(
                    "文件格式过旧（仅含模块数量，无模块数据），请使用新版本重新导出"
                )
            else:
                result["errors"].append("文件格式错误：缺少必需字段 'blocks'")
        else:
            blocks = data["blocks"]
            if not isinstance(blocks, list):
                result["errors"].append("文件格式错误：'blocks' 必须是数组")

        if result["errors"]:
            json_result = json.dumps(result, ensure_ascii=False)
            self.validationCompleted.emit(json_result)
            return json_result

        blocks = data.get("blocks", [])
        variables = data.get("variables", [])
        result["valid"] = True
        result["name"] = data.get("name", "")
        result["blockCount"] = len(blocks) if isinstance(blocks, list) else data.get("cards", 0)
        result["variableCount"] = len(variables) if isinstance(variables, list) else data.get("variables", 0)

        json_result = json.dumps(result, ensure_ascii=False)
        self.validationCompleted.emit(json_result)
        return json_result

    # ── Import ──

    @Slot(str)
    def importFromPromptx(self, path: str):
        """Import a .promptx file: create project, blocks, and variables."""
        if not os.path.isfile(path):
            self.importError.emit(f"文件不存在: {path}")
            return

        # Security: check file size to prevent memory exhaustion
        MAX_FILE_SIZE = 50 * 1024 * 1024  # 50 MB
        try:
            file_size = os.path.getsize(path)
            if file_size > MAX_FILE_SIZE:
                self.importError.emit(f"文件过大（{file_size // (1024*1024)}MB），最大支持 50MB")
                return
        except OSError:
            self.importError.emit("无法读取文件信息")
            return

        try:
            with open(path, "r", encoding="utf-8") as f:
                data = json.load(f)
        except (json.JSONDecodeError, UnicodeDecodeError):
            self.importError.emit("文件格式错误：无法解析JSON")
            return

        if not isinstance(data, dict):
            self.importError.emit("文件格式错误：顶层结构不是对象")
            return

        for field in _REQUIRED_FIELDS:
            if field not in data:
                self.importError.emit(f"文件格式错误：缺少必需字段 '{field}'")
                return

        # Validate blocks field exists and is an array
        if "blocks" not in data:
            if "cards" in data and isinstance(data["cards"], int):
                self.importError.emit(
                    "文件格式过旧（仅含模块数量，无模块数据），请使用新版本重新导出"
                )
            else:
                self.importError.emit("文件格式错误：缺少必需字段 'blocks'")
            return

        blocks = data["blocks"]
        if not isinstance(blocks, list):
            self.importError.emit("文件格式错误：'blocks' 必须是数组")
            return

        try:
            with get_session() as session:
                # Create project
                project = ProjectCRUD.create(
                    session,
                    name=data["name"],
                    description=data.get("description"),
                )
                project_id = project.id

                # Create blocks — support both snake_case and camelCase field names
                for i, block_data in enumerate(blocks):
                    if not isinstance(block_data, dict):
                        continue
                    # Map camelCase (from QML export) to snake_case (DB model)
                    block_type = block_data.get("block_type") or block_data.get("blockType", "custom")
                    title = block_data.get("title", "")
                    compiled_code = block_data.get("compiled_code") or block_data.get("content")
                    order_index = block_data.get("order_index") or block_data.get("orderIndex", i)

                    block = BlockCRUD.create(
                        session,
                        project_id=project_id,
                        block_type=block_type,
                        title=title,
                        description_text=block_data.get("description_text"),
                        content_json=block_data.get("content_json"),
                        config=block_data.get("config"),
                        order_index=order_index,
                    )
                    if compiled_code is not None:
                        block.compiled_code = compiled_code
                        session.flush()

                # Create variables
                variables = data.get("variables", [])
                if isinstance(variables, list):
                    for var_data in variables:
                        if not isinstance(var_data, dict):
                            continue
                        VariableCRUD.create(
                            session,
                            project_id=project_id,
                            name=var_data.get("name"),
                            var_type=var_data.get("var_type", "text"),
                            default_value=var_data.get("default_value"),
                            constraints=var_data.get("constraints"),
                            scope=var_data.get("scope", "global"),
                            source=var_data.get("source", "user_input"),
                            description=var_data.get("description"),
                        )

                self.importCompleted.emit(project_id)
        except Exception as exc:
            self.importError.emit(f"导入失败：{exc}")
