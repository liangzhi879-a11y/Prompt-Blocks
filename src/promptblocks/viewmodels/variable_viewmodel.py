"""Variable ViewModel bridging variable CRUD operations to QML."""

import re
import uuid

from PySide6.QtCore import QObject, Signal, Slot


class VariableData:
    """Data model for a single variable."""

    def __init__(
        self,
        var_id: str,
        name: str,
        var_type: str = "text",
        default_value: str = "",
        scope: str = "global",
    ):
        self.var_id = var_id
        self.name = name
        self.var_type = var_type
        self.default_value = default_value
        self.scope = scope

    def to_dict(self) -> dict:
        return {
            "id": self.var_id,
            "name": self.name,
            "var_type": self.var_type,
            "default_value": self.default_value,
            "scope": self.scope,
        }


class VariableViewModel(QObject):
    """ViewModel managing variable state and operations."""

    variableAdded = Signal(str)  # noqa: N815
    variableRemoved = Signal(str)  # noqa: N815
    variableChanged = Signal(str)  # noqa: N815

    def __init__(self, parent=None):
        super().__init__(parent)
        self._variables: list[VariableData] = []

    @Slot(str, str, str, str)
    def addVariable(self, name: str, var_type: str, default_value: str, scope: str) -> None:  # noqa: N802
        """Add a new variable."""
        var_id = str(uuid.uuid4())[:8]
        var_data = VariableData(
            var_id=var_id,
            name=name,
            var_type=var_type,
            default_value=default_value,
            scope=scope,
        )
        self._variables.append(var_data)
        self.variableAdded.emit(var_id)

    @Slot(str)
    def removeVariable(self, var_id: str) -> None:  # noqa: N802
        """Remove a variable by ID."""
        self._variables = [v for v in self._variables if v.var_id != var_id]
        self.variableRemoved.emit(var_id)

    @Slot(str, str, str, str, str)
    def updateVariable(self, var_id: str, name: str, var_type: str, default_value: str, scope: str) -> None:  # noqa: N802
        """Update a variable's properties."""
        for v in self._variables:
            if v.var_id == var_id:
                v.name = name
                v.var_type = var_type
                v.default_value = default_value
                v.scope = scope
                self.variableChanged.emit(var_id)
                return

    @Slot(result="QVariantList")
    def getVariables(self) -> list:  # noqa: N802
        """Return all variables as a list of dicts."""
        return [v.to_dict() for v in self._variables]

    @Slot(result="QVariantList")
    def getVariablesForQML(self) -> list:  # noqa: N802
        """Return all variables as a QVariantList suitable for QML ListView.

        Each item is a dict with: id, name, var_type, default_value, scope.
        """
        return [v.to_dict() for v in self._variables]

    @Slot(str, result="QVariantList")
    def parseVariableReferences(self, text: str) -> list:  # noqa: N802
        """Find all {{varName}} patterns in text and return list of variable names.

        Args:
            text: The text to parse for variable references.

        Returns:
            A list of unique variable name strings found in the text.
        """
        pattern = r"\{\{(\w+)\}\}"
        matches = re.findall(pattern, text)
        # Return unique names preserving order
        seen: set[str] = set()
        result: list[str] = []
        for name in matches:
            if name not in seen:
                seen.add(name)
                result.append(name)
        return result

    @Slot(str, result="QVariantList")
    def validateReferences(self, text: str) -> list:  # noqa: N802
        """Check if all {{varName}} references have corresponding variable definitions.

        Args:
            text: The text to validate variable references in.

        Returns:
            A list of undefined variable names (references without definitions).
        """
        referenced = self.parseVariableReferences(text)
        defined_names = {v.name for v in self._variables}
        return [name for name in referenced if name not in defined_names]

    @Slot(str, str, result=str)
    def resolveVariable(self, name: str, scope: str) -> str:  # noqa: N802
        """Resolve a variable value based on scope priority.

        Priority: local > project > global
        If scope is 'local', look for local first, then project, then global.
        If scope is 'project', look for project first, then global.
        If scope is 'global', look for global only.
        """
        scope_order = {
            "local": ["local", "project", "global"],
            "project": ["project", "global"],
            "global": ["global"],
        }
        search_scopes = scope_order.get(scope, ["global"])

        for s in search_scopes:
            for v in self._variables:
                if v.name == name and v.scope == s:
                    return v.default_value
        return ""
