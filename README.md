﻿# PromptBlocks

> 桌面级提示词工程 IDE —— 以可视化模块化工作流编排、测试、优化并导出 LLM 提示词。

PromptBlocks 是一款基于 **PySide6 / QML** 的桌面应用，将系统化提示词工程带入本地环境。
你可以将提示词组装为模块化的*块（Block）*，将它们连接在一起，针对多个大模型进行测试，
迭代优化，并导出为 `.promptx`（一种可移植的 JSON 交换格式）。

---

## 功能特性

### 模块化提示词编辑器
- **9 种模块类型**：身份角色、指令说明、示例参考、格式约束、推理链、
  验证检查、数据管理、流程控制、前后处理
- 拖拽式画布，自由排列和组合模块
- 每个模块支持 AI 辅助生成内容

### 提示词测试套件
- **快速测试** — 运行单条提示词，获取五维度质量评分
- **批量测试** — 多版本并排对比，附带统计分析
- **红队测试** — 自动化对抗性测试（提示词注入、越狱等）
- 支持 CSV 导入/导出批量测试用例

### 迭代优化
- **单轮优化器** — 自动精炼原始用户输入
- **三步优化器** — 分析 → 优化 → 验证循环，附带评分对比
- 版本管理，支持快照与回滚

### 知识与变量管理
- 可复用变量，支持作用域（全局 / 模板 / 模块）
- 知识库条目，支持标签和来源追溯
- 工具定义，支持 Schema 和端点配置

### 导出与交换
- `.promptx` — 可移植的 JSON 提示词交换格式
- 支持 Markdown、JSON、CSV、TXT 格式导出

### 桌面原生体验
- Fluent Design 亚克力/毛玻璃美学风格
- Phosphor 图标系统（PUA 编码，跨主题风格统一）
- 无边框窗口，原生 Windows DWM 阴影
- 支持所有缩放级别的 Hi-DPI 适配

---

## 项目结构

```
promptblocks/
├── src/
│   └── promptblocks/           # 主 Python 包
│       ├── app.py              # QApplication + QML 引擎启动
│       ├── config.py           # LLM 配置，基于 QSettings 持久化
│       ├── json_utils.py       # LLM JSON 输出修复与安全解析
│       ├── main.py             # CLI 入口
│       ├── db/                 # SQLAlchemy ORM + CRUD + Alembic 迁移
│       │   ├── models.py       # ORM 模型（Project, Block, Variable 等）
│       │   ├── crud.py         # 类型化 CRUD 辅助
│       │   ├── engine.py       # 引擎工厂 + 自动迁移触发
│       │   ├── session.py      # 上下文管理器数据库会话
│       │   └── base.py         # 声明式基类
│       ├── models/             # QAbstractListModel 实现
│       │   ├── module_card_model.py
│       │   ├── variable_model.py
│       │   ├── knowledge_model.py
│       │   ├── tool_model.py
│       │   └── test_result_model.py
│       ├── viewmodels/         # 基于 QObject 的 ViewModel 层
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
│       ├── compilers/          # 提示词编译与 LLM 客户端
│       │   ├── llm_client.py   # LiteLLM 封装，含重试 + 线程锁
│       │   ├── cache.py        # 内存 LRU 编译缓存
│       │   └── ...
│       ├── synthesis/          # IR 构建器与提示词合成器
│       │   ├── ir.py           # IRBlock, IRGraph, 拓扑排序
│       │   └── synthesizer.py  # PromptSynthesizer
│       ├── testing/            # 测试运行器与校验器
│       │   ├── runner.py       # 基于线程的测试执行
│       │   └── validator.py    # 测试结果 Schema 校验
│       ├── processors/         # 流水线处理引擎
│       ├── highlighters/       # 语法高亮
│       ├── qmlhelpers/         # QML 端 Python 辅助（语法检查器等）
│       ├── undo/               # 基于 QUndoStack 的撤销管理
│       ├── workers/            # 后台 LLM 工作线程
│       ├── qml/                # QML UI 层
│       │   ├── main.qml        # 根窗口
│       │   ├── Theme.qml       # Fluent Design 主题单例
│       │   ├── Icons.qml       # 图标字形注册表
│       │   ├── SetupWizard.qml # 首次运行 LLM 配置向导
│       │   ├── qmldir          # QML 模块定义
│       │   ├── components/     # 30+ 可复用 UI 组件
│       │   └── views/          # 视图级 QML（MainView, TestPanel 等）
│       ├── assets/
│       │   └── fonts/          # Phosphor 图标字体（Regular, Bold, Fill）
│       └── resources/
│           └── icons/          # 应用图标 (.ico)
├── alembic/                    # 数据库迁移脚本
│   ├── env.py
│   ├── script.py.mako
│   └── versions/
│       └── de6b56f35aca_redesign_v2.py
├── scripts/                    # 构建与维护脚本
│   ├── build.py
│   ├── build_windows.py
│   ├── diagnose_startup.py
│   └── verify_build.py
├── installer/                  # Windows NSIS 安装程序配置
│   └── promptblocks_installer.nsi
├── logo-design/                # 品牌素材
│   ├── PB-logo.svg
│   └── PB字母拼图logo设计.png
├── tests/                      # Pytest 测试套件
│   ├── conftest.py
│   ├── test_compilers.py
│   ├── test_synthesis.py
│   └── test_*_crud.py
├── alembic.ini                 # Alembic 配置
├── launch.py                   # 直接启动脚本（绕过包入口点）
├── pyproject.toml              # 项目元数据与工具配置
└── README.md
```

---

## 环境要求

- **Python ≥ 3.11**
- **pip** 或兼容的包管理器
- **Windows 10/11**（主要目标平台；macOS/Linux 可能可用但未充分测试）

---

## 安装

### 1. 克隆并创建虚拟环境

```bash
git clone https://github.com/liangzhi879-a11y/Prompt-Blocks
cd Prompt-Blocks
python -m venv .venv
.venv\Scripts\activate   # Windows
# source .venv/bin/activate  # macOS/Linux
```

### 2. 安装依赖

```bash
pip install -e ".[dev]"
```

核心依赖：
- `pyside6` — Qt for Python（QML + Widgets）
- `sqlalchemy` + `alembic` — ORM 与数据库迁移
- `litellm` — 统一 LLM API 客户端（支持 100+ 厂商）
- `pydantic` — 数据校验

开发依赖：`pytest`、`ruff`、`mypy`、`pyinstaller`

### 3. 启动应用

```bash
# 通过包入口点（pip install -e . 后）
promptblocks

# 或直接启动（可处理中文路径编码问题）
python launch.py
```

> **提示：** 首次启动时，设置向导将引导你配置 LLM 厂商（API 密钥、Base URL、模型名称）。
> 测试专用的 API 密钥可在模型配置对话框中单独设置。

---

## 使用指南

### 快速上手

1. **配置 LLM** — 在设置向导中设置 API 密钥和模型（首次运行自动打开）。
2. **创建提示词** — 点击左侧面板中的模块类型按钮来添加块。
3. **编辑内容** — 手动输入或使用 AI 生成为每个块生成内容。
4. **测试** — 切换到测试面板，运行快速测试，查看评分。
5. **优化** — 使用三步优化器进行迭代改进。
6. **导出** — 保存为 `.promptx`、Markdown 或 JSON。

### 键盘快捷键

| 按键 | 操作 |
|------|------|
| `Ctrl+S` | 保存版本快照 |
| `Ctrl+Z` | 撤销 |
| `Ctrl+Shift+Z` | 重做 |

---

## 开发指南

### 代码质量

```bash
# 代码检查
ruff check src/

# 类型检查
mypy src/

# 运行测试
pytest tests/ -v
```

### 编码规范

- **Python**：遵循 PEP 8，通过 `ruff` 强制（行宽 100，目标 Python 3.11）
- **QML**：组件名使用大驼峰，信号/槽命名保持一致
- **命名约定**：Python 方法使用 `snake_case`；暴露给 QML 的 `@Slot` 方法使用 `camelCase`（带 `noqa: N802` 抑制）
- **导入规范**：所有模块使用 `from __future__ import annotations` 实现惰性注解求值
- **线程安全**：`LLMClient` 操作受 `threading.Lock` 保护；所有长耗时 LLM 调用运行在 `QThread` 工作线程上

### 架构设计

```
QML 视图层 (main.qml + components/)
    ↕ signals / properties
ViewModel 层 (viewmodels/*.py)
    ↕ 数据绑定
Model 层 (models/*.py — QAbstractListModel)
    ↕ CRUD
数据库层 (db/ — SQLAlchemy ORM)
```

应用遵循 **MVVM**（Model-View-ViewModel）架构：
- **Model**：`QAbstractListModel` 子类，向 QML 暴露数据
- **ViewModel**：`QObject` 子类，带有 `@Property` 和 `@Signal`/`@Slot`
- **View**：消费 `contextProperty` 暴露对象的 QML 组件

---

## 构建打包

### Windows 安装程序

```bash
python scripts/build_windows.py
```

此命令通过 PyInstaller 生成独立的 `.exe`，然后用 NSIS 打包为安装程序。

### 手动 PyInstaller 构建

```bash
pyinstaller PromptBlocks.spec
```

---

## 许可证

本项目采用 [MIT 许可证](LICENSE) 开源。

---

## 贡献指南

欢迎内部贡献。请遵循以下规则：

1. 先通过 Issue 或讨论沟通变更内容
2. 遵循上述编码规范
3. 为新功能添加测试
4. 提交前运行 `ruff check` 和 `pytest`
5. 使用 Conventional Commits 规范编写提交信息

---

## 常见问题

| 问题 | 解决方案 |
|------|----------|
| 启动时报 GBK 编码错误 | 使用 `python launch.py` 代替 `promptblocks` 入口点 |
| 字体图标不显示 | 确认 `src/promptblocks/assets/fonts/Phosphor-*.ttf` 文件存在 |
| LLM 调用卡住 | 检查 API 密钥和网络；litellm 超时 60s，最多 3 次重试 |
| QML 修改未生效 | 删除 `%LOCALAPPDATA%\PromptBlocks\qmlcache\` 或设置 `QML_DISABLE_DISK_CACHE=1` |
