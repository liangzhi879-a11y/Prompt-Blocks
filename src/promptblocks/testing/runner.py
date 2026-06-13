"""TestRunner — execute LLM tests and collect results."""

from __future__ import annotations

import time
from dataclasses import dataclass

from PySide6.QtCore import QObject, Signal

from promptblocks.compilers.llm_client import LLMClient


@dataclass
class TestRunResult:
    """Result of a single test run."""

    success: bool
    input_data: str
    actual_output: str
    error: str | None = None
    latency_ms: float = 0.0


class TestRunner(QObject):
    """Run single or batch LLM tests, emitting signals for progress and results."""

    resultReady = Signal(dict)  # noqa: N815
    progress = Signal(int, int)
    streamChunk = Signal(str)  # noqa: N815

    def __init__(self, llm_client: LLMClient | None = None, parent=None):
        super().__init__(parent)
        self._llm = llm_client or LLMClient()

    def run_single_test(self, prompt: str, input_data: str) -> TestRunResult:
        """Run a single test: call LLM with *prompt* as system prompt and
        *input_data* as user input.

        Emits ``resultReady`` and ``streamChunk`` signals.
        """
        start = time.monotonic()
        try:
            # Simulate streaming by calling complete and emitting the full result as one chunk
            output = self._llm.complete(
                system_prompt=prompt,
                user_prompt=input_data,
            )
            self.streamChunk.emit(output)

            latency_ms = (time.monotonic() - start) * 1000
            result = TestRunResult(
                success=True,
                input_data=input_data,
                actual_output=output,
                latency_ms=latency_ms,
            )
        except Exception as exc:
            latency_ms = (time.monotonic() - start) * 1000
            result = TestRunResult(
                success=False,
                input_data=input_data,
                actual_output="",
                error=str(exc),
                latency_ms=latency_ms,
            )

        self.resultReady.emit(self._result_to_dict(result))
        return result

    def run_batch_tests(
        self, prompt: str, test_cases: list[dict]
    ) -> list[TestRunResult]:
        """Run multiple test cases sequentially.

        Each item in *test_cases* should have an ``"input_data"`` key.
        Emits ``progress`` after each case and ``resultReady`` for each result.
        """
        results: list[TestRunResult] = []
        total = len(test_cases)
        for idx, case in enumerate(test_cases, start=1):
            input_data = case.get("input_data", "")
            result = self.run_single_test(prompt, input_data)
            results.append(result)
            self.progress.emit(idx, total)
        return results

    @staticmethod
    def _result_to_dict(result: TestRunResult) -> dict:
        return {
            "success": result.success,
            "input_data": result.input_data,
            "actual_output": result.actual_output,
            "error": result.error,
            "latency_ms": result.latency_ms,
        }


class TestWorker(QObject):
    """Execute tests in a background QThread without blocking the UI."""

    finished = Signal(list)
    error = Signal(str)

    def __init__(
        self,
        runner: TestRunner,
        prompt: str,
        test_cases: list[dict] | None = None,
        input_data: str | None = None,
        parent=None,
    ):
        super().__init__(parent)
        self._runner = runner
        self._prompt = prompt
        self._test_cases = test_cases
        self._input_data = input_data
        self._cancelled = False

    def run(self) -> None:
        """Execute the test(s) and emit ``finished`` with results."""
        try:
            if self._test_cases is not None:
                results = self._runner.run_batch_tests(self._prompt, self._test_cases)
                self.finished.emit(
                    [TestRunner._result_to_dict(r) for r in results]
                )
            elif self._input_data is not None:
                result = self._runner.run_single_test(self._prompt, self._input_data)
                self.finished.emit([TestRunner._result_to_dict(result)])
            else:
                self.error.emit("No test data provided")
        except Exception as exc:
            self.error.emit(str(exc))

    def cancel(self) -> None:
        """Mark the worker as cancelled (for cooperative cancellation)."""
        self._cancelled = True
