"""PromptOptimizer ViewModel — three-step prompt optimization with LLM."""

import json
import re

from PySide6.QtCore import Property, QObject, QThread, Signal, Slot

from promptblocks.compilers.llm_client import LLMClient
from promptblocks.db.crud import OptimizationRecordCRUD
from promptblocks.db.session import get_session
from promptblocks.json_utils import parse_llm_json


# --- Step 1: Analyze problems ---

_ANALYZE_PROBLEMS_PROMPT = """你是一个提示词优化专家。请分析以下测试结果，识别提示词中存在的问题。

当前提示词：
{prompt}

测试结果：
{test_result_summary}

请从以下维度分析问题：
1. 内容质量：是否存在回答不准确、不完整的情况？
2. 格式规范：是否存在输出格式不符合要求的情况？
3. 输入一致性：是否存在偏离用户输入意图的情况？
4. 安全性：是否存在安全风险（红队测试未通过）？
5. 响应速度：是否存在响应过慢的问题？

请以JSON格式输出：
{{"problems": [{{"dimension": "内容质量", "issue": "问题描述", "evidence": "测试结果中的证据", "suggestion": "改进方向"}}], "priorityOrder": ["最优先维度", "次优先维度", ...]}}"""


# --- Step 2: Optimize prompt ---

_OPTIMIZE_PROMPT = """你是一个提示词优化专家。请基于以下问题分析，对提示词进行针对性优化。

当前提示词：
{prompt}

问题分析：
{problem_analysis}

{history_examples}

优化要求：
1. 针对每个识别出的问题进行具体改进
2. 保持提示词的整体结构和意图不变
3. 改进应具体、可操作，而非泛泛而谈
4. 输出完整的优化后提示词（不是片段）

请以JSON格式输出：
{{"optimizedPrompt": "优化后的完整提示词", "changes": [{{"dimension": "维度", "before": "修改前的关键内容", "after": "修改后的关键内容", "reason": "修改原因"}}]}}"""


# --- Step 3: Verify improvement ---

_VERIFY_IMPROVEMENT_PROMPT = """你是一个提示词评估专家。请对比优化前后的提示词，评估改进效果。

原始提示词：
{original_prompt}

优化后提示词：
{optimized_prompt}

问题分析：
{problem_analysis}

变更说明：
{changes}

请评估：
1. 每个识别的问题是否得到有效解决？
2. 是否引入了新的问题？
3. 整体改进程度如何？

请以JSON格式输出：
{{"improvements": [{{"dimension": "维度", "resolved": true/false, "improvement": "改进说明"}}], "newIssues": ["新引入的问题1", ...], "overallImprovement": "显著/中等/轻微/无改进", "confidence": 0.85}}"""


def _parse_json_response(text: str) -> dict:
    """Extract and parse JSON from LLM response with robust error recovery.

    Uses the shared json_utils module which handles:
    - Markdown code block wrapping
    - Truncated output (unclosed strings/brackets)
    - Single quotes, trailing commas, comments
    - Python-style booleans/None
    - JSON substring extraction
    """
    return parse_llm_json(text)


class PromptOptimizer(QObject):
    """ViewModel for three-step prompt optimization, exposed to QML."""

    optimizationCompleted = Signal(str)  # noqa: N815
    optimizationError = Signal(str)  # noqa: N815
    stepChanged = Signal()  # noqa: N815
    isOptimizingChanged = Signal()  # noqa: N815

    _STEP_DESCRIPTIONS = {
        -1: "优化失败",
        0: "未开始",
        1: "正在分析测试结果，识别提示词问题…",
        2: "正在基于分析结果优化提示词…",
        3: "正在验证优化效果…",
    }

    def __init__(self, app_config=None, parent=None):
        super().__init__(parent)
        self._app_config = app_config
        self._is_optimizing: bool = False
        self._current_step: int = 0
        self._step_description: str = self._STEP_DESCRIPTIONS[0]
        self._worker: "_OptimizeWorker | None" = None
        self._thread: "QThread | None" = None
        self._llm_client: "LLMClient | None" = None

    # --- Q_PROPERTY: isOptimizing ---

    def _read_is_optimizing(self) -> bool:
        return self._is_optimizing

    def _set_is_optimizing(self, value: bool) -> None:
        if self._is_optimizing != value:
            self._is_optimizing = value
            self.isOptimizingChanged.emit()

    isOptimizing = Property(bool, _read_is_optimizing, _set_is_optimizing, notify=isOptimizingChanged)  # noqa: N815

    # --- Q_PROPERTY: currentStep ---

    def _read_current_step(self) -> int:
        return self._current_step

    def _set_current_step(self, value: int) -> None:
        if self._current_step != value:
            self._current_step = value
            self._step_description = self._STEP_DESCRIPTIONS.get(value, "")
            self.stepChanged.emit()

    currentStep = Property(int, _read_current_step, _set_current_step, notify=stepChanged)  # noqa: N815

    # --- Q_PROPERTY: stepDescription ---

    def _read_step_description(self) -> str:
        return self._step_description

    stepDescription = Property(str, _read_step_description, notify=stepChanged)  # noqa: N815

    # --- Slot: optimize ---

    @Slot(str, str, str)
    def optimize(self, prompt: str, testResultJson: str, project_id: str) -> None:  # noqa: N815
        """Start the three-step optimization process in a background thread."""
        if not prompt or not prompt.strip():
            self.optimizationError.emit("提示词不能为空")
            return
        if not testResultJson or not testResultJson.strip():
            self.optimizationError.emit("测试结果不能为空")
            return

        self._cleanup_thread()
        self._set_is_optimizing(True)
        self._set_current_step(0)

        llm = self._get_llm_client()
        self._thread = QThread()
        self._worker = _OptimizeWorker(
            llm=llm,
            prompt=prompt,
            test_result_json=testResultJson,
            project_id=project_id,
        )
        self._worker.moveToThread(self._thread)
        self._thread.started.connect(self._worker.run)
        self._worker.stepChanged.connect(self._on_step_changed)
        self._worker.finished.connect(self._on_optimize_finished)
        self._worker.error.connect(self._on_optimize_error)
        self._worker.finished.connect(self._thread.quit)
        self._worker.error.connect(self._thread.quit)
        self._thread.finished.connect(self._on_thread_finished)
        self._thread.start()

    @Slot()
    def stopOptimization(self) -> None:  # noqa: N802
        """Stop the currently running optimization worker."""
        self._cleanup_thread()
        self._set_is_optimizing(False)
        self._set_current_step(0)

    # --- Internal handlers ---

    def _on_step_changed(self, step: int) -> None:
        self._set_current_step(step)

    def _on_optimize_finished(self, result_json: str) -> None:
        self._set_is_optimizing(False)
        # Keep currentStep at 3 (completed) — do NOT reset to 0 here,
        # otherwise the popup's visible: currentStep >= 3 condition will
        # hide the result content before it's displayed.
        self.optimizationCompleted.emit(result_json)

    def _on_optimize_error(self, message: str) -> None:
        self._set_is_optimizing(False)
        # Set step to -1 to indicate error state (popup shows error UI)
        if self._current_step != -1:
            self._current_step = -1
            self._step_description = message
            self.stepChanged.emit()
        self.optimizationError.emit(message)

    def _on_thread_finished(self) -> None:
        """Clear worker/thread references after the thread has fully stopped.

        Only clears if the references still point to THIS thread/worker,
        to prevent an old thread's finished signal from clearing new references.
        """
        sender = self.sender()
        if sender is self._thread:
            self._worker = None
            self._thread = None

    def _cleanup_thread(self) -> None:
        """Safely stop any existing worker/thread and clear references.

        Uses non-blocking quit to avoid freezing the UI. If the thread
        is still running after quit(), we disconnect the finished signal
        to prevent the old thread from clearing new references, and let
        the thread finish naturally in the background.
        """
        if self._worker is not None:
            try:
                self._worker.cancel()
            except RuntimeError:
                pass
        if self._thread is not None:
            try:
                if self._thread.isRunning():
                    self._thread.quit()
                    # Non-blocking: don't wait for the thread to finish.
                    # If it doesn't stop immediately, it will finish on its own.
                    self._thread.wait(500)
            except RuntimeError:
                pass
            try:
                self._thread.finished.disconnect(self._on_thread_finished)
            except RuntimeError:
                pass
        self._worker = None
        self._thread = None

    def _get_llm_client(self) -> LLMClient:
        """Get or create a reusable LLMClient."""
        if self._llm_client is None:
            if self._app_config is not None:
                self._llm_client = LLMClient.from_app_config(self._app_config)
            else:
                self._llm_client = LLMClient()
        return self._llm_client


class _OptimizeWorker(QObject):
    """Background worker for three-step prompt optimization."""

    finished = Signal(str)
    error = Signal(str)
    stepChanged = Signal(int)  # noqa: N815

    def __init__(self, llm: LLMClient, prompt: str, test_result_json: str, project_id: str, parent=None):
        super().__init__(parent)
        self._llm = llm
        self._prompt = prompt
        self._test_result_json = test_result_json
        self._project_id = project_id
        self._cancelled = False

    def run(self) -> None:
        try:
            # Step 1: Analyze problems
            self.stepChanged.emit(1)
            problem_analysis = self._analyze_problems()
            if self._cancelled:
                return

            # Step 2: Optimize prompt
            self.stepChanged.emit(2)
            optimization_result = self._optimize_prompt(problem_analysis)
            if self._cancelled:
                return

            # Step 3: Verify improvement
            self.stepChanged.emit(3)
            improvement_report = self._verify_improvement(problem_analysis, optimization_result)
            if self._cancelled:
                return

            # Assemble final result
            result = {
                "originalPrompt": self._prompt,
                "optimizedPrompt": optimization_result.get("optimizedPrompt", ""),
                "problemAnalysis": problem_analysis,
                "changes": optimization_result.get("changes", []),
                "improvementReport": improvement_report,
            }

            # Save to database
            self._save_to_db(result)

            self.finished.emit(json.dumps(result, ensure_ascii=False))

        except Exception as exc:
            self.error.emit(f"优化失败: {exc}")

    def _analyze_problems(self) -> dict:
        """Step 1: Analyze test results to identify prompt weaknesses."""
        user_prompt = _ANALYZE_PROBLEMS_PROMPT.format(
            prompt=self._prompt,
            test_result_summary=self._test_result_json[:3000],
        )
        response = self._llm.complete(
            system_prompt="你是一个提示词优化专家。请严格按照JSON格式输出分析结果。",
            user_prompt=user_prompt,
            temperature=0.3,
            max_tokens=4096,
        )
        return _parse_json_response(response)

    def _optimize_prompt(self, problem_analysis: dict) -> dict:
        """Step 2: Optimize the prompt based on problem analysis."""
        history_examples = self._build_history_examples()

        user_prompt = _OPTIMIZE_PROMPT.format(
            prompt=self._prompt,
            problem_analysis=json.dumps(problem_analysis, ensure_ascii=False, indent=2),
            history_examples=history_examples,
        )
        response = self._llm.complete(
            system_prompt="你是一个提示词优化专家。请严格按照JSON格式输出优化结果。",
            user_prompt=user_prompt,
            temperature=0.3,
            max_tokens=16384,
        )
        return _parse_json_response(response)

    def _verify_improvement(self, problem_analysis: dict, optimization_result: dict) -> dict:
        """Step 3: Compare original and optimized prompts, evaluate improvement."""
        changes_text = json.dumps(optimization_result.get("changes", []), ensure_ascii=False, indent=2)
        user_prompt = _VERIFY_IMPROVEMENT_PROMPT.format(
            original_prompt=self._prompt,
            optimized_prompt=optimization_result.get("optimizedPrompt", ""),
            problem_analysis=json.dumps(problem_analysis, ensure_ascii=False, indent=2),
            changes=changes_text,
        )
        response = self._llm.complete(
            system_prompt="你是一个提示词评估专家。请严格按照JSON格式输出评估结果。",
            user_prompt=user_prompt,
            temperature=0.1,
            max_tokens=4096,
        )
        return _parse_json_response(response)

    def _build_history_examples(self) -> str:
        """Build few-shot examples from recent optimization records for the project."""
        try:
            with get_session() as session:
                records = OptimizationRecordCRUD.get_recent_for_fewshot(session, self._project_id, limit=3)
                if not records:
                    return ""
                examples = []
                for rec in records:
                    examples.append(
                        f"历史优化示例：\n"
                        f"原始提示词片段：{rec.original_prompt[:200]}…\n"
                        f"优化后提示词片段：{rec.optimized_prompt[:200]}…\n"
                        f"主要变更：{json.dumps(rec.changes, ensure_ascii=False) if rec.changes else '无记录'}"
                    )
                return "\n\n".join(examples)
        except Exception:
            return ""

    def _save_to_db(self, result: dict) -> None:
        """Save the optimization result to the database."""
        try:
            with get_session() as session:
                OptimizationRecordCRUD.create(
                    session,
                    project_id=self._project_id,
                    original_prompt=result["originalPrompt"],
                    optimized_prompt=result["optimizedPrompt"],
                    problem_analysis=result.get("problemAnalysis"),
                    changes=result.get("changes"),
                    improvement_report=result.get("improvementReport"),
                    test_result_snapshot=json.loads(self._test_result_json) if self._test_result_json else None,
                )
        except Exception:
            pass

    def cancel(self) -> None:
        self._cancelled = True
