"""Tests for Block CRUD operations."""

from promptblocks.db.crud import BlockCRUD, ProjectCRUD


class TestBlockCRUD:
    def _create_project(self, session):
        return ProjectCRUD.create(session, name="BlockTestProject")

    def test_create(self, db_session):
        project = self._create_project(db_session)
        block = BlockCRUD.create(
            db_session,
            project_id=project.id,
            block_type="instruction",
            title="Test Block",
            position_x=100.0,
            position_y=200.0,
        )
        assert block.id is not None
        assert block.project_id == project.id
        assert block.block_type == "instruction"
        assert block.position_x == 100.0
        assert block.order_index == 1

    def test_create_auto_order(self, db_session):
        project = self._create_project(db_session)
        b1 = BlockCRUD.create(db_session, project_id=project.id, block_type="instruction", title="B1")
        b2 = BlockCRUD.create(db_session, project_id=project.id, block_type="example", title="B2")
        assert b1.order_index == 1
        assert b2.order_index == 2

    def test_get(self, db_session):
        project = self._create_project(db_session)
        created = BlockCRUD.create(
            db_session, project_id=project.id, block_type="instruction", title="GetBlock"
        )
        fetched = BlockCRUD.get(db_session, created.id)
        assert fetched is not None
        assert fetched.title == "GetBlock"

    def test_get_by_project(self, db_session):
        project = self._create_project(db_session)
        BlockCRUD.create(db_session, project_id=project.id, block_type="instruction", title="B1")
        BlockCRUD.create(db_session, project_id=project.id, block_type="example", title="B2")
        blocks = BlockCRUD.get_by_project(db_session, project.id)
        assert len(blocks) == 2

    def test_update(self, db_session):
        project = self._create_project(db_session)
        block = BlockCRUD.create(
            db_session, project_id=project.id, block_type="instruction", title="Old"
        )
        updated = BlockCRUD.update(db_session, block.id, title="New", compiled_code="print('hi')")
        assert updated is not None
        assert updated.title == "New"
        assert updated.compiled_code == "print('hi')"

    def test_delete(self, db_session):
        project = self._create_project(db_session)
        block = BlockCRUD.create(
            db_session, project_id=project.id, block_type="instruction", title="Del"
        )
        assert BlockCRUD.delete(db_session, block.id) is True
        assert BlockCRUD.get(db_session, block.id) is None

    def test_reorder(self, db_session):
        project = self._create_project(db_session)
        b1 = BlockCRUD.create(db_session, project_id=project.id, block_type="instruction", title="B1")
        b2 = BlockCRUD.create(db_session, project_id=project.id, block_type="example", title="B2")
        b3 = BlockCRUD.create(db_session, project_id=project.id, block_type="validation", title="B3")
        BlockCRUD.reorder(db_session, project.id, [b3.id, b1.id, b2.id])
        blocks = BlockCRUD.get_by_project(db_session, project.id)
        assert blocks[0].id == b3.id
        assert blocks[1].id == b1.id
        assert blocks[2].id == b2.id
