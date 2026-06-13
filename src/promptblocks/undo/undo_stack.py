"""UndoStack — QUndoStack-based undo/redo for module card operations."""

import json
from PySide6.QtCore import QObject, Slot, Signal, Property
from PySide6.QtGui import QUndoStack, QUndoCommand


class ContentEditCommand(QUndoCommand):
    """Undo command for editing a card's content."""

    def __init__(self, model, row, oldContent, newContent):
        super().__init__()
        self._model = model
        self._row = row
        self._oldContent = oldContent
        self._newContent = newContent
        self.setText("编辑内容")

    def undo(self):
        self._model.updateCardContentDirect(self._row, self._oldContent)

    def redo(self):
        self._model.updateCardContentDirect(self._row, self._newContent)


class SnapshotCommand(QUndoCommand):
    """Undo command for restoring a full model snapshot."""

    def __init__(self, model, oldSnapshotJson, newSnapshotJson):
        super().__init__()
        self._model = model
        self._oldSnapshot = json.loads(oldSnapshotJson) if oldSnapshotJson else []
        self._newSnapshot = json.loads(newSnapshotJson) if newSnapshotJson else []
        self.setText("编辑")

    def undo(self):
        self._restoreSnapshot(self._oldSnapshot)

    def redo(self):
        self._restoreSnapshot(self._newSnapshot)

    def _restoreSnapshot(self, snapshot):
        """Restore the model to match the given snapshot."""
        # Get current state
        current_cards = self._model._cards.copy()

        # Create a map of snapshot items by blockId for quick lookup
        snapshot_map = {item.get("blockId"): item for item in snapshot}
        current_map = {card["blockId"]: card for card in current_cards}

        # Remove cards that are not in the snapshot
        for card in current_cards:
            if card["blockId"] not in snapshot_map:
                self._model.removeCard(card["blockId"])

        # Update or add cards from snapshot
        for item in snapshot:
            block_id = item.get("blockId")
            block_type = item.get("blockType", "")
            content = item.get("content", "")
            title = item.get("title", "")

            if block_id in current_map:
                # Update existing card
                row = self._model.findRowByBlockId(block_id)
                if row >= 0:
                    self._model.updateCardContentDirect(row, content)
                    # Update title if changed
                    if self._model._cards[row].get("title") != title:
                        self._model._cards[row]["title"] = title
                        idx = self._model.index(row, 0)
                        self._model.dataChanged.emit(idx, idx, [self._model.TitleRole])
            else:
                # Add new card
                if self._model.addCard(block_type):
                    row = self._model.rowCount() - 1
                    # Update the newly added card with the correct data
                    self._model._cards[row]["blockId"] = block_id
                    self._model._cards[row]["content"] = content
                    self._model._cards[row]["title"] = title
                    idx = self._model.index(row, 0)
                    self._model.dataChanged.emit(idx, idx, [
                        self._model.ContentRole,
                        self._model.TitleRole,
                        self._model.BlockIdRole
                    ])

        # Reorder cards to match snapshot order
        for i, item in enumerate(snapshot):
            block_id = item.get("blockId")
            current_row = self._model.findRowByBlockId(block_id)
            if current_row >= 0 and current_row != i:
                self._model.moveCard(current_row, i)


class CardMoveCommand(QUndoCommand):
    """Undo command for moving a card from one row to another."""

    def __init__(self, model, fromRow, toRow):
        super().__init__()
        self._model = model
        self._fromRow = fromRow
        self._toRow = toRow
        self.setText("移动卡片")

    def undo(self):
        # Reverse: move from toRow back to fromRow
        self._model.moveCard(self._toRow, self._fromRow)

    def redo(self):
        self._model.moveCard(self._fromRow, self._toRow)


class UndoManager(QObject):
    """Wrapper exposing QUndoStack to QML via slots and properties."""

    canUndoChanged = Signal(bool)
    canRedoChanged = Signal(bool)

    def __init__(self, parent=None):
        super().__init__(parent)
        self._stack = QUndoStack(self)
        self._stack.canUndoChanged.connect(self.canUndoChanged.emit)
        self._stack.canRedoChanged.connect(self.canRedoChanged.emit)
        self._lastSnapshot = None
        self._model = None

    @Property(bool, notify=canUndoChanged)
    def canUndo(self):
        return self._stack.canUndo()

    @Property(bool, notify=canRedoChanged)
    def canRedo(self):
        return self._stack.canRedo()

    @Slot()
    def undo(self):
        self._stack.undo()

    @Slot()
    def redo(self):
        self._stack.redo()

    @Slot()
    def clear(self):
        self._stack.clear()

    @Slot(result=str)
    def undoText(self):
        return self._stack.undoText()

    @Slot(result=str)
    def redoText(self):
        return self._stack.redoText()

    @Slot()
    def pushContentEdit(self, model, row, oldContent, newContent):
        """Push a content edit command onto the undo stack."""
        self._stack.push(ContentEditCommand(model, row, oldContent, newContent))

    @Slot()
    def pushCardMove(self, model, fromRow, toRow):
        """Push a card move command onto the undo stack."""
        self._stack.push(CardMoveCommand(model, fromRow, toRow))

    @Slot("QObject*", str)
    def pushSnapshot(self, model, snapshotJson):
        """Push a snapshot command onto the undo stack.

        This captures the state BEFORE a change. The AFTER state is captured
        when the next snapshot is pushed or when undo/redo is triggered.
        """
        self._model = model
        if self._lastSnapshot is not None:
            # We have a previous snapshot, so we can create a command
            # with old=previous snapshot, new=current snapshot
            self._stack.push(SnapshotCommand(model, self._lastSnapshot, snapshotJson))
        # Store current snapshot as the last one
        self._lastSnapshot = snapshotJson

    @Slot()
    def captureCurrentState(self):
        """Capture the current model state as the last snapshot.

        Call this AFTER making changes to prepare for the next undo operation.
        """
        if self._model is not None:
            snapshot = []
            count = self._model.rowCount()
            for i in range(count):
                idx = self._model.index(i, 0)
                snapshot.append({
                    "blockId": self._model.data(idx, 257),  # BlockIdRole
                    "blockType": self._model.data(idx, 258),  # BlockTypeRole
                    "title": self._model.data(idx, 259),  # TitleRole
                    "content": self._model.data(idx, 260),  # ContentRole
                    "orderIndex": i
                })
            self._lastSnapshot = json.dumps(snapshot)
