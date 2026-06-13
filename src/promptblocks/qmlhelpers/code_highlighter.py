"""Syntax highlighter for code display in QML blocks."""

from __future__ import annotations

from PySide6.QtGui import QColor, QFont, QSyntaxHighlighter, QTextCharFormat


class CodeHighlighter(QSyntaxHighlighter):
    """QSyntaxHighlighter subclass supporting Python, JSON, and Guidance syntax."""

    def __init__(self, parent=None, language: str = "python"):
        super().__init__(parent)
        self._language = language
        self._formats: dict[str, QTextCharFormat] = {}
        self._rules: list[tuple] = []
        self._init_formats()
        self._init_rules()

    def _init_formats(self) -> None:
        """Initialize text formats for different syntax elements."""
        # Keywords
        keyword_fmt = QTextCharFormat()
        keyword_fmt.setForeground(QColor("#c678dd"))
        keyword_fmt.setFontWeight(QFont.Bold)
        self._formats["keyword"] = keyword_fmt

        # Strings
        string_fmt = QTextCharFormat()
        string_fmt.setForeground(QColor("#98c379"))
        self._formats["string"] = string_fmt

        # Numbers
        number_fmt = QTextCharFormat()
        number_fmt.setForeground(QColor("#d19a66"))
        self._formats["number"] = number_fmt

        # Comments
        comment_fmt = QTextCharFormat()
        comment_fmt.setForeground(QColor("#5c6370"))
        comment_fmt.setFontItalic(True)
        self._formats["comment"] = comment_fmt

        # Built-in functions / types
        builtin_fmt = QTextCharFormat()
        builtin_fmt.setForeground(QColor("#61afef"))
        self._formats["builtin"] = builtin_fmt

        # JSON keys
        json_key_fmt = QTextCharFormat()
        json_key_fmt.setForeground(QColor("#e06c75"))
        self._formats["json_key"] = json_key_fmt

        # Guidance special
        guidance_fmt = QTextCharFormat()
        guidance_fmt.setForeground(QColor("#e5c07b"))
        guidance_fmt.setFontWeight(QFont.Bold)
        self._formats["guidance"] = guidance_fmt

    def _init_rules(self) -> None:
        """Initialize highlighting rules based on language."""
        import re

        self._rules = []

        if self._language == "python":
            keywords = [
                "def", "class", "if", "elif", "else", "for", "while", "return",
                "import", "from", "as", "try", "except", "finally", "with",
                "raise", "pass", "break", "continue", "and", "or", "not",
                "in", "is", "lambda", "yield", "global", "nonlocal", "assert",
                "True", "False", "None",
            ]
            builtins = [
                "print", "len", "range", "str", "int", "float", "list", "dict",
                "set", "tuple", "bool", "type", "isinstance", "hasattr",
                "getattr", "setattr", "super", "property", "staticmethod",
                "classmethod",
            ]
            for kw in keywords:
                self._rules.append(
                    (re.compile(r"\b" + kw + r"\b"), self._formats["keyword"])
                )
            for bi in builtins:
                self._rules.append(
                    (re.compile(r"\b" + bi + r"\b"), self._formats["builtin"])
                )
            # Strings
            self._rules.append(
                (re.compile(r'"[^"\\]*(\\.[^"\\]*)*"'), self._formats["string"])
            )
            self._rules.append(
                (re.compile(r"'[^'\\]*(\\.[^'\\]*)*'"), self._formats["string"])
            )
            self._rules.append(
                (re.compile(r'"""[^"]*"""'), self._formats["string"])
            )
            # Comments
            self._rules.append(
                (re.compile(r"#[^\n]*"), self._formats["comment"])
            )
            # Numbers
            self._rules.append(
                (re.compile(r"\b[0-9]+\.?[0-9]*\b"), self._formats["number"])
            )

        elif self._language == "json":
            # JSON keys (strings before colon)
            self._rules.append(
                (re.compile(r'"[^"\\]*(\\.[^"\\]*)*"\s*:'), self._formats["json_key"])
            )
            # JSON string values
            self._rules.append(
                (
                    re.compile(r':\s*"[^"\\]*(\\.[^"\\]*)*"'),
                    self._formats["string"],
                )
            )
            # JSON numbers
            self._rules.append(
                (re.compile(r":\s*-?[0-9]+\.?[0-9]*"), self._formats["number"])
            )
            # JSON booleans / null
            for kw in ["true", "false", "null"]:
                self._rules.append(
                    (re.compile(r"\b" + kw + r"\b"), self._formats["keyword"])
                )

        elif self._language == "guidance":
            # Guidance {{...}} blocks
            self._rules.append(
                (re.compile(r"\{\{[^}]*\}\}"), self._formats["guidance"])
            )
            # Guidance special keywords
            for kw in ["gen", "select", "each", "if", "elif", "else", "set"]:
                self._rules.append(
                    (re.compile(r"\b" + kw + r"\b"), self._formats["keyword"])
                )
            # Strings
            self._rules.append(
                (re.compile(r'"[^"\\]*(\\.[^"\\]*)*"'), self._formats["string"])
            )
            self._rules.append(
                (re.compile(r"'[^'\\]*(\\.[^'\\]*)*'"), self._formats["string"])
            )

    def highlightBlock(self, text: str) -> None:  # noqa: N802
        """Apply syntax highlighting to a block of text."""
        for pattern, fmt in self._rules:
            for match in pattern.finditer(text):
                start = match.start()
                length = match.end() - start
                self.setFormat(start, length, fmt)

    def set_language(self, language: str) -> None:
        """Change the highlighting language and re-highlight."""
        self._language = language
        self._rules = []
        self._init_rules()
        self.rehighlight()
