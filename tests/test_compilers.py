"""Tests for the NL→Block compiler core."""

from __future__ import annotations

import json
from unittest.mock import MagicMock, patch

import pytest

from promptblocks.compilers.cache import CompileCache
from promptblocks.compilers.guidance_compiler import GuidanceCompiler
from promptblocks.compilers.llm_client import LLMClient
from promptblocks.compilers.registry import CompileResult, CompilerRegistry
from promptblocks.compilers.schema_compiler import SchemaCompiler, SchemaCompileResult


# ---------------------------------------------------------------------------
# CompileCache
# ---------------------------------------------------------------------------


class TestCompileCache:
    def test_get_miss(self):
        cache = CompileCache()
        assert cache.get("nonexistent") is None

    def test_set_and_get(self):
        cache = CompileCache()
        cache.set("key1", "value1")
        assert cache.get("key1") == "value1"

    def test_overwrite(self):
        cache = CompileCache()
        cache.set("key1", "old")
        cache.set("key1", "new")
        assert cache.get("key1") == "new"

    def test_lru_eviction(self):
        cache = CompileCache(max_size=3)
        cache.set("a", "1")
        cache.set("b", "2")
        cache.set("c", "3")
        cache.set("d", "4")  # evicts "a"
        assert cache.get("a") is None
        assert cache.get("d") == "4"

    def test_lru_access_promotes(self):
        cache = CompileCache(max_size=3)
        cache.set("a", "1")
        cache.set("b", "2")
        cache.set("c", "3")
        cache.get("a")  # promote "a"
        cache.set("d", "4")  # evicts "b" (least recently used)
        assert cache.get("a") == "1"
        assert cache.get("b") is None

    def test_clear(self):
        cache = CompileCache()
        cache.set("k", "v")
        cache.clear()
        assert cache.get("k") is None

    def test_make_key_deterministic(self):
        k1 = CompileCache.make_key("m", "sys", "usr", 0.1)
        k2 = CompileCache.make_key("m", "sys", "usr", 0.1)
        assert k1 == k2

    def test_make_key_differs_for_different_inputs(self):
        k1 = CompileCache.make_key("m1", "sys", "usr", 0.1)
        k2 = CompileCache.make_key("m2", "sys", "usr", 0.1)
        assert k1 != k2


# ---------------------------------------------------------------------------
# LLMClient
# ---------------------------------------------------------------------------


class TestLLMClient:
    def test_complete_returns_content(self):
        mock_response = MagicMock()
        mock_response.choices = [MagicMock()]
        mock_response.choices[0].message.content = '{"type": "object"}'

        with patch("promptblocks.compilers.llm_client.litellm") as mock_litellm:
            mock_litellm.completion.return_value = mock_response
            mock_litellm.exceptions = MagicMock()
            client = LLMClient(model_name="test-model", api_key="fake")
            result = client.complete("sys", "usr")
        assert result == '{"type": "object"}'

    def test_complete_uses_cache(self):
        cache = CompileCache()
        key = CompileCache.make_key("test-model", "sys", "usr", 0.1)
        cache.set(key, "cached_result")

        client = LLMClient(model_name="test-model", cache=cache)
        result = client.complete("sys", "usr")
        assert result == "cached_result"

    def test_complete_retries_on_api_error(self):
        mock_response = MagicMock()
        mock_response.choices = [MagicMock()]
        mock_response.choices[0].message.content = "ok"

        import litellm as real_litellm

        with patch("promptblocks.compilers.llm_client.litellm") as mock_litellm:
            mock_litellm.completion.side_effect = [
                real_litellm.exceptions.APIError(
                    status_code=500, message="fail", llm_provider="test", model="test-model"
                ),
                mock_response,
            ]
            mock_litellm.exceptions = real_litellm.exceptions
            client = LLMClient(model_name="test-model", api_key="fake")
            with patch("promptblocks.compilers.llm_client.time.sleep"):
                result = client.complete("sys", "usr")
        assert result == "ok"

    def test_complete_raises_after_max_retries(self):
        import litellm as real_litellm

        with patch("promptblocks.compilers.llm_client.litellm") as mock_litellm:
            mock_litellm.completion.side_effect = real_litellm.exceptions.APIError(
                status_code=500, message="fail", llm_provider="test", model="test-model"
            )
            mock_litellm.exceptions = real_litellm.exceptions
            client = LLMClient(model_name="test-model", api_key="fake")
            with patch("promptblocks.compilers.llm_client.time.sleep"):
                with pytest.raises(RuntimeError, match="failed after 3 retries"):
                    client.complete("sys", "usr")

    def test_complete_auth_error_raises_immediately(self):
        import litellm as real_litellm

        with patch("promptblocks.compilers.llm_client.litellm") as mock_litellm:
            mock_litellm.completion.side_effect = real_litellm.exceptions.AuthenticationError(
                message="bad key", llm_provider="test", model="test-model"
            )
            mock_litellm.exceptions = real_litellm.exceptions
            client = LLMClient(model_name="test-model", api_key="bad")
            with pytest.raises(RuntimeError, match="authentication failed"):
                client.complete("sys", "usr")

    def test_from_app_config(self):
        config = MagicMock()
        config.get_llm_model.return_value = "deepseek/deepseek-chat"
        config.get_llm_api_key.return_value = "sk-test"
        config.get_llm_api_base.return_value = "https://api.deepseek.com"
        client = LLMClient.from_app_config(config)
        assert client.model_name == "deepseek/deepseek-chat"
        assert client.api_key == "sk-test"
        assert client.api_base == "https://api.deepseek.com"


# ---------------------------------------------------------------------------
# SchemaCompiler
# ---------------------------------------------------------------------------


class TestSchemaCompiler:
    def test_compile_success(self):
        schema_json = json.dumps({
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "姓名": {"type": "string"},
                    "年龄": {"type": "integer"},
                    "性别": {"type": "string"},
                },
                "required": ["姓名", "年龄", "性别"],
            },
        })

        mock_llm = MagicMock(spec=LLMClient)
        mock_llm.complete.return_value = schema_json

        compiler = SchemaCompiler(llm_client=mock_llm)
        result = compiler.compile("输出一个列表，每个元素包含姓名、年龄、性别，年龄是整数")

        assert result.success is True
        assert result.schema["type"] == "array"
        assert "姓名" in result.schema["items"]["properties"]
        assert result.error is None

    def test_compile_caches_result(self):
        schema_json = '{"type": "object", "properties": {"name": {"type": "string"}}}'
        mock_llm = MagicMock(spec=LLMClient)
        mock_llm.complete.return_value = schema_json

        compiler = SchemaCompiler(llm_client=mock_llm)
        r1 = compiler.compile("same input")
        r2 = compiler.compile("same input")

        assert r1.success is True
        assert r2.success is True
        # LLM should only be called once due to cache
        assert mock_llm.complete.call_count == 1

    def test_compile_handles_markdown_fences(self):
        schema_json = '```json\n{"type": "object", "properties": {"x": {"type": "string"}}}\n```'
        mock_llm = MagicMock(spec=LLMClient)
        mock_llm.complete.return_value = schema_json

        compiler = SchemaCompiler(llm_client=mock_llm)
        result = compiler.compile("describe x")

        assert result.success is True
        assert result.schema["type"] == "object"

    def test_compile_failure_returns_error(self):
        mock_llm = MagicMock(spec=LLMClient)
        mock_llm.complete.side_effect = RuntimeError("LLM down")

        compiler = SchemaCompiler(llm_client=mock_llm)
        result = compiler.compile("anything")

        assert result.success is False
        assert result.error is not None
        assert "LLM down" in result.error

    def test_compile_invalid_json_retries(self):
        mock_llm = MagicMock(spec=LLMClient)
        mock_llm.complete.side_effect = ["not json at all", '{"type": "object"}']

        compiler = SchemaCompiler(llm_client=mock_llm)
        result = compiler.compile("test")

        assert result.success is True
        assert mock_llm.complete.call_count == 2


# ---------------------------------------------------------------------------
# GuidanceCompiler
# ---------------------------------------------------------------------------


class TestGuidanceCompiler:
    def test_compile_from_schema_simple_object(self):
        schema = {
            "type": "object",
            "properties": {
                "name": {"type": "string"},
                "age": {"type": "integer"},
            },
        }
        compiler = GuidanceCompiler()
        template = compiler.compile_from_schema(schema)

        assert "{{#system~}}" in template
        assert "{{~/system}}" in template
        assert "{{gen 'name'}}" in template
        assert "{{gen 'age'}}" in template

    def test_compile_from_schema_array(self):
        schema = {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "姓名": {"type": "string"},
                    "年龄": {"type": "integer"},
                },
            },
        }
        compiler = GuidanceCompiler()
        template = compiler.compile_from_schema(schema)

        assert "{{#each items}}" in template
        assert "{{gen '姓名'}}" in template
        assert "{{gen '年龄'}}" in template

    def test_compile_from_nl(self):
        schema_json = json.dumps({
            "type": "object",
            "properties": {"result": {"type": "string"}},
        })
        mock_llm = MagicMock(spec=LLMClient)
        mock_llm.complete.return_value = schema_json

        compiler = GuidanceCompiler(llm_client=mock_llm)
        template = compiler.compile_from_nl("输出一个结果字段")

        assert "{{#system~}}" in template
        assert "{{gen 'result'}}" in template

    def test_compile_from_nl_failure(self):
        mock_llm = MagicMock(spec=LLMClient)
        mock_llm.complete.side_effect = RuntimeError("fail")

        compiler = GuidanceCompiler(llm_client=mock_llm)
        template = compiler.compile_from_nl("anything")

        assert template == ""

    def test_complex_schema_uses_llm(self):
        schema = {
            "type": "object",
            "properties": {
                "user": {
                    "type": "object",
                    "properties": {
                        "profile": {
                            "type": "object",
                            "properties": {
                                "deep": {"type": "string"},
                            },
                        },
                    },
                },
            },
        }
        mock_llm = MagicMock(spec=LLMClient)
        mock_llm.complete.return_value = "{{#system~}}\ncomplex\n{{~/system}}"

        compiler = GuidanceCompiler(llm_client=mock_llm)
        template = compiler.compile_from_schema(schema)

        assert "complex" in template

    def test_conditional_schema_is_complex(self):
        schema = {
            "type": "object",
            "properties": {"x": {"type": "string"}},
            "anyOf": [{"required": ["x"]}],
        }
        compiler = GuidanceCompiler()
        assert compiler._is_complex(schema) is True


# ---------------------------------------------------------------------------
# CompilerRegistry
# ---------------------------------------------------------------------------


class TestCompilerRegistry:
    def test_register_and_compile(self):
        mock_compiler = MagicMock()
        mock_compiler.compile.return_value = CompileResult(
            success=True, compiled_code="output", raw_response="output"
        )

        registry = CompilerRegistry()
        registry.register("instruction", mock_compiler)
        result = registry.compile("instruction", "test input")

        assert result.success is True
        assert result.compiled_code == "output"
        mock_compiler.compile.assert_called_once_with("test input")

    def test_compile_unknown_type(self):
        registry = CompilerRegistry()
        result = registry.compile("unknown", "input")

        assert result.success is False
        assert "No compiler registered" in (result.error or "")

    def test_get_compiler(self):
        mock_compiler = MagicMock()
        registry = CompilerRegistry()
        registry.register("format_constraint", mock_compiler)

        assert registry.get_compiler("format_constraint") is mock_compiler
        assert registry.get_compiler("nonexistent") is None


# ---------------------------------------------------------------------------
# CompileResult
# ---------------------------------------------------------------------------


class TestCompileResult:
    def test_defaults(self):
        r = CompileResult(success=True, compiled_code="x", raw_response="x")
        assert r.error is None
        assert r.cache_hit is False

    def test_with_error(self):
        r = CompileResult(success=False, compiled_code="", raw_response="", error="bad")
        assert r.error == "bad"
