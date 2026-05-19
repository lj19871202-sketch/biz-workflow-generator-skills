# Phase 1 文件读取工具链优化 实施计划

> **For agentic workers:** 本计划分 3 个独立任务，建议依次执行。

**目标：** 将 biz-workflow-generator Phase 1 的文件读取从"固定 3 次尝试"改为"六层工具链流水线"

**涉及文件：**
- `references/troubleshooting.md` — 核心重写
- `SKILL.md` — Phase 1 部分更新
- `README.md` — 描述更新

---

### Task 1: 重写 references/troubleshooting.md

**文件：** `references/troubleshooting.md`

将当前"5.2 针对原因给出解决方案"的固定 3 方案表格替换为分层工具链表格，新增自动依赖安装机制和层间跳转逻辑。

- [ ] **Step 1: 将"5.2 针对原因给出解决方案"表格改为"分层工具链"**

保留 5.1（诊断原因）不变。将整个 5.2 节重写为：

**5.2 分层工具链自动尝试**：

每个文件按 Level 1 → Level 6 顺序尝试。当前层内遍历所有可用工具，全部失败才进入下一层。

**Level 1 — 专用解析库**

| 格式 | 工具 1 | 工具 2 | 工具 3 | 自动安装 |
|------|--------|--------|--------|---------|
| .docx | python-docx | docx2txt | — | `pip install python-docx docx2txt` |
| .xlsx | openpyxl | pandas read_excel | xlrd（旧版） | `pip install openpyxl pandas xlrd` |
| .pptx | python-pptx | — | — | `pip install python-pptx` |
| .pdf（文本） | PyMuPDF (fitz) | pdfplumber | PyPDF2 | `pip install PyMuPDF pdfplumber PyPDF2` |
| .pdf（扫描） | → 转入 Level 4 OCR | — | — | — |
| .html | BeautifulSoup + lxml | html.parser | — | `pip install beautifulsoup4 lxml` |
| .csv | csv 模块 | pandas | — | `pip install pandas` |
| .json | json 模块 | — | — | — |
| .xml | xml.etree.ElementTree | lxml | — | `pip install lxml` |
| .md | 直接读取 | markdown 库 | — | `pip install markdown` |
| .txt/.log | 直接读取 | chardet 编码探测 | — | `pip install chardet` |
| .eml | email 库 | — | — | — |
| .msg | extract-msg | — | — | `pip install extract-msg` |
| .db/.sqlite | sqlite3 模块 | — | — | — |

**Level 2 — 通用转换器**

| 工具 | 支持格式 | 安装命令 |
|------|---------|---------|
| Docling (IBM) | PDF, DOCX, PPTX, XLSX, HTML, 图片 | `pip install docling` |
| pandoc | DOCX, HTML, LaTeX, Markdown, EPUB | `pip install pandoc` 或 `apt install pandoc` |
| MarkItDown (微软) | DOCX, XLSX, PPTX, PDF, HTML, 图片 | `pip install markitdown` |
| textract | DOC, DOCX, PDF, PPTX, XLSX, 图片 | `pip install textract` |

**Level 3 — CLI 工具集**

| 工具 | 适用格式 | 系统安装命令（需 sudo） |
|------|---------|----------------------|
| `libreoffice --cat` | doc/docx/xls/xlsx/ppt/pptx/odt/ods/odp | `apt install libreoffice` |
| `antiword` | .doc（旧版 Word） | `apt install antiword` |
| `catdoc` | .doc（旧版 Word） | `apt install catdoc` |
| `docx2txt` | .docx | `apt install docx2txt` |
| `pdftotext` | .pdf | `apt install poppler-utils` |
| `lynx -dump` | .html | `apt install lynx` |

> **注意**：CLI 工具不自动安装（需 sudo），不存在时直接跳过。

**Level 4 — OCR / 兜底提取**

| 工具 | 适用场景 | 安装命令 |
|------|---------|---------|
| Tesseract + pytesseract | 扫描件 PDF、图片文字 | `pip install pytesseract` + `apt install tesseract-ocr` |
| EasyOCR | 图片文字（多语言） | `pip install easyocr` |
| `strings` 命令 | 二进制中提取可读文本 | 系统内置 |
| chardet 编码探测 | 编码异常的多编码尝试 | `pip install chardet` |

编码探测流程：chardet 检测编码 → 按推荐编码读取 → UTF-8 → GBK → Latin-1 依次回退。

**Level 5 — 手动接管**（不变）
选项 A：用户粘贴全文
选项 B：用户粘贴摘要
选项 C：用户描述内容

**Level 6 — 兜底处理**（不变）
记录元数据，基于文件名推断业务含义。

- [ ] **Step 2: 替换"5.3 自动尝试与计数"为"层间跳转逻辑"**

原有 5.3 的"最大尝试次数 3 次"需要替换为：

**5.3 层间跳转逻辑**

每个文件独立执行以下流程：

```
1. 从 Level 1 开始，按层级顺序执行
2. 当前层内：按表格顺序遍历所有工具
   a. 工具可用（已安装）→ 尝试解析
   b. 工具缺失但可自装（Python 包）→ pip install → 重试
   c. 工具缺失且不可自装（CLI 工具）→ 跳过
   d. 解析成功 → 标记"已读取(Level N:工具名)" → 完成
   e. 解析失败 → 下一个工具
3. 当前层所有工具都失败 → 进入下一层
4. Level 6 兜底后强制完成
```

**自动安装规则**：
- Python 包：`pip install <package> --quiet` 自动安装
- CLI 系统工具：不安装（跳过）
- 安装失败 → 跳过该工具
- 安装成功 → 立即重试该工具
- 安装和解析的总超时：30 秒/工具

**文件级独立**：A 文件可到 Level 4 才成功，B 文件可能在 Level 1 就成功，互不影响。

- [ ] **Step 3: 删除"5.4 手动接管机制"和"5.5 完成确认"中的冗余内容**

Level 5（手动接管）和 Level 6（兜底处理）的逻辑不变，但精简编号层级。把 5.4 改为 5.4，5.5 改为 5.5。

---

### Task 2: 更新 SKILL.md 的 Phase 1 描述

**文件：** `SKILL.md`

- [ ] **Step 1: 更新 Phase 1 的自动尝试描述**

定位 Phase 1 第 5 步中的"无法读取文件的处理"子节。将"最多尝试 3 次 → 手动接管 → 兜底处理"描述改为：

```
**无法读取文件的处理**（六层工具链自动流水线）：
1. **Level 1 — 专用解析库**：按格式匹配专用 Python 库（python-docx、openpyxl、PyMuPDF 等），缺失时自动 pip install
2. **Level 2 — 通用转换器**：尝试跨格式工具（Docling、pandoc、MarkItDown）
3. **Level 3 — CLI 工具集**：尝试系统级工具（libreoffice --cat、antiword、pdftotext 等）
4. **Level 4 — OCR / 兜底**：图片文字识别（Tesseract、EasyOCR）+ 二进制 strings 提取
5. **Level 5 — 手动接管**：用户粘贴/描述文件内容（A/B/C 三选项）
6. **Level 6 — 元数据兜底**：记录文件元数据，基于文件名推断业务含义

每层内遍历所有可用工具，全部失败才进入下一层。详见 `references/troubleshooting.md`。
```

- [ ] **Step 2: 同步更新 Phase 1 第 4 步中引用 troubleshooting.md 的描述**

确保"必须引用：加载 references/troubleshooting.md 查看完整的故障排除流程"这一提示仍然准确指向更新后的文档。

---

### Task 3: 更新 README.md

**文件：** `README.md`

- [ ] **Step 1: 更新"工作流程"表格**

Phase 1 的说明从：
```
Phase 1 | 文件夹扫描与文档采集 | 读取指定文件夹的所有业务文档，**遇到无法读取的文件会诊断原因→自动尝试（最多3次）→手动接管→兜底处理**
```
改为：
```
Phase 1 | 文件夹扫描与文档采集 | 读取指定文件夹的所有业务文档，**遇到无法读取的文件会触发六层工具链流水线（专用库→通用转换器→CLI工具→OCR→手动接管→兜底），每层遍历所有工具，全部失败才进入下一层**
```

- [ ] **Step 2: 更新"无法读取文件的处理机制"章节**

将"四重保障"改为"六层工具链"，标题和内容更新为新的分层描述。

---

### Task 4: 最终验证

- [ ] **Step 1: 内容一致性检查**

确认三个文件的描述一致：
- troubleshooting.md 定义完整的工具链和执行逻辑
- SKILL.md 正确引用 troubleshooting.md
- README.md 概要描述与实际情况一致

- [ ] **Step 2: 层级完整性检查**

确认所有 6 层均被覆盖，没有遗漏。

- [ ] **Step 3: 格式完整性检查**

确认 Markdown 表格格式正确、引用链接有效。
