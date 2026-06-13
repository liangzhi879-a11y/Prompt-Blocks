"""SingleTurnViewModel — optimizes raw user input for single-turn AI conversations."""

import re

from PySide6.QtCore import Property, QObject, QThread, Signal, Slot


# System prompt for single-turn optimization
_SINGLE_TURN_SYSTEM_PROMPT = """你是一个专业的提示词优化专家。你的任务是将用户粗糙的输入优化为高质量、低歧义的提示词，使AI能够给出更准确、更可用的回答。

## 优化原则

### 1. 角色锚定
如果用户未明确指定角色，根据问题类型为其补充合适的专家角色（如专家、教师、编辑、顾问、面试官等）。

### 2. 目标具象化
将模糊的请求转化为具体产出要求，量化输出形式、数量、长度、受众和风格。

### 3. 背景与上下文补充
在保持原意的基础上，推断可能需要的技术栈、业务场景等背景信息，补充到提示词中。

### 4. 格式与结构指令
根据需要添加输出格式要求（JSON、Markdown表格、列表等），确保输出可解析和可读。

### 5. 思维链与约束
对于需要推理的任务，添加分步思考要求；对于需要限定范围的任务，添加明确的约束条件。

### 6. 示例驱动
如果用户需求适合，提供输入-输出范例格式。

### 7. 安全与伦理约束
如果用户请求涉及敏感领域，自动添加安全护栏（如医疗建议免责声明、法律风险提示等）。

## 输出规范

- 直接输出优化后的提示词，不要添加解释、前言或后记
- 保持用户原始的核心意图不变，只做增强和结构化
- 优化后的提示词应具备清晰的层次结构
- 如果原始输入已经很好，只做必要的小幅改进，不要过度改写
- 适当使用Markdown格式增强可读性

## 优化策略选择

根据用户输入的特点，选择合适的优化策略组合：
- 信息不足时：补充上下文和角色
- 目标模糊时：具象化为具体产出
- 需要结构化输出时：添加格式指令
- 需要推理分析时：添加思维链
- 面向公众使用时：添加安全护栏"""


class SingleTurnViewModel(QObject):
    """ViewModel for single-turn conversation input optimization."""

    contentChanged = Signal()
    optimizationCompleted = Signal()
    optimizationFailed = Signal(str)

    def __init__(self, app_config=None, parent=None):
        super().__init__(parent)
        self._app_config = app_config
        self._raw_input = ""
        self._optimized_output = ""
        self._optimizing = False
        self._thread = None
        self._worker = None

    @Property(str, notify=contentChanged)
    def rawInput(self) -> str:
        return self._raw_input

    @rawInput.setter
    def rawInput(self, value: str):
        if self._raw_input != value:
            self._raw_input = value
            self.contentChanged.emit()

    @Property(str, notify=contentChanged)
    def optimizedOutput(self) -> str:
        return self._optimized_output

    @optimizedOutput.setter
    def optimizedOutput(self, value: str):
        if self._optimized_output != value:
            self._optimized_output = value
            self.contentChanged.emit()

    @Property(bool, notify=contentChanged)
    def isOptimizing(self) -> bool:
        return self._optimizing

    @isOptimizing.setter
    def isOptimizing(self, value: bool):
        if self._optimizing != value:
            self._optimizing = value
            self.contentChanged.emit()

    @Slot(str)
    def optimize(self, user_input: str):
        """Optimize the user's raw input for single-turn conversation (async)."""
        if not user_input or not user_input.strip():
            self.optimizationFailed.emit("请输入需要优化的内容")
            return

        # Clean up any previous thread before starting a new one
        if self._thread is not None and self._thread.isRunning():
            self._thread.quit()
            self._thread.wait(3000)
        self._worker = None
        self._thread = None

        self.isOptimizing = True
        self.rawInput = user_input

        # Run optimization in a background thread to prevent UI freeze
        self._thread = QThread()
        self._worker = _OptimizeWorker(
            app_config=self._app_config,
            user_input=user_input,
        )
        self._worker.moveToThread(self._thread)
        self._thread.started.connect(self._worker.run)
        self._worker.finished.connect(self._on_optimize_finished)
        self._worker.error.connect(self._on_optimize_error)
        self._worker.finished.connect(self._thread.quit)
        self._worker.error.connect(self._thread.quit)
        self._thread.finished.connect(self._on_thread_finished)
        self._thread.start()

    def _on_optimize_finished(self, result: str):
        self.optimizedOutput = self._post_process(result)
        self.isOptimizing = False
        self.optimizationCompleted.emit()

    def _on_optimize_error(self, message: str):
        self.optimizedOutput = ""
        self.isOptimizing = False
        self.optimizationFailed.emit(message)

    def _on_thread_finished(self):
        """Clear references after the thread has fully stopped.

        Only clears if the references still point to THIS thread/worker,
        to prevent an old thread's finished signal from clearing new references.
        """
        sender = self.sender()
        if sender is self._thread:
            self._worker = None
            self._thread = None

    def _post_process(self, text: str) -> str:
        """Clean up AI optimization output."""
        if not text:
            return ""

        text = text.strip()

        # Remove common preamble patterns
        preamble_patterns = [
            r'^(好的[，,]\s*)?(以下是|根据您|以下为)[^#\n]*?\n',
            r'^(好的[，,]\s*)?(我将|我来)[^#\n]*?\n',
            r'^\*\*优化后的[^*]*\*\*\n?',
            r'^优化后的[^\n]*\n?',
            r'^(优化结果[:：]?\s*)',
        ]
        for pat in preamble_patterns:
            text = re.sub(pat, '', text, flags=re.MULTILINE)

        return text.strip()


class _OptimizeWorker(QObject):
    """Background worker for LLM optimization to prevent UI freeze."""

    finished = Signal(str)
    error = Signal(str)

    def __init__(self, app_config, user_input: str, parent=None):
        super().__init__(parent)
        self._app_config = app_config
        self._user_input = user_input

    def run(self) -> None:
        try:
            from promptblocks.compilers.llm_client import LLMClient
            if self._app_config:
                client = LLMClient.from_app_config(self._app_config)
            else:
                client = LLMClient()

            user_prompt = (
                "请优化以下用户输入，使其更适合与AI对话：\n\n"
                f"---\n{self._user_input}\n---\n\n"
                "请直接输出优化后的提示词。"
            )

            result = client.complete(
                system_prompt=_SINGLE_TURN_SYSTEM_PROMPT,
                user_prompt=user_prompt,
                temperature=0.3,
                max_tokens=2048,
            )

            self.finished.emit(result)

        except Exception as e:
            self.error.emit(str(e))
