# Claude Code Config Sync

一键同步 Claude Code 的 skills、agents、hooks、MCP servers 和 plugin 配置到新设备。

## 快速安装

**Windows (PowerShell):**
```powershell
iwr -useb https://raw.githubusercontent.com/<YOUR_REPO>/main/install.ps1 | iex
```

**macOS / Linux:**
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/<YOUR_REPO>/main/install.sh)
```

**本地安装:**
```powershell
# Windows
powershell -ExecutionPolicy Bypass -File install.ps1

# macOS / Linux
bash install.sh
```

## 完整清单

### Custom Skills（自定义，安装脚本自动部署）

| Skill | 功能 | 来源 |
|---|---|---|
| `obsidian` | Obsidian Vault 管理 — 项目添加、Bug 记录、更新日志、上下文加载 | 自定义创建 |
| `mysql-query` | MySQL 直连查询（MCP 不可用时的备选方案） | 自定义创建 |

### Plugin Skills（通过插件市场安装）

| Skill | 功能 |
|---|---|
| `understand` | 扫描代码库，生成交互式知识图谱 |
| `understand-chat` | 向代码库知识图谱提问 |
| `understand-dashboard` | 打开 Web 交互仪表板（React Flow） |
| `understand-diff` | 分析 git diff 影响范围 |
| `understand-explain` | 深入解释特定文件/函数 |
| `understand-domain` | 提取业务领域知识图谱 |
| `understand-knowledge` | 管理外部知识库（wiki 等） |
| `understand-onboard` | 生成新人入职指南 |

**安装命令（在 Claude Code 中运行）：**
```
/plugin marketplace add Lum1104/Understand-Anything
/plugin install understand-anything
```

### Agents（Understand-Anything 自带）

| Agent | 用途 |
|---|---|
| `project-scanner` | 扫描文件、检测语言和框架 |
| `file-analyzer` | 提取函数、类、依赖，构建图谱节点 |
| `architecture-analyzer` | 识别架构分层 |
| `domain-analyzer` | 提取业务领域概念 |
| `tour-builder` | 生成引导式学习路径 |
| `graph-reviewer` | 验证图谱完整性和引用完整性 |
| `knowledge-graph-guide` | 知识图谱操作指南 |
| `article-analyzer` | 分析文档/文章 |
| `assemble-reviewer` | 组装和审查最终图谱 |

### MCP Servers

| Server | 包名 | 用途 |
|---|---|---|
| `api-lab` | `api-lab-mcp` | API 测试和调试 |
| `brave-search` | `@modelcontextprotocol/server-brave-search` | Web 搜索（需要 Brave API Key） |
| `codegraph` | `@lum1104/codegraph-mcp` | 代码知识图谱索引 |

### Hooks

| Hook | 触发时机 | 行为 |
|---|---|---|
| PostToolUse | git commit/merge/rebase | Understand-Anything 自动增量更新知识图谱 |
| SessionStart | 新会话启动 | 检测知识图谱是否过期，提示更新 |

### 环境配置

```json
{
  "ANTHROPIC_AUTH_TOKEN": "<your-deepseek-api-key>",
  "ANTHROPIC_BASE_URL": "https://api.deepseek.com/anthropic",
  "ANTHROPIC_DEFAULT_HAIKU_MODEL": "deepseek-v4-flash",
  "ANTHROPIC_DEFAULT_OPUS_MODEL": "deepseek-v4-pro",
  "ANTHROPIC_DEFAULT_SONNET_MODEL": "deepseek-v4-pro",
  "ANTHROPIC_MODEL": "deepseek-v4-pro"
}
```

### 内置 Skills（Claude Code 自带，无需同步）

`brainstorming`, `dispatching-parallel-agents`, `executing-plans`, `finishing-a-development-branch`, `receiving-code-review`, `requesting-code-review`, `subagent-driven-development`, `systematic-debugging`, `test-driven-development`, `using-git-worktrees`, `using-superpowers`, `verification-before-completion`, `writing-plans`, `writing-skills`

## 目录结构

```
claude-config-sync/
├── README.md
├── install.sh                          # macOS/Linux 安装脚本
├── install.ps1                         # Windows 安装脚本
├── config/
│   ├── mcp.json                        # MCP Server 配置（模板）
│   ├── hooks.json                      # Hooks 配置
│   └── settings.template.json          # 环境变量模板（不含密钥）
└── skills/
    ├── obsidian/
    │   └── SKILL.md
    └── mysql-query/
        └── SKILL.md
```

## 添加到新设备

1. `git clone` 本仓库
2. 运行 `install.ps1`（Windows）或 `install.sh`（macOS/Linux）
3. 编辑 `~/.claude/mcp.json` 填入你的 Brave API Key
4. 编辑 `~/.claude/settings.json` 填入你的 DeepSeek API Key
5. 打开 Claude Code，运行 plugin 安装命令
6. 重启 Claude Code
