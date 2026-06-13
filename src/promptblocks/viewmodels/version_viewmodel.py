"""VersionViewModel — bridges Version CRUD operations to QML."""

import difflib
import json

from PySide6.QtCore import QObject, Property, Signal, Slot

from promptblocks.db.crud import VersionCRUD
from promptblocks.db.session import get_session


class VersionViewModel(QObject):
    versionCreated = Signal()       # noqa: N815
    versionRestored = Signal()      # noqa: N815
    versionsChanged = Signal()      # noqa: N815
    errorOccurred = Signal(str)     # noqa: N815

    def __init__(self, parent=None):
        super().__init__(parent)
        self._project_id = ""
        self._versions_data = []

    # ── Project ID ──

    @Slot(str)
    def setProjectId(self, project_id):
        self._project_id = project_id
        self.versionsChanged.emit()

    # ── Versions property ──

    @Property(list, notify=versionsChanged)
    def versions(self):
        return self._versions_data

    @Property(str, notify=versionsChanged)
    def currentVersion(self):
        if not self._versions_data:
            return ""
        return "v" + str(self._versions_data[0].get("version_number", 0))

    # ── Slots ──

    @Slot(str, result=str)
    def createSnapshot(self, description):
        if not self._project_id:
            self.errorOccurred.emit("No project selected")
            return ""
        try:
            with get_session() as session:
                version = VersionCRUD.create_snapshot(
                    session,
                    project_id=self._project_id,
                    description=description if description else None,
                )
                self._refresh_versions(session)
                self.versionCreated.emit()
                return version.id
        except Exception as e:
            self.errorOccurred.emit(str(e))
            return ""

    @Slot(str)
    def restoreVersion(self, version_id):
        try:
            with get_session() as session:
                project = VersionCRUD.restore(session, version_id)
                if project is None:
                    self.errorOccurred.emit("Version not found")
                    return
                self._refresh_versions(session)
                self.versionRestored.emit()
        except Exception as e:
            self.errorOccurred.emit(str(e))

    @Slot(result=str)
    def getVersions(self):
        return json.dumps(self._versions_data, ensure_ascii=False)

    @Slot(str, str, result=str)
    def diffVersions(self, id1, id2):
        try:
            with get_session() as session:
                from promptblocks.db.models import Version
                v1 = session.get(Version, id1)
                v2 = session.get(Version, id2)
                if v1 is None or v2 is None:
                    return "Version not found"
                snap1 = json.dumps(v1.snapshot, ensure_ascii=False, indent=2).splitlines(keepends=True)
                snap2 = json.dumps(v2.snapshot, ensure_ascii=False, indent=2).splitlines(keepends=True)
                diff = difflib.unified_diff(snap1, snap2, fromfile=f"v{v1.version_number}", tofile=f"v{v2.version_number}")
                return "".join(diff)
        except Exception as e:
            return str(e)

    # ── Internal ──

    def _refresh_versions(self, session):
        if not self._project_id:
            self._versions_data = []
            self.versionsChanged.emit()
            return
        versions = VersionCRUD.get_by_project(session, self._project_id)
        self._versions_data = [
            {
                "id": v.id,
                "version_number": v.version_number,
                "description": v.description or "",
                "created_at": v.created_at.isoformat() if v.created_at else "",
            }
            for v in versions
        ]
        self.versionsChanged.emit()
