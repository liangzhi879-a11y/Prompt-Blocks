"""Tests for Project CRUD operations."""

from promptblocks.db.crud import ProjectCRUD


class TestProjectCRUD:
    def test_create(self, db_session):
        project = ProjectCRUD.create(db_session, name="Test Project", description="A test")
        assert project.id is not None
        assert project.name == "Test Project"
        assert project.description == "A test"
        assert project.created_at is not None

    def test_get(self, db_session):
        created = ProjectCRUD.create(db_session, name="GetTest")
        fetched = ProjectCRUD.get(db_session, created.id)
        assert fetched is not None
        assert fetched.name == "GetTest"

    def test_get_not_found(self, db_session):
        result = ProjectCRUD.get(db_session, "nonexistent-id")
        assert result is None

    def test_get_all(self, db_session):
        ProjectCRUD.create(db_session, name="P1")
        ProjectCRUD.create(db_session, name="P2")
        all_projects = ProjectCRUD.get_all(db_session)
        assert len(all_projects) == 2

    def test_update(self, db_session):
        created = ProjectCRUD.create(db_session, name="Old Name")
        updated = ProjectCRUD.update(db_session, created.id, name="New Name")
        assert updated is not None
        assert updated.name == "New Name"

    def test_update_not_found(self, db_session):
        result = ProjectCRUD.update(db_session, "nonexistent-id", name="X")
        assert result is None

    def test_delete(self, db_session):
        created = ProjectCRUD.create(db_session, name="ToDelete")
        assert ProjectCRUD.delete(db_session, created.id) is True
        assert ProjectCRUD.get(db_session, created.id) is None

    def test_delete_not_found(self, db_session):
        assert ProjectCRUD.delete(db_session, "nonexistent-id") is False
