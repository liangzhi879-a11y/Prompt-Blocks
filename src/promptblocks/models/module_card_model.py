"""ModuleCardModel — QAbstractListModel for module cards on the canvas."""

import uuid

from PySide6.QtCore import Qt, QAbstractListModel, QModelIndex, Slot, Signal


# 9 module types with metadata (context_memory removed — agent system-level config, not prompt engineering)
MODULE_TYPES = {
    "identity_role": {
        "title": "身份与角色定义",
        "icon": "🎭",
        "color": "#89b4fa",
        "label": "IR",
        "defaultContent": "# 角色定义\n\n请描述AI应扮演的角色、专业领域、沟通风格和能力边界。",
        "aiFormat": "## 角色定位\n[一句话描述AI的身份和角色]\n\n## 专业领域\n- 领域1\n- 领域2\n\n## 沟通风格\n[描述语气、用词习惯、回复长度偏好]\n\n## 能力边界\n- [可做的事]\n- [不可做的事]",
    },
    "task_goal": {
        "title": "任务与目标",
        "icon": "🎯",
        "color": "#a6e3a1",
        "label": "TG",
        "defaultContent": "# 任务描述\n\n请描述AI需要完成的核心任务、成功标准和子目标。可引用 {{变量名}}。",
        "aiFormat": "## 核心任务\n[一句话描述任务]\n\n## 成功标准\n1. 标准1\n2. 标准2\n\n## 子目标\n1. 目标1\n2. 目标2",
    },
    "knowledge_rag": {
        "title": "知识库与RAG",
        "icon": "📚",
        "color": "#cba6f7",
        "label": "KR",
        "defaultContent": "# 知识库配置\n\n请定义知识来源、检索策略和引用规则。",
        "aiFormat": "## 知识来源\n- 来源1\n- 来源2\n\n## 检索策略\n[描述检索方式和优先级]\n\n## 引用规则\n[描述如何引用检索到的知识]",
    },
    "capability_tool": {
        "title": "能力与工具调用",
        "icon": "🔧",
        "color": "#94e2d5",
        "label": "CT",
        "defaultContent": "# 工具调用\n\n请列出可用工具、调用规则和权限范围。",
        "aiFormat": "## 可用工具\n| 工具名 | 功能 | 调用方式 |\n|--------|------|----------|\n| tool_name | 描述 | 方式 |\n\n## 调用规则\n1. 规则1\n2. 规则2\n\n## 权限范围\n[描述工具的权限边界]",
    },
    "reasoning_workflow": {
        "title": "推理与工作流框架",
        "icon": "🧠",
        "color": "#f38ba8",
        "label": "RW",
        "defaultContent": "# 推理框架\n\n请定义AI的推理步骤、思考链和自我检查点。",
        "aiFormat": "## 推理框架\n[如: Chain-of-Thought / Tree-of-Thought]\n\n## 推理步骤\n1. 步骤1：理解问题\n2. 步骤2：分析关键因素\n3. 步骤3：推导结论\n\n## 自检点\n- [ ] 检查1\n- [ ] 检查2",
    },
    "output_format": {
        "title": "输出格式与协议",
        "icon": "📋",
        "color": "#fab387",
        "label": "OF",
        "defaultContent": "# 输出格式\n\n请定义AI输出的格式要求、字段规范和示例。",
        "aiFormat": "## 格式类型\n[如: JSON / Markdown / 纯文本]\n\n## 字段规范\n| 字段名 | 类型 | 必填 | 说明 |\n|--------|------|------|------|\n| field | type | 是/否 | 描述 |\n\n## 格式示例\n```\n[示例内容]\n```",
    },
    "constraint_safety": {
        "title": "约束与安全护栏",
        "icon": "🛡️",
        "color": "#f9e2af",
        "label": "CS",
        "defaultContent": "# 约束条件\n\n请定义硬性禁止项、隐私规则和拒绝策略。",
        "aiFormat": "## 硬性禁止\n- 禁止1\n- 禁止2\n\n## 隐私保护\n- 规则1\n- 规则2\n\n## 拒绝策略\n[当请求违反约束时的处理方式]",
    },
    "example_fewshot": {
        "title": "示例与少样本库",
        "icon": "💡",
        "color": "#a6e3a1",
        "label": "EF",
        "defaultContent": "# 示例\n\n请提供2-3个输入输出示例，覆盖典型场景。可引用 {{变量名}}。",
        "aiFormat": "## 示例1\n**输入**：\n[用户输入内容]\n\n**输出**：\n[期望的输出内容]\n\n## 示例2\n**输入**：\n[用户输入内容]\n\n**输出**：\n[期望的输出内容]",
    },
    "prepost_process": {
        "title": "预处理与后处理逻辑",
        "icon": "⚙️",
        "color": "#b4befe",
        "label": "PP",
        "defaultContent": "# 处理逻辑\n\n请定义输入清洗规则和输出格式化步骤。",
        "aiFormat": "## 预处理\n1. 步骤1：输入清洗\n2. 步骤2：格式转换\n\n## 后处理\n1. 步骤1：结果校验\n2. 步骤2：格式美化\n\n## 过滤管道\n[可选的变量过滤规则列表]",
    },
}


class ModuleCardModel(QAbstractListModel):
    """QAbstractListModel managing module cards for the canvas."""

    # Role definitions
    BlockIdRole = Qt.ItemDataRole.UserRole + 1
    BlockTypeRole = Qt.ItemDataRole.UserRole + 2
    TitleRole = Qt.ItemDataRole.UserRole + 3
    ContentRole = Qt.ItemDataRole.UserRole + 4
    TypeColorRole = Qt.ItemDataRole.UserRole + 5
    TypeIconRole = Qt.ItemDataRole.UserRole + 6
    TypeLabelRole = Qt.ItemDataRole.UserRole + 7
    OrderIndexRole = Qt.ItemDataRole.UserRole + 8
    IsExpandedRole = Qt.ItemDataRole.UserRole + 9
    EditModeRole = Qt.ItemDataRole.UserRole + 10

    cardAdded = Signal(str)
    cardRemoved = Signal(str)
    cardsReordered = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._cards = []  # list of dicts
        self._project_id = ""

    def rowCount(self, parent=QModelIndex()):
        return len(self._cards)

    def data(self, index, role=Qt.ItemDataRole.DisplayRole):
        if not index.isValid() or index.row() >= len(self._cards):
            return None
        card = self._cards[index.row()]
        role_map = {
            self.BlockIdRole: "blockId",
            self.BlockTypeRole: "blockType",
            self.TitleRole: "title",
            self.ContentRole: "content",
            self.TypeColorRole: "typeColor",
            self.TypeIconRole: "typeIcon",
            self.TypeLabelRole: "typeLabel",
            self.OrderIndexRole: "orderIndex",
            self.IsExpandedRole: "isExpanded",
            self.EditModeRole: "editMode",
        }
        key = role_map.get(role)
        if key is not None:
            return card.get(key)
        return None

    def roleNames(self):
        return {
            self.BlockIdRole: b'blockId',
            self.BlockTypeRole: b'blockType',
            self.TitleRole: b'title',
            self.ContentRole: b'content',
            self.TypeColorRole: b'typeColor',
            self.TypeIconRole: b'typeIcon',
            self.TypeLabelRole: b'typeLabel',
            self.OrderIndexRole: b'orderIndex',
            self.IsExpandedRole: b'isExpanded',
            self.EditModeRole: b'editMode',
        }

    @Slot(str, result=bool)
    def addCard(self, blockType):
        """Add a new module card of the given type. Returns True on success."""
        type_info = MODULE_TYPES.get(blockType)
        if type_info is None:
            return False

        card = {
            "blockId": str(uuid.uuid4())[:8],
            "blockType": blockType,
            "title": type_info["title"],
            "content": type_info["defaultContent"],
            "typeColor": "",
            "typeIcon": type_info["icon"],
            "typeLabel": type_info["label"],
            "orderIndex": len(self._cards),
            "isExpanded": True,
            "editMode": False,
        }

        row = len(self._cards)
        self.beginInsertRows(QModelIndex(), row, row)
        self._cards.append(card)
        self.endInsertRows()

        # Persist to DB
        if self._project_id:
            try:
                from promptblocks.db.crud import BlockCRUD
                from promptblocks.db.session import get_session
                with get_session() as session:
                    block = BlockCRUD.create(
                        session,
                        project_id=self._project_id,
                        block_type=blockType,
                        title=type_info["title"],
                        description_text=type_info.get("desc", ""),
                        order_index=len(self._cards) - 1,
                    )
                    # Update the card's blockId with the DB-generated ID
                    self._cards[-1]["blockId"] = block.id
            except Exception:
                pass  # Continue with in-memory only

        self.cardAdded.emit(card["blockId"])
        return True

    @Slot(str, result=bool)
    def removeCard(self, blockId):
        """Remove a card by blockId. Returns True if found and removed."""
        for i, card in enumerate(self._cards):
            if card["blockId"] == blockId:
                self.beginRemoveRows(QModelIndex(), i, i)
                self._cards.pop(i)
                self.endRemoveRows()
                self._reindex()
                self.cardRemoved.emit(blockId)
                return True
        return False

    @Slot(int, int)
    def moveCard(self, fromRow, toRow):
        """Move a card from fromRow to toRow."""
        if fromRow < 0 or fromRow >= len(self._cards):
            return
        if toRow < 0 or toRow >= len(self._cards):
            return
        if fromRow == toRow:
            return

        # Qt convention: source parent, source first/last, target parent, target row
        if fromRow < toRow:
            # Moving down: target row is toRow + 1 per Qt convention
            ok = self.beginMoveRows(
                QModelIndex(), fromRow, fromRow,
                QModelIndex(), toRow + 1,
            )
        else:
            # Moving up: target row is toRow
            ok = self.beginMoveRows(
                QModelIndex(), fromRow, fromRow,
                QModelIndex(), toRow,
            )
        if not ok:
            return

        card = self._cards.pop(fromRow)
        self._cards.insert(toRow, card)
        self.endMoveRows()
        self._reindex()
        self.cardsReordered.emit()

    @Slot(str, str)
    def updateCardContent(self, blockId, content):
        """Update the content of a card identified by blockId."""
        for i, card in enumerate(self._cards):
            if card["blockId"] == blockId:
                if card["content"] != content:
                    card["content"] = content
                    idx = self.index(i, 0)
                    self.dataChanged.emit(idx, idx, [self.ContentRole])
                    # Persist to DB
                    if self._project_id:
                        try:
                            from promptblocks.db.crud import BlockCRUD
                            from promptblocks.db.session import get_session
                            with get_session() as session:
                                BlockCRUD.update(session, blockId, compiled_code=content)
                        except Exception:
                            pass
                return

    @Slot(str, bool)
    def setExpanded(self, blockId, expanded):
        """Set the expanded state of a card."""
        for i, card in enumerate(self._cards):
            if card["blockId"] == blockId:
                if card["isExpanded"] != expanded:
                    card["isExpanded"] = expanded
                    idx = self.index(i, 0)
                    self.dataChanged.emit(idx, idx, [self.IsExpandedRole])
                return

    @Slot(str, bool)
    def setEditMode(self, blockId, editMode):
        """Set the edit mode of a card."""
        for i, card in enumerate(self._cards):
            if card["blockId"] == blockId:
                if card["editMode"] != editMode:
                    card["editMode"] = editMode
                    idx = self.index(i, 0)
                    self.dataChanged.emit(idx, idx, [self.EditModeRole])
                return

    @Slot(str, str)
    def updateCardTitle(self, blockId, title):
        """Update the title of a card."""
        for i, card in enumerate(self._cards):
            if card["blockId"] == blockId:
                if card["title"] != title:
                    card["title"] = title
                    idx = self.index(i, 0)
                    self.dataChanged.emit(idx, idx, [self.TitleRole])
                return

    @Slot(str)
    def setProjectId(self, project_id: str) -> None:
        """Set the current project ID for DB persistence."""
        self._project_id = project_id

    @Slot(result=str)
    def getProjectId(self) -> str:
        """Return the current project ID."""
        return self._project_id

    @Slot()
    def loadFromDb(self) -> None:
        """Load all blocks for the current project from the database into the model."""
        if not self._project_id:
            return

        try:
            from promptblocks.db.crud import BlockCRUD
            from promptblocks.db.session import get_session

            with get_session() as session:
                db_blocks = BlockCRUD.get_by_project(session, self._project_id)
        except Exception:
            return

        # Clear existing cards
        if self._cards:
            self.beginRemoveRows(QModelIndex(), 0, len(self._cards) - 1)
            self._cards.clear()
            self.endRemoveRows()

        # Load from database
        if not db_blocks:
            return

        self.beginInsertRows(QModelIndex(), 0, len(db_blocks) - 1)
        for db_block in db_blocks:
            type_info = MODULE_TYPES.get(db_block.block_type, {})
            card = {
                "blockId": db_block.id,
                "blockType": db_block.block_type,
                "title": db_block.title,
                "content": db_block.compiled_code or type_info.get("defaultContent", ""),
                "typeColor": "",
                "typeIcon": type_info.get("icon", "📋"),
                "typeLabel": type_info.get("label", "XX"),
                "orderIndex": db_block.order_index or 0,
                "isExpanded": True,
                "editMode": False,
            }
            self._cards.append(card)
        self.endInsertRows()

        self.cardsReordered.emit()

    @Slot(str)
    def updateAllContent(self, content: str) -> None:
        """Replace all card contents with the given text (for optimization apply).

        Update the first card with the full optimized content and clear
        all other cards, since the optimized prompt is a single unified text.
        """
        if not self._cards:
            return

        # Update the first card with the full optimized content
        self._cards[0]["content"] = content
        first_idx = self.index(0, 0)
        self.dataChanged.emit(first_idx, first_idx, [self.ContentRole])

        # Clear all other cards' content
        if len(self._cards) > 1:
            for i in range(1, len(self._cards)):
                self._cards[i]["content"] = ""
            last_idx = self.index(len(self._cards) - 1, 0)
            self.dataChanged.emit(self.index(1, 0), last_idx, [self.ContentRole])

        # Persist all changes to DB
        if self._project_id:
            try:
                from promptblocks.db.crud import BlockCRUD
                from promptblocks.db.session import get_session
                with get_session() as session:
                    try:
                        # Update first card
                        BlockCRUD.update(session, self._cards[0]["blockId"], compiled_code=content)
                        # Clear remaining cards
                        for i in range(1, len(self._cards)):
                            BlockCRUD.update(session, self._cards[i]["blockId"], compiled_code="")
                        session.commit()
                    except Exception:
                        session.rollback()
            except Exception:
                pass

        # Notify QML that cards have changed so preview/export can update
        self.cardsReordered.emit()

    @Slot(result="QVariantList")
    def getModuleTypes(self):
        """Return list of all 9 module types with metadata for the sidebar."""
        result = []
        for key, info in MODULE_TYPES.items():
            result.append({
                "type": key,
                "title": info["title"],
                "icon": info["icon"],
                "label": info["label"],
                "desc": info["title"],
            })
        return result

    @Slot(str, result=int)
    def findRowByBlockId(self, blockId):
        """Find the row index for a given blockId. Returns -1 if not found."""
        for i, card in enumerate(self._cards):
            if card["blockId"] == blockId:
                return i
        return -1

    def updateCardContentDirect(self, row, content):
        """Directly update content by row index (used by undo commands)."""
        if 0 <= row < len(self._cards):
            self._cards[row]["content"] = content
            idx = self.index(row, 0)
            self.dataChanged.emit(idx, idx, [self.ContentRole])

    @Slot(str, result=str)
    def getContextForBlock(self, blockId):
        """Collect context from all other cards for context-aware generation.

        Returns a JSON string with:
        - existing_modules: list of {blockType, title, content} for all cards except the target

        Note: Variable definitions are now handled centrally by VariableModel, not extracted from card content.
        """
        import json

        existing_modules = []

        for card in self._cards:
            # Skip the target card
            if card["blockId"] == blockId:
                continue

            # Only include cards that have non-trivial content (not just template placeholders)
            content = card.get("content", "")
            if content and len(content.strip()) > 10:
                existing_modules.append({
                    "blockType": card["blockType"],
                    "title": card["title"],
                    "content": content[:500],  # Truncate to avoid token overflow
                })

        context = {
            "existing_modules": existing_modules,
        }
        return json.dumps(context, ensure_ascii=False)

    def _reindex(self):
        """Re-assign sequential orderIndex to all cards."""
        for i, card in enumerate(self._cards):
            card["orderIndex"] = i
        if self._cards:
            first = self.index(0, 0)
            last = self.index(len(self._cards) - 1, 0)
            self.dataChanged.emit(first, last, [self.OrderIndexRole])
