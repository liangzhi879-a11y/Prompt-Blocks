"""CRUD operations for PromptBlocks database models."""

from __future__ import annotations

from typing import Any, Sequence

from sqlalchemy import func
from sqlalchemy.orm import Session

from promptblocks.db.models import (
    Block,
    Knowledge,
    OptimizationRecord,
    Project,
    TestCase,
    TestResult,
    Tool,
    Variable,
    Version,
)

# ---------------------------------------------------------------------------
# Project CRUD
# ---------------------------------------------------------------------------


class ProjectCRUD:
    @classmethod
    def create(cls, session: Session, *, name: str, description: str | None = None) -> Project:
        project = Project(name=name, description=description)
        session.add(project)
        session.flush()
        return project

    @classmethod
    def get(cls, session: Session, project_id: str) -> Project | None:
        return session.get(Project, project_id)

    @classmethod
    def get_all(cls, session: Session) -> Sequence[Project]:
        return session.query(Project).order_by(Project.updated_at.desc()).all()

    @classmethod
    def update(cls, session: Session, project_id: str, **kwargs: Any) -> Project | None:
        project = cls.get(session, project_id)
        if project is None:
            return None
        for key, value in kwargs.items():
            if hasattr(project, key):
                setattr(project, key, value)
        session.flush()
        return project

    @classmethod
    def delete(cls, session: Session, project_id: str) -> bool:
        project = cls.get(session, project_id)
        if project is None:
            return False
        session.delete(project)
        session.flush()
        return True


# ---------------------------------------------------------------------------
# Block CRUD
# ---------------------------------------------------------------------------


class BlockCRUD:
    @classmethod
    def create(
        cls,
        session: Session,
        *,
        project_id: str,
        block_type: str,
        title: str,
        description_text: str | None = None,
        content_json: dict | None = None,
        config: dict | None = None,
        order_index: int | None = None,
        position_x: float = 0.0,
        position_y: float = 0.0,
    ) -> Block:
        if order_index is None:
            max_order = (
                session.query(func.max(Block.order_index))
                .filter(Block.project_id == project_id)
                .scalar()
            )
            order_index = (max_order or 0) + 1
        block = Block(
            project_id=project_id,
            block_type=block_type,
            title=title,
            description_text=description_text,
            content_json=content_json,
            config=config,
            order_index=order_index,
            position_x=position_x,
            position_y=position_y,
        )
        session.add(block)
        session.flush()
        return block

    @classmethod
    def get(cls, session: Session, block_id: str) -> Block | None:
        return session.get(Block, block_id)

    @classmethod
    def get_by_project(cls, session: Session, project_id: str) -> Sequence[Block]:
        return (
            session.query(Block)
            .filter(Block.project_id == project_id)
            .order_by(Block.order_index)
            .all()
        )

    @classmethod
    def update(cls, session: Session, block_id: str, **kwargs: Any) -> Block | None:
        block = cls.get(session, block_id)
        if block is None:
            return None
        for key, value in kwargs.items():
            if hasattr(block, key):
                setattr(block, key, value)
        session.flush()
        return block

    @classmethod
    def delete(cls, session: Session, block_id: str) -> bool:
        block = cls.get(session, block_id)
        if block is None:
            return False
        session.delete(block)
        session.flush()
        return True

    @classmethod
    def reorder(cls, session: Session, project_id: str, block_ids: list[str]) -> None:
        """Re-order blocks within a project according to the given list of IDs."""
        for index, bid in enumerate(block_ids):
            block = session.get(Block, bid)
            if block is not None and block.project_id == project_id:
                block.order_index = index
        session.flush()


# ---------------------------------------------------------------------------
# Variable CRUD
# ---------------------------------------------------------------------------


class VariableCRUD:
    @classmethod
    def create(
        cls,
        session: Session,
        *,
        project_id: str,
        name: str,
        var_type: str = "text",
        default_value: str | None = None,
        constraints: str | None = None,
        scope: str = "global",
        source: str = "user_input",
        description: str | None = None,
    ) -> Variable:
        variable = Variable(
            project_id=project_id,
            name=name,
            var_type=var_type,
            default_value=default_value,
            constraints=constraints,
            scope=scope,
            source=source,
            description=description,
        )
        session.add(variable)
        session.flush()
        return variable

    @classmethod
    def get(cls, session: Session, variable_id: str) -> Variable | None:
        return session.get(Variable, variable_id)

    @classmethod
    def get_by_project(cls, session: Session, project_id: str) -> Sequence[Variable]:
        return session.query(Variable).filter(Variable.project_id == project_id).all()

    @classmethod
    def update(cls, session: Session, variable_id: str, **kwargs: Any) -> Variable | None:
        variable = cls.get(session, variable_id)
        if variable is None:
            return None
        for key, value in kwargs.items():
            if hasattr(variable, key):
                setattr(variable, key, value)
        session.flush()
        return variable

    @classmethod
    def delete(cls, session: Session, variable_id: str) -> bool:
        variable = cls.get(session, variable_id)
        if variable is None:
            return False
        session.delete(variable)
        session.flush()
        return True

    @classmethod
    def reorder(cls, session: Session, project_id: str, variable_ids: list[str]) -> None:
        """Re-order variables within a project according to the given list of IDs."""
        for index, vid in enumerate(variable_ids):
            variable = session.get(Variable, vid)
            if variable is not None and variable.project_id == project_id:
                variable.order_index = index
        session.flush()


# ---------------------------------------------------------------------------
# Knowledge CRUD
# ---------------------------------------------------------------------------


class KnowledgeCRUD:
    @classmethod
    def create(
        cls,
        session: Session,
        *,
        project_id: str,
        name: str,
        source_type: str = "text",
        description: str | None = None,
        reference_url: str | None = None,
        tags: str | None = None,
    ) -> Knowledge:
        knowledge = Knowledge(
            project_id=project_id,
            name=name,
            source_type=source_type,
            description=description,
            reference_url=reference_url,
            tags=tags,
        )
        session.add(knowledge)
        session.flush()
        return knowledge

    @classmethod
    def get(cls, session: Session, knowledge_id: str) -> Knowledge | None:
        return session.get(Knowledge, knowledge_id)

    @classmethod
    def get_by_project(cls, session: Session, project_id: str) -> Sequence[Knowledge]:
        return session.query(Knowledge).filter(Knowledge.project_id == project_id).all()

    @classmethod
    def update(cls, session: Session, knowledge_id: str, **kwargs: Any) -> Knowledge | None:
        knowledge = cls.get(session, knowledge_id)
        if knowledge is None:
            return None
        for key, value in kwargs.items():
            if hasattr(knowledge, key):
                setattr(knowledge, key, value)
        session.flush()
        return knowledge

    @classmethod
    def delete(cls, session: Session, knowledge_id: str) -> bool:
        knowledge = cls.get(session, knowledge_id)
        if knowledge is None:
            return False
        session.delete(knowledge)
        session.flush()
        return True


# ---------------------------------------------------------------------------
# Tool CRUD
# ---------------------------------------------------------------------------


class ToolCRUD:
    @classmethod
    def create(
        cls,
        session: Session,
        *,
        project_id: str,
        name: str,
        tool_type: str = "api",
        description: str | None = None,
        parameters: str | None = None,
        endpoint: str | None = None,
    ) -> Tool:
        tool = Tool(
            project_id=project_id,
            name=name,
            tool_type=tool_type,
            description=description,
            parameters=parameters,
            endpoint=endpoint,
        )
        session.add(tool)
        session.flush()
        return tool

    @classmethod
    def get(cls, session: Session, tool_id: str) -> Tool | None:
        return session.get(Tool, tool_id)

    @classmethod
    def get_by_project(cls, session: Session, project_id: str) -> Sequence[Tool]:
        return session.query(Tool).filter(Tool.project_id == project_id).all()

    @classmethod
    def update(cls, session: Session, tool_id: str, **kwargs: Any) -> Tool | None:
        tool = cls.get(session, tool_id)
        if tool is None:
            return None
        for key, value in kwargs.items():
            if hasattr(tool, key):
                setattr(tool, key, value)
        session.flush()
        return tool

    @classmethod
    def delete(cls, session: Session, tool_id: str) -> bool:
        tool = cls.get(session, tool_id)
        if tool is None:
            return False
        session.delete(tool)
        session.flush()
        return True


# ---------------------------------------------------------------------------
# TestCase CRUD
# ---------------------------------------------------------------------------


class TestCaseCRUD:
    @classmethod
    def create(
        cls,
        session: Session,
        *,
        project_id: str,
        input_data: str,
        expected_output: str | None = None,
    ) -> TestCase:
        test_case = TestCase(
            project_id=project_id, input_data=input_data, expected_output=expected_output
        )
        session.add(test_case)
        session.flush()
        return test_case

    @classmethod
    def get_by_project(cls, session: Session, project_id: str) -> Sequence[TestCase]:
        return session.query(TestCase).filter(TestCase.project_id == project_id).all()

    @classmethod
    def update(cls, session: Session, test_case_id: str, **kwargs: Any) -> TestCase | None:
        test_case = session.get(TestCase, test_case_id)
        if test_case is None:
            return None
        for key, value in kwargs.items():
            if hasattr(test_case, key):
                setattr(test_case, key, value)
        session.flush()
        return test_case

    @classmethod
    def delete(cls, session: Session, test_case_id: str) -> bool:
        test_case = session.get(TestCase, test_case_id)
        if test_case is None:
            return False
        session.delete(test_case)
        session.flush()
        return True

    @classmethod
    def bulk_create(
        cls,
        session: Session,
        project_id: str,
        items: list[dict[str, Any]],
    ) -> list[TestCase]:
        cases = []
        for item in items:
            test_case = TestCase(
                project_id=project_id,
                input_data=item["input_data"],
                expected_output=item.get("expected_output"),
            )
            session.add(test_case)
            cases.append(test_case)
        session.flush()
        return cases


# ---------------------------------------------------------------------------
# TestResult CRUD
# ---------------------------------------------------------------------------


class TestResultCRUD:
    @classmethod
    def create(
        cls,
        session: Session,
        *,
        test_case_id: str,
        block_id: str | None = None,
        actual_output: str | None = None,
        passed: bool = False,
        error_message: str | None = None,
    ) -> TestResult:
        result = TestResult(
            test_case_id=test_case_id,
            block_id=block_id,
            actual_output=actual_output,
            passed=passed,
            error_message=error_message,
        )
        session.add(result)
        session.flush()
        return result

    @classmethod
    def get_by_test_case(cls, session: Session, test_case_id: str) -> Sequence[TestResult]:
        return session.query(TestResult).filter(TestResult.test_case_id == test_case_id).all()

    @classmethod
    def get_by_project(cls, session: Session, project_id: str) -> Sequence[TestResult]:
        return (
            session.query(TestResult)
            .join(TestCase, TestResult.test_case_id == TestCase.id)
            .filter(TestCase.project_id == project_id)
            .all()
        )


# ---------------------------------------------------------------------------
# Version CRUD
# ---------------------------------------------------------------------------


class VersionCRUD:
    @classmethod
    def create_snapshot(
        cls,
        session: Session,
        *,
        project_id: str,
        description: str | None = None,
    ) -> Version:
        max_ver = (
            session.query(func.max(Version.version_number))
            .filter(Version.project_id == project_id)
            .scalar()
        )
        version_number = (max_ver or 0) + 1

        blocks = BlockCRUD.get_by_project(session, project_id)
        variables = VariableCRUD.get_by_project(session, project_id)

        snapshot = {
            "blocks": [
                {
                    "id": b.id,
                    "block_type": b.block_type,
                    "title": b.title,
                    "description_text": b.description_text,
                    "compiled_code": b.compiled_code,
                    "content_json": b.content_json,
                    "config": b.config,
                    "order_index": b.order_index,
                }
                for b in blocks
            ],
            "variables": [
                {
                    "id": v.id,
                    "name": v.name,
                    "var_type": v.var_type,
                    "default_value": v.default_value,
                    "constraints": v.constraints,
                    "scope": v.scope,
                    "source": v.source,
                    "description": v.description,
                }
                for v in variables
            ],
        }

        version = Version(
            project_id=project_id,
            version_number=version_number,
            snapshot=snapshot,
            description=description,
        )
        session.add(version)
        session.flush()
        return version

    @classmethod
    def get_by_project(cls, session: Session, project_id: str) -> Sequence[Version]:
        return (
            session.query(Version)
            .filter(Version.project_id == project_id)
            .order_by(Version.version_number.desc())
            .all()
        )

    @classmethod
    def get_latest(cls, session: Session, project_id: str) -> Version | None:
        return (
            session.query(Version)
            .filter(Version.project_id == project_id)
            .order_by(Version.version_number.desc())
            .first()
        )

    @classmethod
    def restore(cls, session: Session, version_id: str) -> Project | None:
        """Restore project to a version by re-creating blocks and variables from snapshot."""
        version = session.get(Version, version_id)
        if version is None or version.snapshot is None:
            return None

        project_id = version.project_id
        project = session.get(Project, project_id)
        if project is None:
            return None

        # Delete existing blocks and variables
        for block in BlockCRUD.get_by_project(session, project_id):
            session.delete(block)
        for variable in VariableCRUD.get_by_project(session, project_id):
            session.delete(variable)
        session.flush()

        # Re-create from snapshot
        snapshot = version.snapshot
        block_id_map: dict[str, str] = {}
        for b_data in snapshot.get("blocks", []):
            new_block = Block(
                project_id=project_id,
                block_type=b_data["block_type"],
                title=b_data["title"],
                description_text=b_data.get("description_text"),
                compiled_code=b_data.get("compiled_code"),
                content_json=b_data.get("content_json"),
                config=b_data.get("config"),
                order_index=b_data.get("order_index", 0),
            )
            session.add(new_block)
            session.flush()
            block_id_map[b_data["id"]] = new_block.id

        for v_data in snapshot.get("variables", []):
            new_variable = Variable(
                project_id=project_id,
                name=v_data["name"],
                var_type=v_data.get("var_type", "text"),
                default_value=v_data.get("default_value"),
                constraints=v_data.get("constraints"),
                scope=v_data.get("scope", "global"),
                source=v_data.get("source", "user_input"),
                description=v_data.get("description"),
            )
            session.add(new_variable)

        session.flush()
        return project


# ---------------------------------------------------------------------------
# OptimizationRecord CRUD
# ---------------------------------------------------------------------------


class OptimizationRecordCRUD:
    @classmethod
    def create(
        cls,
        session: Session,
        *,
        project_id: str,
        original_prompt: str,
        optimized_prompt: str,
        problem_analysis: dict | None = None,
        changes: dict | None = None,
        improvement_report: dict | None = None,
        test_result_snapshot: dict | None = None,
    ) -> OptimizationRecord:
        record = OptimizationRecord(
            project_id=project_id,
            original_prompt=original_prompt,
            optimized_prompt=optimized_prompt,
            problem_analysis=problem_analysis,
            changes=changes,
            improvement_report=improvement_report,
            test_result_snapshot=test_result_snapshot,
        )
        session.add(record)
        session.flush()
        return record

    @classmethod
    def get_by_project(cls, session: Session, project_id: str) -> Sequence[OptimizationRecord]:
        return (
            session.query(OptimizationRecord)
            .filter(OptimizationRecord.project_id == project_id)
            .order_by(OptimizationRecord.created_at.desc())
            .limit(10)
            .all()
        )

    @classmethod
    def get_recent_for_fewshot(
        cls, session: Session, project_id: str, limit: int = 3
    ) -> Sequence[OptimizationRecord]:
        return (
            session.query(OptimizationRecord)
            .filter(OptimizationRecord.project_id == project_id)
            .order_by(OptimizationRecord.created_at.desc())
            .limit(limit)
            .all()
        )
