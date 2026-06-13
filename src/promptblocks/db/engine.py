"""Database engine configuration using SQLite."""

from __future__ import annotations

from pathlib import Path

from PySide6.QtCore import QStandardPaths
from sqlalchemy import create_engine, inspect, text


def get_db_path() -> Path:
    """Get the database file path in the user's AppData location."""
    data_dir = QStandardPaths.writableLocation(QStandardPaths.AppDataLocation)
    db_dir = Path(data_dir) / "PromptBlocks"
    db_dir.mkdir(parents=True, exist_ok=True)
    return db_dir / "promptblocks.db"


def get_engine():
    """Create and return a SQLAlchemy engine for SQLite."""
    db_path = get_db_path()
    db_url = f"sqlite:///{db_path}"
    return create_engine(db_url, echo=False)


_engine = None


def init_db() -> None:
    """Initialize the database, run migrations, and sync schema."""
    global _engine
    _engine = get_engine()

    # Run Alembic migrations
    _run_migrations()

    # Create tables that don't exist yet (for initial setup without migrations)
    from promptblocks.db.base import Base

    Base.metadata.create_all(_engine)

    # Auto-sync missing columns (handles model additions after initial DB creation)
    _sync_schema(Base)


def _run_migrations() -> None:
    """Run Alembic migrations to the latest revision."""
    try:
        from alembic.config import Config as AlembicConfig  # noqa: I001

        from alembic import command

        alembic_cfg_path = Path(__file__).parent.parent.parent.parent / "alembic.ini"
        if alembic_cfg_path.exists():
            alembic_cfg = AlembicConfig(str(alembic_cfg_path))
            alembic_cfg.set_main_option("sqlalchemy.url", f"sqlite:///{get_db_path()}")
            command.upgrade(alembic_cfg, "head")
    except Exception:
        # If migrations fail (e.g., already applied), continue with create_all
        pass


def _sync_schema(Base) -> None:
    """Detect and add any columns missing from existing tables.

    SQLAlchemy's create_all() only creates new tables, not new columns on
    existing tables. This function compares the model definition with the
    actual database schema and adds missing columns via ALTER TABLE.
    """
    inspector = inspect(_engine)
    table_names = inspector.get_table_names()

    for table_name in table_names:
        if table_name not in Base.metadata.tables:
            continue

        model_table = Base.metadata.tables[table_name]
        model_columns = {col.name for col in model_table.columns}
        db_columns = {col["name"] for col in inspector.get_columns(table_name)}
        missing = model_columns - db_columns

        for col_name in sorted(missing):
            col = model_table.columns[col_name]
            col_type = _sqlite_type_str(col)
            nullable = "" if col.nullable is not False else " NOT NULL"
            default_clause = ""
            if col.default and col.default.is_scalar:
                default_clause = f" DEFAULT {col.default.arg!r}"
            sql = f'ALTER TABLE "{table_name}" ADD COLUMN "{col_name}" {col_type}{nullable}{default_clause}'
            with _engine.connect() as conn:
                conn.execute(text(sql))
                conn.commit()


def _sqlite_type_str(col) -> str:
    """Convert a SQLAlchemy Column type to a SQLite type string."""
    import sqlalchemy.types as types

    type_map = {
        types.Integer: "INTEGER",
        types.BigInteger: "INTEGER",
        types.SmallInteger: "INTEGER",
        types.Boolean: "INTEGER",
        types.Float: "REAL",
        types.Numeric: "REAL",
        types.Text: "TEXT",
        types.UnicodeText: "TEXT",
        types.DateTime: "DATETIME",
        types.Date: "DATE",
        types.Time: "TIME",
        types.LargeBinary: "BLOB",
        types.JSON: "TEXT",
        types.PickleType: "BLOB",
    }

    # Special case: String/Unicode need length from the column type
    if isinstance(col.type, (types.String, types.Unicode)):
        return f"VARCHAR({col.type.length or 255})"

    for type_cls, sqlite_type in type_map.items():
        if isinstance(col.type, type_cls):
            return sqlite_type

    return "TEXT"


def get_session_factory():
    """Return a session factory bound to the current engine."""
    from sqlalchemy.orm import sessionmaker

    if _engine is None:
        raise RuntimeError("Database not initialized. Call init_db() first.")
    return sessionmaker(bind=_engine)
