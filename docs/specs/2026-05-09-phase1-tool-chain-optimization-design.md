# biz-workflow-generator Phase 1 工具链优化设计

## 问题陈述

biz-workflow-generator 的 Phase 1（文件夹扫描与文档采集）在读取文件环节，遇到无法读取的文件时，没有自动尝试足够的工具就进入了手动粘贴环节。具体表现为：

- **固定 3 次尝试限制**过于严格，每个文件最多只试 3 种方案
- **方案不够丰富**，缺少现代文档解析工具（Docling、MarkItDown、pandoc 等）
- **每层级内只试 1 个工具**，而不是尝试所有可用选项后再放弃
- **缺少自动依赖安装**机制，工具缺失就直接跳过

## 设计方案

### 架构：六层工具链流水线

将文件读取从"固定 3 次尝试"改为按层级递进的工具链流水线：

```
Level 1: 专用解析库     Python 原生库，最精确
Level 2: 通用转换器     跨格式文档转换工具
Level 3: CLI 工具集      系统级命令行工具
Level 4: OCR / 兜底     图片文字识别 + 二进制提取
Level 5: 手动接管        A/B/C 三选项用户交互
Level 6: 元数据兜底      文件名推断 + 元数据记录
```

**核心原则**：每层内遍历所有可用工具，全部失败才进入下一层。Python 工具缺失时自动 `pip install`。

### Level 1 — 专用解析库

| 格式 | 工具 1 | 工具 2 | 工具 3 |
|------|--------|--------|--------|
| .docx | python-docx | docx2txt | — |
| .xlsx | openpyxl | pandas (read_excel) | xlrd |
| .pptx | python-pptx | — | — |
| .pdf(文本) | PyMuPDF (fitz) | pdfplumber | PyPDF2 |
| .pdf(扫描) | → 转入 Level 4 OCR | — | — |
| .html | BeautifulSoup + lxml | html.parser | — |
| .csv | csv 模块 | pandas | — |
| .json | json 模块 | — | — |
| .xml | xml.etree.ElementTree | lxml | — |
| .md | 直接读取 | markdown 库 | — |
| .txt/.log | 直接读取（含编码探测） | — | — |
| .eml | email 库 | — | — |
| .msg | extract-msg | — | — |
| .db/.sqlite | sqlite3 | — | — |

**自动安装命令**：
```bash
pip install python-docx openpyxl python-pptx PyMuPDF pdfplumber beautifulsoup4 lxml pandas xlrd extract-msg chardet
```

### Level 2 — 通用转换器

| 工具 | 支持格式 | 安装 |
|------|---------|------|
| Docling (IBM) | PDF, DOCX, PPTX, XLSX, HTML, 图片 | `pip install docling` |
| pandoc | DOCX, HTML, LaTeX, Markdown, EPUB, 等 | `pip install pandoc` |
| MarkItDown (微软) | DOCX, XLSX, PPTX, PDF, HTML, 图片 | `pip install markitdown` |
| textract | DOC, DOCX, PDF, PPTX, XLSX, 图片, 等 | `pip install textract` |
| python-pptx → txt | PPTX 文本提取 | `pip install python-pptx` |

**执行逻辑**：按优先级依次尝试，一个成功即停止。所有工具都失败才进入 Level 3。

### Level 3 — CLI 工具集

| 工具 | 适用格式 | 系统安装命令 |
|------|---------|-------------|
| `libreoffice --cat` | doc/docx/xls/xlsx/ppt/pptx/odt/ods/odp | `apt install libreoffice` |
| `antiword` | .doc（旧版 Word） | `apt install antiword` |
| `catdoc` | .doc（旧版 Word） | `apt install catdoc` |
| `docx2txt` | .docx | `apt install docx2txt` |
| `pdftotext` | .pdf | `apt install poppler-utils` |
| `lynx -dump` | .html | `apt install lynx` |
| `pandoc` (CLI) | 多种格式 | `apt install pandoc` |

**注意**：CLI 工具不自装（避免 sudo 权限问题），不存在则跳过。

### Level 4 — OCR / 兜底提取

| 工具 | 适用场景 | 安装 |
|------|---------|------|
| Tesseract + pytesseract | 扫描件 PDF、图片文字 | `pip install pytesseract` + `apt install tesseract-ocr` |
| EasyOCR | 图片文字（多语言） | `pip install easyocr` |
| `strings` 命令 | 二进制中提取可读文本 | 系统内置 |
| `chardet` 编码检测 | 编码异常时的多编码尝试 | `pip install chardet` |

**编码探测流程**：chardet 检测编码 → 按推荐编码读取 → 按编码优先级回退（UTF-8 → GBK → Latin-1）。

### Level 5 — 手动接管

3 个选项（不改变现有设计）：
- **A**：用户粘贴文件全部内容
- **B**：用户粘贴文件内容摘要
- **C**：用户提供文件内容描述

### Level 6 — 元数据兜底

记录路径、大小、修改时间，基于文件名推断业务含义。

### 自动依赖安装机制

```
遇到 Python 工具缺失 (ImportError/ModuleNotFoundError)
  → pip install <package> --quiet
  → 安装成功 → 重新尝试解析
  → 安装失败 → 跳过该工具，进入下一个
  ⚠ 不安装 CLI 系统工具（需要 sudo）
  ⚠ 安装失败不中断整体流程
```

### 层间跳转逻辑

```
每个文件独立处理：

1. 按 Level 1→2→3→4→5→6 顺序执行
2. 当前层内：按优先级遍历所有工具
   - 工具可用 → 尝试解析
   - 解析成功 → 标记"已读取"，停止该文件
   - 解析失败 → 下一个工具
   - 工具缺失（可自装）→ pip install → 重试
   - 工具缺失（不可自装）→ 跳过
3. 当前层所有工具都失败 → 进入下一层
4. Level 6 兜底后强制完成，进入下一个文件
```

### 修改文件清单

| 文件 | 改动 |
|------|------|
| `SKILL.md` | Phase 1 的自动尝试描述从"3 次尝试"改为"6 层工具链" |
| `references/troubleshooting.md` | 核心重写：分层工具链表格 + 执行逻辑 + 自动安装 |
| `README.md` | 更新"四重保障"描述为"六层工具链" |

## 不变的部分

- Phase 2-6 的逻辑不变
- 手动接管（Level 5）的 A/B/C 三选项不变
- 最终兜底（Level 6）的逻辑不变
- SKILL.md 的 YAML frontmatter、description 等不变
- 文件总数、扫描报告格式不变

## 边界与约束

- **每文件尝试次数**：不再设固定上限，但层级递进保证不会死循环（最多 6 层）
- **自动安装范围**：仅限于 Python 包（pip install），不涉及系统级安装
- **网络搜索**：Level 2 中的某些工具（如 Docling 首次使用需下载模型）可能需联网，标注提示
- **性能**：对于大量文件（500+），Level 4 OCR 较慢，建议在 Level 1-3 优先成功
