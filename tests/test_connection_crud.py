"""Tests for Connection CRUD operations."""

from promptblocks.db.crud import BlockCRUD, ConnectionCRUD, ProjectCRUD


class TestConnectionCRUD:
    def _setup_project_with_blocks(self, session):
        project = ProjectCRUD.create(session, name="ConnTestProject")
        b1 = BlockCRUD.create(session, project_id=project.id, block_type="instruction", title="B1")
        b2 = BlockCRUD.create(session, project_id=project.id, block_type="example", title="B2")
        b3 = BlockCRUD.create(session, project_id=project.id, block_type="validation", title="B3")
        return project, b1, b2, b3

    def test_create(self, db_session):
        project, b1, b2, _ = self._setup_project_with_blocks(db_session)
        conn = ConnectionCRUD.create(
            db_session,
            project_id=project.id,
            source_block_id=b1.id,
            target_block_id=b2.id,
            source_port="output",
            target_port="input",
        )
        assert conn.id is not None
        assert conn.source_block_id == b1.id
        assert conn.target_block_id == b2.id

    def test_get_by_project(self, db_session):
        project, b1, b2, _ = self._setup_project_with_blocks(db_session)
        ConnectionCRUD.create(
            db_session,
            project_id=project.id,
            source_block_id=b1.id,
            target_block_id=b2.id,
            source_port="output",
            target_port="input",
        )
        conns = ConnectionCRUD.get_by_project(db_session, project.id)
        assert len(conns) == 1

    def test_delete(self, db_session):
        project, b1, b2, _ = self._setup_project_with_blocks(db_session)
        conn = ConnectionCRUD.create(
            db_session,
            project_id=project.id,
            source_block_id=b1.id,
            target_block_id=b2.id,
            source_port="output",
            target_port="input",
        )
        assert ConnectionCRUD.delete(db_session, conn.id) is True
        assert len(ConnectionCRUD.get_by_project(db_session, project.id)) == 0

    def test_validate_no_cycle_simple(self, db_session):
        project, b1, b2, b3 = self._setup_project_with_blocks(db_session)
        # b1 -> b2 is fine
        assert ConnectionCRUD.validate_no_cycle(db_session, project.id, b1.id, b2.id) is True
        ConnectionCRUD.create(
            db_session,
            project_id=project.id,
            source_block_id=b1.id,
            target_block_id=b2.id,
            source_port="output",
            target_port="input",
        )
        # b2 -> b3 is fine
        assert ConnectionCRUD.validate_no_cycle(db_session, project.id, b2.id, b3.id) is True
        ConnectionCRUD.create(
            db_session,
            project_id=project.id,
            source_block_id=b2.id,
            target_block_id=b3.id,
            source_port="output",
            target_port="input",
        )
        # b3 -> b1 would create a cycle
        assert ConnectionCRUD.validate_no_cycle(db_session, project.id, b3.id, b1.id) is False

    def test_validate_no_self_loop(self, db_session):
        project, b1, _, _ = self._setup_project_with_blocks(db_session)
        assert ConnectionCRUD.validate_no_cycle(db_session, project.id, b1.id, b1.id) is False

    def test_validate_no_cycle_no_existing_connections(self, db_session):
        project, b1, b2, _ = self._setup_project_with_blocks(db_session)
        assert ConnectionCRUD.validate_no_cycle(db_session, project.id, b1.id, b2.id) is True
