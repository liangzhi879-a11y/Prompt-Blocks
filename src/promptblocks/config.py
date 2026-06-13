"""Application configuration management using QSettings."""

from typing import Optional

from PySide6.QtCore import Property, QObject, QSettings, Signal, Slot

# Provider → default model (LiteLLM format: provider/model-name)
_PROVIDER_MODELS: dict[str, str] = {
    "openai": "openai/gpt-4o",
    "anthropic": "anthropic/claude-sonnet-4-20250514",
    "deepseek": "deepseek/deepseek-chat",
    "zai": "zai/glm-4.5",
    "dashscope": "dashscope/qwen-plus",
    "moonshot": "moonshot/moonshot-v1-auto",
    "minimax": "minimax/MiniMax-M2.5",
    "volcengine": "volcengine/doubao-seed-2-0-pro-260215",
    "ollama": "ollama/llama3",
}

# Provider → API base URL (None means use LiteLLM default)
_PROVIDER_API_BASES: dict[str, str] = {
    "deepseek": "https://api.deepseek.com",
    "zai": "https://api.z.ai/api/paas/v4",
    "dashscope": "https://dashscope.aliyuncs.com/compatible-mode/v1",
    "moonshot": "https://api.moonshot.ai/v1",
    "minimax": "https://api.minimaxi.com/v1",
    "volcengine": "https://ark.cn-beijing.volces.com",
    "ollama": "http://localhost:11434",
}


class AppConfig(QObject):
    """Manage application configuration, including LLM API keys and provider settings."""

    llmConfigChanged = Signal()  # noqa: N815
    testModelChanged = Signal()  # noqa: N815

    def __init__(self, parent=None):
        super().__init__(parent)
        self._settings = QSettings("PromptBlocks", "PromptBlocks")

    @Property(bool, notify=llmConfigChanged)
    def isLLMConfigured(self) -> bool:  # noqa: N802
        """Check if LLM provider and API key are configured."""
        provider = self._settings.value("llm/provider", "")
        api_key = self._settings.value("llm/api_key", "")
        return bool(provider) and (provider == "ollama" or bool(api_key))

    @Slot(result=str)
    def get_llm_provider(self) -> str:
        """Get the configured LLM provider."""
        return self._settings.value("llm/provider", "openai")

    @Slot(result=str)
    def get_llm_api_key(self) -> str:
        """Get the configured LLM API key."""
        return self._settings.value("llm/api_key", "")

    @staticmethod
    def _ensure_litellm_prefix(model_name: str, provider: str) -> str:
        """Ensure model name has LiteLLM provider prefix (e.g. 'deepseek/deepseek-chat')."""
        if "/" in model_name:
            return model_name  # Already has prefix
        if provider in _PROVIDER_MODELS:
            return f"{provider}/{model_name}"
        return model_name

    @Slot(result=str)
    def get_llm_model(self) -> str:
        """Get the default model name for the configured provider (LiteLLM format)."""
        provider = self.get_llm_provider()
        custom_model = self._settings.value("llm/model", "")
        if custom_model:
            return self._ensure_litellm_prefix(custom_model, provider)
        return _PROVIDER_MODELS.get(provider, f"{provider}/default")

    def get_llm_api_base(self) -> Optional[str]:
        """Get the API base URL for the configured provider."""
        custom_base = self._settings.value("llm/api_base", "")
        if custom_base:
            return custom_base
        provider = self.get_llm_provider()
        return _PROVIDER_API_BASES.get(provider)

    @Slot(str, str, str, str)
    def set_llm_config(
        self,
        provider: str,
        api_key: str,
        model: str = "",
        api_base: str = "",
    ) -> None:
        """Set LLM provider, API key, model, and optional API base configuration."""
        self._settings.setValue("llm/provider", provider)
        self._settings.setValue("llm/api_key", api_key)
        self._settings.setValue("llm/model", model)
        self._settings.setValue("llm/api_base", api_base)
        self._settings.sync()
        self.llmConfigChanged.emit()

    @Slot(str, str, str)
    def set_llm_config_3args(self, provider: str, api_key: str, model: str) -> None:
        """Set LLM config with 3 args (no api_base). QML overload entry point."""
        self.set_llm_config(provider, api_key, model, "")

    # ── Test model configuration ──

    @Property(bool, notify=testModelChanged)
    def useSameModel(self) -> bool:
        return bool(self._settings.value("test/use_same_model", True))

    @useSameModel.setter
    def useSameModel(self, value: bool) -> None:
        self._settings.setValue("test/use_same_model", value)
        self._settings.sync()
        self.testModelChanged.emit()

    @Slot(result=str)
    def get_test_provider(self) -> str:
        if self.useSameModel:
            return self.get_llm_provider()
        return self._settings.value("test/provider", "openai")

    @Slot(result=str)
    def get_test_api_key(self) -> str:
        if self.useSameModel:
            return self.get_llm_api_key()
        return self._settings.value("test/api_key", "")

    @Slot(result=str)
    def get_test_model(self) -> str:
        if self.useSameModel:
            return self.get_llm_model()
        custom_model = self._settings.value("test/model", "")
        if custom_model:
            provider = self.get_test_provider()
            return self._ensure_litellm_prefix(custom_model, provider)
        provider = self.get_test_provider()
        return _PROVIDER_MODELS.get(provider, f"{provider}/default")

    def get_test_api_base(self) -> Optional[str]:
        if self.useSameModel:
            return self.get_llm_api_base()
        custom_base = self._settings.value("test/api_base", "")
        if custom_base:
            return custom_base
        provider = self.get_test_provider()
        return _PROVIDER_API_BASES.get(provider)

    @Slot(str, str, str, str)
    def setTestConfig(
        self,
        provider: str,
        api_key: str,
        model: str = "",
        api_base: str = "",
    ) -> None:
        self._settings.setValue("test/provider", provider)
        self._settings.setValue("test/api_key", api_key)
        self._settings.setValue("test/model", model)
        self._settings.setValue("test/api_base", api_base)
        self._settings.sync()
        self.testModelChanged.emit()

    @Slot(str, str, str)
    def setTestConfig_3args(self, provider: str, api_key: str, model: str) -> None:
        """Set test config with 3 args (no api_base). QML overload entry point."""
        self.setTestConfig(provider, api_key, model, "")

    # ── Generic key-value access for QML ──

    # Keys that contain sensitive data and should not be exposed via getValue()
    _SENSITIVE_KEYS = frozenset({"llm/api_key", "test/api_key"})

    @Slot(str, result=str)
    def getValue(self, key: str) -> str:
        """Get a settings value by key, returns empty string if not found.

        Sensitive keys (API keys) are masked for security.
        """
        if key in self._SENSITIVE_KEYS:
            return ""
        return self._settings.value(key, "")

    @Slot(str, str)
    def setValue(self, key: str, value: str) -> None:
        """Set a settings value by key and sync immediately."""
        self._settings.setValue(key, value)
        self._settings.sync()

    # ── Price configuration ──

    @Slot(result=float)
    def get_compile_price_per_1k(self) -> float:
        """Get the price per 1k tokens for compile (main) model."""
        return float(self._settings.value("llm/compile_price_per_1k", 0.03))

    @Slot(float)
    def set_compile_price(self, price: float) -> None:
        """Set the price per 1k tokens for compile (main) model."""
        self._settings.setValue("llm/compile_price_per_1k", price)
        self._settings.sync()

    @Slot(result=float)
    def get_test_price_per_1k(self) -> float:
        """Get the price per 1k tokens for test model."""
        return float(self._settings.value("test/price_per_1k", 0.01))

    @Slot(float)
    def set_test_price(self, price: float) -> None:
        """Set the price per 1k tokens for test model."""
        self._settings.setValue("test/price_per_1k", price)
        self._settings.sync()
