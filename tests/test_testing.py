"""Tests for the testing module: SchemaValidator, TestRunner, TestViewModel."""

from __future__ import annotations

import json
from unittest.mock import MagicMock, patch

import pytest

from promptblocks.testing.validator import SchemaValidator, ValidationResult
from promptblocks.testing.runner import TestRunner, TestRunResult, TestWorker


# ---------------------------------------------------------------------------
# SchemaValidator tests
# ---------------------------------------------------------------------------


class TestSchemaValidator:
    """Test SchemaValidator.validate() and validate_format()."""

    def setup_method(self) -> None:
        self.validator = SchemaValidator()

    # --- validate() ---

    def test_validate_valid_json_matches_schema(self) -> None:
        schema = {
            "type": "object",
            "properties": {"name": {"type": "string"}, "age": {"type": "integer"}},
            "required": ["name", "age"],
        }
        output = json.dumps({"name": "Alice", "age": 30})
        result = self.validator.validate(output, schema)
        assert result.is_valid is True
        assert result.errors == []
        assert result.missing_fields == []
        assert result.type_errors == []

    def test_validate_invalid_json(self) -> None:
        schema = {"type": "object"}
        result = self.validator.validate("not json at all", schema)
        assert result.is_valid is False
        assert any("not valid JSON" in e for e in result.errors)

    def test_validate_missing_required_fields(self) -> None:
        schema = {
            "type": "object",
            "properties": {"name": {"type": "string"}, "age": {"type": "integer"}},
            "required": ["name", "age"],
        }
        output = json.dumps({"name": "Alice"})
        result = self.validator.validate(output, schema)
        assert result.is_valid is False
        assert "age" in result.missing_fields

    def test_validate_type_errors(self) -> None:
        schema = {
            "type": "object",
            "properties": {"age": {"type": "integer"}},
            "required": ["age"],
        }
        output = json.dumps({"age": "thirty"})
        result = self.validator.validate(output, schema)
        assert result.is_valid is False
        assert len(result.type_errors) > 0

    def test_validate_nested_schema(self) -> None:
        schema = {
            "type": "object",
            "properties": {
                "address": {
                    "type": "object",
                    "properties": {"city": {"type": "string"}},
                    "required": ["city"],
                }
            },
            "required": ["address"],
        }
        output = json.dumps({"address": {}})
        result = self.validator.validate(output, schema)
        assert result.is_valid is False
        assert "city" in result.missing_fields

    # --- validate_format() ---

    def test_validate_format_word_count_pass(self) -> None:
        result = self.validator.validate_format(
            "hello world foo", ["word_count:2:5"]
        )
        assert result.is_valid is True

    def test_validate_format_word_count_fail(self) -> None:
        result = self.validator.validate_format(
            "hello", ["word_count:3:10"]
        )
        assert result.is_valid is False

    def test_validate_format_char_count_pass(self) -> None:
        result = self.validator.validate_format(
            "hello", ["char_count:3:10"]
        )
        assert result.is_valid is True

    def test_validate_format_char_count_fail(self) -> None:
        result = self.validator.validate_format(
            "hi", ["char_count:5:100"]
        )
        assert result.is_valid is False

    def test_validate_format_contains_pass(self) -> None:
        result = self.validator.validate_format(
            "The quick brown fox", ["contains:fox"]
        )
        assert result.is_valid is True

    def test_validate_format_contains_fail(self) -> None:
        result = self.validator.validate_format(
            "The quick brown cat", ["contains:fox"]
        )
        assert result.is_valid is False
        assert "fox" in result.missing_fields

    def test_validate_format_not_contains_pass(self) -> None:
        result = self.validator.validate_format(
            "hello world", ["not_contains:spam"]
        )
        assert result.is_valid is True

    def test_validate_format_not_contains_fail(self) -> None:
        result = self.validator.validate_format(
            "this is spam content", ["not_contains:spam"]
        )
        assert result.is_valid is False

    def test_validate_format_regex_pass(self) -> None:
        result = self.validator.validate_format(
            "Order #12345 confirmed", ["regex:#\\d+"]
        )
        assert result.is_valid is True

    def test_validate_format_regex_fail(self) -> None:
        result = self.validator.validate_format(
            "No order number here", ["regex:#\\d+"]
        )
        assert result.is_valid is False

    def test_validate_format_multiple_rules(self) -> None:
        result = self.validator.validate_format(
            "The fox jumped", ["word_count:2:10", "contains:fox"]
        )
        assert result.is_valid is True

    def test_validate_format_unknown_rule(self) -> None:
        result = self.validator.validate_format("test", ["unknown_rule:foo"])
        assert result.is_valid is False
        assert any("Unknown" in e for e in result.errors)


# ---------------------------------------------------------------------------
# TestRunner tests
# ---------------------------------------------------------------------------


class TestTestRunner:
    """Test TestRunner with mocked LLM client."""

    def _make_mock_client(self, response: str = "Mock LLM response") -> MagicMock:
        client = MagicMock()
        client.complete.return_value = response
        return client

    def test_run_single_test_success(self) -> None:
        client = self._make_mock_client("Hello from LLM")
        runner = TestRunner(llm_client=client)
        result = runner.run_single_test("system prompt", "user input")

        assert result.success is True
        assert result.actual_output == "Hello from LLM"
        assert result.input_data == "user input"
        assert result.error is None
        assert result.latency_ms >= 0

    def test_run_single_test_failure(self) -> None:
        client = MagicMock()
        client.complete.side_effect = RuntimeError("LLM error")
        runner = TestRunner(llm_client=client)
        result = runner.run_single_test("system prompt", "user input")

        assert result.success is False
        assert result.actual_output == ""
        assert "LLM error" in result.error

    def test_run_single_test_emits_result_ready(self) -> None:
        client = self._make_mock_client("response")
        runner = TestRunner(llm_client=client)
        emitted: list[dict] = []
        runner.resultReady.connect(lambda d: emitted.append(d))
        runner.run_single_test("prompt", "input")

        assert len(emitted) == 1
        assert emitted[0]["success"] is True
        assert emitted[0]["actual_output"] == "response"

    def test_run_single_test_emits_stream_chunk(self) -> None:
        client = self._make_mock_client("streamed text")
        runner = TestRunner(llm_client=client)
        chunks: list[str] = []
        runner.streamChunk.connect(lambda c: chunks.append(c))
        runner.run_single_test("prompt", "input")

        assert len(chunks) == 1
        assert chunks[0] == "streamed text"

    def test_run_batch_tests(self) -> None:
        client = self._make_mock_client("batch response")
        runner = TestRunner(llm_client=client)
        test_cases = [
            {"input_data": "test1"},
            {"input_data": "test2"},
            {"input_data": "test3"},
        ]
        results = runner.run_batch_tests("prompt", test_cases)

        assert len(results) == 3
        assert all(r.success for r in results)

    def test_run_batch_tests_emits_progress(self) -> None:
        client = self._make_mock_client("response")
        runner = TestRunner(llm_client=client)
        progress_events: list[tuple[int, int]] = []
        runner.progress.connect(lambda c, t: progress_events.append((c, t)))

        test_cases = [{"input_data": "a"}, {"input_data": "b"}]
        runner.run_batch_tests("prompt", test_cases)

        assert len(progress_events) == 2
        assert progress_events[0] == (1, 2)
        assert progress_events[1] == (2, 2)


# ---------------------------------------------------------------------------
# TestWorker tests
# ---------------------------------------------------------------------------


class TestTestWorker:
    """Test TestWorker with mocked TestRunner."""

    def test_worker_single_test(self) -> None:
        client = MagicMock()
        client.complete.return_value = "worker response"
        runner = TestRunner(llm_client=client)
        worker = TestWorker(runner=runner, prompt="prompt", input_data="input")

        finished_results: list[list[dict]] = []
        worker.finished.connect(lambda r: finished_results.append(r))
        worker.run()

        assert len(finished_results) == 1
        assert len(finished_results[0]) == 1
        assert finished_results[0][0]["success"] is True

    def test_worker_batch_tests(self) -> None:
        client = MagicMock()
        client.complete.return_value = "batch"
        runner = TestRunner(llm_client=client)
        test_cases = [{"input_data": "a"}, {"input_data": "b"}]
        worker = TestWorker(runner=runner, prompt="prompt", test_cases=test_cases)

        finished_results: list[list[dict]] = []
        worker.finished.connect(lambda r: finished_results.append(r))
        worker.run()

        assert len(finished_results) == 1
        assert len(finished_results[0]) == 2

    def test_worker_no_data_emits_error(self) -> None:
        client = MagicMock()
        runner = TestRunner(llm_client=client)
        worker = TestWorker(runner=runner, prompt="prompt")

        error_msgs: list[str] = []
        worker.error.connect(lambda m: error_msgs.append(m))
        worker.run()

        assert len(error_msgs) == 1
        assert "No test data" in error_msgs[0]


# ---------------------------------------------------------------------------
# TestRunResult dataclass tests
# ---------------------------------------------------------------------------


class TestTestRunResult:
    def test_defaults(self) -> None:
        result = TestRunResult(success=True, input_data="test", actual_output="out")
        assert result.error is None
        assert result.latency_ms == 0.0

    def test_to_dict(self) -> None:
        result = TestRunResult(
            success=True, input_data="test", actual_output="out", latency_ms=100.5
        )
        d = TestRunner._result_to_dict(result)
        assert d["success"] is True
        assert d["input_data"] == "test"
        assert d["actual_output"] == "out"
        assert d["latency_ms"] == 100.5


# ---------------------------------------------------------------------------
# TestViewModel tests (mocked)
# ---------------------------------------------------------------------------


class TestTestViewModel:
    """Test TestViewModel with mocked dependencies."""

    def test_load_csv(self, tmp_path) -> None:
        from promptblocks.viewmodels.test_viewmodel import TestViewModel

        vm = TestViewModel()
        csv_file = tmp_path / "test.csv"
        csv_file.write_text("input_data,expected_output\nhello,world\nfoo,bar\n", encoding="utf-8")

        cases = vm._load_csv(str(csv_file))
        assert len(cases) == 2
        assert cases[0]["input_data"] == "hello"
        assert cases[1]["input_data"] == "foo"

    def test_load_csv_with_input_column(self, tmp_path) -> None:
        from promptblocks.viewmodels.test_viewmodel import TestViewModel

        vm = TestViewModel()
        csv_file = tmp_path / "test.csv"
        csv_file.write_text("input,output\ntest1,out1\n", encoding="utf-8")

        cases = vm._load_csv(str(csv_file))
        assert len(cases) == 1
        assert cases[0]["input_data"] == "test1"

    def test_load_csv_missing_file(self) -> None:
        from promptblocks.viewmodels.test_viewmodel import TestViewModel

        vm = TestViewModel()
        cases = vm._load_csv("nonexistent.csv")
        assert cases == []

    def test_validate_output_empty(self) -> None:
        from promptblocks.viewmodels.test_viewmodel import TestViewModel

        vm = TestViewModel()
        vm._current_project_id = "fake"
        result = vm._validate_output("")
        assert result.is_valid is False

    def test_validate_output_nonempty(self) -> None:
        from promptblocks.viewmodels.test_viewmodel import TestViewModel

        vm = TestViewModel()
        vm._current_project_id = "fake"
        result = vm._validate_output("some output")
        assert result.is_valid is True
