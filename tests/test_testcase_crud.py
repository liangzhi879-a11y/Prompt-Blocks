"""Tests for TestCase and TestResult CRUD operations."""

from promptblocks.db.crud import BlockCRUD, ProjectCRUD, TestCaseCRUD, TestResultCRUD


class TestTestCaseCRUD:
    def _create_project(self, session):
        return ProjectCRUD.create(session, name="TestCaseProject")

    def test_create(self, db_session):
        project = self._create_project(db_session)
        tc = TestCaseCRUD.create(
            db_session, project_id=project.id, input_data="test input", expected_output="expected"
        )
        assert tc.id is not None
        assert tc.input_data == "test input"
        assert tc.expected_output == "expected"

    def test_get_by_project(self, db_session):
        project = self._create_project(db_session)
        TestCaseCRUD.create(db_session, project_id=project.id, input_data="input1")
        TestCaseCRUD.create(db_session, project_id=project.id, input_data="input2")
        cases = TestCaseCRUD.get_by_project(db_session, project.id)
        assert len(cases) == 2

    def test_update(self, db_session):
        project = self._create_project(db_session)
        tc = TestCaseCRUD.create(db_session, project_id=project.id, input_data="old")
        updated = TestCaseCRUD.update(db_session, tc.id, input_data="new")
        assert updated is not None
        assert updated.input_data == "new"

    def test_delete(self, db_session):
        project = self._create_project(db_session)
        tc = TestCaseCRUD.create(db_session, project_id=project.id, input_data="del")
        assert TestCaseCRUD.delete(db_session, tc.id) is True

    def test_bulk_create(self, db_session):
        project = self._create_project(db_session)
        items = [
            {"input_data": "bulk1", "expected_output": "out1"},
            {"input_data": "bulk2", "expected_output": "out2"},
            {"input_data": "bulk3"},
        ]
        cases = TestCaseCRUD.bulk_create(db_session, project.id, items)
        assert len(cases) == 3
        assert cases[0].input_data == "bulk1"
        assert cases[2].expected_output is None


class TestTestResultCRUD:
    def _setup(self, session):
        project = ProjectCRUD.create(session, name="ResultProject")
        block = BlockCRUD.create(
            session, project_id=project.id, block_type="instruction", title="B1"
        )
        tc = TestCaseCRUD.create(session, project_id=project.id, input_data="test")
        return project, block, tc

    def test_create(self, db_session):
        _, block, tc = self._setup(db_session)
        result = TestResultCRUD.create(
            db_session,
            test_case_id=tc.id,
            block_id=block.id,
            actual_output="actual",
            passed=True,
        )
        assert result.id is not None
        assert result.passed is True

    def test_get_by_test_case(self, db_session):
        _, _, tc = self._setup(db_session)
        TestResultCRUD.create(db_session, test_case_id=tc.id, actual_output="r1", passed=True)
        TestResultCRUD.create(db_session, test_case_id=tc.id, actual_output="r2", passed=False)
        results = TestResultCRUD.get_by_test_case(db_session, tc.id)
        assert len(results) == 2

    def test_get_by_project(self, db_session):
        project, _, tc = self._setup(db_session)
        TestResultCRUD.create(db_session, test_case_id=tc.id, actual_output="r1", passed=True)
        results = TestResultCRUD.get_by_project(db_session, project.id)
        assert len(results) == 1
