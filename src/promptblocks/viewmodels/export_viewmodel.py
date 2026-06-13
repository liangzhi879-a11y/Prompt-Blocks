"""ExportViewModel — handles prompt export to various formats."""

import csv
import json
import re

from PySide6.QtCore import QObject, Signal, Slot
from PySide6.QtGui import QGuiApplication
from PySide6.QtWidgets import QFileDialog


class ExportViewModel(QObject):
    exportCompleted = Signal(str)   # path
    exportError = Signal(str)       # message

    def __init__(self, parent=None):
        super().__init__(parent)

    # ── Helpers ──

    def _get_save_path(self, title, filter_str):
        path, _ = QFileDialog.getSaveFileName(None, title, "", filter_str)
        return path

    # ── Export slots ──

    @Slot(str, bool, result=str)
    def exportAsMarkdown(self, prompt_text, template_mode):
        path = self._get_save_path("导出 Markdown", "Markdown Files (*.md)")
        if not path:
            return ""
        try:
            content = prompt_text
            if not template_mode:
                content = self._replace_variables(content)
            with open(path, "w", encoding="utf-8") as f:
                f.write(content)
            self.exportCompleted.emit(path)
            return path
        except Exception as e:
            self.exportError.emit(str(e))
            return ""

    @Slot(str, result=str)
    def exportAsTxt(self, prompt_text):
        path = self._get_save_path("导出纯文本", "Text Files (*.txt)")
        if not path:
            return ""
        try:
            with open(path, "w", encoding="utf-8") as f:
                f.write(prompt_text)
            self.exportCompleted.emit(path)
            return path
        except Exception as e:
            self.exportError.emit(str(e))
            return ""

    @Slot(str, result=str)
    def exportAsJson(self, card_list_json):
        path = self._get_save_path("导出 JSON", "JSON Files (*.json)")
        if not path:
            return ""
        try:
            data = json.loads(card_list_json) if card_list_json else []
            with open(path, "w", encoding="utf-8") as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
            self.exportCompleted.emit(path)
            return path
        except Exception as e:
            self.exportError.emit(str(e))
            return ""

    @Slot(str, result=str)
    def exportAsCsv(self, variables_json):
        path = self._get_save_path("导出 CSV 变量表", "CSV Files (*.csv)")
        if not path:
            return ""
        try:
            variables = json.loads(variables_json) if variables_json else []
            with open(path, "w", encoding="utf-8", newline="") as f:
                writer = csv.DictWriter(
                    f,
                    fieldnames=["name", "var_type", "default_value", "constraints", "scope", "source", "description"],
                    extrasaction="ignore",
                )
                writer.writeheader()
                for var in variables:
                    writer.writerow({k: (v if v is not None else "") for k, v in var.items()})
            self.exportCompleted.emit(path)
            return path
        except Exception as e:
            self.exportError.emit(str(e))
            return ""

    @Slot(str, result=str)
    def exportAsPromptx(self, project_json):
        path = self._get_save_path("导出工程文件", "PromptBlocks Files (*.promptx)")
        if not path:
            return ""
        try:
            data = json.loads(project_json) if project_json else {}
            with open(path, "w", encoding="utf-8") as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
            self.exportCompleted.emit(path)
            return path
        except Exception as e:
            self.exportError.emit(str(e))
            return ""

    @Slot(str)
    def copyToClipboard(self, text):
        clipboard = QGuiApplication.clipboard()
        clipboard.setText(text)
        self.exportCompleted.emit("clipboard")

    @staticmethod
    def _replace_variables(text):
        return re.sub(r"\{\{[^}]+\}\}", "", text)
