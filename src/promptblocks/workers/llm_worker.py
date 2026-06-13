"""LLMWorker — QThread-based worker for async LLM API calls."""

from PySide6.QtCore import QThread, Signal, Slot, QMutex, QMutexLocker


class LLMWorker(QThread):
    """Background thread worker for calling LLM APIs without blocking the UI."""

    completed = Signal(str)
    error = Signal(str)
    progress = Signal(int)

    def __init__(self, prompt, inputText, config, parent=None):
        super().__init__(parent)
        self._prompt = prompt
        self._inputText = inputText
        self._config = config  # dict with provider, api_key, model, api_base
        self._mutex = QMutex()
        self._cancelled = False

    def run(self):
        """Execute the LLM call in a background thread."""
        try:
            result = self._callLLM()
            locker = QMutexLocker(self._mutex)
            if not self._cancelled:
                locker.unlock()
                self.completed.emit(result)
        except Exception as e:
            locker = QMutexLocker(self._mutex)
            if not self._cancelled:
                locker.unlock()
                self.error.emit(str(e))

    @Slot()
    def cancel(self):
        """Mark the worker as cancelled so it won't emit results."""
        locker = QMutexLocker(self._mutex)
        self._cancelled = True

    def _callLLM(self):
        """Call the LLM API using litellm if available, else return a placeholder."""
        try:
            import litellm
            provider = self._config.get("provider", "openai")
            api_key = self._config.get("api_key", "")
            model = self._config.get("model", "openai/gpt-4o")
            api_base = self._config.get("api_base", "")

            messages = []
            if self._prompt:
                messages.append({"role": "system", "content": self._prompt})
            if self._inputText:
                messages.append({"role": "user", "content": self._inputText})

            kwargs = {
                "model": model,
                "messages": messages,
                "api_key": api_key,
            }
            if api_base:
                kwargs["api_base"] = api_base

            response = litellm.completion(**kwargs)
            self.progress.emit(100)
            return response.choices[0].message.content

        except ImportError:
            # litellm not available — return placeholder
            self.progress.emit(100)
            return f"[LLM未配置] 提示词长度: {len(self._prompt)} 字符, 输入长度: {len(self._inputText)} 字符"
        except Exception as e:
            raise RuntimeError(f"LLM调用失败: {e}") from e
