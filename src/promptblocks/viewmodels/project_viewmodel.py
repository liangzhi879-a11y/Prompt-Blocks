"""ProjectViewModel — bridges Project CRUD operations to QML."""

from __future__ import annotations

import json

from PySide6.QtCore import QObject, Signal, Slot

from promptblocks.db.crud import ProjectCRUD
from promptblocks.db.models import Project
from promptblocks.db.session import get_session


def _project_to_dict(project: Project) -> dict:
    return {
        "id": project.id,
        "name": project.name,
        "description": project.description,
        "created_at": project.created_at.isoformat() if project.created_at else None,
        "updated_at": project.updated_at.isoformat() if project.updated_at else None,
    }


class ProjectViewModel(QObject):
    projectListChanged = Signal()  # noqa: N815
    currentProjectChanged = Signal()  # noqa: N815
    errorOccurred = Signal(str)  # noqa: N815
    synthesisCompleted = Signal(str)  # noqa: N815

    def __init__(self, parent=None):
        super().__init__(parent)
        self._project_list: list[dict] = []
        self._current_project: dict = {}
        self._is_loading: bool = False

    # --- Q_PROPERTY helpers ---

    def _read_project_list(self) -> str:
        return json.dumps(self._project_list)

    def _read_current_project(self) -> str:
        return json.dumps(self._current_project)

    def _read_is_loading(self) -> bool:
        return self._is_loading

    def _set_is_loading(self, value: bool) -> None:
        if self._is_loading != value:
            self._is_loading = value

    # --- Public API ---

    @Slot()
    def refreshProjectList(self) -> None:  # noqa: N802
        try:
            with get_session() as session:
                projects = ProjectCRUD.get_all(session)
                self._project_list = [_project_to_dict(p) for p in projects]
                self.projectListChanged.emit()
        except Exception as e:
            self.errorOccurred.emit(str(e))

    @Slot(str, str)
    def createProject(self, name: str, description: str = "") -> None:  # noqa: N802
        try:
            with get_session() as session:
                project = ProjectCRUD.create(session, name=name, description=description or None)
                self._current_project = _project_to_dict(project)
                self.currentProjectChanged.emit()
                self.refreshProjectList()
        except Exception as e:
            self.errorOccurred.emit(str(e))

    @Slot(str)
    def loadProject(self, project_id: str) -> None:  # noqa: N802
        try:
            with get_session() as session:
                project = ProjectCRUD.get(session, project_id)
                if project is None:
                    self.errorOccurred.emit(f"Project {project_id} not found")
                    return
                self._current_project = _project_to_dict(project)
                self.currentProjectChanged.emit()
        except Exception as e:
            self.errorOccurred.emit(str(e))

    @Slot(str)
    def deleteProject(self, project_id: str) -> None:  # noqa: N802
        try:
            with get_session() as session:
                ProjectCRUD.delete(session, project_id)
                if self._current_project.get("id") == project_id:
                    self._current_project = {}
                    self.currentProjectChanged.emit()
                self.refreshProjectList()
        except Exception as e:
            self.errorOccurred.emit(str(e))

    @Slot(str, str)
    def updateProject(self, project_id: str, data_json: str) -> None:  # noqa: N802
        try:
            with get_session() as session:
                data = json.loads(data_json)
                project = ProjectCRUD.update(session, project_id, **data)
                if project is None:
                    self.errorOccurred.emit(f"Project {project_id} not found")
                    return
                self._current_project = _project_to_dict(project)
                self.currentProjectChanged.emit()
                self.refreshProjectList()
        except Exception as e:
            self.errorOccurred.emit(str(e))

    @Slot(str, str)
    def synthesizeProject(self, project_id: str, backend: str = "guidance") -> None:  # noqa: N802
        """Synthesize all blocks in a project into a final prompt."""
        from promptblocks.synthesis.ir import IRBuilder
        from promptblocks.synthesis.synthesizer import PromptSynthesizer

        try:
            with get_session() as session:
                ir_graph = IRBuilder.build(project_id, session)
                synthesizer = PromptSynthesizer()
                result = synthesizer.synthesize(ir_graph, backend=backend)
                result_json = json.dumps(
                    {
                        "success": result.success,
                        "prompt": result.prompt,
                        "backend": result.backend,
                        "warnings": result.warnings,
                        "block_contributions": result.block_contributions,
                        "error": result.error,
                    },
                    ensure_ascii=False,
                )
                self.synthesisCompleted.emit(result_json)
        except Exception as e:
            error_json = json.dumps(
                {"success": False, "prompt": "", "backend": backend, "error": str(e)},
                ensure_ascii=False,
            )
            self.synthesisCompleted.emit(error_json)
