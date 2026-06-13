"""Tests for the synthesis engine: IRBuilder, PromptSynthesizer, SynthesisResult."""

from __future__ import annotations

import json

import pytest
from sqlalchemy.orm import Session

from promptblocks.db.crud import BlockCRUD, ConnectionCRUD, ProjectCRUD
from promptblocks.synthesis.ir import CyclicDependencyError, IRBlock, IRBuilder, IRConnection, IRGraph
from promptblocks.synthesis.synthesizer import PromptSynthesizer, SynthesisResult


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture()
def project_with_blocks(db_session: Session) -> str:
    """Create a project with several blocks and return its id."""
    project = ProjectCRUD.create(db_session, name="Test Synthesis Project")
    db_session.flush()

    pid = project.id

    b1 = BlockCRUD.create(
        db_session,
        project_id=pid,
        block_type="instruction",
        title="Main Instruction",
        description_text="You are a helpful assistant.",
        order_index=1,
    )
    b2 = BlockCRUD.create(
        db_session,
        project_id=pid,
        block_type="example",
        title="Few-shot Examples",
        order_index=2,
    )
    BlockCRUD.update(
        db_session,
        b2.id,
        compiled_code=json.dumps(
            [
                {"input": "Hello", "output": "Hi there!"},
                {"input": "Goodbye", "output": "See you later!"},
            ]
        ),
    )
    b3 = BlockCRUD.create(
        db_session,
        project_id=pid,
        block_type="format_constraint",
        title="JSON Output",
        order_index=3,
    )
    BlockCRUD.update(
        db_session,
        b3.id,
        compiled_code=json.dumps({"type": "object", "properties": {"answer": {"type": "string"}}}),
    )
    b4 = BlockCRUD.create(
        db_session,
        project_id=pid,
        block_type="validation",
        title="Output Rules",
        order_index=4,
    )
    BlockCRUD.update(db_session, b4.id, compiled_code="Answer must be under 100 words.")
    b5 = BlockCRUD.create(
        db_session,
        project_id=pid,
        block_type="flow_control",
        title="Branch",
        order_index=5,
    )

    db_session.flush()

    # Connections: b1 → b2 → b3, b1 → b4
    ConnectionCRUD.create(
        db_session,
        project_id=pid,
        source_block_id=b1.id,
        target_block_id=b2.id,
        source_port="out",
        target_port="in",
    )
    ConnectionCRUD.create(
        db_session,
        project_id=pid,
        source_block_id=b2.id,
        target_block_id=b3.id,
        source_port="out",
        target_port="in",
    )
    ConnectionCRUD.create(
        db_session,
        project_id=pid,
        source_block_id=b1.id,
        target_block_id=b4.id,
        source_port="out",
        target_port="in",
    )

    db_session.flush()
    return pid


@pytest.fixture()
def project_with_cycle(db_session: Session) -> str:
    """Create a project with a cyclic dependency."""
    project = ProjectCRUD.create(db_session, name="Cyclic Project")
    db_session.flush()

    pid = project.id

    b1 = BlockCRUD.create(db_session, project_id=pid, block_type="instruction", title="A", order_index=1)
    b2 = BlockCRUD.create(db_session, project_id=pid, block_type="instruction", title="B", order_index=2)
    b3 = BlockCRUD.create(db_session, project_id=pid, block_type="instruction", title="C", order_index=3)
    db_session.flush()

    # A → B → C → A  (cycle)
    ConnectionCRUD.create(db_session, project_id=pid, source_block_id=b1.id, target_block_id=b2.id, source_port="out", target_port="in")
    ConnectionCRUD.create(db_session, project_id=pid, source_block_id=b2.id, target_block_id=b3.id, source_port="out", target_port="in")
    ConnectionCRUD.create(db_session, project_id=pid, source_block_id=b3.id, target_block_id=b1.id, source_port="out", target_port="in")
    db_session.flush()

    return pid


@pytest.fixture()
def project_with_reasoning(db_session: Session) -> str:
    """Create a project with a reasoning block."""
    project = ProjectCRUD.create(db_session, name="Reasoning Project")
    db_session.flush()

    pid = project.id

    b_reasoning = BlockCRUD.create(
        db_session,
        project_id=pid,
        block_type="reasoning",
        title="Calculator",
        order_index=1,
    )
    BlockCRUD.update(db_session, b_reasoning.id, compiled_code="def add(a, b):\n    return a + b")
    db_session.flush()
    return pid


# ---------------------------------------------------------------------------
# IR data model tests
# ---------------------------------------------------------------------------


class TestIRDataModel:
    def test_ir_block_defaults(self) -> None:
        block = IRBlock(
            block_id="b1",
            block_type="instruction",
            title="Test",
            description_text="desc",
            compiled_code="",
            config={},
            order_index=0,
        )
        assert block.dependencies == []

    def test_ir_connection(self) -> None:
        conn = IRConnection(source_id="s", target_id="t", source_port="out", target_port="in")
        assert conn.source_id == "s"
        assert conn.target_port == "in"

    def test_ir_graph_defaults(self) -> None:
        graph = IRGraph()
        assert graph.blocks == []
        assert graph.connections == []
        assert graph.topological_order == []


# ---------------------------------------------------------------------------
# IRBuilder tests
# ---------------------------------------------------------------------------


class TestIRBuilder:
    def test_build_from_db(self, db_session: Session, project_with_blocks: str) -> None:
        graph = IRBuilder.build(project_with_blocks, db_session)

        assert len(graph.blocks) == 5
        assert len(graph.connections) == 3

        # All blocks should appear in topological order
        assert set(graph.topological_order) == {b.block_id for b in graph.blocks}

    def test_topological_order_respects_edges(
        self, db_session: Session, project_with_blocks: str
    ) -> None:
        graph = IRBuilder.build(project_with_blocks, db_session)

        block_map = {b.block_id: b for b in graph.blocks}
        order_index = {bid: i for i, bid in enumerate(graph.topological_order)}

        # b1 → b2: b1 must come before b2
        b1 = [b for b in graph.blocks if b.title == "Main Instruction"][0]
        b2 = [b for b in graph.blocks if b.title == "Few-shot Examples"][0]
        assert order_index[b1.block_id] < order_index[b2.block_id]

        # b2 → b3: b2 must come before b3
        b3 = [b for b in graph.blocks if b.title == "JSON Output"][0]
        assert order_index[b2.block_id] < order_index[b3.block_id]

    def test_dependencies_populated(
        self, db_session: Session, project_with_blocks: str
    ) -> None:
        graph = IRBuilder.build(project_with_blocks, db_session)

        block_map = {b.block_id: b for b in graph.blocks}
        b2 = [b for b in graph.blocks if b.title == "Few-shot Examples"][0]
        b1 = [b for b in graph.blocks if b.title == "Main Instruction"][0]

        # b2 depends on b1
        assert b1.block_id in b2.dependencies

    def test_cyclic_dependency_raises(self, db_session: Session, project_with_cycle: str) -> None:
        with pytest.raises(CyclicDependencyError):
            IRBuilder.build(project_with_cycle, db_session)

    def test_empty_project(self, db_session: Session) -> None:
        project = ProjectCRUD.create(db_session, name="Empty")
        db_session.flush()

        graph = IRBuilder.build(project.id, db_session)
        assert graph.blocks == []
        assert graph.connections == []
        assert graph.topological_order == []

    def test_single_block_no_connections(self, db_session: Session) -> None:
        project = ProjectCRUD.create(db_session, name="Single Block")
        db_session.flush()

        BlockCRUD.create(
            db_session,
            project_id=project.id,
            block_type="instruction",
            title="Solo",
            description_text="Hello",
            order_index=1,
        )
        db_session.flush()

        graph = IRBuilder.build(project.id, db_session)
        assert len(graph.blocks) == 1
        assert graph.topological_order == [graph.blocks[0].block_id]


# ---------------------------------------------------------------------------
# PromptSynthesizer tests
# ---------------------------------------------------------------------------


class TestPromptSynthesizer:
    def test_instruction_block(self) -> None:
        block = IRBlock(
            block_id="b1",
            block_type="instruction",
            title="Instr",
            description_text="You are helpful.",
            compiled_code="",
            config={},
            order_index=0,
        )
        graph = IRGraph(blocks=[block], connections=[], topological_order=["b1"])

        result = PromptSynthesizer().synthesize(graph)
        assert result.success
        assert "You are helpful." in result.prompt

    def test_example_block_json(self) -> None:
        block = IRBlock(
            block_id="b1",
            block_type="example",
            title="Examples",
            description_text="",
            compiled_code=json.dumps([{"input": "Hi", "output": "Hello"}]),
            config={},
            order_index=0,
        )
        graph = IRGraph(blocks=[block], connections=[], topological_order=["b1"])

        result = PromptSynthesizer().synthesize(graph)
        assert "示例：" in result.prompt
        assert "输入：Hi" in result.prompt
        assert "输出：Hello" in result.prompt

    def test_example_block_raw_text(self) -> None:
        block = IRBlock(
            block_id="b1",
            block_type="example",
            title="Examples",
            description_text="Just some text",
            compiled_code="",
            config={},
            order_index=0,
        )
        graph = IRGraph(blocks=[block], connections=[], topological_order=["b1"])

        result = PromptSynthesizer().synthesize(graph)
        assert "示例：" in result.prompt
        assert "Just some text" in result.prompt

    def test_format_constraint_guidance(self) -> None:
        block = IRBlock(
            block_id="b1",
            block_type="format_constraint",
            title="Format",
            description_text="",
            compiled_code='{"type": "object"}',
            config={},
            order_index=0,
        )
        graph = IRGraph(blocks=[block], connections=[], topological_order=["b1"])

        result = PromptSynthesizer().synthesize(graph, backend="guidance")
        assert "{{#assistant~}}" in result.prompt
        assert "{{/assistant}}" in result.prompt

    def test_format_constraint_plain_text(self) -> None:
        block = IRBlock(
            block_id="b1",
            block_type="format_constraint",
            title="Format",
            description_text="",
            compiled_code='{"type": "object"}',
            config={},
            order_index=0,
        )
        graph = IRGraph(blocks=[block], connections=[], topological_order=["b1"])

        result = PromptSynthesizer().synthesize(graph, backend="plain_text")
        assert "JSON Schema" in result.prompt
        assert '"type": "object"' in result.prompt

    def test_reasoning_block(self) -> None:
        block = IRBlock(
            block_id="b1",
            block_type="reasoning",
            title="Calc",
            description_text="",
            compiled_code="def add(a, b):\n    return a + b",
            config={},
            order_index=0,
        )
        graph = IRGraph(blocks=[block], connections=[], topological_order=["b1"])

        result = PromptSynthesizer().synthesize(graph)
        assert "```python" in result.prompt
        assert "def add(a, b):" in result.prompt
        assert "先执行计算" in result.prompt

    def test_validation_block(self) -> None:
        block = IRBlock(
            block_id="b1",
            block_type="validation",
            title="Rules",
            description_text="",
            compiled_code="Must be under 100 words.",
            config={},
            order_index=0,
        )
        graph = IRGraph(blocks=[block], connections=[], topological_order=["b1"])

        result = PromptSynthesizer().synthesize(graph)
        assert "输出必须满足以下条件" in result.prompt
        assert "Must be under 100 words." in result.prompt

    def test_flow_control_block_warning(self) -> None:
        block = IRBlock(
            block_id="b1",
            block_type="flow_control",
            title="Branch",
            description_text="",
            compiled_code="",
            config={},
            order_index=0,
        )
        graph = IRGraph(blocks=[block], connections=[], topological_order=["b1"])

        result = PromptSynthesizer().synthesize(graph)
        assert result.prompt == ""
        assert len(result.warnings) == 1
        assert "流程控制块" in result.warnings[0]

    def test_unsupported_backend(self) -> None:
        graph = IRGraph(blocks=[], connections=[], topological_order=[])
        result = PromptSynthesizer().synthesize(graph, backend="unknown")
        assert not result.success
        assert "Unsupported backend" in result.error

    def test_multiple_blocks_concatenated(self) -> None:
        b1 = IRBlock(
            block_id="b1",
            block_type="instruction",
            title="Instr",
            description_text="Be helpful.",
            compiled_code="",
            config={},
            order_index=0,
        )
        b2 = IRBlock(
            block_id="b2",
            block_type="validation",
            title="Rules",
            description_text="",
            compiled_code="Keep it short.",
            config={},
            order_index=1,
        )
        graph = IRGraph(blocks=[b1, b2], connections=[], topological_order=["b1", "b2"])

        result = PromptSynthesizer().synthesize(graph)
        assert result.success
        assert "Be helpful." in result.prompt
        assert "Keep it short." in result.prompt
        # Instruction should come before validation
        assert result.prompt.index("Be helpful.") < result.prompt.index("Keep it short.")

    def test_block_contributions(self) -> None:
        b1 = IRBlock(
            block_id="b1",
            block_type="instruction",
            title="Instr",
            description_text="Hello",
            compiled_code="",
            config={},
            order_index=0,
        )
        graph = IRGraph(blocks=[b1], connections=[], topological_order=["b1"])

        result = PromptSynthesizer().synthesize(graph)
        assert "b1" in result.block_contributions
        assert result.block_contributions["b1"] == "Hello"

    def test_empty_blocks_produce_no_contribution(self) -> None:
        b1 = IRBlock(
            block_id="b1",
            block_type="instruction",
            title="Empty",
            description_text="",
            compiled_code="",
            config={},
            order_index=0,
        )
        graph = IRGraph(blocks=[b1], connections=[], topological_order=["b1"])

        result = PromptSynthesizer().synthesize(graph)
        assert result.block_contributions["b1"] == ""
        # Empty contributions are excluded from the final prompt
        assert result.prompt == ""


# ---------------------------------------------------------------------------
# SynthesisResult dataclass tests
# ---------------------------------------------------------------------------


class TestSynthesisResult:
    def test_defaults(self) -> None:
        result = SynthesisResult(success=True, prompt="test", backend="guidance")
        assert result.warnings == []
        assert result.block_contributions == {}
        assert result.error is None

    def test_with_error(self) -> None:
        result = SynthesisResult(success=False, prompt="", backend="guidance", error="fail")
        assert not result.success
        assert result.error == "fail"


# ---------------------------------------------------------------------------
# Integration: IRBuilder + PromptSynthesizer
# ---------------------------------------------------------------------------


class TestIntegration:
    def test_full_pipeline(
        self, db_session: Session, project_with_blocks: str
    ) -> None:
        graph = IRBuilder.build(project_with_blocks, db_session)
        result = PromptSynthesizer().synthesize(graph, backend="guidance")

        assert result.success
        assert "You are a helpful assistant." in result.prompt
        assert "示例：" in result.prompt
        assert "{{#assistant~}}" in result.prompt
        assert "输出必须满足以下条件" in result.prompt
        # flow_control block should produce a warning
        assert any("流程控制块" in w for w in result.warnings)

    def test_full_pipeline_plain_text(
        self, db_session: Session, project_with_blocks: str
    ) -> None:
        graph = IRBuilder.build(project_with_blocks, db_session)
        result = PromptSynthesizer().synthesize(graph, backend="plain_text")

        assert result.success
        assert "JSON Schema" in result.prompt

    def test_reasoning_pipeline(
        self, db_session: Session, project_with_reasoning: str
    ) -> None:
        graph = IRBuilder.build(project_with_reasoning, db_session)
        result = PromptSynthesizer().synthesize(graph)

        assert result.success
        assert "```python" in result.prompt
        assert "def add(a, b):" in result.prompt
