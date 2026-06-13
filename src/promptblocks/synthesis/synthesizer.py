"""PromptSynthesizer — merges IR blocks into a single executable prompt.

The synthesizer walks the IRGraph in topological order and, depending on
each block's type and the chosen backend, produces a text contribution.
All contributions are concatenated to form the final prompt.
"""

from __future__ import annotations

import json
from dataclasses import dataclass, field

from promptblocks.synthesis.ir import IRBlock, IRGraph


@dataclass
class SynthesisResult:
    success: bool
    prompt: str
    backend: str
    warnings: list[str] = field(default_factory=list)
    block_contributions: dict[str, str] = field(default_factory=dict)
    error: str | None = None


class PromptSynthesizer:
    """Synthesize an IRGraph into a final prompt string."""

    def synthesize(self, ir_graph: IRGraph, backend: str = "guidance") -> SynthesisResult:
        """Produce a SynthesisResult from *ir_graph* using *backend*.

        Parameters
        ----------
        ir_graph:
            The intermediate-representation graph built by IRBuilder.
        backend:
            Either ``"guidance"`` or ``"plain_text"``.
        """
        if backend not in ("guidance", "plain_text"):
            return SynthesisResult(
                success=False,
                prompt="",
                backend=backend,
                error=f"Unsupported backend: {backend}",
            )

        warnings: list[str] = []
        block_contributions: dict[str, str] = {}
        block_map: dict[str, IRBlock] = {b.block_id: b for b in ir_graph.blocks}

        for block_id in ir_graph.topological_order:
            block = block_map.get(block_id)
            if block is None:
                continue
            contribution = self._synthesize_block(block, backend, warnings)
            block_contributions[block_id] = contribution

        # Concatenate non-empty contributions with double newlines
        parts = [c for c in (block_contributions[bid] for bid in ir_graph.topological_order) if c]
        prompt = "\n\n".join(parts)

        return SynthesisResult(
            success=True,
            prompt=prompt,
            backend=backend,
            warnings=warnings,
            block_contributions=block_contributions,
        )

    # ------------------------------------------------------------------
    # Per-block synthesis helpers
    # ------------------------------------------------------------------

    @staticmethod
    def _synthesize_block(block: IRBlock, backend: str, warnings: list[str]) -> str:
        dispatch = {
            "instruction": PromptSynthesizer._synthesize_instruction,
            "example": PromptSynthesizer._synthesize_example,
            "format_constraint": PromptSynthesizer._synthesize_format_constraint,
            "reasoning": PromptSynthesizer._synthesize_reasoning,
            "validation": PromptSynthesizer._synthesize_validation,
            "flow_control": PromptSynthesizer._synthesize_flow_control,
        }
        handler = dispatch.get(block.block_type)
        if handler is None:
            warnings.append(f"Unknown block type: {block.block_type} (block: {block.title})")
            return ""
        return handler(block, backend, warnings)

    # --- instruction ---------------------------------------------------

    @staticmethod
    def _synthesize_instruction(block: IRBlock, _backend: str, _warnings: list[str]) -> str:
        return block.description_text

    # --- example -------------------------------------------------------

    @staticmethod
    def _synthesize_example(block: IRBlock, _backend: str, _warnings: list[str]) -> str:
        code = block.compiled_code or block.description_text
        if not code:
            return ""
        # Try to parse compiled_code as JSON list of examples
        examples: list[dict[str, str]] = []
        try:
            parsed = json.loads(code)
            if isinstance(parsed, list):
                examples = parsed
        except (json.JSONDecodeError, TypeError):
            pass

        if examples:
            lines = ["示例："]
            for ex in examples:
                inp = ex.get("input", ex.get("输入", ""))
                out = ex.get("output", ex.get("输出", ""))
                lines.append(f"输入：{inp}")
                lines.append(f"输出：{out}")
            return "\n".join(lines)

        # Fallback: treat raw text as a single example
        return f"示例：\n{code}"

    # --- format_constraint ---------------------------------------------

    @staticmethod
    def _synthesize_format_constraint(block: IRBlock, backend: str, _warnings: list[str]) -> str:
        code = block.compiled_code or block.description_text
        if not code:
            return ""

        if backend == "guidance":
            return f"{{{{#assistant~}}}}\n{code}\n{{{{/assistant}}}}"

        # plain_text backend
        # Try to extract schema from compiled_code (JSON)
        schema = code
        try:
            parsed = json.loads(code)
            schema = json.dumps(parsed, indent=2, ensure_ascii=False)
        except (json.JSONDecodeError, TypeError):
            pass
        return f"请严格按照以下 JSON Schema 输出：\n{schema}"

    # --- reasoning -----------------------------------------------------

    @staticmethod
    def _synthesize_reasoning(block: IRBlock, _backend: str, _warnings: list[str]) -> str:
        code = block.compiled_code or block.description_text
        if not code:
            return ""
        return (
            f"请使用以下 Python 函数进行计算：\n"
            f"```python\n{code}\n```\n"
            f"先执行计算，再基于结果回答。"
        )

    # --- validation ----------------------------------------------------

    @staticmethod
    def _synthesize_validation(block: IRBlock, _backend: str, _warnings: list[str]) -> str:
        rules = block.compiled_code or block.description_text
        if not rules:
            return ""
        return f"输出必须满足以下条件：\n{rules}"

    # --- flow_control --------------------------------------------------

    @staticmethod
    def _synthesize_flow_control(block: IRBlock, _backend: str, warnings: list[str]) -> str:
        warnings.append(f"流程控制块「{block.title}」暂不支持合成（Phase 2 实现）")
        return ""
