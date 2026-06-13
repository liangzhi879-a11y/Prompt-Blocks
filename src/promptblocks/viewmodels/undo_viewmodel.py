"""Undo/Redo ViewModel for card list state management."""

from PySide6.QtCore import Property, QObject, Signal, Slot


class UndoViewModel(QObject):
    """ViewModel providing undo/redo functionality for card list state.

    Stores full card list state as JSON strings in undo/redo stacks.
    Before any card operation, push the current state; on undo/redo,
    restore the card list from the returned JSON.
    """

    undoAvailableChanged = Signal()  # noqa: N815
    redoAvailableChanged = Signal()  # noqa: N815
    stateRestored = Signal(str)  # noqa: N815

    def __init__(self, parent=None):
        super().__init__(parent)
        self._undo_stack: list[str] = []
        self._redo_stack: list[str] = []
        self._max_history: int = 50

    @Property(bool, notify=undoAvailableChanged)
    def canUndo(self) -> bool:  # noqa: N802
        return len(self._undo_stack) > 0

    @Property(bool, notify=redoAvailableChanged)
    def canRedo(self) -> bool:  # noqa: N802
        return len(self._redo_stack) > 0

    @Slot(str)
    def pushState(self, state_json: str) -> None:  # noqa: N802
        """Push current state to undo stack and clear redo stack."""
        if not state_json:
            return

        self._undo_stack.append(state_json)

        # Enforce max history
        if len(self._undo_stack) > self._max_history:
            self._undo_stack.pop(0)

        # Clear redo stack on new action
        self._redo_stack.clear()

        self.undoAvailableChanged.emit()
        self.redoAvailableChanged.emit()

    @Slot(result=str)
    def undo(self) -> str:  # noqa: N802
        """Pop from undo stack, push current to redo, return previous state."""
        if not self._undo_stack:
            return ""

        state = self._undo_stack.pop()
        self._redo_stack.append(state)

        self.undoAvailableChanged.emit()
        self.redoAvailableChanged.emit()

        # Return the new top of undo stack (the state to restore)
        if self._undo_stack:
            restored = self._undo_stack[-1]
            self.stateRestored.emit(restored)
            return restored

        # No more undo states — return empty to indicate initial state
        self.stateRestored.emit("")
        return ""

    @Slot(result=str)
    def redo(self) -> str:  # noqa: N802
        """Pop from redo stack, return that state."""
        if not self._redo_stack:
            return ""

        state = self._redo_stack.pop()
        self._undo_stack.append(state)

        self.undoAvailableChanged.emit()
        self.redoAvailableChanged.emit()

        self.stateRestored.emit(state)
        return state

    @Slot()
    def clear(self) -> None:
        """Clear both undo and redo stacks."""
        self._undo_stack.clear()
        self._redo_stack.clear()
        self.undoAvailableChanged.emit()
        self.redoAvailableChanged.emit()
