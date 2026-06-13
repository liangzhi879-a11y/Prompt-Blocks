"""Robust JSON parsing utilities for LLM output handling.

Handles common LLM JSON output issues:
- Markdown code block wrapping (```json ... ```)
- Truncated output (unclosed strings/brackets due to max_tokens)
- Single quotes instead of double quotes
- Trailing commas
- JavaScript-style comments (// and /* */)
- Python-style booleans/None (True/False/None → true/false/null)
- Unquoted object keys
- Chinese punctuation mixed in JSON
- Unescaped newlines inside strings
- Leading/trailing non-JSON text
"""

import json
import re
import logging

logger = logging.getLogger(__name__)


def parse_llm_json(text: str) -> object:
    """Parse JSON from LLM response with comprehensive error recovery.

    Args:
        text: Raw LLM output text.

    Returns:
        Parsed Python object (dict, list, etc.).

    Raises:
        RuntimeError: If JSON cannot be parsed after all repair attempts.
    """
    if not text or not text.strip():
        raise RuntimeError("LLM 返回为空，无法解析。")

    # Log parsing state for debugging (avoid logging raw LLM content for security)
    logger.debug("[parse_llm_json] Input length: %d chars", len(text))

    cleaned = _strip_markdown(text)

    # Step 1: Try direct parse
    try:
        return json.loads(cleaned)
    except json.JSONDecodeError:
        pass

    # Step 2: Fix common syntax issues
    cleaned = _fix_common_issues(cleaned)
    try:
        return json.loads(cleaned)
    except json.JSONDecodeError as e:
        logger.debug("[parse_llm_json] Step 2 failed: %s", e)

    # Step 3: Repair truncated JSON (unclosed strings/brackets)
    repaired = _repair_truncated(cleaned)
    try:
        return json.loads(repaired)
    except json.JSONDecodeError as e:
        logger.debug("[parse_llm_json] Step 3 failed: %s", e)

    # Step 4: Try to extract any valid JSON substring
    extracted = _extract_json_substring(cleaned)
    if extracted is not None:
        try:
            return json.loads(extracted)
        except json.JSONDecodeError as e:
            logger.debug("[parse_llm_json] Step 4 failed: %s", e)

    # Step 5: Aggressive cleanup — remove all non-JSON prefix/suffix
    aggressive = _aggressive_extract(cleaned)
    if aggressive is not None:
        try:
            return json.loads(aggressive)
        except json.JSONDecodeError as e:
            logger.debug("[parse_llm_json] Step 5 failed: %s", e)

    # Log the final failed attempt for debugging (avoid logging raw content)
    logger.warning(
        "[parse_llm_json] All repair attempts failed. Input length: %d chars",
        len(cleaned)
    )

    raise RuntimeError(
        "LLM 返回的 JSON 格式无效，无法自动修复。"
        "可能原因：输出被截断、格式严重错误或非 JSON 内容。"
        "请尝试缩短提示词或增加 max_tokens 参数。"
    )


def parse_llm_json_safe(text: str, default=None) -> object:
    """Safe version that returns default instead of raising."""
    try:
        return parse_llm_json(text)
    except (RuntimeError, Exception):
        return default


def _strip_markdown(text: str) -> str:
    """Remove markdown code block wrapping."""
    cleaned = text.strip()
    # Handle ```json ... ``` and ``` ... ```
    if cleaned.startswith("```"):
        cleaned = re.sub(r'^```\w*\n?', '', cleaned)
        cleaned = re.sub(r'\n?```$', '', cleaned)
    return cleaned.strip()


def _fix_common_issues(text: str) -> str:
    """Fix common LLM JSON syntax issues."""
    # Remove JavaScript-style single-line comments
    text = re.sub(r'//[^\n]*', '', text)
    # Remove multi-line comments
    text = re.sub(r'/\*.*?\*/', '', text, flags=re.DOTALL)

    # Replace Python-style booleans and None
    text = re.sub(r'\bTrue\b', 'true', text)
    text = re.sub(r'\bFalse\b', 'false', text)
    text = re.sub(r'\bNone\b', 'null', text)

    # Remove trailing commas before closing brackets/braces
    text = re.sub(r',\s*([}\]])', r'\1', text)

    # Replace single-quoted strings with double-quoted strings
    text = _replace_single_quotes(text)

    # Fix Chinese punctuation that sometimes appears in LLM output
    text = _fix_chinese_punctuation(text)

    # Fix unescaped newlines inside JSON strings
    text = _fix_unescaped_newlines(text)

    return text


def _fix_chinese_punctuation(text: str) -> str:
    """Replace Chinese punctuation with English equivalents in JSON context."""
    # Only replace outside of double-quoted strings
    result = []
    in_string = False
    escape_next = False
    for ch in text:
        if escape_next:
            result.append(ch)
            escape_next = False
            continue
        if ch == '\\':
            result.append(ch)
            escape_next = True
            continue
        if ch == '"':
            in_string = not in_string
            result.append(ch)
            continue
        if not in_string:
            # Chinese punctuation replacements
            if ch == '，':
                result.append(',')
            elif ch == '：':
                result.append(':')
            elif ch == '“' or ch == '”':
                result.append('"')
            elif ch == '‘' or ch == '’':
                result.append("'")
            elif ch == '【':
                result.append('[')
            elif ch == '】':
                result.append(']')
            elif ch == '｛':
                result.append('{')
            elif ch == '｝':
                result.append('}')
            else:
                result.append(ch)
        else:
            result.append(ch)
    return ''.join(result)


def _fix_unescaped_newlines(text: str) -> str:
    """Escape literal newlines inside JSON string values."""
    result = []
    in_string = False
    escape_next = False
    for ch in text:
        if escape_next:
            result.append(ch)
            escape_next = False
            continue
        if ch == '\\':
            result.append(ch)
            escape_next = True
            continue
        if ch == '"':
            in_string = not in_string
            result.append(ch)
            continue
        if in_string and ch == '\n':
            result.append('\\n')
        elif in_string and ch == '\r':
            result.append('\\r')
        elif in_string and ch == '\t':
            result.append('\\t')
        else:
            result.append(ch)
    return ''.join(result)


def _replace_single_quotes(text: str) -> str:
    """Replace single-quoted strings with double-quoted strings in JSON."""
    result = []
    in_double_quote = False
    i = 0
    while i < len(text):
        ch = text[i]
        if ch == '"' and (i == 0 or text[i - 1] != '\\'):
            in_double_quote = not in_double_quote
            result.append(ch)
        elif ch == "'" and not in_double_quote:
            result.append('"')
        else:
            result.append(ch)
        i += 1
    return ''.join(result)


def _repair_truncated(text: str) -> str:
    """Repair truncated JSON by closing unclosed structures."""
    in_string = False
    escape_next = False
    open_stack = []

    i = 0
    while i < len(text):
        ch = text[i]
        if escape_next:
            escape_next = False
            i += 1
            continue
        if ch == '\\' and in_string:
            escape_next = True
            i += 1
            continue
        if ch == '"' and not escape_next:
            in_string = not in_string
        elif not in_string:
            if ch in '{[':
                open_stack.append(ch)
            elif ch in '}]':
                if open_stack:
                    open_stack.pop()
        i += 1

    # Close unclosed string
    if in_string:
        text += '"'

    # Close unclosed brackets/braces in reverse order
    closing = {'{': '}', '[': ']'}
    for bracket in reversed(open_stack):
        text += closing[bracket]

    return text


def _extract_json_substring(text: str) -> str | None:
    """Try to extract a valid JSON object or array from the text."""
    start = -1
    for i, ch in enumerate(text):
        if ch in '{[':
            start = i
            break

    if start == -1:
        return None

    open_char = text[start]
    close_char = '}' if open_char == '{' else ']'

    depth = 0
    in_string = False
    escape_next = False

    for i in range(start, len(text)):
        ch = text[i]
        if escape_next:
            escape_next = False
            continue
        if ch == '\\' and in_string:
            escape_next = True
            continue
        if ch == '"' and not escape_next:
            in_string = not in_string
        elif not in_string:
            if ch == open_char:
                depth += 1
            elif ch == close_char:
                depth -= 1
                if depth == 0:
                    return text[start:i + 1]

    return None


def _aggressive_extract(text: str) -> str | None:
    """Aggressively try to find and repair any JSON-like structure.

    Handles cases where LLM outputs explanatory text before/after JSON.
    """
    # Find the largest balanced { ... } or [ ... ] structure
    best_match = None
    best_length = 0

    for start in range(len(text)):
        if text[start] not in '{[':
            continue
        open_char = text[start]
        close_char = '}' if open_char == '{' else ']'

        depth = 0
        in_string = False
        escape_next = False

        for i in range(start, len(text)):
            ch = text[i]
            if escape_next:
                escape_next = False
                continue
            if ch == '\\' and in_string:
                escape_next = True
                continue
            if ch == '"' and not escape_next:
                in_string = not in_string
            elif not in_string:
                if ch == open_char:
                    depth += 1
                elif ch == close_char:
                    depth -= 1
                    if depth == 0:
                        segment = text[start:i + 1]
                        if len(segment) > best_length:
                            best_length = len(segment)
                            best_match = segment
                        break

    if best_match:
        # Try to repair this extracted segment
        return _repair_truncated(best_match)

    return None
