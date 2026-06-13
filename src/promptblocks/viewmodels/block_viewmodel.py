"""BlockViewModel — bridges Block CRUD operations to QML."""

from __future__ import annotations

import json

from PySide6.QtCore import QObject, Signal, Slot

from promptblocks.compilers.guidance_compiler import GuidanceCompiler
from promptblocks.compilers.llm_client import LLMClient
from promptblocks.compilers.registry import CompilerRegistry
from promptblocks.compilers.schema_compiler import SchemaCompiler
from promptblocks.db.crud import BlockCRUD
from promptblocks.db.models import Block
from promptblocks.db.session import get_session


def _block_to_dict(block: Block) -> dict:
    return {
        "id": block.id,
        "project_id": block.project_id,
        "block_type": block.block_type,
        "title": block.title,
        "description_text": block.description_text,
        "compiled_code": block.compiled_code,
        "position_x": block.position_x,
        "position_y": block.position_y,
        "config": block.config,
        "order_index": block.order_index,
        "created_at": block.created_at.isoformat() if block.created_at else None,
        "updated_at": block.updated_at.isoformat() if block.updated_at else None,
    }


class BlockViewModel(QObject):
    blocksChanged = Signal()  # noqa: N815
    blockCompiled = Signal(str, str)  # noqa: N815  (block_id, compiled_code)
    errorOccurred = Signal(str)  # noqa: N815

    def __init__(self, parent=None):
        super().__init__(parent)
        self._blocks: list[dict] = []
        self._current_block: dict = {}
        self._project_id: str = ""
        self._registry = self._build_registry()

    # --- Public API ---

    @Slot(str)
    def loadBlocks(self, project_id: str) -> None:  # noqa: N802
        session = _get_session()
        try:
            self._project_id = project_id
            blocks = BlockCRUD.get_by_project(session, project_id)
            self._blocks = [_block_to_dict(b) for b in blocks]
            self.blocksChanged.emit()
        except Exception as e:
            self.errorOccurred.emit(str(e))
        finally:
            session.close()

    @Slot(str, str, float, float)
    def addBlock(  # noqa: N802
        self, project_id: str, block_type: str, pos_x: float, pos_y: float
    ) -> None:
        session = _get_session()
        try:
            block = BlockCRUD.create(
                session,
                project_id=project_id,
                block_type=block_type,
                title=block_type.title(),
                position_x=pos_x,
                position_y=pos_y,
            )
            session.commit()
            self._current_block = _block_to_dict(block)
            self.loadBlocks(project_id)
        except Exception as e:
            session.rollback()
            self.errorOccurred.emit(str(e))
        finally:
            session.close()

    @Slot(str, str)
    def updateBlock(self, block_id: str, data_json: str) -> None:  # noqa: N802
        session = _get_session()
        try:
            data = json.loads(data_json)
            block = BlockCRUD.update(session, block_id, **data)
            if block is None:
                self.errorOccurred.emit(f"Block {block_id} not found")
                return
            session.commit()
            self._current_block = _block_to_dict(block)
            if self._project_id:
                self.loadBlocks(self._project_id)
        except Exception as e:
            session.rollback()
            self.errorOccurred.emit(str(e))
        finally:
            session.close()

    @Slot(str)
    def deleteBlock(self, block_id: str) -> None:  # noqa: N802
        try:
            with get_session() as session:
                block = BlockCRUD.get(session, block_id)
                project_id = block.project_id if block else self._project_id
                BlockCRUD.delete(session, block_id)
                if project_id:
                    self.loadBlocks(project_id)
        except Exception as e:
            self.errorOccurred.emit(str(e))

    @Slot(str, float, float)
    def moveBlock(self, block_id: str, pos_x: float, pos_y: float) -> None:  # noqa: N802
        session = _get_session()
        try:
            BlockCRUD.update(session, block_id, position_x=pos_x, position_y=pos_y)
            session.commit()
            if self._project_id:
                self.loadBlocks(self._project_id)
        except Exception as e:
            session.rollback()
            self.errorOccurred.emit(str(e))
        finally:
            session.close()

    @Slot(str, str)
    def updateBlockCode(self, block_id: str, code: str) -> None:  # noqa: N802
        session = _get_session()
        try:
            BlockCRUD.update(session, block_id, compiled_code=code)
            session.commit()
            self.blockCompiled.emit(block_id, code)
        except Exception as e:
            session.rollback()
            self.errorOccurred.emit(str(e))
        finally:
            session.close()

    @Slot(str)
    def compileBlock(self, block_id: str) -> None:  # noqa: N802
        """Compile a block's description_text using the registered compiler."""
        session = _get_session()
        try:
            block = BlockCRUD.get(session, block_id)
            if block is None:
                self.errorOccurred.emit(f"Block {block_id} not found")
                return
            description = block.description_text or ""
            if not description:
                self.errorOccurred.emit("Block has no description to compile")
                return
            result = self._registry.compile(block.block_type, description)
            if result.success:
                BlockCRUD.update(session, block_id, compiled_code=result.compiled_code)
                session.commit()
                self.blockCompiled.emit(block_id, result.compiled_code)
            else:
                self.errorOccurred.emit(result.error or "Compilation failed")
        except Exception as e:
            session.rollback()
            self.errorOccurred.emit(str(e))
        finally:
            session.close()

    @staticmethod
    def _build_registry() -> CompilerRegistry:
        """Build and return a CompilerRegistry with default compilers."""
        llm = LLMClient()
        schema_compiler = SchemaCompiler(llm_client=llm)
        guidance_compiler = GuidanceCompiler(llm_client=llm, schema_compiler=schema_compiler)

        registry = CompilerRegistry()
        registry.register("format_constraint", _SchemaAdapter(schema_compiler))
        registry.register("instruction", _GuidanceAdapter(guidance_compiler))
        registry.register("example", _GuidanceAdapter(guidance_compiler))
        registry.register("reasoning", _GuidanceAdapter(guidance_compiler))
        registry.register("validation", _GuidanceAdapter(guidance_compiler))
        registry.register("flow_control", _GuidanceAdapter(guidance_compiler))
        return registry


class _SchemaAdapter:
    """Adapt SchemaCompiler to the Compiler protocol expected by CompilerRegistry."""

    def __init__(self, compiler: SchemaCompiler) -> None:
        self._compiler = compiler

    def compile(self, input_data: str):  # type: ignore[override]
        from promptblocks.compilers.registry import CompileResult

        r = self._compiler.compile(input_data)
        import json

        code = json.dumps(r.schema, indent=2, ensure_ascii=False) if r.success else ""
        return CompileResult(
            success=r.success,
            compiled_code=code,
            raw_response=r.raw_response,
            error=r.error,
        )


class _GuidanceAdapter:
    """Adapt GuidanceCompiler to the Compiler protocol expected by CompilerRegistry."""

    def __init__(self, compiler: GuidanceCompiler) -> None:
        self._compiler = compiler

    def compile(self, input_data: str):  # type: ignore[override]
        from promptblocks.compilers.registry import CompileResult

        template = self._compiler.compile_from_nl(input_data)
        success = bool(template)
        return CompileResult(
            success=success,
            compiled_code=template,
            raw_response=template,
            error=None if success else "Guidance compilation returned empty result",
        )
