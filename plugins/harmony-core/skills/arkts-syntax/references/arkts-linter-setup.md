# 接入官方 ArkTS linter(编译器级诊断闭环)

> 本仓库的 `arkts-syntax` 教 agent **写对** ArkTS;本文档配套一个**确定性校验闭环**——
> 用 OpenHarmony 官方 ArkTS checker 运行时对生成的 `.ets` 做真实编译器诊断,而不是靠 grep 猜。
> 配好后,`hooks/ets-lint-gate.sh`(写 .ets 自动触发)与 `scripts/arkts-lint.sh`(手动)都会优先用它。

## 三种检查器(从强到弱)

| 检查器 | 准确度 | 获取方式 | 适用 |
|---|---|---|---|
| OpenHarmony **linter-cli** | 最高(真 checker) | 见下 | CI / agent 自动门禁 |
| DevEco **CodeLinter** | 高 | DevEco Studio 内置 | 本地人工 |
| 内置 grep 快检 | 低(兜底) | 本仓库自带 | 无上述环境时的提示 |

## 安装 OpenHarmony linter-cli

linter-cli 是从 `arkts-cli` 抽取出来的独立 ArkTS 诊断工具(只做 checker 诊断,不产出 `.abc`、
不跑 vm)。来源:`harmonyos-agent-rules` 仓库 `arkts-rules/tools/linter-cli/`。

> 约束:官方包标注 `os: linux` / `cpu: x64`。Windows 用户在 **WSL** 下运行;Windows 风格
> SDK 路径(如 `D:\DevEco Studio\sdk\default\openharmony\ets`)在 WSL 下被接受。

```bash
# 1. 取得 linter-cli
git clone https://gitcode.com/HarmonyOS_Skills/harmonyos-agent-rules.git
cd harmonyos-agent-rules/arkts-rules/tools/linter-cli

# 2. 安装依赖 + OpenHarmony 定制 TypeScript 运行时
npm install
npm run install-runtime-deps      # 默认浅克隆 openharmony/third_party_typescript 并装入 node_modules/typescript

# 3. 自测
npm run check
```

## 接入本仓库的检查闭环

配置环境变量(指向上一步的 linter-cli),hook 与脚本即自动启用官方诊断:

```bash
export HARMONY_ARKTS_LINTER="/abs/path/harmonyos-agent-rules/arkts-rules/tools/linter-cli"
export HARMONY_SDK_PATH="/abs/path/sdk/default"      # 可选:OpenHarmony ETS SDK 根
export HARMONY_LINTER_CACHE="/tmp/arkts-linter-cache" # 可选:checker 缓存
```

手动检查单个文件:

```bash
bash plugins/harmony-core/skills/arkts-syntax/scripts/arkts-lint.sh \
  entry/src/main/ets/pages/Index.ets
```

直接用官方 CLI(等价):

```bash
node .../linter-cli/bin/linter-cli.js \
  --input /abs/path/entry/src/main/ets/pages/Index.ets \
  --sdk-path "/abs/path/sdk/default"
# 输出 "Lint Check: OK" 或 ArkTS checker 诊断
```

## 行为说明

- 输入是单个 `.ets` 文件;CLI 默认从 `src/main/ets` 前一段推断模块根,必要时用
  `--module-root`/`--project-root`/`--module-json` 指定。
- 通过时输出 `Lint Check: OK`;有问题时把 checker/tsc 诊断打到 stdout/stderr。
- 未配置官方 linter 时,hook 回退到 codelinter,再回退到 grep 快检(仅提示,可能误报)。
