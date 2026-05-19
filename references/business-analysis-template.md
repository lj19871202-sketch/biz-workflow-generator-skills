# 业务理解模板

> **填充指引**：使用 Phase 2 分析的业务理解成果来填充各要素。
> - **业务全景**：从目录索引、总览文档中提取业务体系名称和范围
> - **核心领域模型**：从制度文档中提取业务实体（如客户、订单、供应商）及其关系
> - **业务模块架构**：按文档所在目录和文档标题聚类，提炼各模块职责
> - **文档关联矩阵**：分析文档间的引用（A引B第X条）、配套使用、触发关系
> - **核心业务流程**：从流程文档中提取步骤、角色、产出物、时限
> - **业务规则与约束**：从制度文档中提取审批权限、金额门槛、时间限制
> - **可复用模式**：提炼通用的业务模式（如三级审批、供应商准入），标注适用条件

## 1. 业务全景
- **业务体系名称**：{business_system_name}
- **一句话描述**：{one_sentence_description}
- **详细说明**：{detailed_description}
- **适用范围**：{scope}（部门/岗位/场景）
- **核心价值**：{value_proposition}

## 2. 核心领域模型
```
[业务实体A] --关系--> [业务实体B]
例如：
[采购申请] --提交给--> [采购部门]
[采购部门] --审核后--> [供应商]
```

## 3. 业务模块架构
| 模块名 | 职责 | 关键文档 | 关联模块 |
|--------|------|----------|----------|
| {module} | {responsibility} | {documents} | {dependencies} |

## 4. 文档关联矩阵
```
{document_a} --引用--> {document_b}（引用条款：第X条）
{document_c} --配套--> {document_d}（配套使用场景）
{document_e} --触发--> {document_f}（触发条件）
```

## 5. 核心业务流程
### {process_name}
**适用场景**：{scenario}
**参与角色**：{roles}

1. {step_1}（产出：{output_1}）
2. {step_2}（产出：{output_2}）
3. {step_3}（产出：{output_3}）

## 6. 业务规则与约束
- **审批权限**：{approval_rules}
- **金额门槛**：{amount_thresholds}
- **时间限制**：{time_limits}
- **合规要求**：{compliance_requirements}

## 7. 可复用模式
- **{pattern_name}**：{description}
  - 适用场景：{applicable_scenario}
  - 关键要素：{key_elements}
