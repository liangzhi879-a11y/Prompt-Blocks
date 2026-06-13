"""SchemaCompiler — compile natural language descriptions to JSON Schema via LLM."""

from __future__ import annotations

import hashlib
import json
from dataclasses import dataclass, field

from promptblocks.compilers.llm_client import LLMClient
from promptblocks.json_utils import parse_llm_json

_SYSTEM_PROMPT = """\
You are a JSON Schema generator. Given a natural language description of a data format, \
you produce a strict, valid JSON Schema object (Draft-07).

Rules:
1. Output ONLY the JSON Schema object — no markdown fences, no commentary.
2. Use Chinese field names when the description is in Chinese.
3. Set "required" to include all properties mentioned in the description.
4. Choose appropriate types: string, integer, number, boolean, array, object.
5. For array types, describe the items schema.
6. Do NOT add "$schema" or "definitions" unless explicitly asked.

Example input: "输出一个列表，每个元素包含姓名、年龄、性别，年龄是整数"
Example output:
{
  "type": "array",
  "items": {
    "type": "object",
    "properties": {
      "姓名": {"type": "string"},
      "年龄": {"type": "integer"},
      "性别": {"type": "string"}
    },
    "required": ["姓名", "年龄", "性别"]
  }
}
"""

_MAX_RETRIES = 2


@dataclass
class SchemaCompileResult:
    """Result of a schema compilation attempt."""

    schema: dict = field(default_factory=dict)
    raw_response: str = ""
    success: bool = False
    error: str | None = None


class SchemaCompiler:
    """Compile natural language format descriptions into JSON Schema."""

    def __init__(self, llm_client: LLMClient | None = None) -> None:
        self._llm = llm_client or LLMClient()
        self._cache: dict[str, SchemaCompileResult] = {}

    def compile(self, natural_language: str) -> SchemaCompileResult:
        """Compile a natural language description to JSON Schema.

        Returns a SchemaCompileResult with schema dict, raw LLM response,
        success flag, and optional error message.
        """
        cache_key = hashlib.md5(natural_language.encode()).hexdigest()
        if cache_key in self._cache:
            return self._cache[cache_key]

        last_error: str | None = None
        for attempt in range(_MAX_RETRIES + 1):
            try:
                raw = self._llm.complete(
                    system_prompt=_SYSTEM_PROMPT,
                    user_prompt=natural_language,
                    temperature=0.1,
                    max_tokens=2048,
                )
                schema = self._parse_json(raw)
                result = SchemaCompileResult(
                    schema=schema,
                    raw_response=raw,
                    success=True,
                    error=None,
                )
                self._cache[cache_key] = result
                return result
            except json.JSONDecodeError as exc:
                last_error = f"Invalid JSON in LLM response: {exc}"
            except RuntimeError as exc:
                last_error = str(exc)
            except Exception as exc:
                last_error = f"Unexpected error: {exc}"

        result = SchemaCompileResult(
            schema={},
            raw_response="",
            success=False,
            error=last_error,
        )
        self._cache[cache_key] = result
        return result

    @staticmethod
    def _parse_json(text: str) -> dict:
        """Extract and parse JSON from LLM response with robust error recovery."""
        return dict(parse_llm_json(text))
