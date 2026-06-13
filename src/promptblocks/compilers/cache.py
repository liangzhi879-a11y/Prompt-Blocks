"""CompileCache — in-memory LRU cache for LLM compilation results."""

from __future__ import annotations

import hashlib
from collections import OrderedDict
from threading import Lock


class CompileCache:
    """Thread-safe LRU cache for LLM call results.

    Key is derived from model + system_prompt + user_prompt + temperature.
    Maximum 1000 entries; oldest evicted when full.
    """

    def __init__(self, max_size: int = 1000) -> None:
        self._max_size = max_size
        self._cache: OrderedDict[str, str] = OrderedDict()
        self._lock = Lock()

    @staticmethod
    def make_key(model: str, system_prompt: str, user_prompt: str, temperature: float) -> str:
        """Generate a deterministic cache key from call parameters."""
        raw = f"{model}||{system_prompt}||{user_prompt}||{temperature}"
        return hashlib.md5(raw.encode()).hexdigest()

    def get(self, key: str) -> str | None:
        """Retrieve a cached value. Returns None on miss."""
        with self._lock:
            if key not in self._cache:
                return None
            self._cache.move_to_end(key)
            return self._cache[key]

    def set(self, key: str, value: str) -> None:
        """Store a value in the cache, evicting the oldest entry if at capacity."""
        with self._lock:
            if key in self._cache:
                self._cache.move_to_end(key)
                self._cache[key] = value
            else:
                if len(self._cache) >= self._max_size:
                    self._cache.popitem(last=False)
                self._cache[key] = value

    def clear(self) -> None:
        """Remove all entries from the cache."""
        with self._lock:
            self._cache.clear()
