"""CardList ViewModel managing module card state and operations."""

import json
import uuid

from PySide6.QtCore import Property, QObject, Signal, Slot


class ModuleCardData(QObject):
    """Data model for a single module card."""

    dataChanged = Signal()  # noqa: N815

    def __init__(self, card_id: str, module_type: str, title: str, parent=None):
        super().__init__(parent)
        self._card_id = card_id
        self._module_type = module_type
        self._title = title
        self._description = ""
        self._compiled_code = ""
        self._content_json = {}
        self._order_index = 0

    @Property(str, notify=dataChanged)
    def cardId(self) -> str:  # noqa: N802
        return self._card_id

    @Property(str, notify=dataChanged)
    def moduleType(self) -> str:  # noqa: N802
        return self._module_type

    @Property(str, notify=dataChanged)
    def title(self) -> str:
        return self._title

    @title.setter
    def title(self, value: str) -> None:
        if self._title != value:
            self._title = value
            self.dataChanged.emit()

    @Property(str, notify=dataChanged)
    def descriptionText(self) -> str:  # noqa: N802
        return self._description

    @descriptionText.setter
    def descriptionText(self, value: str) -> None:  # noqa: N802
        if self._description != value:
            self._description = value
            self.dataChanged.emit()

    @Property(str, notify=dataChanged)
    def compiledCode(self) -> str:  # noqa: N802
        return self._compiled_code

    @compiledCode.setter
    def compiledCode(self, value: str) -> None:  # noqa: N802
        if self._compiled_code != value:
            self._compiled_code = value
            self.dataChanged.emit()

    @Property(str, notify=dataChanged)
    def contentJson(self) -> str:  # noqa: N802
        return json.dumps(self._content_json, ensure_ascii=False) if self._content_json else ""

    @contentJson.setter
    def contentJson(self, value: str) -> None:  # noqa: N802
        try:
            parsed = json.loads(value) if value else {}
        except (json.JSONDecodeError, TypeError):
            parsed = {}
        if self._content_json != parsed:
            self._content_json = parsed
            self.dataChanged.emit()

    @Property(int, notify=dataChanged)
    def orderIndex(self) -> int:  # noqa: N802
        return self._order_index

    @orderIndex.setter
    def orderIndex(self, value: int) -> None:  # noqa: N802
        if self._order_index != value:
            self._order_index = value
            self.dataChanged.emit()


class CardListViewModel(QObject):
    """ViewModel managing module card list state and operations."""

    cardAdded = Signal(QObject)  # noqa: N815
    cardRemoved = Signal(str)  # noqa: N815
    cardsReordered = Signal()  # noqa: N815

    MODULE_TYPES = {
        "identity_role": {"title": "身份与角色定义", "icon": "🎭", "color": "#89b4fa"},
        "task_goal": {"title": "任务与目标", "icon": "🎯", "color": "#a6e3a1"},
        "variable_param": {"title": "变量与参数定义", "icon": "📐", "color": "#f9e2af"},
        "knowledge_rag": {"title": "知识库与RAG", "icon": "📚", "color": "#cba6f7"},
        "capability_tool": {"title": "能力与工具调用", "icon": "🔧", "color": "#94e2d5"},
        "reasoning_workflow": {"title": "推理与工作流框架", "icon": "🧠", "color": "#f38ba8"},
        "output_format": {"title": "输出格式与协议", "icon": "📋", "color": "#fab387"},
        "constraint_safety": {"title": "约束与安全护栏", "icon": "🛡️", "color": "#f9e2af"},
        "context_memory": {"title": "上下文与记忆管理", "icon": "💾", "color": "#74c7ec"},
        "example_fewshot": {"title": "示例与少样本库", "icon": "💡", "color": "#a6e3a1"},
        "prepost_process": {"title": "预处理与后处理逻辑", "icon": "⚙️", "color": "#b4befe"},
    }

    def __init__(self, parent=None):
        super().__init__(parent)
        self._cards: list[ModuleCardData] = []

    # --- Module Card Management ---

    @Slot(str, result=QObject)
    def addModuleCard(self, module_type: str) -> QObject:  # noqa: N802
        """Add a new module card and return its data."""
        card_id = str(uuid.uuid4())[:8]
        type_info = self.MODULE_TYPES.get(module_type, {"title": "Module"})
        card = ModuleCardData(
            card_id=card_id,
            module_type=module_type,
            title=type_info["title"],
            parent=self,
        )
        card._order_index = len(self._cards)
        self._cards.append(card)
        self.cardAdded.emit(card)
        return card

    @Slot(str)
    def removeModuleCard(self, card_id: str) -> None:  # noqa: N802
        """Remove a module card by ID."""
        self._cards = [c for c in self._cards if c._card_id != card_id]
        self._reindex_cards()
        self.cardRemoved.emit(card_id)

    @Slot(str, result=QObject)
    def getModuleCard(self, card_id: str) -> QObject:  # noqa: N802
        """Get a module card by ID."""
        for card in self._cards:
            if card._card_id == card_id:
                return card
        return None

    @Slot(result=list)
    def getModuleCards(self) -> list:  # noqa: N802
        """Return all module cards."""
        return self._cards

    @Slot()
    def reorderCards(self) -> None:  # noqa: N802
        """Re-order cards based on their current order_index values."""
        self._cards.sort(key=lambda c: c._order_index)
        self._reindex_cards()
        self.cardsReordered.emit()

    def _reindex_cards(self) -> None:
        """Re-assign sequential order_index to all cards."""
        for i, card in enumerate(self._cards):
            card._order_index = i

    # --- Compile ---

    @Slot(str, result=str)
    def compile_block(self, card_id: str) -> str:  # noqa: N802
        """Compile a module card's content into a prompt block. Returns compiled result."""
        card = None
        for c in self._cards:
            if c._card_id == card_id:
                card = c
                break
        if not card:
            return ""

        module_type = card._module_type
        content = card._content_json or {}

        if module_type == "identity_role":
            return self._compile_identity_role(content)
        elif module_type == "task_goal":
            return self._compile_task_goal(content)
        elif module_type == "variable_param":
            return self._compile_variable_param(content)
        elif module_type == "knowledge_rag":
            return self._compile_knowledge_rag(content)
        elif module_type == "capability_tool":
            return self._compile_capability_tool(content)
        elif module_type == "reasoning_workflow":
            return self._compile_reasoning_workflow(content)
        elif module_type == "output_format":
            return self._compile_output_format(content)
        elif module_type == "constraint_safety":
            return self._compile_constraint_safety(content)
        elif module_type == "context_memory":
            return self._compile_context_memory(content)
        elif module_type == "example_fewshot":
            return self._compile_example_fewshot(content)
        elif module_type == "prepost_process":
            return self._compile_prepost_process(content)
        return ""

    def _compile_identity_role(self, content: dict) -> str:
        role = content.get("role", "")
        persona = content.get("persona", "")
        if not role and not persona:
            return ""
        result = f"# 角色: {role}\n"
        if persona:
            result += f"{persona}\n"
        return result

    def _compile_task_goal(self, content: dict) -> str:
        task = content.get("task", "")
        goal = content.get("goal", "")
        if not task and not goal:
            return ""
        result = "# 任务与目标\n"
        if task:
            result += f"## 任务\n{task}\n"
        if goal:
            result += f"## 目标\n{goal}\n"
        return result

    def _compile_variable_param(self, content: dict) -> str:
        params = content.get("params", [])
        if not params:
            return ""
        result = "# 变量与参数\n"
        for p in params:
            name = p.get("name", "")
            desc = p.get("description", "")
            default = p.get("default", "")
            result += f"- **{name}**: {desc}"
            if default:
                result += f" (默认: {default})"
            result += "\n"
        return result

    def _compile_knowledge_rag(self, content: dict) -> str:
        sources = content.get("sources", [])
        instructions = content.get("instructions", "")
        if not sources and not instructions:
            return ""
        result = "# 知识库与RAG\n"
        if sources:
            result += "## 知识来源\n"
            for s in sources:
                result += f"- {s}\n"
        if instructions:
            result += f"## 检索指令\n{instructions}\n"
        return result

    def _compile_capability_tool(self, content: dict) -> str:
        tools = content.get("tools", [])
        if not tools:
            return ""
        result = "# 能力与工具调用\n"
        for t in tools:
            name = t.get("name", "")
            desc = t.get("description", "")
            result += f"- **{name}**: {desc}\n"
        return result

    def _compile_reasoning_workflow(self, content: dict) -> str:
        framework = content.get("framework", "")
        steps = content.get("steps", [])
        if not framework and not steps:
            return ""
        result = "# 推理与工作流框架\n"
        if framework:
            result += f"## 框架\n{framework}\n"
        if steps:
            result += "## 步骤\n"
            for i, step in enumerate(steps, 1):
                result += f"{i}. {step}\n"
        return result

    def _compile_output_format(self, content: dict) -> str:
        fmt = content.get("format", "")
        schema = content.get("schema", "")
        if not fmt and not schema:
            return ""
        result = "# 输出格式与协议\n"
        if fmt:
            result += f"## 格式要求\n{fmt}\n"
        if schema:
            result += f"## Schema\n```json\n{schema}\n```\n"
        return result

    def _compile_constraint_safety(self, content: dict) -> str:
        constraints = content.get("constraints", [])
        safety = content.get("safety_rules", [])
        if not constraints and not safety:
            return ""
        result = "# 约束与安全护栏\n"
        if constraints:
            result += "## 约束条件\n"
            for c in constraints:
                result += f"- {c}\n"
        if safety:
            result += "## 安全规则\n"
            for s in safety:
                result += f"- {s}\n"
        return result

    def _compile_context_memory(self, content: dict) -> str:
        strategy = content.get("strategy", "")
        window = content.get("window_size", "")
        if not strategy and not window:
            return ""
        result = "# 上下文与记忆管理\n"
        if strategy:
            result += f"## 策略\n{strategy}\n"
        if window:
            result += f"## 窗口大小\n{window}\n"
        return result

    def _compile_example_fewshot(self, content: dict) -> str:
        examples = content.get("examples", [])
        if not examples:
            return ""
        result = "# 示例与少样本库\n"
        for i, ex in enumerate(examples, 1):
            inp = ex.get("input", "")
            out = ex.get("output", "")
            result += f"## 示例 {i}\n"
            result += f"**输入**: {inp}\n**输出**: {out}\n\n"
        return result

    def _compile_prepost_process(self, content: dict) -> str:
        pre = content.get("pre_process", "")
        post = content.get("post_process", "")
        if not pre and not post:
            return ""
        result = "# 预处理与后处理逻辑\n"
        if pre:
            result += f"## 预处理\n{pre}\n"
        if post:
            result += f"## 后处理\n{post}\n"
        return result

    # --- Module type info for sidebar ---

    @Slot(result="QVariantList")
    def getModuleTypes(self) -> list:  # noqa: N802
        """Return list of module type info for the sidebar."""
        result = []
        for key, info in self.MODULE_TYPES.items():
            result.append({
                "type": key,
                "title": info["title"],
                "icon": info["icon"],
            })
        return result
