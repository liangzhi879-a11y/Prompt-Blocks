"""PromptHighlighter — QSyntaxHighlighter for prompt template text."""

from PySide6.QtGui import QSyntaxHighlighter, QTextCharFormat, QColor, QFont
from PySide6.QtCore import QRegularExpression


class PromptHighlighter(QSyntaxHighlighter):
    """Syntax highlighter for prompt template text.

    Highlights:
    - {{variable}} references (blue)
    - Markdown headings (#, ##, ###) (yellow)
    - Code blocks (```) (green background)
    - Bold text (**text**) (bold)
    - Unclosed {{ (red error underline)
    """

    def __init__(self, parent=None):
        super().__init__(parent)
        self._inside_code_block = False

        # Variable reference format: {{varName}}
        self._variableFormat = QTextCharFormat()
        self._variableFormat.setBackground(QColor("#89b4fa30"))
        self._variableFormat.setForeground(QColor("#89b4fa"))
        self._variableFormat.setFontWeight(QFont.Bold)

        # Heading format: # ## ###
        self._headingFormat = QTextCharFormat()
        self._headingFormat.setForeground(QColor("#f9e2af"))
        self._headingFormat.setFontWeight(QFont.Bold)

        # Code block format
        self._codeFormat = QTextCharFormat()
        self._codeFormat.setBackground(QColor("#313244"))
        self._codeFormat.setForeground(QColor("#cdd6f4"))

        # Bold format: **text**
        self._boldFormat = QTextCharFormat()
        self._boldFormat.setFontWeight(QFont.Bold)
        self._boldFormat.setForeground(QColor("#cba6f7"))

        # Error format: unclosed {{
        self._errorFormat = QTextCharFormat()
        self._errorFormat.setUnderlineStyle(QTextCharFormat.WaveUnderline)
        self._errorFormat.setUnderlineColor(QColor("#f38ba8"))
        self._errorFormat.setForeground(QColor("#f38ba8"))

        # JSON key format (inside code blocks)
        self._jsonKeyFormat = QTextCharFormat()
        self._jsonKeyFormat.setForeground(QColor("#fab387"))

        # JSON string format (inside code blocks)
        self._jsonStringFormat = QTextCharFormat()
        self._jsonStringFormat.setForeground(QColor("#a6e3a1"))

    def highlightBlock(self, text):
        """Apply syntax highlighting to a block of text."""
        # Track code block state across blocks
        prev_state = self.previousBlockState()
        self._inside_code_block = (prev_state == 1)

        # Check for code block delimiters
        code_delim_re = QRegularExpression(r"^```")
        code_match = code_delim_re.match(text)

        if code_match.hasMatch():
            # This line starts a code block delimiter
            start = code_match.capturedStart()
            length = code_match.capturedLength()
            self.setFormat(start, length, self._codeFormat)

            if self._inside_code_block:
                # Closing code block
                self._inside_code_block = False
                self.setCurrentBlockState(0)
            else:
                # Opening code block
                self._inside_code_block = True
                self.setCurrentBlockState(1)

            # Highlight the rest of the line as code
            if text.length() > length:
                self.setFormat(length, text.length() - length, self._codeFormat)
            return

        if self._inside_code_block:
            # Inside code block: highlight JSON keys/strings
            self.setCurrentBlockState(1)
            self.setFormat(0, text.length(), self._codeFormat)

            # JSON keys: "key":
            json_key_re = QRegularExpression(r'"([^"\\]*(\\.[^"\\]*)*)"\s*:')
            it = json_key_re.globalMatch(text)
            while it.hasNext():
                match = it.next()
                self.setFormat(match.capturedStart(), match.capturedLength(), self._jsonKeyFormat)

            # JSON string values
            json_str_re = QRegularExpression(r':\s*"([^"\\]*(\\.[^"\\]*)*"')
            it = json_str_re.globalMatch(text)
            while it.hasNext():
                match = it.next()
                self.setFormat(match.capturedStart(), match.capturedLength(), self._jsonStringFormat)
            return

        self.setCurrentBlockState(0)

        # Highlight {{variable}} references
        var_re = QRegularExpression(r"\{\{(\w+)(?:\s*\|[^}]*)?\}\}")
        it = var_re.globalMatch(text)
        while it.hasNext():
            match = it.next()
            self.setFormat(match.capturedStart(), match.capturedLength(), self._variableFormat)

        # Detect unclosed {{ (error)
        # Find {{ that are NOT followed eventually by }}
        unclosed_re = QRegularExpression(r"\{\{(?![^{]*\}\})")
        it = unclosed_re.globalMatch(text)
        while it.hasNext():
            match = it.next()
            self.setFormat(match.capturedStart(), match.capturedLength(), self._errorFormat)

        # Highlight Markdown headings
        heading_re = QRegularExpression(r"^(#{1,6})\s+.*$")
        it = heading_re.globalMatch(text)
        while it.hasNext():
            match = it.next()
            self.setFormat(match.capturedStart(), match.capturedLength(), self._headingFormat)

        # Highlight bold: **text**
        bold_re = QRegularExpression(r"\*\*([^*]+)\*\*")
        it = bold_re.globalMatch(text)
        while it.hasNext():
            match = it.next()
            self.setFormat(match.capturedStart(), match.capturedLength(), self._boldFormat)
