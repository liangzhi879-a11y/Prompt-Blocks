"""Intermediate Representation (IR) for the synthesis engine.

Converts database Block ORM objects into an IRGraph with
topological ordering, ready for the PromptSynthesizer.
"""

from __future__ import annotations

from dataclasses import dataclass, field

from sqlalchemy.orm import Session

from promptblocks.db.crud import BlockCRUD
from promptblocks.db.models import Block


@dataclass
class IRBlock:
    block_id: str
    block_type: str  # instruction/example/format_constraint/reasoning/validation/flow_control
    title: str
    description_text: str
    compiled_code: str
    config: dict
    order_index: int
    dependencies: list[str] = field(default_factory=list)


@dataclass
class IRGraph:
    blocks: list[IRBlock] = field(default_factory=list)
    topological_order: list[str] = field(default_factory=list)


class IRBuilder:
    """Build an IRGraph from database records for a given project."""

    @staticmethod
    def build(project_id: str, session: Session) -> IRGraph:
        """Load blocks from the database and return an IRGraph.

        Blocks are ordered by order_index (no explicit connections model yet).
        """
        db_blocks: list[Block] = list(BlockCRUD.get_by_project(session, project_id))

        # Convert ORM objects → IR objects
        ir_blocks: list[IRBlock] = []
        for b in db_blocks:
            ir_blocks.append(
                IRBlock(
                    block_id=b.id,
                    block_type=b.block_type,
                    title=b.title,
                    description_text=b.description_text or "",
                    compiled_code=b.compiled_code or "",
                    config=b.config or {},
                    order_index=b.order_index,
                )
            )

        # Topological order = order_index sort (no connections model yet)
        topo_order = [ib.block_id for ib in sorted(ir_blocks, key=lambda ib: ib.order_index)]

        return IRGraph(
            blocks=ir_blocks,
            topological_order=topo_order,
        )
