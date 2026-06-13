"""LLMClient — unified LLM call layer with caching, retry, and timeout."""

from __future__ import annotations

import threading
import time

import litellm

from promptblocks.compilers.cache import CompileCache

_DEFAULT_MODEL = "gpt-4o-mini"
_DEFAULT_TIMEOUT = 60
_MAX_RETRIES = 3


class LLMClient:
    """Thin wrapper around litellm.completion with caching, retry, and timeout."""

    def __init__(
        self,
        model_name: str | None = None,
        api_key: str | None = None,
        api_base: str | None = None,
        cache: CompileCache | None = None,
    ) -> None:
        self.model_name = model_name or _DEFAULT_MODEL
        self.api_key = api_key
        self.api_base = api_base
        self._cache = cache or CompileCache()
        self._lock = threading.Lock()

    def complete(
        self,
        system_prompt: str,
        user_prompt: str,
        temperature: float = 0.1,
        max_tokens: int = 2048,
    ) -> str:
        """Call LLM with caching, retry (exponential backoff), and timeout.

        Returns the assistant message content as a string.
        Raises RuntimeError on repeated failure.
        """
        cache_key = CompileCache.make_key(self.model_name, system_prompt, user_prompt, temperature)
        cached = self._cache.get(cache_key)
        if cached is not None:
            return cached

        with self._lock:
            last_error: Exception | None = None
            for attempt in range(_MAX_RETRIES):
                try:
                    kwargs: dict = {
                        "model": self.model_name,
                        "messages": [
                            {"role": "system", "content": system_prompt},
                            {"role": "user", "content": user_prompt},
                        ],
                        "temperature": temperature,
                        "max_tokens": max_tokens,
                        "timeout": _DEFAULT_TIMEOUT,
                    }
                    if self.api_key:
                        kwargs["api_key"] = self.api_key
                    if self.api_base:
                        kwargs["api_base"] = self.api_base

                    response = litellm.completion(**kwargs)
                    content = response.choices[0].message.content or ""
                    self._cache.set(cache_key, content)
                    return content

                except litellm.exceptions.AuthenticationError as exc:
                    raise RuntimeError(
                        "LLM authentication failed. Please check your API key and provider settings."
                    ) from exc
                except litellm.exceptions.APIError as exc:
                    last_error = exc
                except litellm.exceptions.Timeout as exc:
                    last_error = exc
                except Exception as exc:
                    last_error = exc

                if attempt < _MAX_RETRIES - 1:
                    backoff = 3 * (2 ** attempt)  # 3s, 6s — more forgiving for rate limits
                    time.sleep(backoff)

            raise RuntimeError(f"LLM call failed after {_MAX_RETRIES} retries: {last_error}")

    @classmethod
    def from_app_config(cls, app_config: object) -> LLMClient:
        """Create an LLMClient from an AppConfig instance (uses compile model config)."""
        model_name = getattr(app_config, "get_llm_model", lambda: "openai/gpt-4o")()
        api_key = getattr(app_config, "get_llm_api_key", lambda: "")()
        api_base = getattr(app_config, "get_llm_api_base", lambda: None)()
        return cls(model_name=model_name, api_key=api_key or None, api_base=api_base)

    @classmethod
    def from_app_config_for_test(cls, app_config: object) -> LLMClient:
        """Create an LLMClient from an AppConfig instance (uses test model config).

        Respects the useSameModel flag: if true, falls back to compile model config.
        """
        model_name = getattr(app_config, "get_test_model", lambda: None)()
        api_key = getattr(app_config, "get_test_api_key", lambda: "")()
        api_base = getattr(app_config, "get_test_api_base", lambda: None)()
        if not model_name:
            return cls.from_app_config(app_config)
        return cls(model_name=model_name, api_key=api_key or None, api_base=api_base)
