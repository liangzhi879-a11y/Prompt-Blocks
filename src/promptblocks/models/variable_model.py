"""VariableModel — QAbstractListModel for variable definitions and resolution."""

import re
import uuid

from PySide6.QtCore import Qt, QAbstractListModel, QModelIndex, Slot, Signal

try:
    from PySide6.QtCore import QRegularExpression
    _HAS_QREGEX = True
except ImportError:
    _HAS_QREGEX = False


class VariableModel(QAbstractListModel):
    """QAbstractListModel managing variable definitions with scope-aware resolution."""

    NameRole = Qt.ItemDataRole.UserRole + 1
    VarTypeRole = Qt.ItemDataRole.UserRole + 2
    DefaultValueRole = Qt.ItemDataRole.UserRole + 3
    ScopeRole = Qt.ItemDataRole.UserRole + 4
    DescriptionRole = Qt.ItemDataRole.UserRole + 5
    ReferenceCountRole = Qt.ItemDataRole.UserRole + 6
    VarIdRole = Qt.ItemDataRole.UserRole + 7

    variableAdded = Signal(str)
    variableRemoved = Signal(str)
    variableChanged = Signal(str)

    def __init__(self, parent=None):
        super().__init__(parent)
        self._variables = []  # list of dicts
        self._project_id = ""

    def setProjectId(self, project_id: str):
        """Set the current project ID for DB operations."""
        self._project_id = project_id

    @Slot()
    def loadFromDb(self):
        """Load variables from the database for the current project."""
        if not self._project_id:
            return
        try:
            from promptblocks.db.crud import VariableCRUD
            from promptblocks.db.session import get_session

            with get_session() as session:
                db_vars = VariableCRUD.get_by_project(session, self._project_id)

            # Clear existing
            if self._variables:
                self.beginRemoveRows(QModelIndex(), 0, len(self._variables) - 1)
                self._variables.clear()
                self.endRemoveRows()

            if not db_vars:
                return

            self.beginInsertRows(QModelIndex(), 0, len(db_vars) - 1)
            for v in db_vars:
                self._variables.append({
                    "varId": v.id,
                    "name": v.name,
                    "varType": v.var_type,
                    "defaultValue": v.default_value or "",
                    "scope": v.scope,
                    "description": v.description or "",
                    "referenceCount": 0,
                })
            self.endInsertRows()
        except Exception:
            pass

    def rowCount(self, parent=QModelIndex()):
        return len(self._variables)

    def data(self, index, role=Qt.ItemDataRole.DisplayRole):
        if not index.isValid() or index.row() >= len(self._variables):
            return None
        var = self._variables[index.row()]
        role_map = {
            self.VarIdRole: "varId",
            self.NameRole: "name",
            self.VarTypeRole: "varType",
            self.DefaultValueRole: "defaultValue",
            self.ScopeRole: "scope",
            self.DescriptionRole: "description",
            self.ReferenceCountRole: "referenceCount",
        }
        key = role_map.get(role)
        if key is not None:
            return var.get(key)
        return None

    def roleNames(self):
        return {
            self.VarIdRole: b'varId',
            self.NameRole: b'name',
            self.VarTypeRole: b'varType',
            self.DefaultValueRole: b'defaultValue',
            self.ScopeRole: b'scope',
            self.DescriptionRole: b'description',
            self.ReferenceCountRole: b'referenceCount',
        }

    @Slot(str, str, str, str, str, result=bool)
    def addVariable(self, name, varType, defaultValue, scope, description=""):
        """Add a new variable. Returns True on success."""
        # Check for duplicate name in same scope
        for v in self._variables:
            if v["name"] == name and v["scope"] == scope:
                return False

        var = {
            "varId": str(uuid.uuid4()),
            "name": name,
            "varType": varType,
            "defaultValue": defaultValue,
            "scope": scope,
            "description": description,
            "referenceCount": 0,
        }

        row = len(self._variables)
        self.beginInsertRows(QModelIndex(), row, row)
        self._variables.append(var)
        self.endInsertRows()

        # Persist to DB
        if self._project_id:
            try:
                from promptblocks.db.crud import VariableCRUD
                from promptblocks.db.session import get_session

                with get_session() as session:
                    db_var = VariableCRUD.create(
                        session,
                        project_id=self._project_id,
                        name=name,
                        var_type=varType,
                        default_value=defaultValue,
                        scope=scope,
                        description=description,
                    )
                    self._variables[-1]["varId"] = db_var.id
            except Exception:
                pass

        self.variableAdded.emit(var["varId"])
        return True

    @Slot(str, result=bool)
    def removeVariable(self, varId):
        """Remove a variable by its ID. Returns True if found and removed."""
        for i, v in enumerate(self._variables):
            if v["varId"] == varId:
                self.beginRemoveRows(QModelIndex(), i, i)
                self._variables.pop(i)
                self.endRemoveRows()

                # Delete from DB
                if self._project_id:
                    try:
                        from promptblocks.db.crud import VariableCRUD
                        from promptblocks.db.session import get_session

                        with get_session() as session:
                            VariableCRUD.delete(session, varId)
                    except Exception:
                        pass

                self.variableRemoved.emit(varId)
                return True
        return False

    @Slot(str, str, str, str, str, str)
    def updateVariable(self, varId, name, varType, defaultValue, scope, description):
        """Update a variable's properties."""
        for i, v in enumerate(self._variables):
            if v["varId"] == varId:
                v["name"] = name
                v["varType"] = varType
                v["defaultValue"] = defaultValue
                v["scope"] = scope
                v["description"] = description
                idx = self.index(i, 0)
                self.dataChanged.emit(idx, idx)

                # Update in DB
                if self._project_id:
                    try:
                        from promptblocks.db.crud import VariableCRUD
                        from promptblocks.db.session import get_session

                        with get_session() as session:
                            VariableCRUD.update(
                                session,
                                varId,
                                name=name,
                                var_type=varType,
                                default_value=defaultValue,
                                scope=scope,
                                description=description,
                            )
                    except Exception:
                        pass

                self.variableChanged.emit(varId)
                return

    @Slot(str, str, result=str)
    def resolveVariable(self, name, scope):
        """Resolve a variable value based on scope priority.

        Priority: local > project > global
        """
        scope_order = {
            "local": ["local", "project", "global"],
            "project": ["project", "global"],
            "global": ["global"],
        }
        search_scopes = scope_order.get(scope, ["global"])

        for s in search_scopes:
            for v in self._variables:
                if v["name"] == name and v["scope"] == s:
                    return v["defaultValue"]
        return ""

    @Slot(str, result="QVariantList")
    def parseVariableReferences(self, text):
        """Find all {{varName}} patterns in text and return unique variable names."""
        if _HAS_QREGEX:
            regex = QRegularExpression(r"\{\{(\w+)\}\}")
            it = regex.globalMatch(text)
            seen = set()
            result = []
            while it.hasNext():
                match = it.next()
                name = match.captured(1)
                if name not in seen:
                    seen.add(name)
                    result.append(name)
            return result
        else:
            pattern = r"\{\{(\w+)\}\}"
            matches = re.findall(pattern, text)
            seen = set()
            result = []
            for name in matches:
                if name not in seen:
                    seen.add(name)
                    result.append(name)
            return result

    @Slot(str, result="QVariantList")
    def validateReferences(self, text):
        """Check if all {{varName}} references have corresponding variable definitions.

        Returns list of undefined variable names.
        """
        referenced = self.parseVariableReferences(text)
        defined_names = {v["name"] for v in self._variables}
        return [name for name in referenced if name not in defined_names]

    @Slot(str)
    def updateReferenceCounts(self, fullText):
        """Update referenceCount for each variable based on full prompt text."""
        referenced = self.parseVariableReferences(fullText)
        from collections import Counter
        counts = Counter(referenced)
        for i, v in enumerate(self._variables):
            new_count = counts.get(v["name"], 0)
            if v["referenceCount"] != new_count:
                v["referenceCount"] = new_count
                idx = self.index(i, 0)
                self.dataChanged.emit(idx, idx, [self.ReferenceCountRole])

    @Slot(result="QVariantList")
    def getVariables(self):
        """Return all variables as a list of dicts for QML."""
        return [
            {
                "varId": v["varId"],
                "name": v["name"],
                "varType": v["varType"],
                "defaultValue": v["defaultValue"],
                "scope": v["scope"],
                "description": v["description"],
                "referenceCount": v["referenceCount"],
            }
            for v in self._variables
        ]
