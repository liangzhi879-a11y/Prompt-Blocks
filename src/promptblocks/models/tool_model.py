"""ToolModel — QAbstractListModel for tool/capability definitions."""

import uuid

from PySide6.QtCore import Qt, QAbstractListModel, QModelIndex, Slot, Signal


class ToolModel(QAbstractListModel):
    """QAbstractListModel managing tool/capability definitions (form-based infrastructure)."""

    NameRole = Qt.ItemDataRole.UserRole + 1
    ToolTypeRole = Qt.ItemDataRole.UserRole + 2
    DescriptionRole = Qt.ItemDataRole.UserRole + 3
    ParametersRole = Qt.ItemDataRole.UserRole + 4
    EndpointRole = Qt.ItemDataRole.UserRole + 5
    ToolIdRole = Qt.ItemDataRole.UserRole + 6

    toolAdded = Signal(str)
    toolRemoved = Signal(str)

    def __init__(self, parent=None):
        super().__init__(parent)
        self._entries = []
        self._project_id = ""

    def rowCount(self, parent=QModelIndex()):
        return len(self._entries)

    def data(self, index, role=Qt.ItemDataRole.DisplayRole):
        if not index.isValid() or index.row() >= len(self._entries):
            return None
        entry = self._entries[index.row()]
        role_map = {
            self.ToolIdRole: "toolId",
            self.NameRole: "name",
            self.ToolTypeRole: "toolType",
            self.DescriptionRole: "description",
            self.ParametersRole: "parameters",
            self.EndpointRole: "endpoint",
        }
        key = role_map.get(role)
        if key is not None:
            return entry.get(key)
        return None

    def roleNames(self):
        return {
            self.ToolIdRole: b'toolId',
            self.NameRole: b'name',
            self.ToolTypeRole: b'toolType',
            self.DescriptionRole: b'description',
            self.ParametersRole: b'parameters',
            self.EndpointRole: b'endpoint',
        }

    def setProjectId(self, project_id: str):
        """Set the current project ID for DB operations."""
        self._project_id = project_id

    @Slot()
    def loadFromDb(self):
        """Load tool entries from the database for the current project."""
        if not self._project_id:
            return
        try:
            from promptblocks.db.crud import ToolCRUD
            from promptblocks.db.session import get_session

            with get_session() as session:
                db_entries = ToolCRUD.get_by_project(session, self._project_id)

            if self._entries:
                self.beginRemoveRows(QModelIndex(), 0, len(self._entries) - 1)
                self._entries.clear()
                self.endRemoveRows()

            if not db_entries:
                return

            self.beginInsertRows(QModelIndex(), 0, len(db_entries) - 1)
            for e in db_entries:
                self._entries.append({
                    "toolId": e.id,
                    "name": e.name,
                    "toolType": e.tool_type,
                    "description": e.description or "",
                    "parameters": e.parameters or "",
                    "endpoint": e.endpoint or "",
                })
            self.endInsertRows()
        except Exception:
            pass

    @Slot(str, str, str, str, str, result=bool)
    def addTool(self, name, toolType, description, parameters, endpoint=""):
        """Add a tool definition. Returns True on success."""
        for e in self._entries:
            if e["name"] == name:
                return False

        entry = {
            "toolId": str(uuid.uuid4()),
            "name": name,
            "toolType": toolType,
            "description": description,
            "parameters": parameters,
            "endpoint": endpoint,
        }

        row = len(self._entries)
        self.beginInsertRows(QModelIndex(), row, row)
        self._entries.append(entry)
        self.endInsertRows()

        if self._project_id:
            try:
                from promptblocks.db.crud import ToolCRUD
                from promptblocks.db.session import get_session

                with get_session() as session:
                    db_entry = ToolCRUD.create(
                        session,
                        project_id=self._project_id,
                        name=name,
                        tool_type=toolType,
                        description=description,
                        parameters=parameters,
                        endpoint=endpoint,
                    )
                    self._entries[-1]["toolId"] = db_entry.id
            except Exception:
                pass

        self.toolAdded.emit(entry["toolId"])
        return True

    @Slot(str, result=bool)
    def removeTool(self, toolId):
        """Remove a tool definition by ID. Returns True if found."""
        for i, e in enumerate(self._entries):
            if e["toolId"] == toolId:
                self.beginRemoveRows(QModelIndex(), i, i)
                self._entries.pop(i)
                self.endRemoveRows()

                if self._project_id:
                    try:
                        from promptblocks.db.crud import ToolCRUD
                        from promptblocks.db.session import get_session

                        with get_session() as session:
                            ToolCRUD.delete(session, toolId)
                    except Exception:
                        pass

                self.toolRemoved.emit(toolId)
                return True
        return False

    @Slot(str, str, str, str, str, str)
    def updateTool(self, toolId, name, toolType, description, parameters, endpoint):
        """Update a tool definition's properties."""
        for i, e in enumerate(self._entries):
            if e["toolId"] == toolId:
                e["name"] = name
                e["toolType"] = toolType
                e["description"] = description
                e["parameters"] = parameters
                e["endpoint"] = endpoint
                idx = self.index(i, 0)
                self.dataChanged.emit(idx, idx)
                if self._project_id:
                    try:
                        from promptblocks.db.crud import ToolCRUD
                        from promptblocks.db.session import get_session

                        with get_session() as session:
                            ToolCRUD.update(
                                session,
                                toolId,
                                name=name,
                                tool_type=toolType,
                                description=description,
                                parameters=parameters,
                                endpoint=endpoint,
                            )
                    except Exception:
                        pass
                return

    @Slot(result="QVariantList")
    def getTools(self):
        """Return all tool definitions as a list of dicts for QML and context."""
        return [
            {
                "toolId": e["toolId"],
                "name": e["name"],
                "toolType": e["toolType"],
                "description": e["description"],
                "parameters": e["parameters"],
                "endpoint": e["endpoint"],
            }
            for e in self._entries
        ]
