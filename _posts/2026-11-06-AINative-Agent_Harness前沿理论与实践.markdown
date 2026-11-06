---
layout: post
title: "AINative-Agent_Harness前沿理论与实践"
categories: AINative
tags: AINative
author: xueyp
description:
---

## 目录

- 调研假设与边界
- 第0章 执行摘要（含 L0~L7 技术栈分层表、成熟度分级表、核心判断）
- 第1章 概念辨析：Harness 的多重含义与严格定义（§1.3 概念矩阵／§1.5 边界案例）
- 第2章 前沿理论（§2.1 认知架构四传统／§2.2 能力归因／§2.3 Context Engineering／§2.4 信息论视角）
- 第3章 学术研究现状（§3.1 实证数据／§3.2 经典论文拆解／§3.3 长时程／§3.4 可复现性／§3.5 评测 Harness）
- 第4章 Harness 的架构与组成部件（§4.1 主循环 ~ §4.8 评测钩子）
- 第5章 Harness 的设计模式（12 模式＋过度设计清单）
- 第6章 长时程 Harness（Anthropic 三部曲＋12 项设计检查点）
- 第7章 产业落地实践（Anthropic／OpenAI／Cursor／Devin／Aider／OpenHands／LangGraph／Google ADK＋横向对比）
- 第8章 工程实现细节（沙箱选型／工具接口／成本延迟／测试 Harness）
- 第9章 Harness 与 AI Agent 的区别与联系（层次／职责／类比检验／归因模型／决策树）
- 第10章 企业场景：权限与副作用（含工业设备运维示例）
- 第11章 书单与免费资源（A/B/C 三类＋三条阅读路径）
- 第12章 趋势与判断
- **第13章 补充调研**：安全威胁模型／评测基准生态／记忆系统／Durable Execution／MCP 生态／互操作协议／国产模型适配／Claude Code 扩展体系／术语与大事记／落地路线
- 附录 A 术语表｜附录 B 关键论文清单｜附录 C 开源项目｜附录 D 失败案例｜
- 参考文献


---

## 调研假设与边界

本报告基于以下明确假设与边界条件执行：

1. **术语口径**：以「Agent Harness / Agentic Scaffold」为主线，即套在基础模型外面、把模型能力转化为 agency 的代码层。同时交代 harness 的其他三重含义（Evaluation Harness、Test Harness、RL Harness）。
2. **受众定位**：面向一线工程师与架构师，所有内容要能落到「怎么写、怎么设计、怎么取舍、怎么测」。
3. **时间范围**：以 2022 年 ReAct 论文为起点，重点覆盖 2024–2026 年。2026 年的内容均来自可核验的公开来源，不可核验的标注「来源待核」。
4. **不涉及**：不做模型训练、不涉及具体云厂商比价、不做 harness 性能的原创实验。
5. **资源获取约束**：不提供任何盗版电子书下载链接。所有书籍资源分为官方合法免费资源、商业出版物（给官方购买入口）、官方免费技术指南三类。

---

## 第0章 执行摘要

**Agent Harness 是将语言模型从「文本生成器」转变为「能自主完成任务的 Agent」的运行时基础设施层。** 同一模型在不同 harness 下的性能差异可以达到数倍甚至数十倍——SWE-bench 上，Claude 3.5 Sonnet 在 Agentless（简单三阶段 harness）下达到 32.00% 的解决率，而在更复杂的早期 agent 系统中反而更低。Anthropic 明确指出：「改进 harness 往往比更新模型本身带来更大的质量提升。」【厂商自报】

截至本报告快照时点（2026-11-06），harness 领域呈现出三个核心趋势：（1）**Context Engineering 已取代 Prompt Engineering 成为 harness 的核心职能**——97% 的从业者认同上下文管理的重要性，但仅 4% 的企业具备成熟的上下文工程能力（Redis 2026 报告）；（2）**harness 架构正在从单体走向解耦**——Anthropic 的 Managed Agents 将「大脑」（模型+harness）与「双手」（沙箱+工具）完全分离，实现独立扩展和故障恢复；（3）**标准化协议（MCP/A2A）正在定义 harness 的工具层接口**——MCP SDK 月下载量从 2025 年 12 月官方披露的 9700 万+（Python+TypeScript 合计）增长到 2026 年 7 月 Anthropic 官宣的 4 亿次以上（约为年初的 4 倍）。

### Harness 技术栈分层总览表

| 层级 | 职责 | 代表技术/产品 | 成熟度 |
|------|------|--------------|--------|
| **L0: 基础模型** | 推理、生成、工具调用意图 | Claude Opus 4.5/4.6, GPT-5.6 系列（o1 已于 2026-10-23 停用、GPT-4o 已进入弃用流程）, Gemini 3（Gemini 2.5 已过时） | 成熟 |
| **L1: 工具接口层** | 工具注册、schema 发现、调用执行 | MCP 2026-07-28, Function Calling | 快速成熟 |
| **L2: 主循环层** | Agent loop、终止条件、错误恢复 | ReAct loop, Claude Agent SDK | 成熟 |
| **L3: 上下文管理层** | 窗口预算、压缩、检索注入、渐进式披露 | Context Condensation, Compaction | 快速发展 |
| **L4: 状态持久化层** | Checkpoint、Durable Execution、跨会话记忆 | LangGraph Checkpointer, Git-based state | 发展中 |
| **L5: 权限与安全层** | 沙箱隔离、能力模型、审批门、审计 | E2B/SPACE microVM, OPA | 快速发展 |
| **L6: 可观测性层** | Trace、Span、OTel GenAI 语义约定 | OpenTelemetry GenAI, LangSmith | 早期成熟 |
| **L7: 评测层** | Benchmark harness、eval-in-the-loop | lm-evaluation-harness, SWE-bench | 成熟 |

### Harness 成熟度分级表

| 成熟度等级 | 定义 | 典型特征 | 代表系统 |
|-----------|------|---------|---------|
| **Level 0: 裸循环** | while 循环 + 模型调用 | 无工具、无状态管理、无错误恢复 | 教学 demo |
| **Level 1: 工具增强** | 模型可调用工具，有基本循环 | Function calling + 简单重试 | 早期 ReAct 实现 |
| **Level 2: 上下文管理** | 有 compaction/压缩，能处理长任务 | 滑动窗口、基本摘要 | SWE-agent, Aider |
| **Level 3: 状态持久化** | 跨 context window 的状态保持 | Checkpoint、progress 文件、git | Anthropic long-running harness |
| **Level 4: 安全沙箱** | 完整的隔离执行环境 | microVM、网络策略、凭证隔离 | Claude Code + E2B, Managed Agents |
| **Level 5: 可观测与自适应** | 全链路 trace、自动 harness 调优 | OTel、automated harness adaptation | OpenHands Enterprise, Anthropic Managed Agents |

### 核心判断 5 条

1. **Harness 是 Agent 的必要条件，不是附属品**——没有 harness 的模型只是一个文本生成器；agency 是 harness 的产物，不是模型的自带属性。
2. **同一模型换 harness 后能力差异巨大**——SWE-bench 上同一模型在不同 harness 下分数差异可达 2-3 倍：GPT-4o 在 SWE-bench Verified 上从 SWE-agent 的 23.2% 到 Agentless 的 38.8%；Claude 3.5 Sonnet 在 Verified 上从 SWE-agent 的 33.6% 到 OpenHands CodeAct 2.1 的 53.0%。【已复现】（注：原句 12.5% 为 GPT-4 Turbo+SWE-agent 的 full test 分数；55.2% 未见于 SWE-bench 官方任何分榜，最接近为 Amazon Q 55.0%（Verified，2024-12），与 12.5% 并非同一模型）
3. **简单 harness 可能打败复杂 harness**——Agentless 的三阶段无 agent 设计在 SWE-bench Lite 上达到 32.00%，超过同期所有开源 agent 系统。【已复现】
4. **harness 工程正在成为独立的工程学科**——Anthropic 称之为「harness engineering」，Cursor 称之为「agent harness」，Microsoft Agent Framework 直接提供 `create_harness_agent()` 工厂函数。
5. **harness 的护城河不在代码而在上下文积累**——CLAUDE.md、rules、skills 等组织级知识资产才是真正的差异化来源。

### 工程师可立即执行的动作清单

1. 审视你当前的 agent 实现：它属于哪个成熟度等级？缺少哪些层级？
2. 从 Level 0 开始，先实现一个最小可用的 ReAct 循环（本文第 4 章提供完整伪代码）。
3. 为每个工具调用添加幂等性保证和错误恢复机制。
4. 实现上下文压缩（compaction），确保长任务不会因窗口耗尽而崩溃。
5. 将 harness 的状态持久化到外部存储（文件或数据库），使 agent 可跨会话恢复。

---

## 第1章 概念辨析：Harness 的多重含义与严格定义

### 1.1 Harness 的四重含义与词源

**词源隐喻**：harness 的本义是「马具/挽具」——一套套在马身上的皮革、绳索和金属装置，功能是把马的力量导向人的意图。这个隐喻对理解 AI agent harness 极其贴切：

- **LLM 是马**：力量强大（通晓语言、具备推理能力），但方向不定（只会生成文本，不会自主行动）
- **Harness 是挽具**：把力量约束并导向目标（通过主循环、工具调用、上下文管理等机制，让模型的推理能力转化为实际行动）
- **Agent 是「套上挽具的马正在拉车」**：一个完整的运行状态，包含马（模型）+ 挽具（harness）+ 正在执行的任务

**但这个类比有一处关键失效**：马不会自我修改挽具，而 LLM 可以。当模型足够聪明时，它可以编写自己的工具、修改自己的 system prompt、甚至设计新的 harness 组件。这意味着 harness 的设计必须考虑到「被管理对象可能改变管理规则」这一根本性挑战。

在 AI 语境中，「harness」至少有四种不同所指：

| 含义 | 定义 | 代表 | 本报告定位 |
|------|------|------|-----------|
| **Agent Harness / Scaffold** | 套在模型外面的运行时脚手架，把模型转化为 agent | Claude Code, SWE-agent, OpenHands | **主线** |
| **Evaluation Harness** | 标准化跑分框架 | EleutherAI lm-evaluation-harness, SWE-bench harness | 独立一节（§3.5） |
| **Test Harness** | 软件工程中的测试桩/测试框架 | JUnit, pytest, Google Test | 概念溯源，简短交代 |
| **RL Harness / Rollout Infrastructure** | 强化学习中的环境与 rollout 基础设施 | Isaac Gym, Brax | 概念溯源与类比 |

**Test Harness 的概念溯源**：在软件工程中，test harness 是一个已有数十年的历史术语，指围绕被测代码的测试基础设施——它提供输入、捕获输出、验证结果。这个含义与 agent harness 的核心逻辑完全一致：围绕一个「核心执行体」（被测代码 / LLM），提供输入输出管理和验证机制。

**RL Harness 的类比**：在强化学习中，harness 负责管理环境与 agent 的交互循环——提供 observation、执行 action、计算 reward、管理 episode。这与 agent harness 的主循环（观察→推理→行动→反馈）在结构上高度相似，关键区别在于 RL harness 通常需要管理 reward 信号和策略更新，而 agent harness 在推理时使用固定模型权重。

### 1.2 Agent Harness 的定义：多源综合

以下给出 5 个权威来源对 agent harness 的定义，比较其异同：

**定义 1 — Anthropic（2025）**：
> "An 'agent' refers to the combination of an AI model and the software scaffolding around it." The scaffolding is "responsible for generating the prompts that go into the model, parsing the model's output to take action, and managing the interaction loop where the result of the model's previous action is incorporated into its next prompt."
> — Anthropic, SWE-bench 文档

**定义 2 — Anthropic（2025b）**：
> Claude Code 是 "the agentic harness around Claude" that "provides the tools, context management, and execution environment that turn a language model into a capable coding agent."
> — Anthropic, Claude Code 文档

**定义 3 — Microsoft Agent Framework（2026）**：
> "An agent harness, sometimes called an AI harness, is the runtime scaffolding that turns a language model into an agent that can perform work. It drives model and tool calls, manages conversation state and context, applies approval policies, and can keep the agent progressing through a multistep task."
> — Microsoft Learn, Agent Harness 概念页

**定义 4 — BasicsOf.AI（2026）**：
> "An agent harness is the layer of ordinary software that gives a model those abilities and runs it in a loop... The model is the brain that decides what to do. The harness is the body and nervous system that senses the environment, carries out the decision, and reports back what happened."
> — BasicsOf.AI, Agent Harnesses 概念文章

**定义 5 — 学术论文 Liu（2026）**：
> "In recent engineering discussions, the term harness has been used to describe this surrounding scaffold: the software and operational configuration through which a large language model receives context, proposes actions, uses tools, maintains state, resumes work and produces effects outside the model itself."
> — Jia'an Liu, "Engineering and Governing the Agent Harness: A Technology and Policy Framework for the Runtime Layer of Agentic AI", UNU Institute in Macau, 2026

**比较与综合**：

| 维度 | Anthropic | Microsoft | BasicsOf.AI | Liu (学术) |
|------|-----------|-----------|-------------|-----------|
| 是否包含模型 | 是（agent = model + scaffold） | 否（harness wraps model） | 否（brain vs body） | 否（harness surrounds model） |
| 核心职责 | prompt 生成 + 输出解析 + 循环管理 | 驱动调用 + 状态管理 + 审批策略 | 工具分发 + 上下文管理 + 反馈循环 | 文本生成 + 动作解释 + 后果观察 + 决策 |
| 是否包含安全/权限 | 隐含 | 明确（approval policies） | 明确（permissions, human checkpoints） | 明确（governance） |
| 是否包含执行环境 | 是（execution environment） | 是（sandbox 可选） | 是（safe place to act） | 隐含 |

**本报告采用的综合定义**：

> **Agent Harness** 是围绕语言模型的运行时软件层，它驱动模型与工具的交互循环，管理上下文窗口的内容编排与预算控制，提供执行环境的隔离与安全保障，实施权限策略与人类审批门控，并将模型的文本生成能力转化为可自主完成多步任务的 agent 行为。Harness 是 agent 的必要基础设施——没有 harness，模型只是一个文本生成器；有了 harness，模型才成为能行动的 agent。

### 1.3 相关概念辨析矩阵

以下十个概念在文献和工程实践中经常混用，本节给出严格的职责边界划分：

| 概念 | 核心职责 | 包含模型？ | 可独立运行？ | 可替换？ | 典型实例 |
|------|---------|-----------|-------------|---------|---------|
| **Model** | 推理、生成、理解 | — | 否（需 harness 才能行动） | 是（同一 harness 可换模型） | Claude Opus 4.5, GPT-4o |
| **Harness** | 循环管理 + 工具分发 + 上下文管理 | 否（包裹模型） | 否（需要模型） | 是（同一模型可换 harness） | Claude Code, SWE-agent |
| **Agent** | 自主完成多步任务的完整系统 | 是（= model + harness） | 是 | — | Devin, Claude Code 实例 |
| **Agent Framework** | 提供构建 agent 的抽象和组件库 | 否 | 否（需用户组装） | 是 | LangChain, AutoGen, CrewAI |
| **Runtime** | 生产环境中运行 agent 的执行引擎 | 否 | 是（运行已构建的 agent） | 是 | OpenHands Runtime, Modal |
| **Orchestrator** | 多 agent 之间的任务分配与协调 | 否 | 否（需要被编排的 agents） | 是 | LangGraph supervisor, AutoGen group chat |
| **Workflow** | 预定义的确定性执行流程 | 否 | 是 | 是 | Dify workflow, Coze workflow |
| **Scaffold** | harness 的同义词，学术文献常用 | 否 | 否 | 是 | SWE-agent scaffold |
| **Tool** | agent 可调用的外部能力 | 否 | 否（需要 harness 调用） | 是 | 文件编辑器、shell、搜索引擎 |
| **Policy** | 约束 agent 行为的规则集合 | 否 | 否（需要 harness 执行） | 是 | 权限白名单、审批规则 |

**关键区分**：

- **Harness vs Framework**：Framework 是你用来构建 harness 的工具箱（如 LangChain 提供模型封装、工具抽象、链式调用等组件），harness 是你用这些组件组装出来的具体运行时系统。Cursor 的博客明确指出：「Cursor's agent harness orchestrates these components for each model we support.」
- **Harness vs Workflow**：Workflow 是确定性的、预定义的流程图（A→B→C），harness 是自适应的、由模型驱动决策的循环（模型决定下一步做什么）。
- **Harness vs Orchestrator**：Orchestrator 管理多个 agent 之间的协调，harness 管理单个 agent 内部的循环。一个 orchestrator 下面可以有多个 harness。
- **Harness vs Runtime**：Runtime 强调生产环境的执行引擎（进程管理、资源分配、健康检查），harness 强调 agent 逻辑层面的循环管理。实际产品中两者经常合并。

### 1.4 「Agent = Model + Harness」的严格论证

**命题**：Agent 是 harness 的产物，而不是模型的自带属性。

**论证 1 — 必要性论证**：

一个裸模型（无论多强大）只能做一件事：给定输入文本，生成输出文本。它不能：
- 打开文件（需要文件操作工具 + 调用机制）
- 执行代码（需要沙箱 + 执行工具）
- 记住之前做了什么（需要状态管理 + 持久化）
- 知道自己做得对不对（需要反馈循环 + 评估机制）

这些「不能」都不是模型能力的问题，而是缺少 harness 的问题。给模型加上 harness，它才能从「文本生成器」变成「能行动的系统」。

**论证 2 — 实证证据：同一模型、不同 harness 的性能差异**

| 模型 | Harness | SWE-bench 分数 | 来源 |
|------|---------|---------------|------|
| Claude 3.5 Sonnet | Agentless（简单三阶段） | 32.00% | Agentless 论文, 2024【已复现】 |
| Claude 3.5 Sonnet | SWE-agent（复杂 ACI） | ~20% | SWE-agent 论文原始数据【已复现】 |
| GPT-4 Turbo / Claude 3 Opus | 裸基线（无 harness，非交互 RAG） | 1.31%–4.33%（见 §3.1 注） | SWE-agent 论文 Table 1【已核实】 |
| GPT-4o | Agentless | ~25% | Agentless 论文【已复现】 |
| Claude Sonnet 4.5 | Anthropic long-running harness | 显著提升（具体数字未公开） | Anthropic 博客【厂商自报】 |
| 多种模型 | OpenHands CodeAct 2.1 | 53% SWE-bench Verified | OpenHands 博客【厂商自报】 |

**关键发现**：同一个 Claude 3.5 Sonnet，在 Agentless 的简单 harness 下（32.00%）显著优于在 SWE-agent 的复杂 harness 下的表现。这说明 harness 设计不是「越复杂越好」，而是「越适配越好」。

**论证 3 — 反事实论证**：

如果 agency 是模型的自带属性，那么：
- 换 harness 不应影响 agent 表现 → **事实相反**（见上表）
- 更强的模型必然产生更好的 agent → **事实相反**（Anthropic 发现 Sonnet 4.5 有「context anxiety」行为，需要 harness 补偿；Opus 4.5 则天然没有这个问题，harness 可以去掉这部分补偿逻辑）
- 模型升级后 harness 不再重要 → **事实相反**（Anthropic 2026 年 3 月博客明确指出：「harnesses encode assumptions that go stale as models improve」，意味着 harness 需要持续适配模型进化）

### 1.5 边界案例逐个判定

| 系统 | 是 agent 还是 harness？ | 判定理由 |
|------|----------------------|---------|
| **一个 while 循环 + LLM 调用** | Harness（Level 0） | 有循环但没有工具、没有状态管理，是最原始的 harness |
| **Prompt chain（A→B→C 的确定性流程）** | 不是 agent，是 workflow | 没有自主决策，每一步都是预定义的 |
| **RAG 系统（检索增强生成）** | 不是 agent，是 harness 的一个组件 | 只有单次检索-生成循环，没有多步自主决策 |
| **Claude Code** | 既是 harness 也是 agent | 作为产品是 harness（它包裹 Claude 模型）；运行时的 Claude Code 实例是 agent |
| **ChatGPT** | 边界情况 | 基础聊天模式是 model + 简单 harness（有工具调用但无持久状态）；Canvas 模式和 GPTs 更接近完整 agent |
| **SWE-agent** | Harness | 它是包裹模型的脚手架，提供 ACI 接口 |
| **Devin** | Agent（产品级别） | 它包含模型 + harness + UI + 状态管理，是完整的 agent 产品 |
| **LangGraph** | Framework（可构建 harness） | 它提供构建 harness 的抽象（StateGraph、nodes、edges），但不是 harness 本身 |
| **AutoGPT** | Harness（Level 1-2） | 有循环和工具调用，但上下文管理和错误恢复较原始 |

### 工程师可立即执行的动作清单

1. 检查你的团队是否在用「模型能力不足」来解释实际上是「harness 设计不足」导致的问题。
2. 使用 §1.3 的概念矩阵，确保团队对 harness、framework、workflow 等术语有统一理解。
3. 评估你当前的 agent 系统属于 §1.5 中的哪个边界案例，明确你在构建的是 agent 还是 harness。
4. 如果还在用 prompt chain 实现「agent」，考虑是否需要引入真正的自主决策循环。

---

## 第2章 前沿理论

### 2.1 理论根基：从认知架构到 Agent Harness

Agent harness 的设计并非凭空而来，它有着深厚的理论基础。以下梳理四个核心理论传统与 harness 设计的对应关系：

#### 2.1.1 POMDP（部分可观察马尔可夫决策过程）

**核心机制**：在 POMDP 框架中，agent 无法直接观察到环境的完整状态，而是通过观测（observation）来推断信念状态（belief state）。最优策略是在信念空间上做规划，而不是在状态空间上。

**与 harness 的对应**：
- LLM 的上下文窗口就是 agent 的「信念状态」——它永远无法看到完整的代码库、所有历史记录或全部环境状态
- Harness 的核心职责之一就是管理这个「信念状态」——决定什么信息进入上下文窗口（观察选择），什么信息被压缩或丢弃（信念更新）
- Context Engineering 的本质就是在 POMDP 框架下优化信念状态的构建

**对 harness 设计的指导**：
- 不要假设模型能「看到」所有信息——harness 必须主动选择和组织进入上下文的信息
- 上下文压缩不是可选优化，而是 POMDP 约束下的必然需求
- 信念状态的准确性直接决定 agent 的行动质量

**局限**：POMDP 假设状态转移和观测概率是固定的，但 LLM agent 的环境（代码库、用户意图）可能在任务执行过程中发生变化。

**来源**：Sumers et al., "Cognitive Architectures for Language Agents", TMLR 2024（CoALA 论文）将 LLM agent 结构化为「工作记忆+长期记忆（情景/语义/程序性）+ 内外行动空间 + 决策周期」的认知架构框架。"上下文窗口≈POMDP 信念状态"的视角系本报告的分析引申（POMDP 经典形式化可引 Kaelbling et al., 1998），并非 CoALA 原文表述。

#### 2.1.2 控制论（Cybernetics / Feedback Loop）

**核心机制**：控制论的核心是反馈循环——系统通过传感器获取输出信息，与期望状态比较，产生纠正信号，调整行为。维纳（Norbert Wiener）在 1948 年奠定了这一理论基础。

**与 harness 的对应**：
- ReAct 循环（Thought → Action → Observation → Thought）本质上就是一个控制论反馈循环
- Harness 是这个反馈循环的物理实现——它执行 action、获取 observation、将结果反馈给模型
- Reflexion 框架在 ReAct 的基础上增加了「verbal reinforcement」——失败后的自我反思作为额外的反馈信号

**对 harness 设计的指导**：
- 每个 agent action 都必须有可观察的结果（否则反馈循环断裂）
- 反馈信号的延迟和噪声直接影响 agent 性能——harness 应最小化 action→observation 的延迟
- 多层次的反馈循环（工具执行反馈 → 自我评估反馈 → 人类反馈）可以叠加提升性能

**来源**：ReAct（Yao et al., ICLR 2023）和 Reflexion（Shinn et al., NeurIPS 2023）是控制论思想在 LLM agent 中的直接体现。

#### 2.1.3 BDI 模型（Belief-Desire-Intention）

**核心机制**：BDI 模型是理性 agent 的形式化框架，将 agent 的心智状态分解为三个成分：
- **Belief（信念）**：agent 对世界的认知
- **Desire（欲望/目标）**：agent 想要达到的状态
- **Intention（意图）**：agent 当前承诺执行的计划

**与 harness 的对应**：
- Belief → 上下文窗口中的信息（harness 管理）
- Desire → 用户任务描述 + 模型自主设定的子目标
- Intention → 当前正在执行的具体步骤（harness 需要追踪和管理）

**对 harness 设计的指导**：
- Harness 需要提供「意图追踪」机制——agent 当前在做什么，为什么做，下一步是什么
- Anthropic 的 long-running harness 中的 `claude-progress.txt` 文件就是一个 intention tracker
- LangGraph 的 state schema 本质上就是在维护 BDI 三个成分的形式化表示

**来源**：BDI 模型的经典出处为 Rao & Georgeff (1995) 等理性 agent 理论文献；CoALA 论文原文未讨论 BDI（其理论根基为 Soar 等认知架构的生产式系统传统）。

#### 2.1.4 Soar / ACT-R 认知架构

**核心机制**：Soar（Laird et al., 1987）和 ACT-R（Anderson, 1993）是两个人类认知的计算模型，核心思想包括：
- 工作记忆（有限容量）+ 长期记忆（近乎无限）
- 产生式规则（if-then 规则匹配与执行）
- 问题空间搜索（手段-目的分析）

**与 harness 的对应**：
- 上下文窗口 = 工作记忆（容量有限，需要主动管理）
- 向量数据库 / 文件系统 = 长期记忆（需要检索机制）
- Agent loop = 产生式规则的执行循环
- Plan-Execute 模式 = 问题空间搜索

**对 harness 设计的指导**：
- 不要试图把所有信息塞进上下文窗口（工作记忆容量有限）
- 实现分层记忆系统（短期 / 情景 / 语义 / 程序性）
- Voyager 的 skill library 就是程序性记忆的一种实现——将成功行为存储为可检索、可组合的代码片段

**来源**：Voyager（Wang et al., 2023, TMLR 2024）的 skill library 设计直接受到认知架构中程序性记忆概念的启发。CoALA 论文以 Soar 为核心案例梳理了经典认知架构与 LLM agent 的对应关系（ACT-R 仅作为文献引证出现，未展开）。

#### 理论根基总结表

| 理论 | 核心概念 | 在 harness 中的体现 | 关键设计启示 |
|------|---------|-------------------|-------------|
| POMDP | 信念状态管理 | 上下文窗口的内容编排 | 主动选择信息，不要假设模型能看到一切 |
| 控制论 | 反馈循环 | ReAct loop, Reflexion | 确保每个 action 有可观察结果 |
| BDI | 信念/欲望/意图 | 进度追踪、计划管理 | 提供 intention tracking 机制 |
| Soar/ACT-R | 工作记忆 + 长期记忆 | 分层记忆、skill library | 实现分层记忆，不要把所有东西塞进上下文 |

### 2.2 「能力归因」问题：模型能力 vs Harness 能力

**核心问题**：当 agent 完成了一个复杂任务，功劳应该归于模型还是 harness？

这个问题的答案在 2024-2026 年间发生了显著变化：

**2023-2024 年的共识**：大部分能力归于模型。Benchmark 分数被视为模型能力的直接度量。

**2024-2025 年的转变**：SWE-agent 论文（NeurIPS 2024）首次系统地证明了 interface design（即 harness 设计）对 agent 性能的巨大影响。同一模型在 SWE-agent 的 ACI 下比直接提示提升了数倍性能。

**2025-2026 年的共识**：Anthropic 明确表示「Harnesses encode assumptions that go stale as models improve」（Managed Agents 博客），并指出 harness design 对长时程 agentic coding 的效果有实质性影响。Agentless 的发现进一步强化了这一观点——简单的三阶段 harness 就能打败复杂的 agent 系统。

**「能力幻觉」的讨论**：

一个值得警惕的现象是，很多被认为是「模型能力」的表现，实际上是 harness 提供的：
- 模型本身不能执行代码 → harness 提供沙箱
- 模型本身不能记住之前做了什么 → harness 提供状态管理
- 模型本身不能看到代码库全貌 → harness 提供检索和导航工具
- 模型本身不能自我纠正 → harness 提供反馈循环

这意味着 benchmark 测量的从来不是纯粹的「模型能力」，而是「模型 + harness」的系统能力。2026 年的 JetBrains 研究（SWE-TaskFlow）进一步证明，即使是交互协议本身（单轮 vs 多轮）也会显著影响 agent 的测量分数。

### 2.3 Context Engineering 作为 Harness 的核心职能

**范式转移**：2025 年中，从 Prompt Engineering 到 Context Engineering 的范式转移标志着 harness 设计进入新阶段。

**时间线**：
- 2025 年 6 月：Shopify CEO Tobi Lütke 提出 context engineering 概念
- 2025 年 6 月：Andrej Karpathy 将其定义为「the delicate art and science of filling the context window」
- 2025 年 9 月：Anthropic 发表《Effective Context Engineering for AI Agents》
- 2025 年 6 月：LangChain CEO Harrison Chase 指出「Agent 犯错很多时候是因为缺少正确的上下文」（出自其博客《The Rise of "Context Engineering"》，2025-06-23）
- 2026 年 3 月：Harrison Chase 在访谈中提出 harness engineering 是 context engineering 的延伸
- 2026 年：Redis 报告显示 97% 从业者认同上下文重要性，但仅 4% 企业具备成熟能力

**核心洞察**：大多数 agent 失败不是模型失败，而是上下文失败。模型接收正确的 50,000 token 时，表现会优于在 200,000 token 噪声中挣扎的同一模型。

**Context Engineering 的三个层次**：

| 层次 | 内容 | 示例 |
|------|------|------|
| **静态上下文** | 跨请求稳定的信息 | 系统 prompt、API 规范、编码规范 |
| **动态上下文** | 每个请求即时组装的信息 | 用户状态、实时数据、检索到的文档 |
| **元上下文** | 关于如何管理上下文的信息 | token 预算分配、压缩策略、缓存规则 |

**对 harness 设计的指导**：
- 将上下文窗口视为稀缺的结构化资源，显式地预算管理
- 分离稳定内容和动态内容——前者可以激进缓存，后者必须精确投放
- 实现三层压缩级联：工具输出截断（零 LLM 调用）→ 输入驱逐（~85% 填充率时）→ LLM 摘要（阈值触发）

### 2.4 信息论视角：Harness 的本质是信息压缩

**核心命题**：Harness 的本质功能是将开放式问题压缩为模型可解的窄问题。

一个真实的软件工程问题（例如「修复这个 GitHub issue」）包含的信息量远超任何模型的上下文窗口。Harness 的工作是：
1. **选择**：从海量信息中选择与当前步骤最相关的子集
2. **压缩**：将选中的信息压缩到上下文窗口可容纳的大小
3. **编排**：以模型最能有效利用的方式组织这些信息
4. **更新**：随着任务推进，持续更新上下文中的信息

从信息论角度看，这个过程可以形式化为：

```
harness(task, environment) → argmax_{context ∈ C, |context| ≤ W} P(model_solve | context)

其中：
- task: 完整任务描述（信息量可能远超 W）
- environment: 环境状态（代码库、文件系统、外部服务）
- C: 所有可能的上下文组合
- W: 上下文窗口大小
```

这意味着 harness 的设计本质上是一个**信息瓶颈（information bottleneck）**问题——在有限的通道容量（上下文窗口）下，最大化传输的有效信息量。

### 2.5 Harness 与 Scaling Law 的关系

**核心问题**：Harness 能否替代模型规模？

**短期答案**：在某些场景下，可以。Agentless 的发现证明，一个好的 harness 可以让中等模型打败差 harness 下的更强模型。

**长期答案**：不能完全替代，但可以显著降低所需的模型规模。

| 场景 | 模型规模要求（无 harness 优化） | 模型规模要求（有 harness 优化） |
|------|------|------|
| 简单代码修复 | GPT-4 级别 | GPT-3.5 级别 + 好 harness |
| 复杂软件工程 | Claude Opus 级别 | Claude Sonnet 级别 + 好 harness |
| 长时程自主开发 | 当前不可行 | 当前勉强可行（Anthropic 的实验） |

**趋势**：2026 年出现的「Better Harnesses, Smaller Models」研究方向（Yang et al., 2026）系统性地探索了通过自动优化 harness 来降低对模型规模的需求。这表明 harness 和模型规模之间存在替代关系，但不是完全替代。

### 工程师可立即执行的动作清单

1. 在你的 agent 系统中实现显式的 token 预算管理——不要无限制地向上下文窗口塞信息。
2. 将上下文压缩设计为三层级联（截断 → 驱逐 → 摘要），避免不必要的 LLM 调用。
3. 当你想换更强的模型时，先尝试优化 harness 的上下文管理——这可能更便宜且更有效。
4. 为 harness 的每个信息注入点（system prompt、工具结果、历史记录）设置明确的 token 预算分配。

---

## 第3章 学术研究现状

### 3.1 Harness 效应的实证证据

以下汇总了多个基准测试中「同一模型、不同 harness」的性能差异数据：

#### SWE-bench 上的 Harness 效应

| 模型 | Harness | SWE-bench Lite | SWE-bench Verified | 评测时间 | 来源 | 置信度 |
|------|---------|---------------|-------------------|---------|------|--------|
| Claude 3.5 Sonnet | Agentless | 32.00% | >50% | 2024 Q3 | Agentless 论文【已复现】 | HIGH |
| Claude 3.5 Sonnet | SWE-agent | 23.0% | 33.6% | 2024-06-20 | SWE-bench 官方 leaderboard（SWE-agent队提交 20240620_sweagent_claude3.5sonnet；full test 18.13%）【已复现】 | HIGH |
| GPT-4 Turbo / Claude 3 Opus | 无 harness（非交互 RAG 基线） | 2.67% / 4.33%（Lite） | 1.31% / 3.79%（full test） | 2024 H1 | SWE-agent 论文 Table 1【已核实】（注：Claude 3.5 Sonnet 无公开裸模型口径，官方 33.4%/49.0% 均为带 scaffold） | MEDIUM |
| GPT-4o | Agentless | 27.33%（v1）/ 32.00%（Agentless-1.5） | 38.8% | 2024-06 / 2024-10 | Agentless 论文（arXiv:2407.01489）＋SWE-bench 官方 leaderboard【已复现】 | HIGH |
| GPT-4o | AutoCodeRover-v2 | 30.67% | N/A | 2024 Q3 | AutoCodeRover 论文【已复现】 | HIGH |
| Claude 3.5 Sonnet (claude-3-5-sonnet-20241022) | OpenHands CodeAct 2.1 | 41.7% | 53% | 2024 Q4（2024-10-29 提交；博客 2024-11-01） | OpenHands 博客 + SWE-bench/experiments 官方评测（265/500=53.0%） | HIGH |
| 多种 | Sonar Foundation Agent | N/A | 75% | 2025 Q4 | Sonar 博客【厂商自报】 | MEDIUM |

**重要警告**：上述分数**不可直接横比**。影响因素包括：
- 评测时间（SWE-bench Lite 和 Verified 是不同的子集）
- pass@1 vs pass@k（大多数报告的是 pass@1）
- harness 版本和具体配置
- token 预算限制
- 模型版本（同一模型名称可能有不同日期的版本）

#### WebArena / OSWorld 上的 Harness 效应

WebArena 和 OSWorld 是面向 web 和操作系统环境的 agent 基准。这些基准上的 harness 效应同样显著，但由于环境本身的随机性更大，数据更难以精确复现。

### 3.2 经典 Harness 设计论文逐篇拆解

#### 3.2.1 SWE-agent：Agent-Computer Interface（ACI）

**论文**：Yang et al., "SWE-agent: Agent-Computer Interfaces Enable Automated Software Engineering", NeurIPS 2024.

**核心贡献**：首次系统地研究了界面设计对 LM agent 性能的影响，提出 Agent-Computer Interface（ACI）概念。

**ACI 设计的五个核心组件**：

| 组件 | 功能 | 设计要点 |
|------|------|---------|
| Search & Navigation | 在代码库中定位文件和代码 | `find_file`, `search_file`, `search_dir`，限制返回结果最多 50 条 |
| File Viewer | 查看文件内容 | 窗口式浏览（每次最多 100 行），显示行号、总行数、上下文信息 |
| File Editor | 编辑代码 | 基于行范围的替换编辑，集成 linter 检查，无效编辑自动丢弃 |
| Context Management | 管理 agent 上下文 | 历史观察自动压缩，只保留最近 5 步的完整输出 |
| Error Handling | 处理格式错误 | 格式错误触发重试，首次错误信息保留，后续错误信息覆盖 |

**关键发现**：
- ACI 设计对性能的影响**超过**模型选择的影响
- 限制搜索结果的 verbosity 可以显著提升效率
- 编辑后自动展示更新后的文件内容，减少 agent 的额外查询

**局限**：SWE-agent 的 ACI 主要面向代码编辑场景，对其他类型任务（如 web 浏览、数据分析）的泛化性未充分验证。

#### 3.2.2 OpenHands / CodeAct：可执行代码作为统一动作空间

**论文**：Wang et al., "Executable Code Actions Elicit Better LLM Agents", ICML 2024; OpenHands SDK 论文, arXiv:2511.03690, 2025.

**核心贡献**：
1. 提出用可执行的 Python 代码（而非结构化 JSON）作为 agent 的统一动作空间（CodeAct）
2. 构建了 OpenHands 平台（前身 OpenDevin），一个完整的开源 coding agent 系统

**CodeAct 的设计动机**：
- JSON 格式的工具调用有表达力限制（无法表达循环、条件、变量赋值等）
- 代码天然支持组合、抽象和复用
- 代码可以立即执行验证，提供确定性反馈

**OpenHands SDK 架构**（2025 年重新设计）：
- 简洁的 agent 接口：几行代码即可实现基本 agent
- 可扩展的工具系统：支持自定义工具、记忆管理
- 本地到远程的无缝移植：同一代码可在本地 Docker 和云端运行
- 模型无关：支持多 LLM 路由和 fallback

**Context Condensation**（2025 年 4 月）：
- 实现智能上下文压缩，保持有界对话大小
- 在 SWE-bench Verified 子集上：54% vs 53% 解决率，但 API 成本降低 2 倍
- 关键设计：只在上下文达到阈值时触发压缩，最大化 prompt cache 效率

#### 3.2.3 Agentless：反 Harness 派的关键发现

**论文**：Xia et al., "Agentless: Demystifying LLM-based Software Engineering Agents", FSE 2025（Proc. ACM Softw. Eng. 2, FSE）, arXiv:2407.01489.

**核心发现**：**简单的三阶段无 agent 流程可以打败复杂的 agent 系统**。

Agentless 的设计：
```
阶段 1: 定位（Localization）
  → 层次化定位：文件 → 类/函数 → 具体行号
  → 结合 LLM 定位 + 传统 IR 定位

阶段 2: 修复（Repair）
  → 基于定位结果构建上下文窗口
  → 生成多个候选补丁（Search/Replace 格式）
  → 同时生成复现测试

阶段 3: 验证（Patch Validation）
  → 用复现测试筛选候选补丁
  → 重新排序，选择最佳补丁提交
```

**关键数据**：
- SWE-bench Lite: 32.00%（96 个正确修复），超过同期所有开源 agent
- 成本仅 $0.70/issue
- 在 SWE-bench Verified 上使用 Claude 3.5 Sonnet 达到 >50% 解决率
- 已被 OpenAI 采用为展示 GPT-4o 和 o1 编码能力的标准方法（o1 system card 原文：采用当时最佳开源 scaffold「Agentless」、每题 5 次尝试；「标准方法」为报告转述）

**对 Harness 复杂度设计的启示**：
1. **不是越复杂的 harness 越好**——Agentless 的成功恰恰在于它**不做**什么：不让 LLM 自主决定下一步行动，不使用复杂工具
2. **结构化的分治策略**可以替代自主规划——定位→修复→验证的流水线比自由探索更高效
3. **LLM 的自主决策能力被高估**——在很多任务中，让 LLM 在受限的框架内工作，反而比让它自由规划更有效

**但也要注意**：Agentless 的策略高度依赖任务结构（代码修复有明确的定位→修复→验证流程）。对于更开放的任务（如产品设计、长时程开发），Agentless 的方法可能不适用。

#### 3.2.4 Voyager：技能库与终身学习

**论文**：Wang et al., "Voyager: An Open-Ended Embodied Agent with Large Language Models", 2023, TMLR 2024.

**核心贡献**：提出 skill library（技能库）作为 agent 的长期记忆机制。

**三大组件**：
1. **自动课程（Automatic Curriculum）**：GPT-4 基于当前状态提议下一个探索任务
2. **迭代提示（Iterative Prompting）**：代码生成 → 执行 → 环境反馈 + 执行错误 + 自我验证 → 修订，最多 4 轮
3. **技能库（Skill Library）**：成功验证的代码保存为可复用技能，用自然语言描述的 embedding 索引

**关键结果**：
- 发现 3.3× 更多独特物品
- 解锁科技树里程碑速度提升 15.3×
- 是唯一达到钻石工具的 agent（ReAct、Reflexion、AutoGPT 均无法达到）
- 技能库可以被迁移到新世界解决未见过的任务

**对 Harness 设计的启示**：
- **学习应该发生在 harness 层面**（技能库），而不是模型层面（权重更新）
- **技能存储为代码而非文本**：代码是可组合的（程序调用程序）、可验证的（运行成功或失败）、确定性的（不受上下文窗口遗忘影响）
- **自我验证是关键**：没有自我验证，发现的物品减少 73%

#### 3.2.5 Generative Agents：可信的人类行为模拟

**论文**：Park et al., "Generative Agents: Interactive Simulacra of Human Behavior", UIST 2023.

**核心贡献**：虽然主要面向模拟而非工具使用，但其记忆架构对 harness 设计有重要启示。

**记忆架构**：
- **观察流（Observation Stream）**：agent 感知到的环境事件
- **反思（Reflection）**：定期对观察进行高层次总结
- **规划（Planning）**：基于反思生成未来行动计划

**对 Harness 的启示**：
- 分层记忆系统（短期观察 → 中期反思 → 长期规划）优于单一的历史记录
- 反思机制可以帮助 agent 从经验中提取可迁移的知识

### 3.3 长时程 Harness 研究

长时程 agent（跨越多个上下文窗口工作的 agent）面临的特殊挑战：

**核心挑战**：
1. **上下文窗口耗尽**：单个窗口无法容纳整个任务的信息
2. **状态漂移**：跨窗口传递状态时信息丢失或扭曲
3. **目标遗忘**：agent 在子任务中迷失，忘记总体目标
4. **成本失控**：长时间运行导致 API 成本不可控
5. **人类监督缺位**：长时间无人看管时错误累积

**Anthropic 的两阶段解决方案（2025 年 11 月）**：
1. **Initializer Agent**：仅第一次会话使用，生成 `init.sh`、`feature_list.json`（200+ 功能）、`claude-progress.txt` 和初始 git commit
2. **Coding Agent**：后续所有会话使用，每个会话：
   - 读取 git 日志和进度文件
   - 选择最高优先级的未完成功能
   - 只做一个功能
   - 提交 git commit 并更新进度文件

**关键设计决策**：
- 使用 JSON 而非 Markdown 存储功能列表（模型不太可能随意修改 JSON）
- 强烈措辞的指令禁止修改或删除测试（"It is unacceptable to remove or edit tests"）
- 进度文件 + git 历史让新窗口的 agent 能快速了解状态

**Anthropic 的三阶段演进（2026 年 3 月）**：
1. **Planner Agent**：将简短提示扩展为完整产品规格
2. **Generator Agent**：按 sprint 工作，每次实现一个功能
3. **Evaluator Agent**：使用 Playwright MCP 进行 E2E 测试，对每个 sprint 评分

**重要发现**：当模型从 Sonnet 4.5 升级到 Opus 4.5 时，「context anxiety」行为消失，sprint 结构可以去掉，evaluator 的价值也降低了——**harness 的组件应该随模型能力的提升而动态调整**。

### 3.4 可复现性危机

**问题**：不同论文之间的 benchmark 分数往往不可比较。

**原因**：
1. **Harness 不同**：同一模型在不同 harness 下分数差异巨大（见 §3.1）
2. **评测条件不同**：token 预算、温度、few-shot 数量、prompt 模板
3. **时间点不同**：模型版本可能已更新（同一名称下的不同日期版本）
4. **pass@1 vs pass@k**：不同论文使用不同的采样策略
5. **任务子集不同**：SWE-bench Lite vs Verified vs Full 是不同的子集

**2026 年的反思**：
- JetBrains 的 SWE-TaskFlow（2026 年 10 月）证明，**交互协议本身**（单轮 vs 多轮）也是重要的评测维度
- Pairing Matters（Zhao et al., 2026）发现，harness-model 配对之间的失败模式存在显著差异
- 学界呼吁标准化的评测 harness 协议，但尚未达成共识

### 3.5 Evaluation Harness：独立小节

#### 3.5.1 EleutherAI lm-evaluation-harness

**定位**：标准化的 LLM 评测框架，支持 200+ 评测任务、25+ 模型后端。

**架构**：

| 层级 | 职责 | 关键模块 |
|------|------|---------|
| 用户接口 | 评测入口 | `lm_eval/__main__.py`, `evaluator.py` |
| 核心编排 | 协调评测流程 | `evaluator.py`, `tasks/manager.py` |
| 模型集成 | 加载和包装模型 | `models/__init__.py`, `api/registry.py` |
| 任务定义 | 发现和配置任务 | `tasks/manager.py`, `api/task.py` |
| 处理基础设施 | 过滤、指标、缓存 | `api/metrics.py`, `api/registry.py` |

**关键设计特点**：
- **Registry 模式**：通过装饰器注册模型后端、任务、过滤器、指标
- **YAML 任务定义**：声明式配置，无需修改核心代码
- **请求缓存**：SQLite 后端，避免重复推理
- **多 GPU 支持**：通过 `accelerate` 实现数据并行

**元问题**：评测 harness 本身也会影响结果。`--num_fewshot` 参数的变化可以显著改变分数；不同的 prompt 模板也会导致结果差异。

#### 3.5.2 SWE-bench Harness

SWE-bench 的评测 harness 与 agent harness 有密切关系——它测量的不是纯模型能力，而是 model + harness 的系统能力。

**关键设计**：
- 每个 issue 在独立的 Docker 容器中运行
- 使用真实 GitHub issue 和对应的 pull request 作为评测标准
- 测试通过/失败作为唯一的评判标准（不需要人工评估）

#### 3.5.3 HELM 和 OpenAI Evals

- **HELM**（Stanford）：强调全面性（accuracy, calibration, robustness, fairness, bias, toxicity, efficiency）
- **OpenAI Evals**：开放注册的评测框架，社区贡献评测任务

### 工程师可立即执行的动作清单

1. 在比较不同 agent 系统的 benchmark 分数时，必须同时记录 harness、模型版本、评测时间、pass@1/pass@k。
2. 使用 lm-evaluation-harness 在自己的环境中复现 benchmark，不要轻信论文中报告的数字。
3. 为你的 agent 系统实现内部的 eval 钩子（见第 4 章 §4.8），持续监控 harness 变更对性能的影响。
4. 当你的 agent 表现不佳时，先检查是模型问题还是 harness 问题——用同一模型搭配不同 harness 进行对照实验。

---

## 第4章 Harness 的架构与组成部件

### 4.0 整体架构 ASCII 图

```
┌─────────────────────────────────────────────────────────────────┐
│                      AGENT HARNESS 整体架构                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────┐    ┌──────────────────────────────────────────┐   │
│  │  用户/   │    │           HARNESS (运行时脚手架)           │   │
│  │  外部    │───▶│                                          │   │
│  │  系统    │    │  ┌─────────┐   ┌─────────────────────┐   │   │
│  └──────────┘    │  │  主循环  │──▶│   上下文管理器        │   │   │
│                  │  │ (Agent  │   │  ┌───────┐ ┌──────┐ │   │   │
│  ┌──────────┐    │  │  Loop)  │◀──│  │ 窗口  │ │ 压缩 │ │   │   │
│  │  模型    │◀──▶│  │         │   │  │ 预算  │ │ 策略 │ │   │   │
│  │  (LLM)   │    │  └────┬────┘   │  └───────┘ └──────┘ │   │   │
│  └──────────┘    │       │        └─────────────────────┘   │   │
│                  │       ▼                                    │   │
│                  │  ┌─────────┐   ┌─────────────────────┐   │   │
│                  │  │ 工具注册 │   │   状态持久化          │   │   │
│                  │  │ 表      │   │  ┌───────┐ ┌──────┐ │   │   │
│                  │  │ + MCP   │   │  │Checkpt│ │记忆   │ │   │   │
│                  │  └────┬────┘   │  └───────┘ └──────┘ │   │   │
│                  │       │        └─────────────────────┘   │   │
│                  └───────┼──────────────────────────────────┘   │
│                          │                                       │
│  ┌───────────────────────▼──────────────────────────────────┐   │
│  │                  安全与执行层                              │   │
│  │  ┌────────┐  ┌────────┐  ┌──────────┐  ┌────────────┐   │   │
│  │  │ 权限层  │  │ 审批门  │  │  沙箱     │  │  可观测性   │   │   │
│  │  │(Capability│ │(HITL) │  │(Sandbox) │  │  (OTel)    │   │   │
│  │  └────────┘  └────────┘  └──────────┘  └────────────┘   │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 4.1 主循环（Agent Loop）与终止条件

**职责**：驱动模型与环境的交互循环，是 harness 的核心引擎。

**基本模式**：

```python
# 最小可用 Harness 的完整伪代码
class AgentHarness:
    def __init__(self, model, tools, context_manager, sandbox):
        self.model = model
        self.tools = tools
        self.ctx = context_manager
        self.sandbox = sandbox
        self.history = []
        self.max_iterations = 50  # 安全上限
    
    def run(self, task: str) -> str:
        """主循环：驱动 agent 完成任务"""
        self.ctx.initialize(task)
        
        for i in range(self.max_iterations):
            # 1. 准备上下文
            context = self.ctx.build()
            
            # 2. 调用模型
            response = self.model.generate(context)
            
            # 3. 解析响应
            if response.is_final_answer:
                return response.answer
            
            if response.is_tool_call:
                # 4. 执行工具
                for tool_call in response.tool_calls:
                    # 权限检查
                    if not self.check_permission(tool_call):
                        result = "Permission denied"
                    else:
                        result = self.execute_tool(tool_call)
                    
                    # 5. 记录结果
                    self.history.append({
                        "tool": tool_call.name,
                        "args": tool_call.args,
                        "result": result
                    })
            
            # 6. 更新上下文
            self.ctx.update(response, self.history[-1])
            
            # 7. 检查终止条件
            if self.should_stop(i, self.history):
                break
        
        return self.generate_summary()
    
    def check_permission(self, tool_call) -> bool:
        """检查工具调用是否在权限范围内"""
        return tool_call.name in self.tools.allowed
    
    def execute_tool(self, tool_call) -> str:
        """在沙箱中执行工具"""
        return self.sandbox.execute(
            self.tools[tool_call.name],
            tool_call.args
        )
    
    def should_stop(self, iteration, history) -> bool:
        """终止条件检查"""
        # 条件 1: 达到最大迭代
        if iteration >= self.max_iterations - 1:
            return True
        # 条件 2: 连续 N 次无进展
        if self.no_progress(history, window=5):
            return True
        # 条件 3: 成本超预算
        if self.cost_exceeded():
            return True
        return False
```

**终止条件的设计取舍**：

| 终止条件 | 优点 | 缺点 | 适用场景 |
|---------|------|------|---------|
| 最大迭代次数 | 简单可靠，防止无限循环 | 可能在任务完成前截断 | 所有场景（必须有的安全网） |
| 模型声明完成 | 灵活，由模型判断 | 可能过早声明（Anthropic 发现的「early victory」问题） | 简单任务 |
| 连续无进展 | 检测卡死状态 | 需要定义「进展」的度量 | 长时程任务 |
| 成本预算 | 控制开支 | 可能因预算不足而失败 | 生产环境 |
| 功能列表完成 | 客观、可验证 | 需要预定义功能列表 | Anthropic long-running harness |
| 测试全部通过 | 确定性验证 | 需要完善的测试套件 | 代码相关任务 |

**常见错误**：
1. 不设置最大迭代上限 → agent 陷入无限循环，成本失控
2. 仅依赖模型判断完成 → 「early victory」问题
3. 没有在终止时保存状态 → 下次无法恢复

### 4.2 工具注册表与 Schema 设计

**职责**：管理 agent 可调用的工具集，提供工具发现、schema 验证和调用分发。

**设计要点**：

```python
# 工具注册表设计
class ToolRegistry:
    def __init__(self):
        self.tools = {}
        self.schemas = {}
    
    def register(self, name: str, schema: dict, handler: Callable):
        """注册工具及其 JSON Schema"""
        self.tools[name] = handler
        self.schemas[name] = schema
    
    def get_for_model(self) -> list:
        """返回模型可理解的工具定义列表"""
        return [
            {
                "name": name,
                "description": schema["description"],
                "parameters": schema["parameters"]
            }
            for name, schema in self.schemas.items()
        ]
    
    def dispatch(self, name: str, args: dict) -> str:
        """分发工具调用到对应处理器"""
        if name not in self.tools:
            return f"Error: Unknown tool '{name}'"
        # 参数验证
        if not self.validate(name, args):
            return f"Error: Invalid arguments for '{name}'"
        return self.tools[name](**args)
```

**MCP 作为工具层标准**：

Model Context Protocol（MCP）在 2024 年 11 月由 Anthropic 发布，到 2026 年 7 月已成为事实标准：
- SDK 月下载量：2025-12 官方披露 9700 万+（Python+TypeScript 合计），2026-07 Anthropic 官宣 4 亿次以上【已核实】（初版「2024.11=200 万」起点未见公开口径）
- 所有主要云提供商和 AI 实验室支持
- 2026-07-28 规范引入无状态核心（stateless core），支持 serverless 部署

**MCP 的设计要点**：
- **按意图分组工具**：少而精的工具 > 穷举 API 镜像。一个 `create_issue_from_thread` 工具好于 `get_thread` + `parse_messages` + `create_issue` + `link_attachment`
- **渐进式工具加载**：Tool Search Tool 按需发现并加载工具，官方示例中总上下文 token 从约 77K 降至约 8.7K（减少 85%）；通过代码执行按需读取工具定义，可减少 98.7% 的工具定义 token（150,000→2,000）
- **程序化结果处理**：在沙箱中处理工具结果，只有最终输出进入上下文，减少约 37% 的 token 使用

**常见错误**：
1. 工具描述不清晰 → 模型无法正确选择工具
2. 工具粒度过细 → 需要多次调用才能完成一个任务
3. 没有错误处理 → 工具失败时 agent 不知道如何应对

### 4.3 上下文管理器

**职责**：管理上下文窗口的内容编排、预算控制和生命周期。

**这是 2025-2026 年 harness 设计中最重要的组件**。

**上下文窗口的预算分配**：

| 区域 | 典型占比 | 内容 |
|------|---------|------|
| System Prompt | 5-10% | 身份、规则、输出格式 |
| 工具定义 | 5-15% | 工具 schema 和描述 |
| 检索注入 | 10-30% | RAG 检索到的文档、代码片段 |
| 对话历史 | 30-50% | 之前的交互记录 |
| 当前任务 | 5-10% | 用户最新输入 |
| 预留空间 | 10-20% | 给模型输出的空间 |

**压缩策略**：

```python
# 三层压缩级联伪代码
class ContextManager:
    def __init__(self, max_tokens: int):
        self.max_tokens = max_tokens
        self.static_context = []   # 可激进缓存
        self.dynamic_context = []  # 需要精确投放
        self.history = []
    
    def build(self) -> list:
        """构建当前上下文"""
        total = sum(self.estimate_tokens(x) for x in self.static_context)
        total += sum(self.estimate_tokens(x) for x in self.dynamic_context)
        
        # Layer 1: 工具输出截断（零 LLM 调用）
        history = self.truncate_tool_outputs(self.history, max_tokens=2000)
        total = self.sum_tokens(self.static_context, history)
        
        # Layer 2: 输入驱逐（~85% 填充率时触发）
        if total > self.max_tokens * 0.85:
            history = self.evict_large_inputs(history)
            total = self.sum_tokens(self.static_context, history)
        
        # Layer 3: LLM 摘要（阈值触发）
        if total > self.max_tokens * 0.90:
            history = self.llm_summarize(
                history,
                preserve_recent_ratio=0.10  # 保留最近 10% 的原始内容
            )
        
        return self.static_context + history
    
    def truncate_tool_outputs(self, history, max_tokens):
        """Layer 1: 截断大型工具输出"""
        for entry in history:
            if entry.get("type") == "tool_result":
                if self.estimate_tokens(entry["content"]) > max_tokens:
                    entry["content"] = (
                        entry["content"][:max_tokens * 3]  # 字符级截断
                        + f"\n[... truncated, full content at {entry['file_path']}]"
                    )
        return history
    
    def llm_summarize(self, history, preserve_recent_ratio):
        """Layer 3: LLM 摘要压缩"""
        split_point = int(len(history) * (1 - preserve_recent_ratio))
        old_history = history[:split_point]
        recent_history = history[split_point:]
        
        summary = self.model.generate(
            f"Summarize the following conversation history, "
            f"focusing on progress, key decisions, and remaining work:\n\n"
            f"{self.format(old_history)}"
        )
        
        return [{"role": "system", "content": f"Previous progress summary: {summary}"}] + recent_history
```

**关键设计决策**：
- **保留最近 10% 的原始对话**：确保 agent 对当前工作有准确认知
- **结构化摘要格式**：7 字段 JSON（session_intent, progress_so_far, key_facts, artifacts_created, files_modified, blockers, next_steps）优于自由文本（字段清单为本报告综合实践建议，非引自单一信源）
- **Layer 1 和 Layer 2 处理大部分压力**：Layer 3（LLM 摘要）是最后手段，不是主机制

### 4.4 状态存储与持久化

**职责**：跨 context window 和跨会话保存 agent 的工作状态。

**方案对比**：

| 方案 | 优点 | 缺点 | 适用场景 |
|------|------|------|---------|
| 文件系统（progress.txt） | 简单、可读、git 友好 | 结构化程度低 | Anthropic long-running harness |
| Git 历史 | 天然的版本控制、可回滚 | 需要 git 环境 | 代码相关任务 |
| 数据库（PostgreSQL） | 结构化、支持查询 | 增加依赖 | LangGraph checkpointer |
| 内存快照 | 完整状态保存 | 资源占用大 | E2B pause/resume |
| 向量数据库 | 语义检索 | 只适合非结构化信息 | 长期记忆 |

**Checkpoint/Resume 伪代码**：

```python
class CheckpointManager:
    def __init__(self, storage):
        self.storage = storage  # 可以是文件、数据库、对象存储
    
    def save(self, session_id: str, state: dict):
        """保存检查点"""
        checkpoint = {
            "session_id": session_id,
            "timestamp": datetime.utcnow().isoformat(),
            "state": {
                "history": state["history"],
                "current_task": state["current_task"],
                "progress": state["progress"],
                "artifacts": state["artifacts"],
                "token_usage": state["token_usage"]
            }
        }
        self.storage.put(f"checkpoint/{session_id}", checkpoint)
    
    def load(self, session_id: str) -> dict:
        """从检查点恢复"""
        checkpoint = self.storage.get(f"checkpoint/{session_id}")
        if checkpoint is None:
            raise ValueError(f"No checkpoint found for session {session_id}")
        return checkpoint["state"]
    
    def resume(self, harness, session_id: str):
        """恢复 agent 运行"""
        state = self.load(session_id)
        harness.history = state["history"]
        harness.current_task = state["current_task"]
        # 上下文管理器从状态中重建
        harness.ctx.restore(state)
        return harness.run_from_checkpoint()
```

### 4.5 权限层与沙箱

**职责**：约束 agent 的行为边界，防止危险操作。

**Capability 模型设计**：

| 权限级别 | 允许的操作 | 需要审批的操作 | 禁止的操作 |
|---------|-----------|-------------|-----------|
| **只读** | 读取文件、搜索代码、查看日志 | — | 任何写入操作 |
| **受限写入** | 编辑指定目录的文件、运行测试 | 删除文件、安装依赖 | 修改系统配置、网络访问 |
| **完全写入** | 所有文件操作、运行命令 | 网络请求、API 调用 | 修改权限设置 |
| **管理员** | 所有操作 | — | — |

**Anthropic Managed Agents 的安全架构**（2026 年 4 月）：

关键设计决策：**将凭证与沙箱完全隔离**

```
┌─────────────────────────────────────────────────────┐
│                  Harness (大脑)                     │
│                                                     │
│  ┌───────────┐    ┌──────────────────────┐          │
│  │ Claude +  │    │ Session Log          │          │
│  │ Harness   │    │ (append-only event   │          │
│  │           │    │  log, outside        │          │
│  │           │    │  harness)            │          │
│  └─────┬─────┘    └──────────────────────┘          │
│        │ execute(name, input) -> string             │
└────────┼────────────────────────────────────────────┘
         │
         v
┌────────┴────────────────────────────────────────────┐
│                  Sandbox (双手)                     │
│                                                     │
│  ┌───────────┐    ┌──────────────────────┐          │
│  │ Container │    │ NO CREDENTIALS HERE  │          │
│  │ (代码执行)│    │ Git token 在初始化时 │          │
│  │           │    │ 已注入 remote URL    │          │
│  │           │    │ OAuth 经 MCP proxy   │          │
│  │           │    │ 在外层注入           │          │
│  └───────────┘    └──────────────────────┘          │
└─────────────────────────────────────────────────────┘
```

### 4.6 错误处理与重试

**职责**：管理工具执行失败、模型输出异常和系统错误。

**设计原则**：

| 原则 | 实现方式 | 示例 |
|------|---------|------|
| **幂等性** | 确保同一操作执行多次结果相同 | 文件写入用「写入目标内容」而非「追加」 |
| **副作用管理** | 记录所有有副作用的操作，支持回滚 | 维护 undo log |
| **分级重试** | 不同错误类型采用不同策略 | 网络错误→指数退避重试；格式错误→让模型重新生成 |
| **优雅降级** | 部分失败时继续可用 | 一个工具不可用时切换到替代方案 |

**错误分类与处理策略**：

| 错误类型 | 示例 | 处理策略 |
|---------|------|---------|
| 模型格式错误 | 工具调用格式不对 | 显示错误信息，让模型重新生成（最多 3 次） |
| 工具执行失败 | 命令返回非零退出码 | 将错误输出反馈给模型，让其调整 |
| 超时 | 工具执行超过时限 | 终止执行，通知模型 |
| 权限拒绝 | 调用未授权工具 | 返回拒绝信息，记录审计日志 |
| 资源耗尽 | Token 预算用完 | 保存状态，通知用户 |
| 系统错误 | 沙箱崩溃 | 从 checkpoint 恢复，重新创建沙箱 |

### 4.7 可观测性

**职责**：提供 agent 运行过程的全链路追踪能力。

**OpenTelemetry GenAI 语义约定**（官方修正版，核查时点 2026-11-06）：GenAI 约定整体处于 Development 状态；2026-06-12 随核心 v1.42.0 迁入独立仓库 `open-telemetry/semantic-conventions-genai`（旧文档站 URL 已失效）。span name 为模板写法，占位符在导出时以属性值代入：

| 官方 span 命名 | Span Kind | 关键属性 | 描述 |
|------|------|------|------|
| `create_agent {gen_ai.agent.name}` | CLIENT | gen_ai.agent.name / description / version | 创建（远程）agent |
| `invoke_agent {gen_ai.agent.name}` | CLIENT（远程）／INTERNAL（本地） | gen_ai.conversation.id | 一次 agent 调用/会话 |
| `{gen_ai.operation.name} {gen_ai.request.model}`（例 `chat gpt-4o`） | CLIENT／INTERNAL | gen_ai.usage.input_tokens / output_tokens 等 | 一次模型推理调用 |
| `execute_tool {gen_ai.tool.name}` | INTERNAL | gen_ai.tool.name / call.id / type | 一次工具执行 |
| `plan {gen_ai.agent.name}` | INTERNAL | — | 一次规划调用 |

**初版自造 span 名的官方对照**：`agent.session`→无官方对应，会话关联用属性 `gen_ai.conversation.id`；`agent.step`→无官方对应（OTel 不以「一步」为 span 单位，按语义拆分为 chat / execute_tool / plan）；`model.call`→`chat {gen_ai.request.model}`；`tool.execution`→`execute_tool {gen_ai.tool.name}`；`context.compaction`→无官方对应（不得占用 gen_ai. 前缀，如需记录用自定义名并自行文档化）。另：`gen_ai.system` 已废弃、改用 `gen_ai.provider.name`（核心 v1.37.0）；token 用量指标已按操作拆分（`gen_ai.client.inference.duration` 等）。规范文本：https://github.com/open-telemetry/semantic-conventions-genai 【已核实 2026-11-06】

### 4.8 评测钩子

**职责**：在 harness 内部嵌入持续评测能力。

```python
# 评测钩子伪代码
class EvalHooks:
    def __init__(self, eval_config):
        self.metrics = {}
        self.config = eval_config
    
    def on_step_complete(self, step_data):
        """每步完成后收集指标"""
        self.metrics.setdefault("step_count", 0)
        self.metrics["step_count"] += 1
        
        # 检测「无进展」循环
        if self.is_stuck(step_data):
            self.metrics["stuck_events"] = self.metrics.get("stuck_events", 0) + 1
    
    def on_tool_complete(self, tool_result):
        """工具执行完成后检查"""
        if tool_result.is_error:
            self.metrics["tool_errors"] = self.metrics.get("tool_errors", 0) + 1
    
    def on_session_complete(self, session_data):
        """会话完成后计算最终指标"""
        self.metrics["total_tokens"] = session_data.token_usage
        self.metrics["total_cost"] = session_data.cost
        self.metrics["success"] = self.verify_task_completion(session_data)
        return self.metrics
```

### 工程师可立即执行的动作清单

1. 实现 §4.1 中的最小可用 harness 伪代码，作为你的 agent 系统的起点。
2. 为每个工具调用添加幂等性保证（§4.6），这是可靠重试的前提。
3. 实现三层上下文压缩级联（§4.3），从 Layer 1（零 LLM 调用）开始。
4. 添加 OTel GenAI 追踪（§4.7），你无法改进你无法观察的东西。
5. 实现 checkpoint/resume 机制（§4.4），确保长时间任务可以从中间恢复。
6. 在 harness 内部嵌入 eval 钩子（§4.8），持续监控变更对性能的影响。

---

## 第5章 Harness 的设计模式

### 5.0 模式总览表

| # | 模式名称 | 核心思想 | 适用场景 | 过度设计风险 |
|---|---------|---------|---------|-------------|
| 1 | Plan-Execute | 先规划后执行 | 复杂多步任务 | 中：简单任务不需要正式规划 |
| 2 | Reflexion | 失败后语言反馈自我改进 | 需要迭代改进的任务 | 低 |
| 3 | Router | 根据任务类型路由到专门处理器 | 多类型任务混合 | 低 |
| 4 | Orchestrator-Worker | 编排者分配任务给多个工作者 | 可并行的子任务 | 高：单线程任务不需要 |
| 5 | Evaluator-Optimizer | 评估者评分，优化者改进 | 需要质量保证的生成任务 | 中：评估成本可能很高 |
| 6 | Human-in-the-Loop Gate | 关键决策点暂停等待人类审批 | 高风险操作 | 低 |
| 7 | Sandbox-First | 所有代码在隔离沙箱中执行 | 代码生成和执行 | 低（2026 年已是标准做法） |
| 8 | Progressive Disclosure | 按需加载工具和信息 | 工具数量大的场景 | 低 |
| 9 | Context Compaction | 主动压缩历史上下文 | 长时程任务 | 低 |
| 10 | Sub-agent Delegation | 将子任务委派给独立 agent | 探索与编辑分离 | 中：增加了复杂性 |
| 11 | Durable Execution | 持久化每一步执行状态 | 需要可靠性保证的任务 | 中 |
| 12 | Fallback Chain | 多级备选方案 | 关键路径操作 | 低 |

### 5.1 Plan-Execute 模式

**问题**：复杂任务直接执行容易迷失方向、浪费 token。

**解法**：先用一个模型调用生成结构化计划，再按计划逐步执行。

```
ASCII 结构:

  ┌──────────┐      ┌──────────┐      ┌──────────┐
  │  Plan    │─────▶│ Execute  │─────▶│ Review   │
  │ (LLM)   │      │ Step 1   │      │ & Adjust │
  └──────────┘      └──────────┘      └────┬─────┘
                                            │
                       ┌────────────────────┘
                       ▼
                 ┌──────────┐
                 │ Execute  │ ... (循环)
                 │ Step N   │
                 └──────────┘
```

**代码骨架**：

```python
class PlanExecuteHarness:
    def run(self, task):
        # Phase 1: Plan
        plan = self.model.generate(
            f"Create a step-by-step plan for: {task}\n"
            f"Output as JSON array of steps."
        )
        steps = json.loads(plan)
        
        # Phase 2: Execute each step
        results = []
        for i, step in enumerate(steps):
            result = self.execute_step(step, results)
            results.append(result)
            
            # 可选：每 N 步重新评估计划
            if (i + 1) % 3 == 0:
                plan = self.replan(task, results, steps[i+1:])
        
        return self.synthesize(task, results)
```

**适用与不适用**：
- ✅ 适用于：多步软件工程任务、研究任务、数据分析
- ❌ 不适用于：简单问答、实时交互任务、步骤高度不确定的探索任务

### 5.2 Reflexion 模式

**问题**：agent 重复犯同样的错误。

**解法**：失败后用自然语言记录反思，在下次尝试时注入上下文。

```python
class ReflexionHarness:
    def run(self, task, max_attempts=3):
        reflections = []
        
        for attempt in range(max_attempts):
            # 注入历史反思
            context = self.build_context(task, reflections)
            result = self.execute(context)
            
            if result.success:
                return result
            
            # 生成反思
            reflection = self.model.generate(
                f"Task: {task}\n"
                f"Attempt {attempt + 1} failed.\n"
                f"What went wrong: {result.error}\n"
                f"What should be done differently:"
            )
            reflections.append(reflection)
        
        return self.generate_failure_report(task, reflections)
```

### 5.3-5.12 其他模式简述

**Router 模式**：在 agent loop 前加一个分类器，根据任务类型路由到不同的专门 harness。Cursor 的 agent harness 就是这种模式——它为不同模型调整指令和工具。

**Orchestrator-Worker 模式**：一个编排 agent 将任务分解为子任务，分配给多个工作 agent 并行执行。LangGraph 的 supervisor 模式是其典型实现。**注意**：2025-2026 年的实践表明，对于顺序依赖性强的任务（如代码编写），多 agent 并行反而增加了协调开销。

**Evaluator-Optimizer 模式**：Anthropic 2026 年 3 月博客的三 agent 架构（Planner + Generator + Evaluator）就是这种模式。关键发现：**evaluator 的价值取决于任务是否在当前模型能力的边界上**——模型能轻松完成的任务不需要 evaluator，超出模型能力的任务 evaluator 也帮不上忙。

**Human-in-the-Loop Gate**：在高风险操作（如部署、删除、发送邮件）前暂停，等待人类审批。Microsoft Agent Framework 的 `tool_approval` 机制和 standing approval rules 是生产级实现。

**Progressive Disclosure**：不是一次性加载所有工具和上下文，而是按需加载。MCP 的 tool search 模式是典型实现——可以将工具定义 token 减少 85%+。

**Sub-agent Delegation**：Anthropic 推荐的模式——用只读子 agent 探索代码库，将发现写入文件，主 agent 基于文件内容进行编辑。这解决了「探索消耗编辑上下文」的问题。

### 2025-2026 年被证明「过度设计」的模式

| 模式 | 为什么过度 | 替代方案 |
|------|-----------|---------|
| 复杂的多 agent 辩论 | 增加延迟和成本，收益不明显 | 单 agent + 自我反思 |
| 层次化的规划-验证-重规划循环 | Agentless 证明简单流水线更好 | 三阶段流水线 |
| 基于 RL 的动态 harness 调整 | 工程复杂度过高 | 基于规则的自适应 |
| 全面的 agent-to-agent 通信协议 | 大多数场景不需要 | 文件系统 + Git |

### 工程师可立即执行的动作清单

1. 从 Plan-Execute 模式开始——这是投入产出比最高的设计模式。
2. 实现 Reflexion 模式——让你的 agent 从失败中学习。
3. 对于代码任务，优先尝试 Agentless 的三阶段流水线，而不是一开始就构建复杂的多 agent 系统。
4. 使用 Progressive Disclosure 管理工具数量——不要把所有工具定义一次性塞进上下文。
5. 在高风险操作前添加 HITL Gate——但用 standing approval rules 减少频繁审批的摩擦。

---

## 第6章 长时程 Harness（Long-Running Agents）

### 6.1 核心挑战

长时程 agent 被定义为需要跨越多个 context window（数小时到数天）才能完成的任务。

| 挑战 | 描述 | 严重程度 |
|------|------|---------|
| 上下文窗口耗尽 | 单个窗口无法容纳完整任务信息 | ★★★★★ |
| 状态漂移 | 跨窗口传递状态时信息丢失或扭曲 | ★★★★☆ |
| 目标遗忘 | agent 在子任务中迷失总体目标 | ★★★★☆ |
| 成本失控 | 长时间运行的 API 成本不可预测 | ★★★★☆ |
| 人类监督缺位 | 错误在无人看管时累积 | ★★★☆☆ |
| 早期胜利宣言 | agent 看到部分进展就认为任务完成 | ★★★★★ |
| 一次性做太多 | agent 试图一次实现所有功能 | ★★★★☆ |

### 6.2 Anthropic 方法论的核心拆解

Anthropic 在 2025 年 11 月到 2026 年 3 月间发布了三篇关于长时程 harness 的博客文章，构成了目前最系统的方法论：

**第一篇（2025.11）— 两 agent 系统**：
- Initializer Agent + Coding Agent
- 核心创新：`feature_list.json`（200+ 功能的结构化追踪）、`claude-progress.txt`（跨会话状态传递）、`init.sh`（环境标准化）
- 核心洞察：从有效的软件工程师日常实践中获取灵感

**第二篇（2026.03）— 三 agent 系统**：
- Planner + Generator + Evaluator
- 核心创新：sprint contract（generator 和 evaluator 在执行前协商「完成」的定义）
- 核心发现：模型升级后（Opus 4.5 → Opus 4.6），sprint 结构可以去掉，evaluator 从每 sprint 改为最终一次性评估

**第三篇（2026.04）— Managed Agents**：
- 核心创新：将 agent 分解为三个独立接口——session（append-only event log）、harness（循环 + 工具路由）、sandbox（执行环境）
- 核心设计原则：「为尚未被想象到的程序设计系统」——类比操作系统为未来程序虚拟化硬件
- 关键实现：harness 与容器解耦，容器变成「cattle」而非「pets」

### 6.3 长时程 Harness 的 12 项设计检查点

| # | 检查点 | 验证方法 | 失败后果 |
|---|--------|---------|---------|
| 1 | 每个会话开始时读取进度文件 | 检查 system prompt 是否包含进度读取指令 | agent 重复已完成的工作 |
| 2 | 每个会话结束时更新进度文件并提交 git | 检查 stop hook 或终止逻辑 | 下一个会话无法恢复状态 |
| 3 | 功能列表用 JSON 格式（非 Markdown） | 检查文件格式 | 模型可能随意修改功能列表 |
| 4 | 有明确的「一次只做一件事」指令 | 检查 system prompt | agent 试图一次做太多 |
| 5 | 有防止「早期胜利」的机制 | 检查是否有客观完成标准 | agent 过早宣布完成 |
| 6 | 有 E2E 测试验证（不仅仅是单元测试） | 检查是否有 Playwright/Puppeteer 测试 | 看起来工作但实际有 bug |
| 7 | 有成本预算和监控 | 检查 token 使用追踪 | 成本失控 |
| 8 | 支持 checkpoint/resume | 检查状态持久化机制 | 崩溃后无法恢复 |
| 9 | 上下文压缩不会丢失关键信息 | 对比压缩前后的关键事实保留率 | agent 做出基于错误信息的决策 |
| 10 | 有 git revert 能力 | 检查是否能回滚坏的代码变更 | 错误代码累积无法回退 |
| 11 | harness 组件可随模型升级而调整 | 检查各组件是否可独立替换 | 无法利用模型改进 |
| 12 | 凭证与沙箱隔离 | 安全审计 | 凭证泄露 |

### 工程师可立即执行的动作清单

1. 对照 §6.3 的 12 项检查点，审计你的长时程 agent 系统。
2. 实现 progress 文件 + git commit 的跨会话状态传递模式——这是目前验证最有效的方法。
3. 使用 JSON（而非 Markdown）存储结构化的进度追踪信息。
4. 实现 E2E 测试验证，而不仅仅是让 agent 检查代码是否「看起来对」。
5. 为 harness 的每个组件设置独立的开关，使其可以随模型升级而调整。

---

## 第7章 产业落地实践

### 7.1 逐家拆解

#### 7.1.1 Anthropic（Claude Code / Agent SDK / Managed Agents）

**Harness 架构特点**：
- 扩展机制：CLAUDE.md、Hooks、Skills、Plugins、MCP Servers 等（官方 Extend Claude Code 页列约 10 种扩展机制，「五层」为报告自创口径）
- 各机制角色与官方一致：CLAUDE.md 常驻加载、Hooks 事件触发、Skills 按需加载；Plugins 是官方明示的打包层（打包 Skills/Hooks/Subagents/MCP），非并列第五层
- Subagent 支持：只读探索 agent + 编辑 agent 分离

**关键设计决策**：
- CLAUDE.md 用于项目级知识（始终加载），Skills 用于任务级知识（按需加载）——避免所有东西都塞进 CLAUDE.md
- Hooks 不仅用于阻止错误行为，更用于持续改进（stop hook 可以反思会话并提议 CLAUDE.md 更新）
- 凭证永远不进入沙箱——通过 MCP proxy 在外层注入

**公开的失败教训**：
- Sonnet 4.5 有「context anxiety」——感知到上下文限制时会过早结束任务。解法：在 harness 中添加 context reset
- Opus 4.5 没有这个问题——harness 中的 context reset 变成了「dead weight」
- 通用配置不一定在所有上下文中最优——harness 需要针对特定任务调整

**可借鉴点**：
1. 渐进式上下文加载（CLAUDE.md → Skills → Plugins 的分层设计）
2. Hook 机制用于持续改进而非仅用于防护
3. Brain/Hands 解耦的架构

#### 7.1.2 OpenAI（Codex / Agents SDK / Operator）

**Harness 架构特点**：
- Codex：云端异步执行，agent 克隆 repo、创建分支、完成后开 PR
- Agents SDK：提供 handoff、guardrails、tracing 等原语
- 强调安全和 guardrails

**关键设计决策**：
- Codex 采用异步模式——开发者分配任务后可以离开，完成后收到通知
- 采用 Agentless 作为展示模型编码能力的标准 harness

**可借鉴点**：异步执行模式、从 Slack 触发 agent

#### 7.1.3 Cursor

**Harness 架构特点**：
- 三个核心组件：Instructions + Tools + Model
- 为每个模型专门调优指令和工具（不同模型对相同 prompt 响应不同）
- Plan Mode（Shift+Tab）：先研究和规划，经人类批准后再执行

**关键设计决策**：
- Rules（静态上下文）vs Skills（动态能力）的分离
- Hooks 实现「grind」模式——agent 持续迭代直到测试全部通过
- Cloud Agents：远程沙箱执行，可以关闭笔记本后检查进度

**公开的失败教训**：
- 不同模型对相同 prompt 的响应差异巨大——需要为每个模型专门调优
- 过度优化的 Rules 反而降低性能

**可借鉴点**：
1. 为每个模型调优 harness（不要假设一套 prompt 适用于所有模型）
2. Plan Mode 作为 HITL 的轻量实现
3. Hook 驱动的「grind」模式

#### 7.1.4 Devin（Cognition）

**Harness 架构特点**：
- 全自主软件工程 agent
- 包含完整的开发环境（编辑器、浏览器、终端）
- 强调长时程自主工作

**可借鉴点**：context engineering 是 Devin 的核心关注点（Devin 团队最早提出 context engineering 概念）

#### 7.1.5 Aider

**Harness 架构特点**：
- 终端原生的 AI 编码助手
- 专注于 git 集成的编辑工作流
- 使用 repo map（代码库结构图）作为上下文

**可借鉴点**：repo map 作为代码库上下文的紧凑表示

#### 7.1.6 OpenHands

**Harness 架构特点**：
- 官方组件架构：Software Agent SDK（Agent/Conversation/LLM/Tools/Events/Workspace）＋ Agent Server ＋ Agent Canvas（浏览器客户端）＋ Sandbox Server（「Harness→Orchestrator→Control Plane」三层命名为报告自创概括）
- CodeAct 动作空间（可执行代码作为统一动作）
- Context Condensation（智能上下文压缩）
- Agent Canvas：可视化工作空间
- Agent Client Protocol：支持 Claude Code、Codex、Gemini CLI 等多种 agent

**关键设计决策**：
- 模型无关：支持多 LLM 路由
- 本地到远程无缝移植
- SDK 设计强调可组合性和可扩展性

**可借鉴点**：三层架构（harness → orchestrator → control plane）的分层思路

#### 7.1.7 LangGraph

**Harness 架构特点**：
- 图结构的有状态 agent 编排
- TypedDict 状态 schema + reducer 函数
- Checkpointer 支持持久化和 resume
- 条件边（conditional edges）实现动态路由

**可借鉴点**：显式的状态管理 + checkpoint 是长时程任务的关键

#### 7.1.8 Google ADK

**Harness 架构特点**：
- Agent Development Kit
- 强调多 agent 协作
- 与 Google Cloud 深度集成

### 7.2 横向对比表

| 维度 | Claude Code | Cursor | Devin | OpenHands | Aider | LangGraph |
|------|-------------|--------|-------|-----------|-------|-----------|
| **主循环模式** | ReAct + Subagent | ReAct + Plan Mode | 全自主 | CodeAct | Edit-focused | StateGraph |
| **上下文管理** | CLAUDE.md + Skills + Progressive Disclosure | Rules + Skills | Context Engineering | Context Condensation | Repo Map | TypedDict State |
| **状态持久化** | Git + Progress File | Workspace | 内部状态 | Checkpoint | Git | Checkpointer |
| **沙箱** | 本地 + Managed Agents | Cloud Agents (远程) | 完整开发环境 | Docker 容器 | 本地 | 外部 |
| **MCP 支持** | 原生 | 原生 | 部分 | 支持 | 不支持 | 通过工具 |
| **多模型** | Claude only | 多模型 | Claude/GPT | 多模型 | 多模型 | 多模型 |
| **多 agent** | Subagent | 无 | 无 | Agent Canvas | 无 | 原生支持 |
| **可观测性** | 内置 | 内置 | 内置 | OTel | 基础 | OTel |
| **开源** | 部分 | 否 | 否 | 是(MIT) | 是(MIT) | 是(MIT) |

### 工程师可立即执行的动作清单

1. 选择与你场景最接近的 harness 设计作为起点，不要从零开始。
2. 如果你构建 coding agent，研究 Claude Code 的五层扩展体系和 Cursor 的 Rules/Skills 分离。
3. 如果你需要长时程运行，研究 Anthropic 的 progress file + git 模式。
4. 如果你需要多 agent 协作，研究 LangGraph 的 StateGraph 模式。
5. 无论你选择哪种方案，确保 harness 是可组合的——每个组件都可以独立替换。

---

## 第8章 工程实现细节

### 8.1 沙箱技术选型

**沙箱技术对比表（2026 年最新）**：

| 技术 | 隔离方式 | 冷启动 | 安全级别 | 适用场景 | 开源 |
|------|---------|--------|---------|---------|------|
| **Firecracker microVM** | 独立内核的 microVM | 本体官方 ~125ms；SPACE 实测 60-89ms（median/p90）【已核实】 | 最高 | 生产 agent 环境 | Apache 2.0 |
| **E2B** | Firecracker microVM | ~150ms（快照恢复口径 150-170ms；standby <25ms）【已核实】 | 最高 | 商业 agent 平台 | Apache 2.0 |
| **Perplexity SPACE** | Firecracker microVM | ~60ms | 最高 | 自托管 agent 沙箱 | Apache 2.0 |
| **gVisor** | 用户态内核 | 官方基准约 1.1-2.5s（经 Docker，与 runc 同量级）；无官方毫秒级口径 | 高 | 兼容现有 Docker 生态的场景 | Apache 2.0 |
| **Docker 容器** | 共享内核 | ~1-3s | 中 | 开发环境 | Apache 2.0 |
| **Daytona** | Docker/VM | 官方自述 <90ms（2026-06 起核心转私有、开源仓归档）【已核实】 | 中-高 | 开发者友好型 | AGPL-3.0 |

**关键发现**（Perplexity SPACE 红队测试，2026 年 9 月）：
- 9 个模型在 guest 内拥有 root 权限
- 216 次运行
- VM 逃逸：0/108 次到达 host 侧密钥
- 网络策略绕过（修复前）：11/54 次成功
- 网络策略绕过（修复后）：0 次验证成功
- 10 个第三方平台中 8 个存在至少一个网络策略绕过

**选型建议**：
- 生产环境：Firecracker microVM（E2B 或 SPACE）
- 快速原型：Docker + 网络限制
- 需要 GPU：Modal 或 Daytona

### 8.2 工具接口设计

**Function Calling Schema 最佳实践**：

```json
{
  "name": "search_codebase",
  "description": "Search the codebase for relevant code snippets. Returns ranked results with file path, line numbers, and matched content.",
  "parameters": {
    "type": "object",
    "properties": {
      "query": {
        "type": "string",
        "description": "Natural language description of what you're looking for"
      },
      "file_pattern": {
        "type": "string",
        "description": "Glob pattern to filter files (e.g., '*.py'). Optional."
      },
      "max_results": {
        "type": "integer",
        "description": "Maximum number of results to return. Default: 10, max: 50.",
        "default": 10
      }
    },
    "required": ["query"]
  }
}
```

**MCP Server 实现要点**：
1. 按意图分组工具，不要 1:1 映射 API
2. 使用 tool search 进行渐进式加载
3. 在 server 端处理大数据结果，只返回摘要
4. 实现 Elicitation（中途询问用户输入）和 Form mode（渲染表单）

### 8.3 成本与延迟工程

**成本优化策略**：

| 策略 | 节省幅度 | 实现复杂度 |
|------|---------|-----------|
| Prompt Caching | 最高 90%（官方口径 up to 90%：缓存读价为原输入价 10%，官方实测 -53%~-90%） | 低 |
| 模型分级（简单任务用小模型） | 约 50-80%（估算值；第三方路由基准 LiteLLM ~58% 等） | 中 |
| 上下文压缩 | 长任务成本降低 50%+（估算值；token 节省≠账单节省，实际可能更低） | 中 |
| 并行工具调用 | 30-50% 延迟降低（估算值，未检索到公开信源） | 低 |
| Tool Result 截断 | 20-40%（估算值；实测研究显示截断对账单成本收益可能为负） | 低 |
| 程序化工具结果处理 | ~37%（Anthropic 官方实测：43,588→27,297 tokens，复杂研究任务） | 中 |

### 8.4 测试一个 Harness

**这是多数团队的盲区**。Harness 的测试需要覆盖三个层面：

| 测试层面 | 测试内容 | 方法 |
|---------|---------|------|
| **单元测试** | 每个组件的独立功能 | Mock 模型和环境，测试工具注册、上下文压缩、权限检查 |
| **集成测试** | 组件间的交互 | 使用固定模型响应，测试完整循环 |
| **端到端测试** | 整体系统行为 | 在真实任务上运行，比较不同 harness 配置的性能 |

**关键测试场景**：
1. 模型返回格式错误的工具调用 → 是否正确重试？
2. 工具执行超时 → 是否正确处理？
3. 上下文窗口即将耗尽 → 是否触发压缩？
4. 连续 5 次无进展 → 是否终止？
5. 沙箱崩溃 → 是否能从 checkpoint 恢复？

### 工程师可立即执行的动作清单

1. 生产环境使用 Firecracker microVM 沙箱（E2B 或 SPACE）。
2. 实现 prompt caching 和模型分级——这是 ROI 最高的成本优化。
3. 为你的 harness 编写测试——至少覆盖 §8.4 中的 5 个关键场景。
4. 使用 OTel GenAI 语义约定记录 token 使用和延迟——你需要数据来做成本优化决策。

---

## 第9章 Harness 与 AI Agent 的区别与联系

### 9.1 层次关系

```
┌─────────────────────────────────────────────────┐
│                   AI AGENT                       │
│  (一个能自主完成任务的完整系统)                      │
│                                                  │
│  ┌─────────────────────────────────────────┐     │
│  │            AGENT HARNESS                 │     │
│  │  (将模型转化为 agent 的运行时基础设施)      │     │
│  │                                          │     │
│  │  ┌─────────────────────────────────┐     │     │
│  │  │        LANGUAGE MODEL            │     │     │
│  │  │  (推理引擎：文本输入 → 文本输出)   │     │     │
│  │  │                                  │     │     │
│  │  │  输入: context window            │     │     │
│  │  │  输出: text + tool calls         │     │     │
│  │  └─────────────────────────────────┘     │     │
│  │                                          │     │
│  │  + 主循环    + 工具注册    + 上下文管理    │     │
│  │  + 状态持久化 + 权限控制    + 错误恢复     │     │
│  │  + 可观测性  + 评测钩子                   │     │
│  └─────────────────────────────────────────┘     │
│                                                  │
│  + 用户界面  + 业务逻辑  + 领域知识               │
│  + 外部系统集成  + 组织流程                       │
└─────────────────────────────────────────────────┘
```

**一句话定义对比**：
- **Model**：接收文本、生成文本的推理引擎
- **Harness**：包裹模型、驱动循环、管理上下文的运行时脚手架
- **Agent**：Model + Harness + 业务逻辑 构成的完整自主系统

### 9.2 职责对比表

| 维度 | Harness | Agent |
|------|---------|-------|
| **定义** | 运行时基础设施 | 完整的自主系统 |
| **是否包含模型** | 否（包裹模型） | 是（= model + harness + 更多） |
| **是否有自主性** | 否（执行预定义的循环逻辑） | 是（自主决策下一步行动） |
| **是否可独立运行** | 否（需要模型 + 任务） | 是（给定任务后可自主运行） |
| **是否可替换** | 是（同一 agent 可以换 harness） | 否（agent 是特定实例） |
| **生命周期** | 随任务创建和销毁 | 可能持续运行很长时间 |
| **失败模式** | 循环卡死、上下文溢出、工具调用失败 | 目标偏离、决策错误、成本失控 |
| **调试对象** | 循环逻辑、工具注册、上下文策略 | 决策质量、任务完成度、用户体验 |
| **责任人** | harness 开发者/平台团队 | agent 部署者/产品团队 |
| **评测方式** | 基准测试（SWE-bench 等）、组件测试 | 端到端任务完成率、用户满意度 |
| **成本结构** | 主要是基础设施成本 | 模型推理成本 + 工具调用成本 + 基础设施成本 |
| **关注焦点** | 「如何让模型更可靠地执行」 | 「如何让任务更高质量地完成」 |
| **可复用性** | 高（同一 harness 可用于不同任务） | 低（每个 agent 实例通常对应特定任务） |
| **与用户的关系** | 间接（用户不直接与 harness 交互） | 直接（用户向 agent 下达任务） |

### 9.3 三个类比的严格检验

#### 类比 1：马与挽具

| 方面 | 是否成立 | 说明 |
|------|---------|------|
| 力量来自马/模型 | ✅ | 模型提供推理能力，马提供物理力量 |
| 方向由挽具/harness 控制 | ✅ | harness 决定模型的能力如何被使用 |
| 马没有挽具无法拉车 | ✅ | 模型没有 harness 无法自主行动 |
| 挽具没有马无法工作 | ✅ | harness 没有模型是空壳 |
| 马可以自我修改挽具 | ❌ | **类比失效**：LLM 可以编写自己的工具和 prompt |
| 挽具的设计与马无关 | ❌ | **类比失效**：harness 设计必须适配特定模型的特性 |

#### 类比 2：引擎与底盘

| 方面 | 是否成立 | 说明 |
|------|---------|------|
| 引擎提供动力 | ✅ | 模型提供推理动力 |
| 底盘传递和控制动力 | ✅ | harness 传递和控制模型的输出 |
| 同一引擎可以装在不同底盘上 | ✅ | 同一模型可以用于不同 harness |
| 同一底盘可以装不同引擎 | ✅ | 同一 harness 可以换不同模型 |
| 引擎可以重新设计底盘 | ⚠️ 部分成立 | 模型进步可以导致 harness 结构变化（如 context reset 变得不必要） |
| 引擎和底盘完全独立 | ❌ | **类比失效**：模型和 harness 需要协同设计 |

#### 类比 3：演员与舞台

| 方面 | 是否成立 | 说明 |
|------|---------|------|
| 演员表演/模型推理 | ✅ | 模型在 harness 提供的框架内工作 |
| 舞台提供表演空间 | ✅ | harness 提供工具、上下文和环境 |
| 舞台设计影响表演质量 | ✅ | harness 设计直接影响 agent 表现 |
| 同一演员在不同舞台表现不同 | ✅ | 同一模型在不同 harness 下表现差异巨大 |
| 演员可以改造舞台 | ⚠️ 部分成立 | 模型可以在 harness 内创建新工具，但不能改变 harness 本身 |
| 观众只看到演员 | ✅ | 用户看到的是 agent，不是 harness |

### 9.4 Agency 的归属问题：分层归因模型

**核心问题**：自主性（agency）到底是模型给的还是 harness 给的？

**答案**：两者都贡献，但在不同层面。

```
┌─────────────────────────────────────────────────────────┐
│              Agency 的分层归因模型                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Layer 4: 创造力与适应性                                  │
│  ┌─────────────────────────────────────────────────┐    │
│  │ 来源: 模型为主                                    │    │
│  │ 表现: 处理未预见的情况、创造性解决问题               │    │
│  │ 示例: 遇到新 bug 时的创新修复策略                    │    │
│  └─────────────────────────────────────────────────┘    │
│                                                         │
│  Layer 3: 规划与决策                                     │
│  ┌─────────────────────────────────────────────────┐    │
│  │ 来源: 模型 + Harness 共同贡献                      │    │
│  │ 模型贡献: 推理能力、任务理解                        │    │
│  │ Harness 贡献: Plan-Execute 结构、选项生成           │    │
│  └─────────────────────────────────────────────────┘    │
│                                                         │
│  Layer 2: 行动与工具使用                                  │
│  ┌─────────────────────────────────────────────────┐    │
│  │ 来源: Harness 为主                                │    │
│  │ 表现: 能调用什么工具、如何调用、结果如何呈现          │    │
│  │ 示例: SWE-agent 的 ACI 设计直接决定编辑能力         │    │
│  └─────────────────────────────────────────────────┘    │
│                                                         │
│  Layer 1: 基础推理能力                                    │
│  ┌─────────────────────────────────────────────────┐    │
│  │ 来源: 模型独有                                     │    │
│  │ 表现: 理解语言、逻辑推理、代码理解                    │    │
│  │ Harness 无法提供这一层                              │    │
│  └─────────────────────────────────────────────────┘    │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

**关键洞察**：
- **底层（推理能力）完全由模型决定**——harness 无法让一个不懂代码的模型变成编码高手
- **中层（行动能力）主要由 harness 决定**——同一模型在不同 harness 下的行动能力差异巨大
- **高层（创造力）主要由模型决定**——但好的 harness 可以通过提供更好的上下文来激发创造力

### 9.5 实践含义：优化模型还是优化 Harness？

**决策树**：

```
Agent 表现不佳
    │
    ├── 模型无法理解任务描述？
    │   └── 是 → 换更强的模型
    │
    ├── 模型理解任务但选错工具？
    │   └── 是 → 改进工具描述 + 优化 harness 的工具注册
    │
    ├── 模型选对工具但执行失败？
    │   └── 是 → 改进沙箱环境 + 错误恢复机制
    │
    ├── 模型执行成功但上下文丢失？
    │   └── 是 → 改进上下文管理（压缩、检索）
    │
    ├── 模型中途迷失方向？
    │   └── 是 → 添加 Plan-Execute 结构 + 进度追踪
    │
    ├── 模型过早宣布完成？
    │   └── 是 → 添加客观验证标准（测试、检查清单）
    │
    └── 成本过高？
        └── 是 → 上下文压缩 + 模型分级 + prompt caching
```

**经验法则**：
1. **先优化 harness，再考虑换模型**——成本更低、效果往往更好
2. **如果模型在裸提示下就无法理解任务，那是模型问题**——harness 无法弥补基础推理能力的缺失
3. **如果模型能理解任务但执行不好，那是 harness 问题**——优化上下文、工具和反馈循环
4. **每次模型升级后重新评估 harness**——一些补偿逻辑可能变得不再必要

### 9.6 常见误解澄清

| # | 误解 | 事实 | 证据 |
|---|------|------|------|
| 1 | 换个更强的模型就能解决 agent 不好用 | 模型只是因素之一；好 harness + 中等模型可能优于差 harness + 强模型 | Agentless 在 Claude 3.5 Sonnet 上达到 32%，同期复杂 agent 系统更低 |
| 2 | Harness 越复杂越强 | 简单三阶段 harness（Agentless）可以打败复杂 agent harness | Agentless vs SWE-agent 对比 |
| 3 | 框架就是 Harness | Framework 是构建 harness 的工具箱，harness 是用它组装出来的运行时系统 | LangChain 是 framework，SWE-agent 是 harness |
| 4 | Harness 只是一组 prompt | Harness 是运行中的软件，包含循环、工具执行、上下文管理、权限控制 | Anthropic: "The harness is what runs that loop" |
| 5 | 模型升级后 Harness 不再重要 | Harness 仍然重要，但具体设计需要调整 | Anthropic: "harnesses encode assumptions that go stale" |
| 6 | Harness、Scaffold、Runtime 是完全不同的东西 | 它们高度重叠，经常互换使用；scaffold 在学术文献中常用，runtime 强调生产执行，harness 通常指完整的集成包 | LangChain 文档、BasicsOf.AI |
| 7 | Agent 的能力是模型的固有属性 | Agency 是 model + harness 的涌现属性，不是模型单独具备的 | 同一模型不同 harness 的性能差异 |

### 工程师可立即执行的动作清单

1. 使用 §9.5 的决策树诊断你的 agent 问题——先确定是模型问题还是 harness 问题。
2. 向团队分享 §9.6 的误解澄清表——统一对 harness 和 agent 的理解。
3. 在评估模型升级时，同时评估 harness 需要哪些调整。
4. 建立「harness 性能基准」——用固定任务集持续测量 harness 变更的影响。

---

## 第10章 企业场景：Harness 如何约束 Agent 的权限与副作用

### 10.1 工具白名单与能力边界

**设计原则**：最小权限原则（Principle of Least Privilege）

```python
class CapabilityModel:
    """基于角色的能力模型"""
    
    ROLES = {
        "read_only": {
            "allowed_tools": ["search", "read_file", "list_directory"],
            "denied_tools": ["write_file", "execute", "delete", "network"],
        },
        "developer": {
            "allowed_tools": ["search", "read_file", "write_file", "execute", "test"],
            "denied_tools": ["delete_production", "network_external", "modify_config"],
            "requires_approval": ["install_dependency", "modify_schema"],
        },
        "admin": {
            "allowed_tools": ["*"],  # 所有工具
            "requires_approval": ["deploy", "delete_production"],
        }
    }
```

### 10.2 审批门设计

**三级审批模型**：

| 级别 | 触发条件 | 审批方式 | 示例 |
|------|---------|---------|------|
| **自动批准** | 低风险操作 | 无需人工 | 读取文件、搜索代码、运行单元测试 |
| **Standing Approval** | 中风险、已预授权 | 用户预设规则 | 编辑指定目录的文件、运行 lint |
| **实时审批** | 高风险操作 | 暂停等待人工确认 | 部署到生产、删除数据、发送外部请求 |

### 10.3 审计日志

每条 agent 操作必须记录：
- 时间戳
- Session ID
- 模型名称和版本
- Harness 版本
- 操作类型（工具调用/模型推理/状态变更）
- 操作详情（工具名、参数、结果）
- 权限检查结果
- Token 消耗

### 10.4 工业设备运维场景的完整 Harness 设计示例

```
┌──────────────────────────────────────────────────────────────┐
│               工业设备运维 Agent Harness 架构                │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌────────────┐    ┌────────────────────────────────────┐    │
│  │            │    │              HARNESS               │    │
│  │ 运维工程师 │ <->│  ┌────────────┐  ┌──────────────┐  │    │
│  │ (人类)     │    │  │ 主循环     │  │ 上下文管理   │  │    │
│  └────────────┘    │  │ (ReAct)    │  │ 设备知识图谱 │  │    │
│                    │  └─────┬──────┘  │ 历史故障案例 │  │    │
│  ┌────────────┐    │        │         │ 运维规程手册 │  │    │
│  │ 工单系统   │ <->│  ┌─────┴──────┐  └──────────────┘  │    │
│  │ (CMDB)     │    │  │ 工具注册表 │                    │    │
│  └────────────┘    │  └─────┬──────┘                    │    │
│                    │        │                           │    │
│  ┌────────────┐    │  ┌─────┴──────┐                    │    │
│  │ 监控系统   │ <->│  │ 权限层 +   │                    │    │
│  │ (SCADA)    │    │  │ 审批门     │                    │    │
│  └────────────┘    │  └────────────┘                    │    │
│                             │                                │
│  ┌──────────────────────────┴─────────────────────────────┐  │
│  │                       安全执行层                       │  │
│  │                                                        │  │
│  │  只读命令       受控写入       审批操作       禁止操作 │  │
│  │  查询日志       修改配置       重启设备       删除DB   │  │
│  │  读取传感器     更新工单       修改规程                │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

**权限矩阵**：

| 操作 | 读取诊断 | 配置修改 | 设备控制 | 数据删除 |
|------|---------|---------|---------|---------|
| 查询设备状态 | ✅ 自动 | — | — | — |
| 读取传感器数据 | ✅ 自动 | — | — | — |
| 搜索知识图谱 | ✅ 自动 | — | — | — |
| 修改设备参数 | — | ⚠️ 需审批 | — | — |
| 重启设备 | — | — | ⚠️ 需审批+双人确认 | — |
| 删除历史数据 | — | — | — | ❌ 禁止 |
| 更新运维规程 | — | ⚠️ 需审批 | — | — |

### 工程师可立即执行的动作清单

1. 为你的 agent 实现基于角色的能力模型（Capability Model）——明确哪些工具在每个角色下可用。
2. 实现三级审批模型——自动批准、Standing Approval、实时审批。
3. 所有 agent 操作必须写入不可篡改的审计日志。
4. 在工业控制场景中，agent 只能读取和诊断，任何控制操作必须经过人类确认。

---

## 第11章 书单与免费资源

### 关于获取方式的说明

本报告只给官方合法免费资源与官方购买入口，不提供盗版下载链接。所有资源分为三类：

- **A 类**：官方合法免费书籍（作者/出版社官方免费 PDF 或在线全文）
- **B 类**：商业出版物（给出版社官网页面 + 是否有官方免费样章）
- **C 类**：官方免费技术指南/论文/课程

**事实判断**：harness 这个细分方向目前尚无权威专著。最好的材料是 Anthropic/OpenAI 的官方工程指南、关键学术论文和高质量的开源教科书。以下资源按此现实组织。

### A 类：官方合法免费资源

| # | 名称 | 作者 | 出版方 | 年份 | 为什么值得读 | 适合谁 | 获取方式 |
|---|------|------|--------|------|------------|--------|---------|
| A1 | 《深入理解 AI Agent：设计原理与工程实践》 | 李博杰 (Bojie Li) | 开源 (Apache 2.0) | 2026 | 10 章完整教科书，核心命题 Agent = LLM + Context + Tools，harness engineering 作为核心竞争力。GitHub 57.3k+ stars（2026-11-06 实测 57,275） | 所有 agent 开发者 | https://github.com/bojieli/ai-agent-book (免费 PDF + 代码) |
| A2 | "Effective Harnesses for Long-Running Agents" | Justin Young et al. | Anthropic Engineering Blog | 2025 | 长时程 agent harness 设计的开创性文章，两 agent 系统、progress file、feature list 等核心模式 | agent 平台开发者 | https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents |
| A3 | "Harness Design for Long-Running Application Development" | Anthropic Engineering | Anthropic Engineering Blog | 2026 | 三 agent 架构（Planner/Generator/Evaluator），sprint contract 模式 | 全栈开发 agent 开发者 | https://www.anthropic.com/engineering/harness-design-long-running-apps |
| A4 | "Scaling Managed Agents: Decoupling the Brain from the Hands" | Anthropic Engineering | Anthropic Engineering Blog | 2026 | meta-harness 设计，brain/hands 解耦，安全架构 | 架构师 | https://www.anthropic.com/engineering/managed-agents |
| A5 | "Building Agents That Reach Production Systems with MCP" | Anthropic | Anthropic Blog | 2026 | MCP 工具设计最佳实践，三种连接 agent 与外部系统的方式 | MCP server 开发者 | https://claude.com/blog/building-agents-that-reach-production-systems-with-mcp |
| A6 | "Best Practices for Coding with Agents" | Cursor Team | Cursor Blog | 2026 | agent harness 三组件（Instructions/Tools/Model），Plan Mode，Rules vs Skills | Cursor 用户、coding agent 开发者 | https://cursor.com/blog/agent-best-practices |
| A7 | Agent Harness 概念文档 | Microsoft | Microsoft Learn | 2026 | Microsoft Agent Framework 的 harness 定义和实现，create_harness_agent API | .NET/Python/Go 开发者 | https://learn.microsoft.com/en-za/agent-framework/concepts/harness |
| A8 | "Context Engineering for AI Agents" | Zylos Research | Zylos Research | 2026 | Context Engineering 的系统性综述，结构化摘要蒸馏（token 用量最多降 80%）与五层记忆架构，多 agent 上下文协调 | agent 架构师 | https://zylos.ai/research/2026-06-26-context-engineering-ai-agents-production-discipline/ |
| A9 | "The Hitchhiker's Guide to Agentic AI: From Foundations to Systems" | Haggai Roitman | arXiv | 2026 | 全栈 agent 系统参考，从 LLM 基础到生产部署，包含 harness 设计和 MCP/A2A | 想要全面了解的工程师 | https://arxiv.org/abs/2606.24937 |

### B 类：商业出版物

| # | 名称 | 作者 | 出版方 | 年份 | 为什么值得读 | 适合谁 | 获取方式 |
|---|------|------|--------|------|------------|--------|---------|
| B1 | 《An Illustrated Guide to AI Agents》 | Jay Alammar & Maarten Grootendorst | O'Reilly Media | 2026 | 300+ 原创图表，475 页，涵盖工具、记忆、规划、多 agent、评估。Alammar 是 "The Illustrated Transformer" 作者 | 视觉学习者、入门者 | O'Reilly 官网购买，电子书 $79.99 |
| B2 | 《Designing Multi-Agent Systems》 | Victor Dibia | 自出版（multiagentbook.com / Amazon；作者自述原与 Manning 合作取消） | 2025 | 15 章，从零构建多 agent 框架，包含 OpenTelemetry、MCP/A2A、human-in-the-loop | 多 agent 系统开发者 | multiagentbook.com 或 Amazon 购买，GitHub 仓库 victordibia/designing-multiagent-systems（约 290+ 个 Python 文件，2026-11 计数） |
| B3 | 《Build a Reasoning Model (From Scratch)》 | Sebastian Raschka | Manning | 2026 | 从零训练推理模型，包含 GRPO 训练循环。不是 agent 书，但帮助你理解模型端 | 想了解模型训练的工程师 | Manning 官网购买（ISBN 9781633434677，440 页），GitHub 仓库 rasbt/reasoning-from-scratch（116 个 Python/Notebook 文件，2026-11 计数） |
| B4 | 《Building AI Agents That Actually Work with DeepSeek Harness》 | Steve Publications | Leanpub | 2026 | 以 DeepSeek Harness 为例的 agent 工程指南，从 30 行脚本到生产级服务 | 想要具体实现指导的工程师 | Leanpub 购买，$25-35 |

### C 类：关键学术论文（免费）

| # | 名称 | 作者 | 发表 | 年份 | 为什么值得读 | 获取方式 |
|---|------|------|------|------|------------|---------|
| C1 | "ReAct: Synergizing Reasoning and Acting in Language Models" | Yao et al. | ICLR 2023 (Oral, top 5%) | 2023 | agent loop 的奠基论文 | https://arxiv.org/abs/2210.03629 |
| C2 | "SWE-agent: Agent-Computer Interfaces Enable Automated Software Engineering" | Yang et al. | NeurIPS 2024 | 2024 | ACI 设计，interface design 对 agent 性能的影响 | https://arxiv.org/abs/2405.15793 |
| C3 | "Reflexion: Language Agents with Verbal Reinforcement Learning" | Shinn et al. | NeurIPS 2023 | 2023 | 语言反馈的自我改进机制 | https://arxiv.org/abs/2303.11366 |
| C4 | "Cognitive Architectures for Language Agents" (CoALA) | Sumers, Yao et al. | TMLR 2024 | 2024 | LLM agent 的认知架构理论框架 | https://arxiv.org/abs/2309.02427 |
| C5 | "Agentless: Demystifying LLM-based Software Engineering Agents" | Xia et al. | Proc. ACM Softw. Eng. 2025 | 2024 | 简单三阶段打败复杂 agent | https://arxiv.org/abs/2404.05427 |
| C6 | "Voyager: An Open-Ended Embodied Agent with Large Language Models" | Wang et al. | TMLR 2024 | 2023 | Skill library 和终身学习 | https://arxiv.org/abs/2305.16291 |
| C7 | "Executable Code Actions Elicit Better LLM Agents" (CodeAct) | Wang et al. | ICML 2024 | 2024 | 代码作为统一动作空间 | https://arxiv.org/abs/2402.01030 |
| C8 | "The OpenHands Software Agent SDK" | Wang et al. | arXiv:2511.03690 | 2025 | 完整的开源 coding agent SDK 设计 | https://arxiv.org/abs/2511.03690 |
| C9 | "AI Harness Engineering: A Runtime Substrate for Foundation-Model Software Agents" | Zhong & Zhu | arXiv:2605.13357 | 2026 | harness 的工程化框架 | https://arxiv.org/abs/2605.13357 |
| C10 | "Engineering and Governing the Agent Harness" | Liu | UNU | 2026 | harness 的技术与政策框架 | https://unu.edu/sites/default/files/2026-07/Engineering_and_Governing_the_Agent_Harness.pdf |
| C11 | "Better Harnesses, Smaller Models: Building 90% Cheaper Agents via Automated Harness Adaptation" | Yang et al. | arXiv | 2026 | 自动 harness 优化 | arXiv:2607.08938【已核实 2026-11-06】 |
| C12 | "Pairing Matters: Performance, Failures, and Efficiency in Lightweight Coding Agents" | Zhao et al. | arXiv | 2026 | harness-model 配对的失败模式分析 | arXiv:2610.32131【已核实 2026-11-06】 |
| C13 | "Generative Agents: Interactive Simulacra of Human Behavior" | Park et al. | UIST 2023 | 2023 | 记忆架构设计 | https://arxiv.org/abs/2304.03442 |
| C14 | "Tree of Thoughts: Deliberate Problem Solving with Large Language Models" | Yao et al. | NeurIPS 2023 (Oral) | 2023 | 搜索式推理 | https://arxiv.org/abs/2305.10601 |
| C15 | "SWE-bench: Can Language Models Resolve Real-World GitHub Issues?" | Jimenez et al. | ICLR 2024 (Oral) | 2024 | 评测基准设计 | https://arxiv.org/abs/2310.06770 |

### 三条按工程师成长阶段的阅读路径

**路径 1：入门（0-3 个月）**
1. 李博杰《深入理解 AI Agent》A1 → 建立整体概念框架
2. ReAct 论文 C1 → 理解 agent loop 的基础
3. Anthropic "Effective Harnesses" A2 → 理解长时程 harness 的核心模式
4. Cursor "Best Practices" A6 → 实践中的 harness 设计

**路径 2：进阶（3-12 个月）**
1. CoALA 论文 C4 → 认知架构理论基础
2. SWE-agent 论文 C2 + Agentless 论文 C5 → 对比复杂 vs 简单 harness
3. Anthropic 三篇博客 A2/A3/A4 → 长时程 harness 的完整方法论
4. OpenHands SDK 论文 C8 → 生产级 harness 架构
5. Context Engineering 综述 A8 → 上下文管理的系统知识

**路径 3：高级（12+ 个月）**
1. AI Harness Engineering 论文 C9 + UNU 政策框架 C10 → harness 的工程化与治理
2. MCP 协议文档 A5 → 标准化工具接口
3. Better Harnesses Smaller Models C11 → harness 自动优化
4. Pairing Matters C12 → harness-model 交互的失败分析
5. 跟踪 Anthropic/OpenAI/Google 的最新博客 → 保持前沿

### 工程师可立即执行的动作清单

1. 从路径 1 开始阅读——一周内可以建立完整的 harness 知识框架。
2. 下载李博杰的教科书（A1）——这是目前最完整的开源 agent 教材。
3. 精读 Anthropic 的三篇 harness 博客（A2/A3/A4）——这是长时程 harness 设计的最佳实践来源。
4. 运行 OpenHands 或 SWE-agent 的源代码——通过代码理解 harness 设计。

---

## 第12章 趋势与判断

### 12.1 Harness 会不会成为独立产品层？

**判断：是的，而且正在发生。**

证据：
- Microsoft Agent Framework 提供 `create_harness_agent()` 工厂函数
- Anthropic 的 Managed Agents 将 harness 作为独立服务提供
- OpenHands 将架构分为 Harness → Orchestrator → Control Plane 三层
- DeepSeek 发布了专门的 DeepSeek Harness（MIT 协议）
- 多本书以 harness 为主题出版（B4）

**预测**：到 2027 年，主要的 AI 平台都会提供「harness-as-a-service」，开发者只需要关注业务逻辑和工具定义。

### 12.2 Harness 标准化（MCP/A2A/AG-UI）的进展与阻碍

**进展**：
- MCP：SDK 月下载量 2025-12 官方披露 9700 万+，2026-07 Anthropic 官宣 4 亿次以上【已核实】，成为事实标准
- MCP 2026-07-28 规范：无状态核心、标准化扩展、强化认证
- A2A（Agent-to-Agent）：Google 发起，Linux Foundation 托管
- AG-UI：前端与 agent 交互的协议

**阻碍**：
- 语义对齐问题：agent 之间对共享事实的含义难以达成一致
- 安全问题：跨组织 agent 通信的信任建立
- 向后兼容：新旧规范的过渡

### 12.3 模型-Harness 协同设计（Co-design）的趋势

**趋势**：不再先训练模型再设计 harness，而是两者协同优化。

**证据**：
- OpenHands LM 32B：专门为 OpenHands harness 微调的模型
- Qwen3-Coder-Next：3B 激活参数的编码 agent 专用模型
- Anthropic 发现模型行为随版本变化，harness 需要适配

**预测**：未来的模型训练会考虑 harness 的使用模式，harness 设计也会考虑模型的特性。

### 12.4 Harness 的护城河问题

**问题**：开源 harness 普及后，差异化在哪里？

**答案**：
1. **组织级知识资产**：CLAUDE.md、rules、skills 等积累的领域知识
2. **工具生态**：MCP server 的数量和质量
3. **评测与调优能力**：自动化 harness 优化的能力
4. **安全与合规**：企业级的权限控制和审计能力
5. **模型-Harness 协同**：针对特定模型深度调优的 harness

### 12.5 未来 12 个月值得关注的 8 个方向

| # | 方向 | 为什么重要 | 当前成熟度 |
|---|------|-----------|-----------|
| 1 | 自动 Harness 优化 | 让 harness 自动适配模型和任务 | 早期研究 |
| 2 | Harness 级别的 OTel 标准化 | 统一的 agent 可观测性 | 发展中 |
| 3 | 跨 Harness 的状态迁移 | agent 在不同 harness 间无缝切换 | 概念阶段 |
| 4 | 模型-Harness Co-design | 模型训练考虑 harness 使用模式 | 早期实践 |
| 5 | Harness 安全审计工具 | 自动化检查 harness 的安全漏洞 | 需要 |
| 6 | 多 Agent Harness 协调 | 多个 harness 之间的资源调度 | 早期研究 |
| 7 | Harness 的评测标准化 | 统一 harness 能力的度量方法 | 需要 |
| 8 | 边缘计算上的 Agent Harness | 在设备端运行的轻量 harness | 早期探索 |

### 工程师可立即执行的动作清单

1. 关注 MCP 2026-07-28 规范的实施进展——它定义了工具层的未来。
2. 开始积累组织级的 harness 知识资产（CLAUDE.md、rules、skills）——这是未来的护城河。
3. 实验自动 harness 优化——让你的 harness 能根据失败模式自动调整配置。
4. 投资 agent 可观测性基础设施——OTel GenAI 语义约定将成为标准。

---

## 第13章 补充调研（2026-11 增补）

### 13.1 Agent 安全威胁模型（初版只有权限与沙箱，缺「授权外怎么攻」）

| 威胁 | 机制 | 原始出处 |
|------|------|---------|
| 直接注入（Direct Prompt Injection） | 恶意指令拼入用户输入 | Simon Willison, 2022-09-12（术语命名） |
| 间接注入（Indirect） | 指令埋进 agent 会检索的外部内容（网页/邮件/工具结果），无需接触用户 | Greshake et al., arXiv:2302.12173（ACM AISec 2023） |
| 工具投毒（Tool Poisoning） | 恶意 MCP server 在工具 description 内嵌恶意指令——模型可见、用户界面不显示；可 shadow 正当工具跨服务器外泄 | Invariant Labs, 2025-04-01 |
| Rug Pull | 审定后静默改工具定义（Day 1 批准的工具 Day 7 改道） | Invariant Labs《WhatsApp MCP Exploited》2025-04-07 等 |
| Confused Deputy | agent 被诱导滥用自身权限 | Willison dual-LLM 2023；MCP 官方规范安全专节（2026-07-28 版设 Confused Deputy Problem） |
| 沙箱逃逸 | 零点击注入→扩大沙箱可写面→符号链接缺陷→OS 级 RCE | DuneSlide（Cursor 两枚 CVSS 9.8，Cato 2026-07-01）；EchoLeak（M365 Copilot 零点击外泄，CVE-2025-32711，MSRC critical） |

**缓解模式**：dual-LLM（特权 LLM 无污染内容、隔离 LLM 无工具、受控变量回传，Willison 2023-04-25）；Google DeepMind CaMeL（arXiv:2503.18813，by-design 控制/信息流）；Anthropic 浏览器注入缓解（RL 内化＋全量不可信内容分类器扫描＋大规模红队，自适应 Best-of-N 攻击下 Opus 4.5 ASR 1.4%【厂商自报】，2025-11-24）。

**标准与工程对照**：OWASP LLM Top 10（2025 版，2024-11-18）→ Agentic Security Initiative（2024-12-15 设立）→《Agentic AI – Threats and Mitigations》v1.1（2025-12）→《OWASP Top 10 for Agentic Applications for 2026》（2025-12-09）。工程侧可直接对照 Claude Code 官方安全页：沙箱化 Bash、curl/wget 等取网命令默认不自动批准、.mcp.json 服务器独立信任确认、命令注入检测 fail-closed。**设计含义**：初版 §4.5 与第10章的权限矩阵是第一道门；工具结果按不可信输入隔离（dual-LLM/CaMeL 式）是必须补的第二道门；MCP server 供应链校验（官方 Registry＋MCP-Scan 类扫描器）是第三道门。

### 13.2 评测基准生态（SWE-bench 之外）

| 基准 | 出品方 | 任务形态 | SOTA 量级（【厂商/榜单自报】，快照 2026-11） |
|------|--------|---------|------|
| Terminal-Bench 4.0 | Laude Institute×Stanford（ICLR 2026 论文） | 真实容器内端到端终端任务 | TB2.0 榜首 84.7% 已饱和归档；TB3.0 最佳约 34% |
| SWE-bench Pro V2 | Scale AI×Reflection（2025-09 首发） | 长时程软件工程，网络锁定协议 | 公共榜 Opus 5 99.4%，同模型私有集 81.6% |
| Multi-SWE-bench | 字节跳动 Seed（2025-04） | 多语言 issue 修复（7 语言 1,632 实例） | 榜首 21.62%（官方榜 2025-04 后未更新） |
| SWE-Lancer | OpenAI（2025-02，ICML 2025） | 1,400+ 真实自由职业任务、百万美元计价 | Diamond 子集 o1 $45,625 / 28.4% |
| OSWorld-Verified | XLANG Lab（2025-07） | 真实计算机环境 369 任务 | 榜首 86.0%（2026-08） |
| GAIA | Meta FAIR+HF+AutoGPT（2023-11） | 通用助手 450 题（HAL 托管） | 74.55%（HAL 验证） |
| τ²-bench | Sierra（2025-06） | 工具-代理-用户三方 dual-control | 87.9% pass^1 |
| BrowseComp | OpenAI（2025-04） | 1,266 道极难浏览事实题 | 官方榜与第三方聚合读数差异数倍（口径分裂典型） |

**「模型+harness 联合评测」口径争议与标准化进展**（初版 §3.4 的直接后续）：Vector Institute《Harness-Aware Evaluation》（2026-09）提出 Model/Harness/Environment/Evaluator 四因子框架；arXiv:2610.00651 对 HAL+Harbor 22 个基准做贝叶斯方差分解——固定「模型+scaffold」系统排名可靠性 0.935-0.994，归因到底层模型时降至 0.148-0.841；SWE-bench 提交清单已强制披露 harness/模型/attempts 并只认 Pass@1；普林斯顿 HAL 提供统一第三方 harness 与加密轨迹；METR 用固定公开 scaffold（Triframe/ReAct）测 time horizon。**结论：截至 2026-11 无跨厂商强制标准，但「披露 harness 配置」已成榜单事实要求。**

### 13.3 专门记忆系统（初版只有 progress 文件与向量库）

四条路线：①**MemGPT→Letta**（OS 式分页自编辑记忆；2026-03 转向 git-backed 记忆文件系统 MemFS 与 memory & dreaming）；②**Mem0**（开发者记忆层中间件，三行代码接入，LoCoMo 92.5【厂商自报】；OpenMemory MCP 本地记忆服务器）；③**Zep/Graphiti**（时序知识图谱，bi-temporal 有效性时间窗，Graphiti 内建 MCP server；Zep CE 2025-04 停维护、开源线聚焦 Graphiti）；④**模型厂商原生**（Claude memory tool 2025-09-29：client-side /memories 目录 CRUD＋just-in-time 回读；ChatGPT memory→2026-06-04「Dreaming」后台记忆合成）。**与初版的关系**：checkpointer 管单 harness 会话恢复、memory tool/MemFS 管单 agent 上下文外溢层、Mem0/Zep 管跨应用用户画像记忆——三层互补而非互斥。

### 13.4 Durable Execution（初版只有 LangGraph checkpointer）

durable execution 引擎把 agent 每一步（LLM 调用/工具调用/人工等待）写入持久事件日志，崩溃/重启/多日审批后精确恢复且不重放已完成步骤。四家接入姿势：**Temporal**（AI 框架集成 GA 2026-10-30：Google ADK、OpenAI Agents SDK、LangGraph、AWS Strands 等，模型调用一律以 Activity 运行；另有 Temporal Agent Harness 2026-08-20 early look 与 Claude Agent SDK 集成 pre-release）；**Restate**（journal 化运行时，ctx.run 包裹任意 SDK 调用）；**DBOS**（进程内库，只用 Postgres，装饰器标注）；**Azure Durable Functions / Microsoft Agent Framework durable task extension**（2025-11-13 公开预览，人工审批等待期间不消耗计算与 token）。共同收敛点：把模型/工具调用降级为可重试原子步骤、把 agent 状态外置为持久日志。**注意**：Anthropic 长时程四篇官方文章全部走「harness 内建上下文管理」路线，未点名任何 durable 引擎（2026-11-06 检索确认）——「上下文管理」与「执行持久化」目前是互补的两个可靠性层次；初版 §4.4 的 checkpoint/resume 伪代码属前者。

### 13.5 MCP 生态与规范补充（初版 §4.2/§12.2 的展开）

- **版本链**：2024-11-05 首发 → 2025-03-26（OAuth 2.1、Streamable HTTP、工具注解）→ 2025-06-18（结构化输出、RFC 8707、elicitation、首个安全专节）→ 2025-11-25（OIDC、URL elicitation、实验性 tasks、SEP 治理正式化）→ **2026-07-28（现行）：协议核心 stateless 化（无握手/无会话，跨请求状态用显式句柄）、正式扩展框架（Tasks/MCP Apps/EMA）、授权硬化（iss 校验、CIMD）、12 个月弃用政策**。初版 §4.2「无状态核心」表述与现行版本一致。
- **Registry**：2025-09-08 preview（registry.modelcontextprotocol.io），截至 2026-11-06 **仍未 GA**；官方设计上不希望 host 直连，而应消费符合其 OpenAPI 规范的下游聚合注册表。
- **SDK**：Tier 1＝TypeScript/Python/C#/Go/Rust/Ruby；Tier 2＝Java；Tier 3＝Swift/PHP/Kotlin。
- **治理**：SEP 机制（2025-07-31，仿 PEP/RFC）→ WG/IG（2025-11-25）→ **2025-12-09 捐入 Linux Foundation 旗下 Agentic AI Foundation（AAIF，Anthropic/Block/OpenAI 共同创立，Google/Microsoft/AWS 等支持）**。
- **安全**：官方 Security Best Practices 设 confused deputy、token passthrough（明确禁止）、SSRF、state handle 劫持、本地 server 损陷等专节；工具投毒/rug pull 在规范层主要靠 human-in-the-loop SHOULD 条款，生态靠扫描器（Invariant MCP-Scan，2025-04-11）与 OWASP《MCP Security Cheat Sheet》补位。

### 13.6 互操作协议现状（初版 §12.2 一句话带过，变化已很大）

- **A2A**：Google 2025-06-23 捐 Linux Foundation；**v1.0.0 于 2026-03-12 发布（生产就绪）**——REST/gRPC/JSON-RPC 三绑定等价、签名 Agent Card（JWS+RFC 8785）、多租户；2026-08-27 入 AAIF（Growth Stage）。初版「Google 发起、Linux Foundation 托管」仍对但已滞后一档。
- **AG-UI**（CopilotKit）：agent↔前端实时交互协议，**1.0 规范 2026-09-18 冻结**（31 事件/8 族，STATE_SNAPSHOT+RFC 6902 增量）。
- **ACP**（Zed Agent Client Protocol）：编辑器↔编码 agent（JSON-RPC over stdio，Apache-2.0）；Gemini CLI（2025-09-03）、Claude Code（2025-10-02）、Codex（2025-10-06）均已接入，收录 50+ agent；v2 Draft 2026-07-20。⚠️ IBM/BeeAI 的同名 ACP 已于 2025-08-29 并入 A2A，检索须按全称区分。
- **AGNTCY**（Cisco 牵头，LF 项目，2025-07-29 入驻）：A2A/MCP 之下的发现（OASF+Agent Directory）、身份、传输（SLIM）基础设施。
- **分层格局**：AGENTS.md＋MCP＋A2A 同归 AAIF；AG-UI 社区治理；ACP＝Zed；AGNTCY＝LF——agent 栈各层均已有中立治理或明确主导方。

### 13.7 国产模型 agentic 能力与 harness 适配（初版完全缺失，对国内建设者关键）

| 体系 | 现役旗舰（2026-11） | agentic 口径 | harness 适配 |
|------|------|------|------|
| 阿里 Qwen | Qwen3-Coder-Next（2026-02-02 发布，80B 总参/3B 激活，256K，Apache 2.0）＋Qwen3-Coder-480B-A35B | Code RL＋2 万并行环境 Agent RL；Verified 70%+（SWE-Agent scaffold）【自报】 | Qwen Code CLI；官方适配 Claude Code/Cline；入选 Zed ACP |
| DeepSeek | V4-Pro 正式版（2026-08-13）/V4.1-Flash（552B，原生视觉，2026-09-10） | Thinking in Tool-Use（首个把思考融入工具调用的模型）；1,800+ 环境 agent RL | V3.1 起原生 Anthropic API 格式；V4 适配 Claude Code/Codex/OpenClaw；官方自研 **DeepSeek Harness（MIT）** |
| 智谱 GLM | GLM-5（2026-02-12，MIT 开源，200K）→5.3 | Agent 基座定位；CC-Bench 对标 Claude【自报】 | GLM Coding Plan 官方 Claude Code 兼容端点（ANTHROPIC_DEFAULT_* 环境变量映射）＋Codex/Cursor/OpenCode |
| 月之暗面 Kimi | K2.5（2026-01-27，多模态＋Kimi Code CLI）→K3（2.8T，1M 上下文） | K2 Thinking：200–300 连续工具调用保持连贯；Verified 71.3%【自报】 | OpenAI/Anthropic 双兼容 API；Kimi CLI 入 Zed ACP |
| MiniMax | M2.5（2026-02-12，Verified 80.2%【自报】）→M3（1M）→M3.1 Flash | interleaved thinking；对 Claude Code 等脚手架稳定泛化 | Anthropic 兼容 API；M2 发布即主打 CC/Cursor/Cline 适配 |

**共性（2026-11）**：可执行环境合成＋多步 Agent RL＋thinking-in-tool-use 成为训练标配；「Anthropic API 兼容端点」成国内平台 API 标配（harness 生态兼容的捷径）；小激活 MoE（80B-A3B/230B-A10B/284B-A13B）与低延迟 agent 循环的部署经济学强绑定。⚠️ 易错点：Qwen3-Coder-Next（80B-A3B，2026-02）与 Qwen3-Coder-480B-A35B（2025-07）是两个型号，勿混。

### 13.8 Claude Code 扩展体系与 Agent SDK（初版 §7.1.1「五层」口径的官方补正）

- 官方 Extend Claude Code 页列约 10 种扩展机制，初版「五层」为自创口径。机制角色（官方文档口径）：**CLAUDE.md＝软上下文**（原文「Claude treats them as context, not enforced configuration」——硬阻断用 PreToolUse hook）；**hooks**＝生命周期事件自动执行的 shell/HTTP/MCP/LLM/subagent（JS 函数形态称 mod）；**skills**＝SKILL.md 过程性知识，正文按需加载（slash commands 已并入 skills）；**plugins**＝打包分发单元（打包 skills/hooks/subagents/MCP）；**MCP**＝开放标准工具接入。
- **Agent Skills**：2025-10-16 发布；**2025-12-18 成为跨工具开放标准**（agentskills.io 规范站＋独立 GitHub 组织）；三层渐进式披露（name/description 常驻 → SKILL.md 正文 → 参考文件/脚本）。
- **Claude Agent SDK**：2025-09-29 由 Claude Code SDK 更名（官方原话「the agent harness that powers Claude Code」）；产品分层：Agent SDK（自进程跑 CC 二进制）／CLI／Client SDK（自写工具循环）／**Managed Agents＝「a hosted agent harness」**（2026-04-08 research preview）。
- **headless/subagent**：`-p` 非交互＋`--bare` 跳过全部扩展机制（CI 确定性）；subagent 有独立上下文窗口、自定义 system prompt、受限工具集（`--agents` 接 JSON 定义）。

### 13.9 「harness」术语采用证据链与 2025-10 之后大事记

术语谱系（比初版第0章判断 4 更完整）：评测/RL 行话（METR、SWE-bench 系）→ **Anthropic 2025-09-29 SDK 更名叙事＋2025-11-26《Effective harnesses for long-running agents》升格为一线官方术语** → Microsoft Agent Framework BUILD 2026 宣布 Agent Harness（2026-08 GA）→ LangChain 官方教程《How to Build a Custom Agent Harness》（2026-06-03）→ 学术形式化：arXiv:2606.10106《What makes a harness a harness》（2026-06-08，提出 T1–T4 充要判据并对 Claude Code/SWE-agent/Aider 等真实系统分类）。

2025-10 后重要新事（初版未覆盖）：Agent Skills 开放标准（2025-12-18）；Claude Code on the web（2025-10-20）；OpenAI AgentKit（2025-10-06）；LangChain/LangGraph 1.0 GA（2025-10-22）；Microsoft Agent Framework 1.0 GA（2026-04-03，Harness GA 2026-08）；Google ADK 2.0（2026-05-19，图式 Workflow Runtime）；mini-swe-agent v2.0.0（2026-02-11）；OpenHands Software Agent SDK（2025-11-05，即初版引用的 arXiv:2511.03690）→OpenHands 1.0.0（2025-12-16）；Codex CLI 开源（2025-04-16，Apache-2.0）；Gemini CLI 开源（2025-06-25）。口径澄清：SWE-agent 主仓未发布 2.0，2026 年的「2.0」实际落在 mini-swe-agent。

### 13.10 落地路线建议（对「能否指导建设 AI Agent」的收口）

综合初版方法论骨架与本章补充，一条最小可行路线：

1. **定级**（第0章·成熟度分级表）：先自评 L0~L5，明确缺口层级。
2. **最小 harness**（§4.1 伪代码）：ReAct 循环＋工具注册＋迭代上限＋成本预算——先不引入框架跑通。
3. **上下文管理**（§4.3＋§6.2）：三层压缩级联＋显式 token 预算；跨会话用 progress 文件＋git（目前验证最有效的模式）。
4. **权限与安全**（§4.5＋第10章＋§13.1）：Capability 模型＋三级审批＋沙箱；**工具结果一律按不可信输入处理**（间接注入防线），MCP server 过 Registry＋扫描器。
5. **评测闭环**（§3.5＋§13.2）：固定任务集＋harness 配置披露（内部也执行）；对照实验先于换模型（§9.5 决策树）。
6. **多模型适配**（第7章＋§13.7）：优先选带 Anthropic/OpenAI 兼容端点的模型；harness 与模型分开调优；每次模型升级重审 harness 组件（§6.2 发现）。
7. **生产化**（§4.4＋§13.4）：需要跨天运行/人工审批的 agent 引入 durable execution 层；可观测性直接按 OTel GenAI 官方命名（§4.7）落地避免返工。

初版的 12 项设计模式、长时程 12 项检查点与第1章/第9章概念辨析可直接作为各步骤的设计参考。

---

## 附录

### 附录 A：术语表（40+ 条）

| 术语 | 定义 |
|------|------|
| **Agent** | 能自主完成多步任务的完整系统（= model + harness + 业务逻辑） |
| **Agent Harness** | 包裹模型的运行时脚手架，将模型转化为 agent |
| **Agent-Computer Interface (ACI)** | harness 提供给模型的工具和交互格式，相当于 agent 的「屏幕和键盘」 |
| **Agent Framework** | 提供构建 agent 的抽象和组件库（如 LangChain） |
| **Agent Loop** | harness 驱动的重循环：发送上下文 → 运行工具 → 反馈结果 → 重复 |
| **Automatic Curriculum** | agent 自主提议下一个探索任务的机制（Voyager） |
| **Belief State** | agent 对世界状态的当前认知（POMDP 概念） |
| **Capability Model** | 定义 agent 可以执行哪些操作的权限模型 |
| **Checkpoint** | agent 状态的快照，用于崩溃恢复 |
| **CodeAct** | 使用可执行代码作为 agent 统一动作空间的方法 |
| **Compaction** | 将接近上下文窗口限制的对话进行摘要并重新初始化新窗口 |
| **Context Assembly Pipeline** | 决定每次推理前上下文窗口中包含什么的动态组装流程 |
| **Context Engineering** | 设计模型在推理时面对的完整信息环境的工程学科 |
| **Context Window** | 模型单次推理可以处理的最大 token 数 |
| **Durable Execution** | 每一步执行状态都被持久化的执行模式 |
| **Evaluation Harness** | 标准化评测框架（如 lm-evaluation-harness） |
| **Feedback Loop** | agent 行动后接收环境反馈并据此调整的循环机制 |
| **Feature List** | 结构化的功能追踪列表（Anthropic long-running harness） |
| **Function Calling** | 模型以结构化格式请求调用外部工具的机制 |
| **HITL (Human-in-the-Loop)** | 在关键决策点引入人类判断的设计模式 |
| **Harness** | 同 Agent Harness |
| **Idempotent** | 同一操作执行多次结果相同的性质 |
| **MCP (Model Context Protocol)** | Anthropic 发布的 LLM 与外部工具/数据源集成标准 |
| **Meta-harness** | 不预设特定 harness 实现、而是容纳多种 harness 的更高层系统 |
| **Orchestrator** | 多 agent 之间的任务分配与协调组件 |
| **POMDP** | 部分可观察马尔可夫决策过程 |
| **Plan-Execute** | 先生成计划再逐步执行的设计模式 |
| **Plugin** | 打包 skills、hooks、MCP 配置的可分发单元 |
| **Progress File** | 跨会话传递工作进度的文本文件 |
| **Progressive Disclosure** | 按需加载工具和信息的模式 |
| **ReAct** | 交替进行推理（Thought）和行动（Action）的 agent 模式 |
| **Reflexion** | 通过自然语言反馈（而非权重更新）来改进 agent 行为的方法 |
| **Scaffold** | harness 的同义词，学术文献中常用 |
| **Session** | 一次完整的 agent 交互过程 |
| **Skill** | 打包特定领域知识和工作流的可复用模块 |
| **Skill Library** | 存储和检索可复用行为代码的长期记忆机制（Voyager） |
| **Standing Approval** | 预定义的审批规则，符合条件的操作自动批准 |
| **State Drift** | 跨上下文窗口传递状态时信息丢失或扭曲的现象 |
| **Sub-agent** | 拥有独立上下文窗口的隔离 agent 实例 |
| **Tool Registry** | 管理 agent 可用工具集的组件 |
| **Token Budget** | 分配给上下文各部分的 token 数量上限 |
| **Workflow** | 预定义的确定性执行流程 |

### 附录 B：关键论文清单

| 论文 | arXiv/会议 | 年份 | 核心贡献 |
|------|-----------|------|---------|
| ReAct | ICLR 2023 | 2023 | 推理+行动的交替循环 |
| Reflexion | NeurIPS 2023 | 2023 | 语言反馈的自我改进 |
| Tree of Thoughts | NeurIPS 2023 (Oral) | 2023 | 搜索式推理 |
| Voyager | TMLR 2024 | 2023 | 技能库与终身学习 |
| Generative Agents | UIST 2023 | 2023 | 可信人类行为模拟 |
| CoALA | TMLR 2024 | 2024 | LLM agent 认知架构框架 |
| SWE-bench | ICLR 2024 (Oral) | 2024 | 真实 GitHub issue 评测基准 |
| CodeAct | ICML 2024 | 2024 | 代码作为统一动作空间 |
| SWE-agent | NeurIPS 2024 | 2024 | Agent-Computer Interface 设计 |
| Agentless | Proc. ACM Softw. Eng. 2025 | 2024 | 简单三阶段打败复杂 agent |
| OpenHands SDK | arXiv:2511.03690 | 2025 | 开源 coding agent SDK |
| AI Harness Engineering | arXiv:2605.13357 | 2026 | harness 的工程化框架 |
| SWE-TaskFlow（JetBrains Research） | arXiv:2610.09633【已核实 2026-11-06】 | 2026 | 评测应匹配用户的任务流 |

### 附录 C：开源 Harness 项目清单

| 项目 | GitHub Stars | 语言 | 许可证 | 关键特点 |
|------|-------------|------|--------|---------|
| OpenHands（OpenHands/OpenHands，原 All-Hands-AI/OpenHands） | ~93k（92,757） | Python | MIT | CodeAct、Context Condensation、多模型 |
| SWE-agent | ~21k（20,734） | Python | MIT | ACI 设计、Princeton |
| Aider | ~50k（49,976） | Python | Apache 2.0 | 终端原生、Git 集成 |
| LangGraph | ~45k（44,530） | Python/JS | MIT | 状态图、Checkpointer |
| lm-evaluation-harness | ~14k（14,409） | Python | MIT | 200+ 评测任务 |
| Perplexity SPACE | ~2k（2,060，2026-10 开源） | Rust | Apache 2.0 | Firecracker microVM 沙箱 |
| E2B Runtime | ~15k（14,732） | TypeScript/Go | Apache 2.0 | Firecracker microVM 沙箱 |
| bojieli/ai-agent-book | ~57k（57,275） | Python | Apache 2.0 | 教科书 + 代码 |

### 附录 D：失败案例集

| # | 失败案例 | 根因 | 教训 |
|---|---------|------|------|
| 1 | Anthropic Opus 4.5 单 prompt 构建 claude.ai 克隆失败 | 试图一次性完成所有功能，上下文耗尽后无法恢复 | 需要增量进度 + 进度文件 |
| 2 | Anthropic agent 过早宣布项目完成 | 看到部分进展就认为全部完成 | 需要客观的完成标准（feature list + tests） |
| 3 | Anthropic Sonnet 4.5 的 context anxiety | 感知到上下文限制时过早结束任务 | harness 需要补偿模型的行为缺陷 |
| 4 | 复杂 agent 系统被 Agentless 打败 | 过度复杂的 agent loop 引入错误和低效 | 简单三阶段有时优于复杂 agent |
| 5 | SWE-bench 分数不可复现 | harness、token 预算、评测条件不同 | 必须同时报告 harness 细节 |
| 6 | Perplexity SPACE 网络策略绕过（修复前） | DNS 欺骗和共享 CDN IP | 安全需要纵深防御 |
| 7 | 10 个第三方沙箱中 8 个存在网络策略绕过 | 容器级别的隔离不够 | 生产环境需要 microVM 级别隔离 |
| 8 | LangChain Open SWE 社区反馈不佳 | 框架复杂度高于价值 | agent framework 的抽象不应掩盖底层逻辑 |
| 9 | 同一模型在不同 harness 下分数差异数倍 | harness 设计对性能影响巨大 | 不要只看模型 benchmark，要看系统 benchmark |
| 10 | 长时程 agent 的成本失控 | 没有 token 预算管理和压缩 | 必须实现成本监控和预算控制 |

---

### 附录 E：修正对照表

| # | 编号 | 原表述（摘要） | 修订后（摘要） | 裁决 |
|---|------|--------------|--------------|------|
| 1 | A-SH1 | （3）**标准化协议（MCP/A2A）正在定义 harness 的工具层接口**——MCP SDK 月下载量从 2024 年 11 月发布时… | （3）**标准化协议（MCP/A2A）正在定义 harness 的工具层接口**——MCP SDK 月下载量从 2025 年 12 月官方披… | partially_true |
| 2 | A-SH3 | 2. **同一模型换 harness 后能力差异巨大**——SWE-bench 上同一模型的分数可以从 12.5% 跳到 55.2%，差异完… | 2. **同一模型换 harness 后能力差异巨大**——SWE-bench 上同一模型在不同 harness 下分数差异可达 2-3 倍… | false |
| 3 | A-SH5 | ¦ Claude 3.5 Sonnet ¦ SWE-agent ¦ ~20% ¦ N/A ¦ 2024 Q2 ¦ SWE-agent 论文【… | ¦ Claude 3.5 Sonnet ¦ SWE-agent ¦ 23.0% ¦ 33.6% ¦ 2024-06-20 ¦ SWE-ben… | false |
| 4 | A-SH6 | ¦ Claude 3.5 Sonnet ¦ 裸模型 ¦ <5% ¦ N/A ¦ 2024 ¦ 多源一致【已复现】 ¦ HIGH ¦ | ¦ GPT-4 Turbo / Claude 3 Opus ¦ 无 harness（非交互 RAG 基线） ¦ 2.67% / 4.33%（… | unverified |
| 5 | A-SH7 | ¦ GPT-4o ¦ Agentless ¦ ~25% ¦ N/A ¦ 2024 Q3 ¦ Agentless 论文【已复现】 ¦ HIGH… | ¦ GPT-4o ¦ Agentless ¦ 27.33%（v1）/ 32.00%（Agentless-1.5） ¦ 38.8% ¦ 202… | partially_true |
| 6 | A-SH8 | ¦ Claude Sonnet 4.5 ¦ OpenHands CodeAct 2.1 ¦ N/A ¦ 53% ¦ 2025 Q1 ¦ Op… | ¦ Claude 3.5 Sonnet (claude-3-5-sonnet-20241022) ¦ OpenHands CodeAct 2… | partially_true |
| 7 | A-SH13 | - **渐进式工具加载**：Tool search 模式可以将工具定义 token 减少 85%+ | - **渐进式工具加载**：Tool Search Tool 按需发现并加载工具，官方示例中总上下文 token 从约 77K 降至约 8.… | partially_true |
| 8 | A-SH14 | ¦ **gVisor** ¦ 用户态内核 ¦ ~100-150ms ¦ 高 ¦ 需要快速启动的场景 ¦ Apache 2.0 ¦ | ¦ **gVisor** ¦ 用户态内核 ¦ 官方基准约 1.1-2.5s（经 Docker，与 runc 同量级）；无官方毫秒级口径 ¦ … | partially_true |
| 9 | A-SH16 | ¦ Prompt Caching ¦ 50-90% 的输入 token 成本 ¦ 低 ¦⏎¦ 模型分级（简单任务用小模型） ¦ 60-80%… | ¦ Prompt Caching ¦ 最高 90%（官方口径 up to 90%：缓存读价为原输入价 10%，官方实测 -53%~-90%）… | partially_true |
| 10 | A-SH17 | ¦ OpenHands ¦ 64k+ ¦ Python ¦ MIT ¦ CodeAct、Context Condensation、多模型 ¦… | ¦ OpenHands（OpenHands/OpenHands，原 All-Hands-AI/OpenHands） ¦ ~93k（92,75… | partially_true |
| 11 | A-SH18 | ¦ B2 ¦ 《Designing Multi-Agent Systems》 ¦ Victor Dibia ¦ O'Reilly Media… | ¦ B2 ¦ 《Designing Multi-Agent Systems》 ¦ Victor Dibia ¦ 自出版（multiagent… | partially_true |
| 12 | A-SH19 | ¦ **L0: 基础模型** ¦ 推理、生成、工具调用意图 ¦ Claude Opus 4.5/4.6, GPT-4o/o1, Gemini… | ¦ **L0: 基础模型** ¦ 推理、生成、工具调用意图 ¦ Claude Opus 4.5/4.6, GPT-5.6 系列（o1 已于 … | partially_true |
| 13 | B-AC4-核心 | **来源**：Sumers et al., "Cognitive Architectures for Language Agents", T… | **来源**：Sumers et al., "Cognitive Architectures for Language Agents", T… | false |
| 14 | B-AC4b | **来源**：CoALA 论文（Sumers et al., TMLR 2024）将 BDI 模型作为 LLM agent 认知架构的理论基… | **来源**：BDI 模型的经典出处为 Rao & Georgeff (1995) 等理性 agent 理论文献；CoALA 论文原文未讨论… | false |
| 15 | B-AC4c | CoALA 论文系统梳理了 Soar/ACT-R 与 LLM agent 的对应关系。 | CoALA 论文以 Soar 为核心案例梳理了经典认知架构与 LLM agent 的对应关系（ACT-R 仅作为文献引证出现，未展开）。 | partially_true |
| 16 | B-AC5 | **论文**：Xia et al., "Agentless: Demystifying LLM-based Software Enginee… | **论文**：Xia et al., "Agentless: Demystifying LLM-based Software Enginee… | partially_true |
| 17 | B-AC10 | **定义 5 — 学术论文 Liu（2026）**：⏎> "The term harness has been used to descri… | **定义 5 — 学术论文 Liu（2026）**：⏎> "In recent engineering discussions, the t… | partially_true |
| 18 | B-AC11 | 27. Yang et al. "Better Harnesses, Smarter Models: Building 90% Cheape… | 27. Yang et al. "Better Harnesses, Smaller Models: Building 90% Cheape… | partially_true |
| 19 | B-AC12 | 26. Zhao et al. "Pairing Matters: Performance, Failures, and Efficienc… | 26. Zhao et al. "Pairing Matters: Performance, Failures, and Efficienc… | true |
| 20 | B-AC13 | 28. JetBrains. "Opinion: Coding-Agent Benchmarks Should Match Their Us… | 28. Slinko, Golubev & Titov (JetBrains Research). "Coding-Agent Benchm… | true |
| 21 | C-PR9 | Context Engineering 的系统性综述，三层压缩级联，多 agent 上下文协调 | Context Engineering 的系统性综述，结构化摘要蒸馏（token 用量最多降 80%）与五层记忆架构，多 agent 上下文… | partially_true |
| 22 | C-PR10 | GitHub 6.7k+ stars | GitHub 57.3k+ stars（2026-11-06 实测 57,275） | partially_true |
| 23 | C-PR20 | - 2026 年 3 月：LangChain CEO Harrison Chase 指出「Agent 犯错很多时候是因为缺少正确的上下文」 | - 2025 年 6 月：LangChain CEO Harrison Chase 指出「Agent 犯错很多时候是因为缺少正确的上下文」（… | partially_true |
| 24 | C-PR21 | **2025-2026 年的共识**：Anthropic 明确表示「improving the harness often has more… | **2025-2026 年的共识**：Anthropic 明确表示「Harnesses encode assumptions that go… | partially_true |
| 25 | C-PR22 | - 五层扩展体系：CLAUDE.md → Hooks → Skills → Plugins → MCP Servers⏎- 加载顺序很重要：… | - 扩展机制：CLAUDE.md、Hooks、Skills、Plugins、MCP Servers 等（官方 Extend Claude C… | partially_true |
| 26 | C-PR23 | - 三层架构：Harness → Orchestrator → Control Plane | - 官方组件架构：Software Agent SDK（Agent/Conversation/LLM/Tools/Events/Worksp… | partially_true |
| 27 | C-PR24 | - 已被 OpenAI 采用为展示 GPT-4o 和 o1 编码能力的标准方法 | - 已被 OpenAI 采用为展示 GPT-4o 和 o1 编码能力的标准方法（o1 system card 原文：采用当时最佳开源 sca… | needs_note |
| 28 | M-沙箱E2B | ¦ **E2B** ¦ Firecracker microVM ¦ ~80ms ¦ 最高 ¦ 商业 agent 平台 ¦ Apache 2.… | ¦ **E2B** ¦ Firecracker microVM ¦ ~150ms（快照恢复口径 150-170ms；standby <25m… |  |
| 29 | M-沙箱Firecracker | ¦ **Firecracker microVM** ¦ 独立内核的 microVM ¦ ~60-89ms (SPACE) ¦ 最高 ¦ 生产… | ¦ **Firecracker microVM** ¦ 独立内核的 microVM ¦ 本体官方 ~125ms；SPACE 实测 60-89… |  |
| 30 | M-沙箱Daytona | ¦ **Daytona** ¦ Docker/VM ¦ 取决于类别 ¦ 中-高 ¦ 开发者友好型 ¦ AGPL ¦ | ¦ **Daytona** ¦ Docker/VM ¦ 官方自述 <90ms（2026-06 起核心转私有、开源仓归档）【已核实】 ¦ 中-… |  |
| 31 | M-B2恢复OTel | 15 章，从零构建多 agent 框架，包含 MCP/A2A、human-in-the-loop | 15 章，从零构建多 agent 框架，包含 OpenTelemetry、MCP/A2A、human-in-the-loop |  |
| 32 | M-§1.4裸模型行 | ¦ Claude 3.5 Sonnet ¦ 裸模型（无 harness，直接提示） ¦ <5% ¦ 多个基准测试一致【已复现】 ¦ | ¦ GPT-4 Turbo / Claude 3 Opus ¦ 裸基线（无 harness，非交互 RAG） ¦ 1.31%–4.33%（见… |  |
| 33 | M-MCP下载L817 | - SDK 月下载量从 200 万增长到 4 亿 | - SDK 月下载量：2025-12 官方披露 9700 万+（Python+TypeScript 合计），2026-07 Anthropi… |  |
| 34 | M-MCP下载L1932 | - MCP：月下载量从 200 万（2024.11）到 4 亿（2026.07），成为事实标准 | - MCP：SDK 月下载量 2025-12 官方披露 9700 万+，2026-07 Anthropic 官宣 4 亿次以上【已核实】，成… |  |
| 35 | M-C11编号 | ¦ 自动 harness 优化 ¦ 来源待核 ¦ | ¦ 自动 harness 优化 ¦ arXiv:2607.08938【已核实 2026-11-06】 ¦ |  |
| 36 | M-C12编号 | ¦ harness-model 配对的失败模式分析 ¦ 来源待核 ¦ | ¦ harness-model 配对的失败模式分析 ¦ arXiv:2610.32131【已核实 2026-11-06】 ¦ |  |
| 37 | M-A9全称 | ¦ A9 ¦ "The Hitchhiker's Guide to Agentic AI" ¦ Haggai Roitman ¦ arXiv… | ¦ A9 ¦ "The Hitchhiker's Guide to Agentic AI: From Foundations to Syst… |  |
| 38 | M-ref22全称 | 22. Roitman. "The Hitchhiker's Guide to Agentic AI." arXiv:2606.24937,… | 22. Roitman, Haggai. "The Hitchhiker's Guide to Agentic AI: From Found… |  |
| 39 | M-7字段标注 | - **结构化摘要格式**：7 字段 JSON（session_intent, progress_so_far, key_facts, ar… | - **结构化摘要格式**：7 字段 JSON（session_intent, progress_so_far, key_facts, ar… |  |
| 40 | M-快照时点 | 截至 2026 年底，harness 领域呈现出三个核心趋势 | 截至本报告快照时点（2026-11-06），harness 领域呈现出三个核心趋势 |  |

---


参考
============
## 参考文献

（以下所有引用均来自本报告搜索过程中实际访问的公开来源）

1. Anthropic. "Effective harnesses for long-running agents." Anthropic Engineering Blog, Nov 26, 2025. https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents
2. Anthropic. "Harness design for long-running application development." Anthropic Engineering Blog, Mar 24, 2026. https://www.anthropic.com/engineering/harness-design-long-running-apps
3. Anthropic. "Scaling Managed Agents: Decoupling the brain from the hands." Anthropic Engineering Blog, Apr 8, 2026. https://www.anthropic.com/engineering/managed-agents
4. Anthropic. "Building agents that reach production systems with MCP." Anthropic Blog, Apr 22, 2026.
5. Anthropic. "Bringing MCP 2026-07-28 to Claude." Jul 28, 2026.
6. Microsoft. "Agent Harness." Microsoft Learn, 2026. https://learn.microsoft.com/en-za/agent-framework/concepts/harness
7. BasicsOf.AI. "Agent Harnesses." 2026. https://basicsof.ai/article/agent-harnesses
8. Cursor. "Best practices for coding with agents." Cursor Blog, Jan 9, 2026. https://cursor.com/blog/agent-best-practices
9. Yang et al. "SWE-agent: Agent-Computer Interfaces Enable Automated Software Engineering." NeurIPS 2024.
10. Xia et al. "Agentless: Demystifying LLM-based Software Engineering Agents." Proc. ACM Softw. Eng. 2025.
11. Wang et al. "Executable Code Actions Elicit Better LLM Agents." ICML 2024.
12. Wang et al. "The OpenHands Software Agent SDK." arXiv:2511.03690, 2025.
13. Shinn et al. "Reflexion: Language Agents with Verbal Reinforcement Learning." NeurIPS 2023.
14. Yao et al. "ReAct: Synergizing Reasoning and Acting in Language Models." ICLR 2023.
15. Sumers et al. "Cognitive Architectures for Language Agents." TMLR 2024.
16. Park et al. "Generative Agents: Interactive Simulacra of Human Behavior." UIST 2023.
17. Wang et al. "Voyager: An Open-Ended Embodied Agent with Large Language Models." TMLR 2024.
18. Liu, Jia'an. "Engineering and Governing the Agent Harness." UNU, 2026.
19. Zhong & Zhu. "AI Harness Engineering: A Runtime Substrate for Foundation-Model Software Agents." arXiv:2605.13357, 2026.
20. Zylos Research. "Context Engineering for AI Agents: From Craft to Production Discipline." Jun 26, 2026.
21. Li, Bojie. 《深入理解 AI Agent：设计原理与工程实践》. Apache 2.0, 2026.
22. Roitman, Haggai. "The Hitchhiker's Guide to Agentic AI: From Foundations to Systems." arXiv:2606.24937, 2026.【已核实 2026-11-06】
23. Perplexity. "Escaping SPACE: Part I." Sep 23, 2026.
24. E2B. "Best Code Execution Sandboxes for AI Agents in 2026." Oct 15, 2026.
25. Sonar. "Introducing Sonar Foundation Agent." Nov 14, 2025.
26. Zhao et al. "Pairing Matters: Performance, Failures, and Efficiency in Lightweight Coding Agents." arXiv:2610.32131, 2026.
27. Yang et al. "Better Harnesses, Smaller Models: Building 90% Cheaper Agents via Automated Harness Adaptation." arXiv:2607.08938, 2026.
28. Slinko, Golubev & Titov (JetBrains Research). "Coding-Agent Benchmarks Should Match Their Users' Task Flows." arXiv:2610.09633, Oct 2026.



版权声明：本文为博主原创文章，转载请注明出处。 [旭日酒馆](https：//xueyp.github.io/)
