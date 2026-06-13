# PromptBlocks

> Desktop prompt-engineering IDE — compose, test, optimize, and export LLM prompts with a visual block-based workflow.

PromptBlocks is a **PySide6 / QML** desktop application that brings systematic prompt engineering
to your local machine.  It lets you assemble prompts from modular *blocks*, wire them together,
test them against multiple LLMs, optimize them iteratively, and export to `.promptx` (a portable
JSON-based exchange format).

---

## Features

### Modular Prompt Editor
- **9 block types**: Identity & Role, Instruction, Example, Format Constraint, Reasoning,
  Validation, Data Management, Flow Control, Pre/Post Process
- Drag-and-drop canvas to re-order and arrange blocks
- AI-assisted content generation for each block

### Prompt Testing Suite
- **Quick Test** — run a single prompt and get five-dimension quality scores
- **Batch Test** — compare multiple variants side-by-side with statistical analysis
- **Red Team** — automated adversarial testing (prompt injection, jailbreak, etc.)
- CSV import/export for bulk test cases

### Iterative Optimization
- **Single-turn optimizer** — refine raw user input automatically
- **Three-step optimizer** — analyze → optimize → verify loop with score comparison
- Version management with snapshots and rollback

### Knowledge & Variable Management
- Reusable variables with scoping (global / template / block)
- Knowledge base entries with tags and source tracking
- Tool definitions with schema and endpoint configuration

### Export & Interchange
- `.promptx` — portable JSON-based prompt exchange format
- Markdown, JSON, CSV, TXT exports for documentation

### Desktop-first Experience
- Fluent Design with acrylic/glass aesthetic
- Phosphor icon system (PUA-coded, consistent across themes)
- Frameless window with native Windows DWM shadow
- Hi-DPI support at all scaling levels

---

## Project Structure

```
promptblocks/
├── src/
│   └── promptblocks/           # Main Python package
│       ├── app.py              # QApplication + QML engine bootstrap
│       ├── config.py           # LLM config, QSettings-based persistence
│       ├── json_utils.py       # LLM JSON output repair & safe parsing
│       ├── main.py             # CLI entry point
│       ├── db/                 # SQLAlchemy ORM + CRUD + Alembic migrations
│       │   ├── models.py       # ORM models (Project, Block, Variable, ...)
│       │   ├── crud.py         # Typed CRUD helpers
│       │   ├── engine.py       # Engine factory + auto-migration trigger
│       │   ├── session.py      # Context-managed DB sessions
│       │   └── base.py         # Declarative base
│       ├── models/             # QAbstractListModel implementations
│       │   ├── module_card_model.py
│       │   ├── variable_model.py
│       │   ├── knowledge_model.py
│       │   ├── tool_model.py
│       │   └── test_result_model.py
│       ├── viewmodels/         # QObject-based ViewModel layer
│       │   ├── editor_viewmodel.py
│       │   ├── test_viewmodel.py
│       │   ├── optimizer_viewmodel.py
│       │   ├── single_turn_viewmodel.py
│       │   ├── project_viewmodel.py
│       │   ├── block_viewmodel.py
│       │   ├── version_viewmodel.py
│       │   ├── export_viewmodel.py
│       │   ├── import_viewmodel.py
│       │   └── ...
│       ├── compilers/          # Prompt compilation & LLM client
│       │   ├── llm_client.py   # LiteLLM wrapper with retry + threading lock
│       │   ├── cache.py        # In-memory LRU compile cache
│       │   └── ...
│       ├── synthesis/          # IR builder & prompt synthesizer
│       │   ├── ir.py           # IRBlock, IRGraph, topological sort
│       │   └── synthesizer.py  # PromptSynthesizer
│       ├── testing/            # Test runner & validators
│       │   ├── runner.py       # Thread-based test execution
│       │   └── validator.py    # Schema validation for test results
│       ├── processors/         # Pipeline processing engine
│       ├── highlighters/       # Syntax highlighting
│       ├── qmlhelpers/         # QML-facing Python helpers (syntax checker, etc.)
│       ├── undo/               # QUndoStack-based undo management
│       ├── workers/            # Background LLM workers
│       ├── qml/                # QML UI layer
│       │   ├── main.qml        # Root window
│       │   ├── Theme.qml       # Fluent Design theme singleton
│       │   ├── Icons.qml       # Icon glyph registry
│       │   ├── SetupWizard.qml # First-run LLM configuration
│       │   ├── qmldir          # QML module definition
│       │   ├── components/     # 30+ reusable UI components
│       │   └── views/          # View-level QML (MainView, TestPanel, ...)
│       ├── assets/
│       │   └── fonts/          # Phosphor icon fonts (Regular, Bold, Fill)
│       └── resources/
│           └── icons/          # Application icon (.ico)
├── alembic/                    # Database migration scripts
│   ├── env.py
│   ├── script.py.mako
│   └── versions/
│       └── de6b56f35aca_redesign_v2.py
├── scripts/                    # Build & maintenance scripts
│   ├── build.py
│   ├── build_windows.py
│   ├── diagnose_startup.py
│   └── verify_build.py
├── installer/                  # Windows NSIS installer config
│   └── promptblocks_installer.nsi
├── logo-design/                # Brand assets
│   ├── PB-logo.svg
│   └── PB字母拼图logo设计.png
├── tests/                      # Pytest test suite
│   ├── conftest.py
│   ├── test_compilers.py
│   ├── test_synthesis.py
│   └── test_*_crud.py
├── alembic.ini                 # Alembic configuration
├── launch.py                   # Direct launch script (bypasses package entry point)
├── pyproject.toml              # Project metadata & tool config
└── README.md
```

---

## Prerequisites

- **Python ≥ 3.11**
- **pip** or a compatible package manager
- **Windows 10/11** (primary target; macOS/Linux may work with caveats)

---

## Installation

### 1. Clone and set up a virtual environment

```bash
git clone <repo-url> promptblocks
cd promptblocks
python -m venv .venv
.venv\Scripts\activate   # Windows
# source .venv/bin/activate  # macOS/Linux
```

### 2. Install dependencies

```bash
pip install -e ".[dev]"
```

Core dependencies:
- `pyside6` — Qt for Python (QML + Widgets)
- `sqlalchemy` + `alembic` — ORM and schema migrations
- `litellm` — Unified LLM API client (supports 100+ providers)
- `pydantic` — Data validation

Dev dependencies: `pytest`, `ruff`, `mypy`, `pyinstaller`

### 3. Launch the application

```bash
# Via package entry point (after pip install -e .)
promptblocks

# Or directly (handles Chinese path encoding issues)
python launch.py
```

> **Note:** On first launch, the Setup Wizard will guide you through configuring
> your LLM provider (API key, base URL, model name).  Test-specific API keys
> can be configured separately in the Model Configuration dialog.

---

## Usage

### Quick Start

1. **Configure LLM** — Set your API key and model in the Setup Wizard (auto-opens on first run).
2. **Create a prompt** — Click module type buttons in the left panel to add blocks.
3. **Edit content** — Type or use AI generation for each block.
4. **Test** — Switch to the Test panel, run a quick test, see scores.
5. **Optimize** — Use the three-step optimizer for iterative improvement.
6. **Export** — Save as `.promptx`, Markdown, or JSON.

### Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `Ctrl+S` | Save version snapshot |
| `Ctrl+Z` | Undo |
| `Ctrl+Shift+Z` | Redo |

---

## Development

### Code Quality

```bash
# Lint
ruff check src/

# Type check
mypy src/

# Run tests
pytest tests/ -v
```

### Coding Standards

- **Python**: PEP 8 via `ruff` (line length 100, target Python 3.11)
- **QML**: CamelCase for component names, consistent signal/slot naming
- **Naming**: Python methods use `snake_case`; QML `@Slot`-exposed methods use `camelCase` (with `noqa: N802` suppression)
- **Imports**: `from __future__ import annotations` in all modules for lazy annotation evaluation
- **Thread safety**: `LLMClient` operations are protected by `threading.Lock`; all long-running LLM calls run on `QThread` workers

### Architecture

```
QML View (main.qml + components/)
    ↕ signals / properties
ViewModel Layer (viewmodels/*.py)
    ↕ data binding
Model Layer (models/*.py — QAbstractListModel)
    ↕ CRUD
Database Layer (db/ — SQLAlchemy ORM)
```

The application follows **MVVM** (Model-View-ViewModel):
- **Model**: `QAbstractListModel` subclasses exposing data to QML
- **ViewModel**: `QObject` subclasses with `@Property` and `@Signal`/`@Slot`
- **View**: QML components consuming `contextProperty`-exposed objects

---

## Building

### Windows Installer

```bash
python scripts/build_windows.py
```

This produces a standalone `.exe` via PyInstaller, then wraps it in an NSIS installer.

### Manual PyInstaller Build

```bash
pyinstaller PromptBlocks.spec
```

---

## License

This project is proprietary software. All rights reserved.

---

## Contributing

Internal contributions are welcome.  Please:

1. Discuss the change via issue or discussion first
2. Follow the coding standards above
3. Add tests for new functionality
4. Run `ruff check` and `pytest` before submitting
5. Use Conventional Commits for commit messages

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| GBK encoding error on launch | Use `python launch.py` instead of `promptblocks` entry point |
| Font icons not rendering | Ensure `src/promptblocks/assets/fonts/Phosphor-*.ttf` exist |
| LLM call hangs | Check API key and network; litellm timeout is 60s with 3 retries |
| QML changes not reflected | Delete `%LOCALAPPDATA%\PromptBlocks\qmlcache\` or set `QML_DISABLE_DISK_CACHE=1` |
