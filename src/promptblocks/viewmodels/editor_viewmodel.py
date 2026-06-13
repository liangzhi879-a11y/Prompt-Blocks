"""Editor ViewModel managing editor mode and content state."""

import re

from PySide6.QtCore import Property, QObject, QThread, Signal, Slot


class _GenerateWorker(QObject):
    """Background worker for AI content generation to prevent UI freeze."""

    finished = Signal(str)
    error = Signal(str)

    def __init__(self, app_config, system_prompt: str, user_prompt: str, parent=None):
        super().__init__(parent)
        self._app_config = app_config
        self._system_prompt = system_prompt
        self._user_prompt = user_prompt

    def run(self) -> None:
        try:
            from promptblocks.compilers.llm_client import LLMClient
            if self._app_config:
                client = LLMClient.from_app_config(self._app_config)
            else:
                client = LLMClient()

            result = client.complete(
                system_prompt=self._system_prompt,
                user_prompt=self._user_prompt,
                temperature=0.3,
                max_tokens=1024,
            )

            self.finished.emit(result)

        except Exception as e:
            self.error.emit(str(e))


class EditorViewModel(QObject):
    """ViewModel managing editor mode (AI/manual) and content state."""

    modeChanged = Signal()  # noqa: N815
    contentChanged = Signal()  # noqa: N815
    aiGenerationCompleted = Signal()  # noqa: N815
    currentBlockIdChanged = Signal()  # noqa: N815
    aiGenerationFailed = Signal(str)  # noqa: N815

    # ── FORBIDDEN content markers per module type ──
    # These patterns will be auto-stripped from AI output
    _FORBIDDEN_PATTERNS = {
        # Patterns that indicate variable/parameter definition (only variable_param handles these)
        "identity_role": [
            (r"#+\s*变量.*", "identity_role模块禁止定义变量，变量请使用变量与参数管理面板统一管理"),
            (r"#+\s*参数.*", "identity_role模块禁止定义参数"),
            (r"\|.*变量名.*\|.*类型.*\|", "identity_role模块禁止创建变量表格"),
            (r"#+\s*输出格式.*", "identity_role模块禁止定义输出格式，请在输出格式模块中定义"),
            (r"#+\s*任务.*", "identity_role模块禁止定义任务，请在任务模块中定义"),
        ],
        "task_goal": [
            (r"#+\s*变量.*", "task_goal模块禁止定义变量"),
            (r"\|.*变量名.*\|.*类型.*\|", "task_goal模块禁止创建变量表格"),
            (r"#+\s*输出格式.*", "task_goal模块禁止定义输出格式"),
            (r"#+\s*角色.*定位.*", "task_goal模块禁止定义角色，请在身份模块中定义"),
        ],
        "knowledge_rag": [
            (r"#+\s*变量.*", "knowledge_rag模块禁止定义变量"),
            (r"\|.*变量名.*\|.*类型.*\|", "knowledge_rag模块禁止创建变量表格"),
            (r"#+\s*角色.*", "knowledge_rag模块禁止定义角色"),
        ],
        "capability_tool": [
            (r"#+\s*变量.*", "capability_tool模块禁止定义变量"),
            (r"\|.*变量名.*\|.*类型.*\|", "capability_tool模块禁止创建变量表格"),
            (r"#+\s*角色.*", "capability_tool模块禁止定义角色"),
        ],
        "reasoning_workflow": [
            (r"#+\s*变量.*", "reasoning_workflow模块禁止定义变量"),
            (r"\|.*变量名.*\|.*类型.*\|", "reasoning_workflow模块禁止创建变量表格"),
            (r"#+\s*角色.*", "reasoning_workflow模块禁止定义角色"),
        ],
        "output_format": [
            (r"#+\s*变量.*", "output_format模块禁止定义变量"),
            (r"\|.*变量名.*\|.*类型.*\|", "output_format模块禁止创建变量表格"),
            (r"#+\s*角色.*", "output_format模块禁止定义角色"),
            (r"#+\s*任务.*", "output_format模块禁止定义任务"),
        ],
        "constraint_safety": [
            (r"#+\s*变量.*", "constraint_safety模块禁止定义变量"),
            (r"\|.*变量名.*\|.*类型.*\|", "constraint_safety模块禁止创建变量表格"),
            (r"#+\s*角色.*", "constraint_safety模块禁止定义角色"),
        ],
        "example_fewshot": [
            (r"#+\s*变量.*", "example_fewshot模块禁止定义变量"),
            (r"\|.*变量名.*\|.*类型.*\|", "example_fewshot模块禁止创建变量表格"),
            (r"#+\s*角色.*", "example_fewshot模块禁止定义角色"),
        ],
        "prepost_process": [
            (r"#+\s*变量.*", "prepost_process模块禁止定义变量"),
            (r"\|.*变量名.*\|.*类型.*\|", "prepost_process模块禁止创建变量表格"),
            (r"#+\s*角色.*", "prepost_process模块禁止定义角色"),
        ],
    }

    # ── Common strict rules injected into EVERY system prompt ──
    _COMMON_STRICT_RULES = """## ━━ 绝对禁止项（违反即为错误）━━

【禁止1】严禁输出任何变量定义、变量列表、变量表格。变量统一由系统基础设施管理。
【禁止2】严禁使用单花括号 {变量名}。引用变量必须用双花括号 {{变量名}}。
【禁止3】严禁在输出中定义新的变量名。
【禁止4】严禁包含其他模块的标题或内容（如身份模块不要输出任务、输出格式等）。
【禁止5】严禁添加任何开场白、解释、"好的"、"以下是"等废话。直接输出内容。
【禁止6】严禁在代码块中使用错误的缩进或不闭合的标记。
【禁止7】Markdown标题必须使用 ## 格式，后面紧跟内容，不允许空标题。

## ━━ 必须遵守的格式规范 ━━

【必须1】严格按照下方「输出格式模板」的结构输出，包括所有标题、列表标记。
【必须2】所有 Markdown 语法必须正确闭合（代码块 ``` 必须成对，表格必须完整）。
【必须3】每个 ## 标题下的内容必须充实，不能只有占位符而无实际内容。"""

    # Module type → Chinese label for context display
    _MODULE_LABELS = {
        "identity_role": "身份与角色定义",
        "task_goal": "任务与目标",
        "knowledge_rag": "知识库与RAG",
        "capability_tool": "能力与工具调用",
        "reasoning_workflow": "推理与工作流框架",
        "output_format": "输出格式与协议",
        "constraint_safety": "约束与安全护栏",
        "example_fewshot": "示例与少样本库",
        "prepost_process": "预处理与后处理逻辑",
    }

    # Module type → allowed variable reference names for each module
    # This tells the AI WHICH variables are relevant to reference in each module type
    _MODULE_SCOPE_HINTS = {
        "identity_role": "[在{{ }}中引用变量，例如：具备 {{skills}} 方面的专业知识，角色为 {{role}}]",
        "task_goal": "[在任务描述中引用变量，例如：基于 {{user_input}} 完成任务，使用 {{language}} 编写代码]",
        "knowledge_rag": "[在知识来源中引用变量，例如：检索 {{knowledge_base}} 相关内容]",
        "capability_tool": "[在工具描述中引用变量，例如：调用 {{tool_name}} 执行操作]",
        "reasoning_workflow": "[在推理步骤中引用变量，例如：第一步分析 {{problem_context}}]",
        "output_format": "[在格式规范中引用变量，例如：输出为 {{format_type}} 格式]",
        "constraint_safety": "[在约束规则中引用变量，例如：拒绝 {{forbidden_topic}} 相关请求]",
        "example_fewshot": "[在示例中引用变量，例如：用户输入 {{user_input}} → AI返回...]",
        "prepost_process": "[在处理步骤中引用变量，例如：清洗 {{raw_text}} 中的噪声]",
    }

    # Module type → explicit output format that AI MUST follow
    _MODULE_FORMATS = {
        "identity_role": (
            "你必须严格按照以下格式输出，不得增减任何标题，不得添加其他模块内容：\n"
            "## 角色定位\n[一句话描述AI的身份和角色]\n\n"
            "## 专业领域\n- 领域1\n- 领域2\n- 领域3\n\n"
            "## 沟通风格\n[描述语气、用词习惯、回复长度偏好]\n\n"
            "## 能力边界\n**可做**：\n- 能力1\n- 能力2\n\n**不可做**：\n- 限制1\n- 限制2"
        ),
        "task_goal": (
            "你必须严格按照以下格式输出，不得增减任何标题，不得添加其他模块内容：\n"
            "## 核心任务\n[一句话描述需要完成的任务]\n\n"
            "## 成功标准\n1. 标准1\n2. 标准2\n3. 标准3\n\n"
            "## 子目标\n1. 目标1\n2. 目标2\n3. 目标3"
        ),
        "knowledge_rag": (
            "你必须严格按照以下格式输出，不得增减任何标题，不得添加其他模块内容：\n"
            "## 知识来源\n- 来源1\n- 来源2\n- 来源3\n\n"
            "## 检索策略\n[描述检索方式和优先级]\n\n"
            "## 引用规则\n- 规则1\n- 规则2"
        ),
        "capability_tool": (
            "你必须严格按照以下格式输出，不得增减任何标题，不得添加其他模块内容：\n"
            "## 可用工具\n| 工具名 | 功能 | 调用方式 |\n|--------|------|----------|\n| tool_name | 描述 | API/Cli |\n\n"
            "## 调用规则\n1. 规则1\n2. 规则2\n\n"
            "## 权限范围\n[描述工具的权限边界]"
        ),
        "reasoning_workflow": (
            "你必须严格按照以下格式输出，不得增减任何标题，不得添加其他模块内容：\n"
            "## 推理框架\n[如: Chain-of-Thought / Tree-of-Thought / ReAct]\n\n"
            "## 推理步骤\n1. 步骤1：理解问题\n2. 步骤2：分析关键因素\n3. 步骤3：推导结论\n\n"
            "## 自检点\n- [ ] 检查1\n- [ ] 检查2\n- [ ] 检查3"
        ),
        "output_format": (
            "你必须严格按照以下格式输出，不得增减任何标题，不得添加其他模块内容：\n"
            "## 格式类型\n[如: JSON / Markdown / 纯文本 / YAML]\n\n"
            "## 字段规范\n| 字段名 | 类型 | 必填 | 说明 |\n|--------|------|------|------|\n| field | type | 是/否 | 描述 |\n\n"
            "## 格式示例\n```\n[具体示例内容]\n```"
        ),
        "constraint_safety": (
            "你必须严格按照以下格式输出，不得增减任何标题，不得添加其他模块内容：\n"
            "## 硬性禁止\n- 禁止1\n- 禁止2\n- 禁止3\n\n"
            "## 隐私保护\n- 规则1\n- 规则2\n\n"
            "## 拒绝策略\n[当请求违反约束时的处理方式]"
        ),
        "example_fewshot": (
            "你必须严格按照以下格式输出，不得增减任何标题，不得添加其他模块内容：\n"
            "## 示例1\n**输入**：\n[具体输入内容]\n\n**输出**：\n[期望的输出内容]\n\n"
            "## 示例2\n**输入**：\n[具体输入内容]\n\n**输出**：\n[期望的输出内容]"
        ),
        "prepost_process": (
            "你必须严格按照以下格式输出，不得增减任何标题，不得添加其他模块内容：\n"
            "## 预处理\n1. 步骤1：输入清洗\n2. 步骤2：格式转换\n\n"
            "## 后处理\n1. 步骤1：结果校验\n2. 步骤2：格式美化\n\n"
            "## 过滤管道\n[可选的变量过滤规则列表]"
        ),
    }

    # Brief module role description (one line, injected into system prompt)
    _MODULE_ROLES = {
        "identity_role": "你正在为「身份与角色定义」模块生成内容。此模块定义AI扮演的角色、专业领域、沟通风格和能力边界。",
        "task_goal": "你正在为「任务与目标」模块生成内容。此模块定义AI需要完成的核心任务、成功标准和子目标。",
        "knowledge_rag": "你正在为「知识库与RAG」模块生成内容。此模块定义知识来源、检索策略和引用规则。",
        "capability_tool": "你正在为「能力与工具调用」模块生成内容。此模块定义可用工具、调用规则和权限范围。",
        "reasoning_workflow": "你正在为「推理与工作流框架」模块生成内容。此模块定义推理框架、推理步骤和自检点。",
        "output_format": "你正在为「输出格式与协议」模块生成内容。此模块定义输出格式类型、字段规范和格式示例。",
        "constraint_safety": "你正在为「约束与安全护栏」模块生成内容。此模块定义硬性禁止项、隐私保护和拒绝策略。",
        "example_fewshot": "你正在为「示例与少样本库」模块生成内容。此模块提供输入输出示例，覆盖典型场景。",
        "prepost_process": "你正在为「预处理与后处理逻辑」模块生成内容。此模块定义输入清洗、输出格式化和过滤管道。",
    }

    def __init__(self, app_config=None, module_card_model=None, variable_model=None, knowledge_model=None, tool_model=None, parent=None):
        super().__init__(parent)
        self._current_mode: str = "manual"
        self._current_content: str = ""
        self._current_block_id: str = ""
        self._app_config = app_config
        self._module_card_model = module_card_model
        self._variable_model = variable_model
        self._knowledge_model = knowledge_model
        self._tool_model = tool_model
        self._generate_thread = None
        self._generate_worker = None

    # ── Properties ──

    @Property(str, notify=currentBlockIdChanged)
    def currentBlockId(self) -> str:  # noqa: N802
        return self._current_block_id

    @currentBlockId.setter
    def currentBlockId(self, value: str) -> None:  # noqa: N802
        if self._current_block_id != value:
            self._current_block_id = value
            self.currentBlockIdChanged.emit()

    @Property(str, notify=modeChanged)
    def currentMode(self) -> str:  # noqa: N802
        return self._current_mode

    @currentMode.setter
    def currentMode(self, value: str) -> None:  # noqa: N802
        if self._current_mode != value:
            self._current_mode = value
            self.modeChanged.emit()

    @Property(str, notify=contentChanged)
    def currentContent(self) -> str:  # noqa: N802
        return self._current_content

    @currentContent.setter
    def currentContent(self, value: str) -> None:  # noqa: N802
        if self._current_content != value:
            self._current_content = value
            self.contentChanged.emit()

    # ── Slots ──

    @Slot(str)
    def setMode(self, mode: str) -> None:  # noqa: N802
        self.currentMode = mode

    @Slot(str)
    def setContent(self, content: str) -> None:  # noqa: N802
        self.currentContent = content

    @Slot(str, str)
    def generateFromAI(self, prompt: str, module_type: str) -> None:  # noqa: N802
        self._do_generate(prompt, module_type, "")

    @Slot(str, str, str)
    def generateFromAIForBlock(self, prompt: str, module_type: str, block_id: str) -> None:  # noqa: N802
        self.currentBlockId = block_id
        self._do_generate(prompt, module_type, block_id)

    # ── Context building ──

    def _build_context_text(self, block_id: str) -> str:
        """Build context text from existing modules and VariableModel."""
        if not self._module_card_model or not block_id:
            return ""

        import json
        try:
            context_json = self._module_card_model.getContextForBlock(block_id)
            context = json.loads(context_json)
        except Exception:
            return ""

        existing_modules = context.get("existing_modules", [])

        # Variables from centralized VariableModel
        defined_variables = []
        if self._variable_model:
            try:
                defined_variables = self._variable_model.getVariables()
            except Exception:
                pass

        if not existing_modules and not defined_variables:
            return ""

        # Build modules text
        modules_parts = []
        for mod in existing_modules:
            label = self._MODULE_LABELS.get(mod["blockType"], mod["title"])
            modules_parts.append(f"### {label}\n{mod['content']}")
        modules_text = "\n\n".join(modules_parts) if modules_parts else "（无其他模块）"

        # Build variables text
        variables_text = ""
        if defined_variables:
            var_lines = []
            for v in defined_variables:
                name = v.get("name", "")
                vtype = v.get("varType", "text")
                desc = v.get("description", "")
                default_val = v.get("defaultValue", "")
                parts = [f"- `{{{{{name}}}}}` (类型:{vtype}"]
                if default_val:
                    parts.append(f", 默认值:{default_val}")
                if desc:
                    parts.append(f", {desc}")
                parts.append(")")
                var_lines.append("".join(parts))
            var_list = "\n".join(var_lines)
            variables_text = (
                "### 可引用的变量（已在系统基础设施中定义，你只能引用不能新建）\n"
                f"{var_list}\n\n"
                "**重要**：引用这些变量时使用 {{{{变量名}}}} 双花括号语法。"
            )

        # Build knowledge base text
        knowledge_text = ""
        if self._knowledge_model:
            try:
                knowledges = self._knowledge_model.getKnowledges()
                if knowledges:
                    kl_lines = []
                    for k in knowledges:
                        name = k.get("name", "")
                        stype = k.get("sourceType", "unknown")
                        desc = k.get("description", "")
                        url = k.get("referenceUrl", "")
                        line = f"- **{name}** (来源类型:{stype}"
                        if desc:
                            line += f", {desc}"
                        if url:
                            line += f", 参考: {url}"
                        line += ")"
                        kl_lines.append(line)
                    knowledge_text = (
                        "### 已配置的知识库（系统基础设施，可在知识库模块中引用）\n"
                        + "\n".join(kl_lines)
                    )
            except Exception:
                pass

        # Build tool definitions text
        tool_text = ""
        if self._tool_model:
            try:
                tools = self._tool_model.getTools()
                if tools:
                    tl_lines = []
                    for t in tools:
                        name = t.get("name", "")
                        ttype = t.get("toolType", "function")
                        desc = t.get("description", "")
                        params = t.get("parameters", "")
                        endpoint = t.get("endpoint", "")
                        line = f"- **{name}** (类型:{ttype}"
                        if desc:
                            line += f", {desc}"
                        if params:
                            line += f", 参数: {params}"
                        if endpoint:
                            line += f", 端点: {endpoint}"
                        line += ")"
                        tl_lines.append(line)
                    tool_text = (
                        "### 已配置的工具（系统基础设施，可在工具调用模块中引用）\n"
                        + "\n".join(tl_lines)
                    )
            except Exception:
                pass

        # Combine all contextual sections
        context_sections = []
        if modules_text:
            context_sections.append(f"### 已有模块\n{modules_text}")
        if variables_text:
            context_sections.append(variables_text)
        if knowledge_text:
            context_sections.append(knowledge_text)
        if tool_text:
            context_sections.append(tool_text)

        if context_sections:
            combined = "\n\n".join(context_sections)
            return f"\n\n## ━━ 已有模块上下文（仅供参考保持一致性）━━\n\n{combined}"
        return ""

    # ── AI Generation ──

    def _build_system_prompt(self, module_type: str) -> str:
        """Build ultra-strict system prompt for the given module type."""
        role = self._MODULE_ROLES.get(module_type, "你是一个提示词工程专家。")
        scope_hint = self._MODULE_SCOPE_HINTS.get(module_type, "")
        format_template = self._MODULE_FORMATS.get(module_type, "")

        parts = [
            f"{role}\n{scope_hint}",
            self._COMMON_STRICT_RULES,
        ]
        if format_template:
            parts.append("\n## ━━ 输出格式模板（必须严格逐字遵守）━━\n" + format_template)

        return "\n\n".join(parts)

    def _build_user_prompt(self, user_input: str, module_type: str, block_id: str) -> str:
        """Build user prompt with format template inlined for better model compliance."""
        format_template = self._MODULE_FORMATS.get(module_type, "")
        context_text = self._build_context_text(block_id)

        parts = []
        # Main instruction with format embedded
        if format_template:
            parts.append(
                f"请严格按照下面的格式模板为「{self._MODULE_LABELS.get(module_type, module_type)}」模块生成内容。\n\n"
                f"**输出格式（必须严格遵循，不得增减修改）**：\n{format_template}"
            )
        else:
            parts.append(f"请为「{self._MODULE_LABELS.get(module_type, module_type)}」模块生成内容。")

        if user_input.strip():
            parts.append(f"\n**用户描述**：{user_input}")

        if context_text:
            parts.append(context_text)

        parts.append("\n**请直接输出内容，不要添加任何前言或解释。**")

        return "\n\n".join(parts)

    def _post_process_output(self, raw_output: str, module_type: str) -> str:
        """Clean up AI output: fix single braces, strip forbidden content patterns."""
        if not raw_output or not raw_output.strip():
            return raw_output

        text = raw_output.strip()

        # ── Fix 1: Replace single-brace variable references with double-brace ──
        # Match {word} that is NOT already {{word}} and NOT a JSON block
        # Strategy: replace {varName} → {{varName}} when varName looks like a variable (word chars)
        text = re.sub(
            r'(?<!\{)\{(\w+)\}(?!\})',
            r'{{\1}}',
            text,
        )

        # ── Fix 2: Strip lines that match forbidden patterns for this module type ──
        forbidden = self._FORBIDDEN_PATTERNS.get(module_type, [])
        lines = text.split("\n")
        filtered_lines = []
        skip_until_empty = False  # For multi-line forbidden sections

        for line in lines:
            stripped = line.strip()

            # Check if line starts a forbidden section (like "## 变量与参数定义")
            is_forbidden = False
            for pattern, _msg in forbidden:
                if re.search(pattern, stripped):
                    is_forbidden = True
                    skip_until_empty = True
                    break

            if is_forbidden:
                continue

            # Skip content after a forbidden heading until we hit an empty line or new heading
            if skip_until_empty:
                if stripped == "" or stripped.startswith("#"):
                    skip_until_empty = False
                    if stripped.startswith("#"):
                        # Check if this new heading is also forbidden
                        still_forbidden = any(re.search(p, stripped) for p, _ in forbidden)
                        if still_forbidden:
                            continue
                    else:
                        continue  # Skip the empty line
                else:
                    continue  # Skip content under forbidden heading

            filtered_lines.append(line)

        text = "\n".join(filtered_lines)

        # ── Fix 3: Remove empty heading lines (## with nothing after) ──
        text = re.sub(r'^##\s*$\n?', '', text, flags=re.MULTILINE)

        # ── Fix 4: Remove common LLM preamble phrases ──
        # Re-split text after previous fixes
        current_lines = text.split("\n")

        # Strip the first line if it looks like a descriptive preamble
        # (not starting with # / - / | / number / **)
        if current_lines:
            first_line = current_lines[0].strip()
            if first_line and not re.match(r'^(#|\-|\||\d+[\.\)]|\*\*|\{)', first_line):
                if len(first_line) > 30 and not first_line.startswith("##"):
                    current_lines = current_lines[1:]

        text = "\n".join(current_lines)

        preamble_patterns = [
            r'^(好的[，,]\s*)?(以下是|根据您|以下为)[^#\n]*?\n',
            r'^(好的[，,]\s*)?(我将|我来)[^#\n]*?\n',
            r'^\*\*注意[：:][^*]*\*\*\n?',
        ]
        for pat in preamble_patterns:
            text = re.sub(pat, '', text, flags=re.MULTILINE)

        # ── Fix 5: Ensure code blocks are properly closed ──
        # Count ``` occurrences; if odd, append a closing ``` at the end
        backtick_count = text.count("```")
        if backtick_count % 2 != 0:
            text = text.rstrip() + "\n```"

        # ── Fix 6: Trim leading/trailing whitespace ──
        text = text.strip()

        return text

    def _do_generate(self, prompt: str, module_type: str, block_id: str) -> None:
        """Call LLM API asynchronously using QThread Worker to prevent UI freeze."""
        if not prompt.strip():
            self.aiGenerationFailed.emit("请输入描述内容")
            return

        # Clean up any previous thread
        self._cleanup_generate_thread()

        # Save module_type for use in callback
        self._current_module_type = module_type

        system_prompt = self._build_system_prompt(module_type)
        user_prompt = self._build_user_prompt(prompt, module_type, block_id)

        self._generate_thread = QThread()
        self._generate_worker = _GenerateWorker(
            app_config=self._app_config,
            system_prompt=system_prompt,
            user_prompt=user_prompt,
        )
        self._generate_worker.moveToThread(self._generate_thread)
        self._generate_thread.started.connect(self._generate_worker.run)
        self._generate_worker.finished.connect(self._on_generate_finished)
        self._generate_worker.error.connect(self._on_generate_error)
        self._generate_worker.finished.connect(self._generate_thread.quit)
        self._generate_worker.error.connect(self._generate_thread.quit)
        self._generate_thread.finished.connect(self._on_generate_thread_finished)
        self._generate_thread.start()

    def _cleanup_generate_thread(self):
        """Clean up the generate thread/worker references."""
        if self._generate_thread is not None and self._generate_thread.isRunning():
            self._generate_thread.quit()
            self._generate_thread.wait(3000)
        self._generate_worker = None
        self._generate_thread = None

    def _on_generate_finished(self, result: str):
        """Handle successful AI generation."""
        module_type = self._current_module_type if hasattr(self, '_current_module_type') else ""
        cleaned = self._post_process_output(result, module_type)
        self.currentContent = cleaned
        self.aiGenerationCompleted.emit()

    def _on_generate_error(self, message: str):
        """Handle AI generation error."""
        self.currentContent = f"[LLM调用失败: {message}]"
        self.aiGenerationFailed.emit(message)
        self.aiGenerationCompleted.emit()

    def _on_generate_thread_finished(self):
        """Clear references after the thread has fully stopped."""
        sender = self.sender()
        if sender is self._generate_thread:
            self._generate_worker = None
            self._generate_thread = None
