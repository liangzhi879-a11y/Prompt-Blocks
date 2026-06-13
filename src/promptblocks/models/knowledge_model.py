"""KnowledgeModel — QAbstractListModel for knowledge base entry definitions."""

import uuid

from PySide6.QtCore import Qt, QAbstractListModel, QModelIndex, Slot, Signal


class KnowledgeModel(QAbstractListModel):
    """QAbstractListModel managing knowledge base entries (form-based infrastructure)."""

    NameRole = Qt.ItemDataRole.UserRole + 1
    SourceTypeRole = Qt.ItemDataRole.UserRole + 2
    DescriptionRole = Qt.ItemDataRole.UserRole + 3
    ReferenceUrlRole = Qt.ItemDataRole.UserRole + 4
    TagsRole = Qt.ItemDataRole.UserRole + 5
    KnowledgeIdRole = Qt.ItemDataRole.UserRole + 6

    knowledgeAdded = Signal(str)
    knowledgeRemoved = Signal(str)

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
            self.KnowledgeIdRole: "knowledgeId",
            self.NameRole: "name",
            self.SourceTypeRole: "sourceType",
            self.DescriptionRole: "description",
            self.ReferenceUrlRole: "referenceUrl",
            self.TagsRole: "tags",
        }
        key = role_map.get(role)
        if key is not None:
            return entry.get(key)
        return None

    def roleNames(self):
        return {
            self.KnowledgeIdRole: b'knowledgeId',
            self.NameRole: b'name',
            self.SourceTypeRole: b'sourceType',
            self.DescriptionRole: b'description',
            self.ReferenceUrlRole: b'referenceUrl',
            self.TagsRole: b'tags',
        }

    def setProjectId(self, project_id: str):
        """Set the current project ID for DB operations."""
        self._project_id = project_id

    @Slot()
    def loadFromDb(self):
        """Load knowledge entries from the database for the current project."""
        if not self._project_id:
            return
        try:
            from promptblocks.db.crud import KnowledgeCRUD
            from promptblocks.db.session import get_session

            with get_session() as session:
                db_entries = KnowledgeCRUD.get_by_project(session, self._project_id)

            if self._entries:
                self.beginRemoveRows(QModelIndex(), 0, len(self._entries) - 1)
                self._entries.clear()
                self.endRemoveRows()

            if not db_entries:
                return

            self.beginInsertRows(QModelIndex(), 0, len(db_entries) - 1)
            for e in db_entries:
                self._entries.append({
                    "knowledgeId": e.id,
                    "name": e.name,
                    "sourceType": e.source_type,
                    "description": e.description or "",
                    "referenceUrl": e.reference_url or "",
                    "tags": e.tags or "",
                })
            self.endInsertRows()
        except Exception:
            pass

    @Slot(str, str, str, str, str, result=bool)
    def addKnowledge(self, name, sourceType, description, referenceUrl, tags=""):
        """Add a knowledge base entry. Returns True on success."""
        for e in self._entries:
            if e["name"] == name:
                return False

        entry = {
            "knowledgeId": str(uuid.uuid4()),
            "name": name,
            "sourceType": sourceType,
            "description": description,
            "referenceUrl": referenceUrl,
            "tags": tags,
        }

        row = len(self._entries)
        self.beginInsertRows(QModelIndex(), row, row)
        self._entries.append(entry)
        self.endInsertRows()

        if self._project_id:
            try:
                from promptblocks.db.crud import KnowledgeCRUD
                from promptblocks.db.session import get_session

                with get_session() as session:
                    db_entry = KnowledgeCRUD.create(
                        session,
                        project_id=self._project_id,
                        name=name,
                        source_type=sourceType,
                        description=description,
                        reference_url=referenceUrl,
                        tags=tags,
                    )
                    self._entries[-1]["knowledgeId"] = db_entry.id
            except Exception:
                pass

        self.knowledgeAdded.emit(entry["knowledgeId"])
        return True

    @Slot(str, result=bool)
    def removeKnowledge(self, knowledgeId):
        """Remove a knowledge entry by ID. Returns True if found."""
        for i, e in enumerate(self._entries):
            if e["knowledgeId"] == knowledgeId:
                self.beginRemoveRows(QModelIndex(), i, i)
                self._entries.pop(i)
                self.endRemoveRows()

                if self._project_id:
                    try:
                        from promptblocks.db.crud import KnowledgeCRUD
                        from promptblocks.db.session import get_session

                        with get_session() as session:
                            KnowledgeCRUD.delete(session, knowledgeId)
                    except Exception:
                        pass

                self.knowledgeRemoved.emit(knowledgeId)
                return True
        return False

    @Slot(str, str, str, str, str, str)
    def updateKnowledge(self, knowledgeId, name, sourceType, description, referenceUrl, tags):
        """Update a knowledge entry's properties."""
        for i, e in enumerate(self._entries):
            if e["knowledgeId"] == knowledgeId:
                e["name"] = name
                e["sourceType"] = sourceType
                e["description"] = description
                e["referenceUrl"] = referenceUrl
                e["tags"] = tags
                idx = self.index(i, 0)
                self.dataChanged.emit(idx, idx)
                # Update in DB
                if self._project_id:
                    try:
                        from promptblocks.db.crud import KnowledgeCRUD
                        from promptblocks.db.session import get_session

                        with get_session() as session:
                            KnowledgeCRUD.update(
                                session,
                                knowledgeId,
                                name=name,
                                source_type=sourceType,
                                description=description,
                                reference_url=referenceUrl,
                                tags=tags,
                            )
                    except Exception:
                        pass
                return

    @Slot(result="QVariantList")
    def getKnowledges(self):
        """Return all knowledge entries as a list of dicts for QML and context."""
        return [
            {
                "knowledgeId": e["knowledgeId"],
                "name": e["name"],
                "sourceType": e["sourceType"],
                "description": e["description"],
                "referenceUrl": e["referenceUrl"],
                "tags": e["tags"],
            }
            for e in self._entries
        ]
