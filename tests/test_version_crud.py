"""Tests for Version CRUD operations."""

from promptblocks.db.crud import BlockCRUD, ConnectionCRUD, ProjectCRUD, VersionCRUD


class TestVersionCRUD:
    def _setup_project_with_blocks(self, session):
        project = ProjectCRUD.create(session, name="VersionProject")
        b1 = BlockCRUD.create(
            session, project_id=project.id, block_type="instruction", title="B1"
        )
        b2 = BlockCRUD.create(
            session, project_id=project.id, block_type="example", title="B2"
        )
        return project, b1, b2

    def test_create_snapshot(self, db_session):
        project, b1, b2 = self._setup_project_with_blocks(db_session)
        ConnectionCRUD.create(
            db_session,
            project_id=project.id,
            source_block_id=b1.id,
            target_block_id=b2.id,
            source_port="output",
            target_port="input",
        )
        version = VersionCRUD.create_snapshot(db_session, project_id=project.id, description="v1")
        assert version.version_number == 1
        assert version.snapshot is not None
        assert len(version.snapshot["blocks"]) == 2
        assert len(version.snapshot["connections"]) == 1

    def test_create_snapshot_auto_increment(self, db_session):
        project, _, _ = self._setup_project_with_blocks(db_session)
        v1 = VersionCRUD.create_snapshot(db_session, project_id=project.id, description="v1")
        v2 = VersionCRUD.create_snapshot(db_session, project_id=project.id, description="v2")
        assert v1.version_number == 1
        assert v2.version_number == 2

    def test_get_by_project(self, db_session):
        project, _, _ = self._setup_project_with_blocks(db_session)
        VersionCRUD.create_snapshot(db_session, project_id=project.id, description="v1")
        VersionCRUD.create_snapshot(db_session, project_id=project.id, description="v2")
        versions = VersionCRUD.get_by_project(db_session, project.id)
        assert len(versions) == 2
        # Should be ordered by version_number desc
        assert versions[0].version_number == 2

    def test_get_latest(self, db_session):
        project, _, _ = self._setup_project_with_blocks(db_session)
        VersionCRUD.create_snapshot(db_session, project_id=project.id, description="v1")
        v2 = VersionCRUD.create_snapshot(db_session, project_id=project.id, description="v2")
        latest = VersionCRUD.get_latest(db_session, project.id)
        assert latest is not None
        assert latest.version_number == v2.version_number

    def test_restore(self, db_session):
        project, b1, b2 = self._setup_project_with_blocks(db_session)
        ConnectionCRUD.create(
            db_session,
            project_id=project.id,
            source_block_id=b1.id,
            target_block_id=b2.id,
            source_port="output",
            target_port="input",
        )
        v1 = VersionCRUD.create_snapshot(db_session, project_id=project.id, description="v1")

        # Modify: add a new block
        BlockCRUD.create(
            db_session, project_id=project.id, block_type="validation", title="B3"
        )
        assert len(BlockCRUD.get_by_project(db_session, project.id)) == 3

        # Restore to v1
        restored = VersionCRUD.restore(db_session, v1.id)
        assert restored is not None
        assert len(BlockCRUD.get_by_project(db_session, project.id)) == 2

    def test_restore_not_found(self, db_session):
        result = VersionCRUD.restore(db_session, "nonexistent-id")
        assert result is None
