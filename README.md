# Biz Workflow Generator Skill

## 业务分析与流程生成器

这是一个用于 OpenCode 的 Skill，能够扫描业务文档文件夹、理解业务逻辑、生成业务模板，并基于模板为新业务生成完整流程和**与原始业务文档格式完全一致的全套业务文件**。

适用于各类业务场景：
- 企业管理制度（人事、财务、行政、采购）
- 运营流程（销售、客服、供应链、质量管理）
- 产品规划（需求文档、上线流程、迭代管理）
- 营销策略（推广方案、活动计划、预算管理）
- 人力资源（招聘、培训、绩效考核、薪酬）
- 合规风控（审计流程、内控制度、合规检查）

## 目录结构

```
biz-workflow-generator/
├── SKILL.md                              # 核心技能定义（OpenCode 读取）
├── README.md                             # 本说明文件
├── references/
│   ├── business-analysis-template.md     # 业务理解模板格式规范
│   ├── workflow-design-template.md       # 业务流程设计模板格式规范
│   └── file-structure-template.md        # 业务文件生成模板（含格式匹配规则）
└── scripts/
    └── scan_project.sh                   # 文档扫描辅助脚本（可选）
```

## 部署方法

### 全局部署（推荐）

```bash
# macOS / Linux
mkdir -p ~/.config/opencode/skills/
cp -r biz-workflow-generator ~/.config/opencode/skills/

# Windows (PowerShell)
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.config\opencode\skills"
Copy-Item -Recurse -Force "biz-workflow-generator" "$env:USERPROFILE\.config\opencode\skills\"
```

### 项目级部署

```bash
cp -r biz-workflow-generator ./your-project/.opencode/skills/
```

## 使用方法

### 方式 1：直接描述需求（自动触发）
```
请分析我 ./公司制度 目录下的所有文档，
理解现有的采购管理制度体系，
然后帮我生成一套"固定资产管理"的完整制度和流程文件，
格式要和 ./公司制度 里的文档保持一致。
```

### 方式 2：显式调用 Skill
```
/skill biz-workflow-generator
```

### 方式 3：查看已加载 Skills
```
/skills
```

## 工作流程

| 阶段 | 名称 | 说明 |
|------|------|------|
| Phase 1 | 文件夹扫描与文档采集 | 读取指定文件夹的所有业务文档，**遇到无法读取的文件会触发六层工具链流水线（专用库→通用转换器→CLI工具→OCR→手动接管→兜底），每层遍历所有工具，全部失败才进入下一层** |
| Phase 2 | 业务理解与关联分析 | 提炼业务逻辑，梳理文档间关联 |
| Phase 3 | 生成业务理解模板 | 输出标准化的业务知识基座 |
| Phase 4 | 自定义业务需求采集 | 获取用户的新业务需求 |
| Phase 5 | 生成全新业务流程 | 基于模板设计新业务的完整流程 |
| Phase 6 | 补充流程所需业务文件 | 生成全套业务文件，**格式与目标文件夹中的文档完全一致** |

## 无法读取文件的处理机制（六层工具链）

本 Skill 在 Phase 1 中遇到无法读取的文件时，不会直接跳过，而是通过六层工具链流水线自动尝试，每层遍历所有可用工具，全部失败才进入下一层：

### Level 1：专用解析库
按格式匹配专用 Python 库（python-docx、openpyxl、PyMuPDF 等），**缺失时自动 pip install**

### Level 2：通用转换器
尝试跨格式工具（Docling、pandoc、MarkItDown），**缺失时自动 pip install**

### Level 3：CLI 工具集
尝试系统级工具（libreoffice --cat、antiword、pdftotext 等），不存在时跳过

### Level 4：OCR / 兜底
图片文字识别（Tesseract、EasyOCR）+ 二进制 strings 提取 + 多编码探测

### Level 5：手动接管
当 Level 1-4 全部失败后，进入手动接管模式，提供 3 种方式：
- **选项 A**：用户直接粘贴文件全部内容
- **选项 B**：用户粘贴文件内容摘要
- **选项 C**：用户提供文件内容描述

### Level 6：兜底处理
如果手动接管也失败或用户无响应，记录元数据并基于文件名推断业务含义，强制进入下一个文件

## 支持的文档格式自动匹配

Skill 会自动检测并继承目标文件夹中的以下特征：

| 检测项 | 说明 | 示例 |
|--------|------|------|
| 文档类型 | Word / Excel / PPT / Markdown / PDF / 文本 | .docx / .xlsx / .pptx / .md |
| 排版风格 | 正式公文 / 操作手册 / 通知公告 | 章节式 / 步骤式 / 表格式 |
| 语言风格 | 正式程度、口语化程度 | 公文用语 / 口语化说明 |
| 章节结构 | 标题层级、内容组织方式 | 第一章/第一条 / # 标题 |
| 编号方式 | 数字编号、中文编号、字母编号 | 1. / （一）/ A. |
| 术语体系 | 行业术语、内部简称 | KPI / OKR / ROI |
| 表格样式 | 表格字段、必填项标记、计算公式 | 下拉选项 / 自动求和 |
| 审批格式 | 审批栏、签字栏、日期栏 | 手写签名区 / 电子签章 |

## 注意事项

- 单次扫描文档数上限 500 个，超出时会询问是否分批处理，但每批必须全部读取完成
- 不会修改或删除原始文件夹的任何内容
- 生成文件前会确认输出目录，避免覆盖现有文件
- 对于无法读取的文件，经过六层工具链流水线（Level 1-6），每层遍历所有可用工具，全部失败才进入下一层，**不会死循环**
- 如果目标文件夹包含多种文档格式，优先使用占比最高的格式
