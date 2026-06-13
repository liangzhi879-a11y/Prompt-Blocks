"""CompilerRegistry — maps block types to compiler instances."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Protocol


class Compiler(Protocol):
    """Protocol for compiler objects used by the registry."""

    def compile(self, input_data: str) -> CompileResult: ...


@dataclass
class CompileResult:
    """Standardised result from any compiler."""

    success: bool
    compiled_code: str
    raw_response: str
    error: str | None = None
    cache_hit: bool = False


class CompilerRegistry:
    """Maintain block_type → compiler mapping and dispatch compilation."""

    def __init__(self) -> None:
        self._registry: dict[str, Compiler] = {}

    def register(self, block_type: str, compiler: Compiler) -> None:
        """Register a compiler for a given block type."""
        self._registry[block_type] = compiler

    def get_compiler(self, block_type: str) -> Compiler | None:
        """Return the compiler registered for *block_type*, or None."""
        return self._registry.get(block_type)

    def compile(self, block_type: str, input_data: str) -> CompileResult:
        """Compile *input_data* using the compiler registered for *block_type*.

        Returns a CompileResult.  If no compiler is registered, returns a
        failed CompileResult with an explanatory error.
        """
        compiler = self._registry.get(block_type)
        if compiler is None:
            return CompileResult(
                success=False,
                compiled_code="",
                raw_response="",
                error=f"No compiler registered for block type: {block_type}",
            )
        return compiler.compile(input_data)
