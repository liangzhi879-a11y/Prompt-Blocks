"""Syntax checking utilities for prompt text analysis."""

import json
import re

from PySide6.QtCore import QObject, Slot


class SyntaxChecker(QObject):
    """QML-exposed syntax checker for prompt text.

    Provides static-like methods via QML slots for checking
    unclosed braces, JSON blocks, markdown structure,
    single-brace violations, and cross-module content patterns.
    """

    @Slot(str, result="QVariantList")
    def checkUnclosedBraces(self, text: str) -> list:  # noqa: N802
        """Check for unclosed {{ or {% template braces.

        Returns list of {line, message, severity} dicts.
        """
        errors = []
        if not text:
            return errors

        lines = text.split("\n")
        open_double = 0
        open_tag = 0

        for i, line in enumerate(lines, 1):
            # Count {{ and }} pairs
            double_open = len(re.findall(r"\{\{", line))
            double_close = len(re.findall(r"\}\}", line))
            open_double += double_open - double_close

            # Count {% and %} pairs
            tag_open = len(re.findall(r"\{%", line))
            tag_close = len(re.findall(r"%\}", line))
            open_tag += tag_open - tag_close

        if open_double > 0:
            errors.append({
                "line": 0,
                "message": "有 " + str(abs(open_double)) + " 个未闭合的 {{ 标记",
                "severity": "error",
            })
        elif open_double < 0:
            errors.append({
                "line": 0,
                "message": "有 " + str(abs(open_double)) + " 个多余的 }} 标记",
                "severity": "error",
            })

        if open_tag > 0:
            errors.append({
                "line": 0,
                "message": "有 " + str(abs(open_tag)) + " 个未闭合的 {% 标记",
                "severity": "error",
            })
        elif open_tag < 0:
            errors.append({
                "line": 0,
                "message": "有 " + str(abs(open_tag)) + " 个多余的 %} 标记",
                "severity": "error",
            })

        return errors

    @Slot(str, result="QVariantList")
    def checkSingleBraces(self, text: str) -> list:  # noqa: N802
        """Detect single-brace {varName} patterns that should be {{varName}}.

        This catches AI-generated content that uses {role} instead of {{role}}.
        """
        errors = []
        if not text:
            return errors

        lines = text.split("\n")
        # Matches {word} that is NOT {{word}} (single brace with word chars inside)
        pattern = re.compile(r"(?<!\{)\{(\w+)\}(?!\})")

        for i, line in enumerate(lines, 1):
            matches = pattern.findall(line)
            for var_name in matches:
                # Skip if inside a code block (```)
                errors.append({
                    "line": i,
                    "message": f"单花括号变量引用：{{{var_name}}} → 应为{{{{{var_name}}}}}",
                    "severity": "error",
                })

        # Deduplicate by variable name (same variable on multiple lines → one error)
        seen = set()
        deduped = []
        for e in errors:
            key = (e["line"], e["message"])
            if key not in seen:
                seen.add(key)
                deduped.append(e)

        return deduped

    @Slot(str, result="QVariantList")
    def checkCrossModuleContent(self, text: str) -> list:  # noqa: N802
        """Detect content patterns that likely belong to other module types.

        This helps identify when AI generates content for the wrong module.
        """
        errors = []
        if not text:
            return errors

        lines = text.split("\n")

        # Patterns that indicate variable/parameter definition sections
        var_section_patterns = [
            (r"#+\s*变量.*(?:列表|定义|表格|说明|与参数)", "疑似变量定义区域（变量应统一在变量管理面板中管理）"),
            (r"\|.*变量名.*\|.*类型.*\|.*默认值.*\|", "疑似变量定义表格"),
            (r"#+\s*参数.*定义", "疑似参数定义区域"),
        ]

        for i, line in enumerate(lines, 1):
            for pattern, msg in var_section_patterns:
                if re.search(pattern, line):
                    errors.append({
                        "line": i,
                        "message": msg,
                        "severity": "warning",
                    })

        return errors

    @Slot(str, result="QVariantList")
    def checkJsonBlocks(self, text: str) -> list:  # noqa: N802
        """Check if JSON code blocks in text are valid JSON.

        Returns list of {line, message, severity} dicts.
        """
        errors = []
        if not text:
            return errors

        # Find ```json ... ``` blocks
        pattern = re.compile(r"```json\s*\n(.*?)```", re.DOTALL)
        for match in pattern.finditer(text):
            json_text = match.group(1).strip()
            start_line = text[:match.start()].count("\n") + 1

            try:
                json.loads(json_text)
            except json.JSONDecodeError as e:
                error_line = start_line + (e.lineno if hasattr(e, "lineno") else 0)
                errors.append({
                    "line": error_line,
                    "message": f"JSON语法错误: {e.msg}",
                    "severity": "error",
                })

        return errors

    @Slot(str, result="QVariantList")
    def checkMarkdownStructure(self, text: str) -> list:  # noqa: N802
        """Check basic markdown structure issues.

        Returns list of {line, message, severity} dicts.
        """
        errors = []
        if not text:
            return errors

        lines = text.split("\n")

        # Check for unclosed code blocks (odd number of ``` lines)
        code_block_lines = []
        for i, line in enumerate(lines, 1):
            if line.strip().startswith("```"):
                code_block_lines.append(i)

        if len(code_block_lines) % 2 != 0:
            errors.append({
                "line": code_block_lines[-1] if code_block_lines else 0,
                "message": "未闭合的代码块 (缺少 ```)",
                "severity": "error",
            })

        # Check for heading without content
        for i, line in enumerate(lines, 1):
            stripped = line.strip()
            if stripped.startswith("#") and not stripped.startswith("```"):
                heading_text = stripped.lstrip("#").strip()
                if not heading_text:
                    errors.append({
                        "line": i,
                        "message": "空标题",
                        "severity": "warning",
                    })

        # Check for broken links [text](url) with empty url
        for i, line in enumerate(lines, 1):
            broken = re.findall(r"\[([^\]]*)\]\(\s*\)", line)
            if broken:
                errors.append({
                    "line": i,
                    "message": f"链接缺少URL: [{broken[0]}]()",
                    "severity": "warning",
                })

        return errors

    @Slot(str, result="QVariantList")
    def checkAll(self, text: str) -> list:  # noqa: N802
        """Run all syntax checks and return combined list of errors."""
        results = []
        results.extend(self.checkUnclosedBraces(text))
        results.extend(self.checkSingleBraces(text))
        results.extend(self.checkCrossModuleContent(text))
        results.extend(self.checkJsonBlocks(text))
        results.extend(self.checkMarkdownStructure(text))
        return results
