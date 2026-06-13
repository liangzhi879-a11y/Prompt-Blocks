"""PipelineProcessor — QRegularExpression-based prompt text filter pipeline."""

import json

from PySide6.QtCore import Qt, QObject, Signal, Slot, QRegularExpression


# Built-in filter implementations
_BUILTIN_FILTERS = {
    "sanitize": "sanitize",
    "trim": "trim",
    "lowercase": "lowercase",
    "uppercase": "uppercase",
    "json_pretty": "json_pretty",
    "mask_pii": "mask_pii",
}


def _apply_sanitize(text):
    """Remove HTML tags."""
    regex = QRegularExpression(r"<[^>]+>")
    match = regex.match(text)
    if match.hasMatch():
        return _remove_matches(text, regex)
    return text


def _remove_matches(text, regex):
    """Remove all matches of regex from text."""
    result = text
    it = regex.globalMatch(text)
    offsets = []
    while it.hasNext():
        match = it.next()
        offsets.append((match.capturedStart(), match.capturedLength()))
    # Replace from end to start to preserve offsets
    for start, length in reversed(offsets):
        result = result[:start] + result[start + length:]
    return result.strip()


def _apply_trim(text):
    return text.strip()


def _apply_lowercase(text):
    return text.lower()


def _apply_uppercase(text):
    return text.upper()


def _apply_json_pretty(text):
    try:
        data = json.loads(text)
        return json.dumps(data, ensure_ascii=False, indent=2)
    except (json.JSONDecodeError, TypeError):
        return text


def _apply_mask_pii(text):
    """Mask email addresses and phone numbers."""
    # Mask email addresses
    email_re = QRegularExpression(r"\b[\w.-]+@[\w.-]+\.\w+\b")
    text = _replace_matches(text, email_re, "[EMAIL]")
    # Mask Chinese mobile numbers
    phone_re = QRegularExpression(r"\b1[3-9]\d{9}\b")
    text = _replace_matches(text, phone_re, "[PHONE]")
    phone_re2 = QRegularExpression(r"\b1[3-9]\d-\d{4}-\d{4}\b")
    text = _replace_matches(text, phone_re2, "[PHONE]")
    return text


def _replace_matches(text, regex, replacement):
    """Replace all matches of regex in text with replacement string."""
    it = regex.globalMatch(text)
    offsets = []
    while it.hasNext():
        match = it.next()
        offsets.append((match.capturedStart(), match.capturedLength()))
    # Replace from end to start
    result = text
    for start, length in reversed(offsets):
        result = result[:start] + replacement + result[start + length:]
    return result


_FILTER_FUNCTIONS = {
    "sanitize": _apply_sanitize,
    "trim": _apply_trim,
    "lowercase": _apply_lowercase,
    "uppercase": _apply_uppercase,
    "json_pretty": _apply_json_pretty,
    "mask_pii": _apply_mask_pii,
}


class PipelineProcessor(QObject):
    """Applies pre/post processing filters to prompt text using QRegularExpression."""

    processingCompleted = Signal(str)
    errorOccurred = Signal(str)

    def __init__(self, parent=None):
        super().__init__(parent)

    @Slot(str, str, result=str)
    def processInput(self, text, pipeline_json):
        """Apply a pipeline of filters to input text."""
        filters = self._parse_pipeline(pipeline_json)
        return self._apply_pipeline(text, filters)

    @Slot(str, str, result=str)
    def processOutput(self, text, pipeline_json):
        """Apply a pipeline of filters to output text."""
        filters = self._parse_pipeline(pipeline_json)
        return self._apply_pipeline(text, filters)

    @Slot(str, str, result=str)
    def applyFilter(self, text, filter_name):
        """Apply a single named filter to text."""
        fn = _FILTER_FUNCTIONS.get(filter_name)
        if fn is None:
            return text
        try:
            return fn(text)
        except Exception:
            return text

    @Slot(str, result=str)
    def parseFilterSyntax(self, text):
        """Parse {{var | filter1 | filter2}} syntax, returns JSON list of {varName, filters}."""
        results = []
        regex = QRegularExpression(r"\{\{\s*(\w+)\s*((?:\|\s*\w+\s*)*)\}\}")
        it = regex.globalMatch(text)
        while it.hasNext():
            match = it.next()
            var_name = match.captured(1)
            filter_part = match.captured(2).strip()
            filters = [f.strip() for f in filter_part.split("|") if f.strip()] if filter_part else []
            results.append({"varName": var_name, "filters": filters})
        return json.dumps(results, ensure_ascii=False)

    @Slot(str, str, str, str, result=str)
    def applyVariableWithFilters(self, text, var_name, value, filters_json):
        """Apply filters to value and replace {{varName}} in text."""
        filters = json.loads(filters_json) if filters_json else []
        processed_value = value
        for f in filters:
            fn = _FILTER_FUNCTIONS.get(f)
            if fn:
                try:
                    processed_value = fn(processed_value)
                except Exception:
                    pass
        # Replace the variable pattern (with or without filters) in text
        pattern = r"\{\{\s*" + QRegularExpression.escape(var_name) + r"\s*(?:\|[^}]*)?\}\}"
        regex = QRegularExpression(pattern)
        return _replace_matches(text, regex, processed_value)

    @Slot(result=str)
    def getAvailableFilters(self):
        """Return JSON list of available filter names."""
        return json.dumps(list(_BUILTIN_FILTERS.keys()), ensure_ascii=False)

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
                fn = _FILTER_FUNCTIONS.get(f)
                if fn:
                    try:
                        result = fn(result)
                    except Exception:
                        pass
            elif isinstance(f, dict):
                name = f.get("name", "")
                fn = _FILTER_FUNCTIONS.get(name)
                if fn:
                    try:
                        result = fn(result)
                    except Exception:
                        pass
        return result
