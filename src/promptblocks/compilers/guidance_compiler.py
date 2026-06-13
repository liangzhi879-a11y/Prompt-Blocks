"""GuidanceCompiler — convert JSON Schema (or NL) to Guidance template syntax."""

from __future__ import annotations

import json

from promptblocks.compilers.llm_client import LLMClient
from promptblocks.compilers.schema_compiler import SchemaCompiler

_GUIDANCE_SYSTEM_PROMPT = """\
You are a Guidance template generator. Given a JSON Schema, produce a Guidance \
template string that enforces the schema during LLM generation.

Rules:
1. Output ONLY the Guidance template — no markdown fences, no commentary.
2. Use Guidance syntax:
   - {{#system~}} ... {{~/system}} for system messages
   - {{#user~}} ... {{~/user}} for user messages
   - {{#assistant~}} ... {{~/assistant}} for assistant messages
   - {{#each array_field}} ... {{/each}} for array iteration
   - {{gen 'field_name'}} for free-text generation
   - {{select 'field_name' options}} for constrained choices
3. For object properties, render each property on its own line.
4. For array items, use {{#each}} to iterate.
5. Include a system block that describes the assistant's role.
6. Use Chinese field names when the schema uses Chinese keys.
"""

# Threshold: schemas with nesting depth > this are considered "complex"
_COMPLEX_DEPTH_THRESHOLD = 2


class GuidanceCompiler:
    """Convert JSON Schema to Guidance template, or directly from NL to Guidance."""

    def __init__(
        self,
        llm_client: LLMClient | None = None,
        schema_compiler: SchemaCompiler | None = None,
    ) -> None:
        self._llm = llm_client or LLMClient()
        self._schema_compiler = schema_compiler or SchemaCompiler(llm_client=self._llm)

    def compile_from_schema(self, schema: dict) -> str:
        """Convert a JSON Schema dict into a Guidance template string.

        For simple schemas, generates the template directly.
        For complex schemas (deep nesting, conditionals), uses LLM.
        """
        if self._is_complex(schema):
            return self._compile_complex_schema(schema)
        return self._compile_simple_schema(schema)

    def compile_from_nl(self, natural_language: str) -> str:
        """Compile natural language directly to a Guidance template.

        Internally calls SchemaCompiler first, then converts.
        """
        result = self._schema_compiler.compile(natural_language)
        if not result.success:
            return ""
        return self.compile_from_schema(result.schema)

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    @staticmethod
    def _is_complex(schema: dict) -> bool:
        """Heuristic: a schema is complex if it has deep nesting or conditionals."""
        if "anyOf" in schema or "oneOf" in schema or "allOf" in schema or "if" in schema:
            return True
        return GuidanceCompiler._nesting_depth(schema) > _COMPLEX_DEPTH_THRESHOLD

    @staticmethod
    def _nesting_depth(schema: dict, current: int = 0) -> int:
        """Compute the maximum nesting depth of a schema."""
        max_depth = current
        props = schema.get("properties", {})
        for prop_schema in props.values():
            if isinstance(prop_schema, dict):
                d = GuidanceCompiler._nesting_depth(prop_schema, current + 1)
                max_depth = max(max_depth, d)
        items = schema.get("items")
        if isinstance(items, dict):
            d = GuidanceCompiler._nesting_depth(items, current + 1)
            max_depth = max(max_depth, d)
        return max_depth

    def _compile_simple_schema(self, schema: dict) -> str:
        """Generate Guidance template for simple schemas without LLM."""
        schema_type = schema.get("type", "object")

        if schema_type == "array":
            return self._template_array(schema)
        if schema_type == "object":
            return self._template_object(schema)
        # Fallback for primitive top-level types
        return (
            "{{#system~}}\nYou are a helpful assistant.\n{{~/system}}\n"
            "{{#user~}}\n{{input}}\n{{~/user}}\n"
            "{{#assistant~}}\n{{gen 'output'}}\n{{~/assistant}}"
        )

    def _template_array(self, schema: dict) -> str:
        """Guidance template for an array-type schema."""
        items = schema.get("items", {})
        item_props = items.get("properties", {})

        lines = [
            "{{#system~}}",
            "You are a helpful assistant.",
            "{{~/system}}",
            "{{#user~}}",
            "{{input}}",
            "{{~/user}}",
            "{{#assistant~}}",
            "{{#each items}}",
        ]
        for name, prop_schema in item_props.items():
            ptype = prop_schema.get("type", "string") if isinstance(prop_schema, dict) else "string"
            if ptype == "integer" or ptype == "number":
                lines.append(f"{name}: {{{{gen '{name}'}}}}")
            else:
                lines.append(f"{name}: {{{{gen '{name}'}}}}")
        lines.append("{{/each}}")
        lines.append("{{~/assistant}}")
        return "\n".join(lines)

    def _template_object(self, schema: dict) -> str:
        """Guidance template for an object-type schema."""
        props = schema.get("properties", {})

        lines = [
            "{{#system~}}",
            "You are a helpful assistant.",
            "{{~/system}}",
            "{{#user~}}",
            "{{input}}",
            "{{~/user}}",
            "{{#assistant~}}",
        ]
        for name, prop_schema in props.items():
            ptype = prop_schema.get("type", "string") if isinstance(prop_schema, dict) else "string"
            if ptype in ("array",) and isinstance(prop_schema, dict) and "items" in prop_schema:
                item_props = prop_schema["items"].get("properties", {})
                lines.append("{{#each " + name + "}}")
                for iname, ipschema in item_props.items():
                    lines.append(f"  {iname}: {{{{gen '{iname}'}}}}")
                lines.append("{{/each}}")
            else:
                lines.append(f"{name}: {{{{gen '{name}'}}}}")
        lines.append("{{~/assistant}}")
        return "\n".join(lines)

    def _compile_complex_schema(self, schema: dict) -> str:
        """Use LLM to generate Guidance template for complex schemas."""
        schema_json = json.dumps(schema, indent=2, ensure_ascii=False)
        try:
            raw = self._llm.complete(
                system_prompt=_GUIDANCE_SYSTEM_PROMPT,
                user_prompt=f"Generate a Guidance template for this JSON Schema:\n\n{schema_json}",
                temperature=0.1,
                max_tokens=2048,
            )
            return self._strip_fences(raw)
        except Exception:
            return ""

    @staticmethod
    def _strip_fences(text: str) -> str:
        """Remove markdown code fences from LLM output."""
        stripped = text.strip()
        if stripped.startswith("```"):
            lines = stripped.split("\n")
            lines = lines[1:]
            if lines and lines[-1].strip() == "```":
                lines = lines[:-1]
            return "\n".join(lines)
        return stripped
