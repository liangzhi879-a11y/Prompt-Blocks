"""PipelineProcessor — applies pre/post processing filters to prompt text."""

import json
import re

from PySide6.QtCore import QObject, Signal, Slot


# Built-in filter implementations
_BUILTIN_FILTERS = {
    "sanitize": lambda t: re.sub(r"<[^>]+>", "", t).strip(),
    "trim": lambda t: t.strip(),
    "lowercase": lambda t: t.lower(),
    "uppercase": lambda t: t.upper(),
    "json_pretty": lambda t: _json_pretty(t),
    "mask_pii": lambda t: _mask_pii(t),
}


def _json_pretty(text):
    try:
        data = json.loads(text)
        return json.dumps(data, ensure_ascii=False, indent=2)
    except (json.JSONDecodeError, TypeError):
        return text


def _mask_pii(text):
    # Mask email addresses
    text = re.sub(r"\b[\w.-]+@[\w.-]+\.\w+\b", "[EMAIL]", text)
    # Mask phone numbers (Chinese mobile: 1xx-xxxx-xxxx or 1xxxxxxxxxx)
    text = re.sub(r"\b1[3-9]\d{9}\b", "[PHONE]", text)
    text = re.sub(r"\b1[3-9]\d-\d{4}-\d{4}\b", "[PHONE]", text)
    return text


class PipelineProcessor(QObject):
    processingCompleted = Signal(str)  # noqa: N815
    errorOccurred = Signal(str)        # noqa: N815

    def __init__(self, parent=None):
        super().__init__(parent)

    # ── Pipeline processing ──

    @Slot(str, str, result=str)
    def processInput(self, text, pipeline_json):
        filters = self._parse_pipeline(pipeline_json)
        return self._apply_pipeline(text, filters)

    @Slot(str, str, result=str)
    def processOutput(self, text, pipeline_json):
        filters = self._parse_pipeline(pipeline_json)
        return self._apply_pipeline(text, filters)

    # ── Single filter ──

    @Slot(str, str, result=str)
    def applyFilter(self, text, filter_name):
        fn = _BUILTIN_FILTERS.get(filter_name)
        if fn is None:
            return text
        try:
            return fn(text)
        except Exception:
            return text

    # ── Filter syntax parsing ──

    @Slot(str, result=str)
    def parseFilterSyntax(self, text):
        """Parse {{var | filter1 | filter2}} syntax, returns JSON list of {varName, filters}."""
        results = []
        pattern = r"\{\{\s*(\w+)\s*((?:\|\s*\w+\s*)*)\}\}"
        for match in re.finditer(pattern, text):
            var_name = match.group(1)
            filter_part = match.group(2).strip()
            filters = [f.strip() for f in filter_part.split("|") if f.strip()] if filter_part else []
            results.append({"varName": var_name, "filters": filters})
        return json.dumps(results, ensure_ascii=False)

    @Slot(str, str, str, str, result=str)
    def applyVariableWithFilters(self, text, var_name, value, filters_json):
        """Apply filters to value and replace {{varName}} in text."""
        filters = json.loads(filters_json) if filters_json else []
        processed_value = value
        for f in filters:
            fn = _BUILTIN_FILTERS.get(f)
            if fn:
                try:
                    processed_value = fn(processed_value)
                except Exception:
                    pass
        # Replace the variable pattern (with or without filters) in text
        pattern = r"\{\{\s*" + re.escape(var_name) + r"\s*(?:\|[^}]*)?\}\}"
        return re.sub(pattern, processed_value, text)

    # ── Available filters ──

    @Slot(result=str)
    def getAvailableFilters(self):
        return json.dumps(list(_BUILTIN_FILTERS.keys()), ensure_ascii=False)

    # ── Internal ──

    @staticmethod
    def _parse_pipeline(pipeline_json):
        if not pipeline_json:
            return []
        try:
            return json.loads(pipeline_json)
        except (json.JSONDecodeError, TypeError):
            return []

    @staticmethod
    def _apply_pipeline(text, filters):
        result = text
        for f in filters:
            if isinstance(f, str):
                fn = _BUILTIN_FILTERS.get(f)
                if fn:
                    try:
                        result = fn(result)
                    except Exception:
                        pass
            elif isinstance(f, dict):
                name = f.get("name", "")
                fn = _BUILTIN_FILTERS.get(name)
                if fn:
                    try:
                        result = fn(result)
                    except Exception:
                        pass
        return result
