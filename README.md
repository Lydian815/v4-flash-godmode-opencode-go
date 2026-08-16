# V4 Flash 神模式 (opencode-go)

> 让 **opencode-go 的 DeepSeek V4 Flash** 从「鬼模式」切换到「神模式」的 dsh agent preset。
>
> **升级（回灌切断）**：本 preset 配合对 `@earendil-works/pi-ai` 的 patch，
> 切断 opencode-go 网关的思维链回灌（见下文「回灌切断」），避免历史
> "Let me…" 链与未装 preset 的旧对话污染智力。

## 回灌切断（升级核心）

opencode-go 网关经 pi-ai 适配层时，`deepseek-v4-flash` 声明
`compat.requiresReasoningContentOnAssistantMessages: true` —— 历史上每一轮
的思维链全文会被作为 `reasoning_content` 回灌给模型。后果：模型看到自己
上一轮的 "Let me…" 长链，模仿并延续 → 语域逐轮漂移；没装 preset 的旧对话
也会回灌污染。

**修复**（`@earendil-works/pi-ai/dist/api/openai-completions.js`，provider 级，
opencode-go 全覆盖，flash + pro 均生效）：

```js
if (nonEmptyThinkingBlocks.length > 0 && model.provider !== "opencode-go") {
```

- opencode-go 的 assistant 消息不再回灌思维链文本；
- `reasoning_content: ""` 空串仍发送（满足网关字段要求）；
- 思维链仍存储并显示在 UI（Think 块不变），只是不再喂回给模型；
- wire 实测：空串回灌 → "我们需要/We need/Let's" 语域稳定；全文回灌 →
  漂移为 "Let me…"。

> ⚠️ 这是对 npm 全局包（`@earendil-works/pi-ai`）的 patch，升级 dsh/pi-ai
> 会被覆盖，需重打。

## 长思考引导（deepThinking，回灌切断配套）

**为什么需要**：切断回灌后，flash 模型失去"看到自己历史长链"的激励，思考
会变浅（实测：同一建模题，思考总量 245K→110K 字符、建模质量 30→24/30）。
**本 preset 提供 `deepThinking` 开关**，用**显式 persona 指令**替代回灌激励，
把思考深度拉回，同时保持 let me 语域干净：

```yaml
# agent.cordis.yml → router-bootstrap 行
config:
  deepThinking: true   # false/删除 → 经典 w7
```

`deepThinking: true` 使用 `WEAK_FLASH_DEEP` persona，显式要求五阶段推演：

1. **Scope** — 明确问题、目标、假设；
2. **Model** — 从第一性原理推导全部方程/步骤；
3. **Challenge** — 主动 red-team 自己的结论（物理合理性、边界、单位、符号）；
4. **Cross-check** — 用独立方法复核关键数值；
5. **Conclude** — 给出带具体数字的结论，说明不确定性，停止。

同时内置反空转锚（"Do not narrate your reasoning as 'Let me…' chatter"）。
实测定位：`deepThinking:false`（经典 w7）= 短思考、干净语域；
`deepThinking:true` = 长思考、干净语域、质量回满。

## 评测数据（Flash 三态对比，煮沸水建模题）

| 组合 | 思考字符 | Let me | 效率(答/思) | 建模总分 |
|---|---|---|---|---|
| 标准 opencode flash | 121,509 | 97 | 12.5% | 79 |
| **Router Flash（切断回灌，浅思考）** | 110,823 | 85 | 14.6% | 81 |
| Router Flash（未切断回灌） | 245,011 | 154 | 8.2% | 86 |
| **Router Flash Deep（切断 + 长思考）** | 105,387 | 83 | 14.6% | **91** |

**结论**：`deepThinking:true` 用更少的思考（105K vs 245K）拿到同等的深度
（13/14），语域更干净（83 vs 154 let me），总分最高（91）——五阶段 persona
完全替代了回灌的激励作用，同时避免了 let me 污染。**Flash 推荐直接用 Deep
变体（preset-deep/）。**

## 这是什么

一个 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness)（dsh）的 agent preset。它把 [dsh-router-standard](https://github.com/yjh051108/dsh-router-standard) 研究里为 **Flash** 标定的最优引导（w7 persona + 深度思考锚）适配到 **opencode-go provider 的 `deepseek-v4-flash`** 上。

**核心问题**：Flash 在默认（无引导）条件下会进入「鬼模式」——思考浅、草草动手、质量差。这不是 Flash 能力不行，而是**引导条件不对**。补上正确的引导（分类 + 回顾 + 反跑题 + 深度思考 + 决策闭环），Flash 就能进入「神模式」——深度规划、高质量交付、自测零错误。

## 实测效果（同一任务、同一 Flash 模型）

四冲程柴油机 3D 仿真任务：

| | 鬼模式（无引导） | 神模式（本 preset） |
|---|---|---|
| 规划深度 | 2.9 万字 | **37.5 万字** |
| 齿轮啮合几何验证 | 无 | ✅ 数值验证 |
| 交付形态 | 单文件依赖 CDN | 多文件 + 合并单文件（离线可用） |
| 数值仿真自测 | 无 | ✅ 四冲程相位 / 气门正时 / 喷油正时 |
| 无头浏览器自测 | 无 | ✅ SELFTEST 零错误（236 网格 / 49 零件） |

## 跨平台支持

本 preset **三平台通用**，dsh 会自动选择 shell 工具：

| 系统 | shell | 状态 |
|---|---|---|
| Linux | bash | ✅ 实测 |
| macOS | bash | ✅ 自动适配 |
| Windows | pwsh（PowerShell） | ✅ 自动适配 |

> 说明：`agent.cordis.yml` 内已有 `process.platform === 'win32'` 判断，Windows 自动禁用 bash、启用 pwsh。核心路由逻辑（persona / 引导 / 模型识别）与操作系统无关。

## 依赖

- [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness)（dsh）rc.6+
- opencode-go provider 的 `deepseek-v4-flash` 模型（`https://opencode.ai/zen/go/v1`）

## 安装

### 方式一：一键脚本

```bash
git clone https://github.com/SheberDavid/v4-flash-godmode-opencode-go.git
cd v4-flash-godmode-opencode-go
./install.sh
```

### 方式二：手动

```bash
# 1. 复制 preset 到 dsh 用户目录
mkdir -p ~/.dsh/.agent-presets
cp -r preset ~/.dsh/.agent-presets/router-flash

# 2. 编辑 ~/.dsh/settings.yaml，确认包含：
#    agent-default-model:
#      provider: opencode-go
#      model: deepseek-v4-flash
#      reasoningEffort: max
#    agent-presets:
#      default: router-flash

# 3. 重启 dsh
```

## 使用

1. 安装后重启 dsh，新会话会自动使用 `router-flash` preset + `deepseek-v4-flash` 模型。
2. 直接提交任务即可。persona 会自动注入「分类 + 回顾 + 反跑题 + 深度思考 + 决策闭环」五个锚。
3. 会话启动后，模型的 system prompt 应包含：
   ```
   You are a helpful assistant.
   Before acting, decide the task type (build or fix)...
   Before acting, briefly review what you have already done...
   Do not run environment checks (echo, whoami, uname...)...
   Think deeply about the architecture, edge cases...
   Produce when your information is complete...
   ```

## 适配了什么（与原版 dsh-router-standard 的区别）

原版依赖三个在你的 dsh 版本上会失效的机制，本 preset 已修复：

1. `ctx.on('session/event')` 注入 —— dsh rc.6 中 session/event 是 session-scoped，agent-plane preset 收不到。
2. `target.inbox.append` —— agent 对象没有 `.inbox` 属性。
3. assemble 时 `session.events` 里还没有 user/message —— 时序问题。

**修复方式**：把引导静态合并进 `WEAK_FLASH` persona，避免依赖任何动态注入机制。对固定任务同样有效，且更简单可靠。

## 适用范围

- ✅ 本 preset 专为 **Flash** 设计：命中 `isFlashModel` 后一律走 weak 模式（作者实测 w7 最优解）。
- ✅ 非 Flash 模型（如 pro）不受影响，走原版关键词分类逻辑。
- ✅ 复杂构建任务（如大型工程、从零开发）尤其受益于深度思考锚。

## 致谢

基于 [dsh-routing-suite](https://github.com/yjh051108/dsh-routing-suite) / [dsh-router-standard](https://github.com/yjh051108/dsh-router-standard) 的研究与代码（MIT）。
