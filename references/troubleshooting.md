# 无法读取文件的处理机制

当遇到无法读取的文件时，**不允许直接跳过或标注"不可读"就放弃**，必须按以下流程处理。

## 5.1 诊断无法读取的原因

分析该文件无法读取的具体原因，常见原因包括：

### 文件格式分类与诊断

**办公文档类：**
- **.docx/.xlsx/.pptx (现代 Office 格式)**
  - 特征：ZIP 压缩的 XML 格式
  - 诊断：需要 python-docx、openpyxl、python-pptx 库
  - 尝试：使用对应库直接读取

- **.doc/.xls/.ppt (旧版 Office 格式)**
  - 特征：二进制 OLE 格式
  - 诊断：需要反编译工具或转换工具
  - 尝试：使用 LibreOffice 转换或使用 antiword、catdoc 等工具

- **.pdf (PDF 文档)**
  - 特征：可能是文本 PDF 或扫描件 PDF
  - 诊断：使用 PyPDF2 尝试读取文本，失败则可能是扫描件
  - 尝试：先试文本提取，失败则 OCR

**网页与标记类：**
- **.html/.htm (网页文件)**
  - 特征：HTML 标记语言
  - 诊断：可用 BeautifulSoup 或正则表达式提取文本
  - 尝试：提取正文内容，去除标签

- **.md (Markdown 文件)**
  - 特征：纯文本带标记语法
  - 诊断：可直接读取，或转换为 HTML 后处理
  - 尝试：直接读取或渲染后提取

- **.css/.js/.json/.xml/.svg (文本格式)**
  - 特征：纯文本或结构化文本
  - 诊断：可直接读取，JSON/XML 可解析
  - 尝试：直接读取或解析结构

**数据与代码类：**
- **.csv/.tsv (表格数据)**
  - 特征：逗号/制表符分隔值
  - 诊断：可用 pandas 或 csv 模块读取
  - 尝试：直接解析，注意编码

- **.py/.java/.js/.go/.cpp 等 (代码文件)**
  - 特征：源代码文本
  - 诊断：可直接读取，提取注释和文档字符串
  - 尝试：直接读取或解析 AST

- **.sql (数据库脚本)**
  - 特征：SQL 语句文本
  - 诊断：可直接读取，提取表结构和注释
  - 尝试：直接读取并分析

**数据库与特殊格式：**
- **.db/.sqlite/.sqlite3 (SQLite 数据库)**
  - 特征：二进制数据库文件
  - 诊断：需要 SQLite3 库连接读取
  - 尝试：连接数据库，导出表结构和示例数据

- **.eml/.msg (邮件文件)**
  - 特征：邮件格式，可能包含附件
  - 诊断：需要 email 库或专用解析器
  - 尝试：解析邮件头、正文、附件列表

- **.log (日志文件)**
  - 特征：时间戳文本记录
  - 诊断：可直接读取，提取关键信息
  - 尝试：读取最后 N 行或按时间过滤

**压缩与容器类：**
- **.zip/.rar/.7z/.tar/.gz (压缩文件)**
  - 特征：包含多个文件的压缩包
  - 诊断：需要解压工具，可能需要遍历内部文件
  - 尝试：解压到临时目录，递归处理内部文件

**图片与多媒体类：**
- **.jpg/.png/.gif/.bmp (图片文件)**
  - 特征：二进制图片格式
  - 诊断：需要 OCR 工具提取文字
  - 尝试：使用 pytesseract 进行 OCR 识别

- **.svg (矢量图)**
  - 特征：XML 格式的矢量图形
  - 诊断：可当作 XML 解析，提取文本元素
  - 尝试：解析 XML，提取 `<text>` 等元素

**其他原因：**
- **原因 A：二进制文件缺乏转换工具**
  - 特征：文件是扫描件 PDF、图片（.jpg/.png）、旧版 Office 二进制格式（.doc/.xls）
  - 诊断：检查是否有可用的 OCR 工具、PDF 解析库、图片文字识别工具

- **原因 B：缺少必要的 Python 库或依赖**
  - 特征：报错信息包含 "ModuleNotFoundError"、"ImportError"、"No module named"
  - 诊断：检查是否安装了 python-docx、openpyxl、PyPDF2、pypandoc 等文档解析库

- **原因 C：文件加密或受密码保护**
  - 特征：打开文件时提示输入密码，或报错 "File is encrypted"
  - 诊断：确认文件是否需要密码，或是否有权限问题

- **原因 D：文件损坏或格式异常**
  - 特征：文件无法打开，或打开后内容乱码
  - 诊断：尝试用不同工具打开，确认是文件本身损坏

- **原因 E：编码问题**
  - 特征：文本文件打开后乱码，或报错 "UnicodeDecodeError"
  - 诊断：检查文件编码（UTF-8、GBK、GB2312 等）

## 5.2 分层工具链自动尝试

每个文件按 **Level 1 → Level 6** 顺序尝试。当前层内遍历所有可用工具，全部失败才进入下一层。

### Level 1 — 专用解析库

按文件格式匹配最精确的 Python 解析库，缺失时自动 `pip install`。

| 格式 | 工具 1 | 工具 2 | 工具 3 | 自动安装命令 |
|------|--------|--------|--------|-------------|
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
| .svg | XML 解析提取 `<text>` | — | — | `pip install lxml` |
| .eml | email 库 | — | — | — |
| .msg | extract-msg | — | — | `pip install extract-msg` |
| .db/.sqlite | sqlite3 模块 | — | — | — |
| .zip/.rar/.7z | zipfile / rarfile / py7zr | — | — | `pip install rarfile py7zr` |
| .tar/.gz/.bz2 | tarfile 模块 | — | — | — |

### Level 2 — 通用转换器

跨格式文档转换工具，一次可处理多种格式。

| 工具 | 支持格式 | 安装命令 |
|------|---------|---------|
| Docling (IBM) | PDF, DOCX, PPTX, XLSX, HTML, 图片 | `pip install docling` |
| pandoc | DOCX, HTML, LaTeX, Markdown, EPUB, 等 | `pip install pandoc` 或 `apt install pandoc` |
| MarkItDown (微软) | DOCX, XLSX, PPTX, PDF, HTML, 图片 | `pip install markitdown` |
| textract | DOC, DOCX, PDF, PPTX, XLSX, 图片 | `pip install textract` |
| python-pptx→txt | PPTX 文本提取 | `pip install python-pptx` |

### Level 3 — CLI 工具集

系统级命令行工具。**不自动安装**（需 sudo），不存在时直接跳过。

| 工具 | 适用格式 | 系统安装命令（需 sudo） |
|------|---------|----------------------|
| `libreoffice --cat` | doc/docx/xls/xlsx/ppt/pptx/odt/ods/odp | `apt install libreoffice` |
| `antiword` | .doc（旧版 Word） | `apt install antiword` |
| `catdoc` | .doc（旧版 Word） | `apt install catdoc` |
| `docx2txt` | .docx | `apt install docx2txt` |
| `pdftotext` | .pdf | `apt install poppler-utils` |
| `lynx -dump` | .html | `apt install lynx` |
| `pandoc`（CLI） | 多种格式 | `apt install pandoc` |

### Level 4 — OCR / 兜底提取

图片文字识别和二进制中提取可读文本。

| 工具 | 适用场景 | 安装命令 |
|------|---------|---------|
| Tesseract + pytesseract | 扫描件 PDF、图片文字 | `pip install pytesseract` + `apt install tesseract-ocr` |
| EasyOCR | 图片文字（多语言） | `pip install easyocr` |
| `strings` 命令 | 二进制中提取可读文本 | 系统内置 |
| chardet 编码探测 | 编码异常的多编码尝试 | `pip install chardet` |

**编码探测流程**：chardet 检测编码 → 按推荐编码读取 → UTF-8 → GBK → Latin-1 依次回退。

### Level 5 — 手动接管

当 Level 1-4 全部失败后，进入手动接管模式（详见 5.4 节）。

### Level 6 — 兜底处理

记录文件元数据，基于文件名推断业务含义（详见 5.5 节）。

> **⚠️ 安全提醒**：使用"在线转换工具"或"在线 OCR API"等第三方服务可能将内部文档内容上传至外部服务器，存在数据泄露风险。优先使用本地工具（如 LibreOffice、Tesseract OCR），确认用户允许后再使用在线服务，并明确告知用户数据将离开本地环境。

## 5.3 层间跳转逻辑

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
- **Python 包**：`pip install <package> --quiet` 自动安装，安装后立即重试该工具
- **CLI 系统工具**：不安装（需 sudo 权限），不存在时直接跳过
- **安装失败**：不中断流程，跳过该工具继续下一个
- **单工具超时**：每个工具安装 + 解析总时间不超过 30 秒

**文件级独立性**：A 文件可能到 Level 4 才成功，B 文件可能在 Level 1 就成功，互不影响。

## 5.4 手动接管机制（Level 5）

当 Level 1-4 全部尝试失败后，触发手动接管流程：

### 步骤 1：通知用户
- 向用户报告："文件 [文件名] 已自动尝试 Level 1-4（专用库→通用转换器→CLI工具→OCR/兜底）均未能读取。现在进入手动接管模式。"
- 说明文件的重要性："该文件位于 [路径]，文件名暗示其可能涉及 [业务领域]，对后续分析可能有重要影响。"

### 步骤 2：提供手动接管选项
向用户提供以下 3 种手动接管方式（用户可任选一种或多种）：

**选项 A：用户直接粘贴文件内容**
- 提示用户："请手动打开文件 [文件名]，复制其全部内容，粘贴到对话中。"
- 用户粘贴后，将粘贴的内容作为该文件的内容进行记录和分析
- 标注来源："内容来源：用户手动粘贴"

**选项 B：用户粘贴文件内容摘要**
- 提示用户："如果文件内容过长，请手动打开文件 [文件名]，提取核心内容（如关键条款、主要流程、重要数据），粘贴到对话中。"
- 用户粘贴摘要后，将摘要作为该文件的核心内容记录
- 标注来源："内容来源：用户手动粘贴摘要"

**选项 C：用户提供文件描述**
- 提示用户："如果您无法打开该文件，请根据文件名和您的了解，描述该文件的主要内容（如：这是什么制度/流程/表格，涉及哪些部门/岗位，核心规则是什么）。"
- 用户描述后，将描述作为该文件的推断内容记录
- 标注来源："内容来源：用户基于了解的描述"

### 步骤 3：等待用户响应
- 等待用户选择上述选项并提供内容
- 如果用户提供了内容，记录并标记为"手动接管成功"
- **如果用户表示无法提供任何内容，或长时间未响应（超过 5 分钟），则进入步骤 4**

### 步骤 4：最终兜底处理
- 向用户报告："文件 [文件名] 经过 Level 1-4 自动尝试和手动接管均未能获取内容。现在进行兜底处理。"
- 记录该文件的元数据：路径、大小、修改时间、文件名、文件扩展名
- 基于文件名和所在目录，推断该文件的业务含义（如：文件名"采购申请表.xlsx"→推断为采购流程中的申请环节）
- 标注："内容未能读取，已记录元数据和推断信息用于关联分析"
- **强制进入下一个文件，不可停留在当前文件**

## 5.5 完成确认

- 每个无法读取的文件都经过：Level 1-4 自动尝试 → Level 5 手动接管（可选）→ Level 6 兜底处理
- 向用户报告："已完成 X/Y 个文件的读取，其中："
  - "Z 个文件直接读取成功"
  - "W 个文件通过自动解决方案成功读取"
  - "V 个文件通过手动接管成功读取"
  - "U 个文件记录了元数据和推断信息"
- 确认是否还有未处理的文件
- **只有在所有文件都经过处理（成功读取、手动接管或记录元数据）后，才能进入 Phase 2**
