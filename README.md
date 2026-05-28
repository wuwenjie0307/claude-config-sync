# Claude Code Config Sync

一键同步 Claude Code 的 skills、hooks、MCP servers 到新设备。所有硬编码路径已替换为**占位符系统**，跨设备开箱可用。

## 快速安装

**本地安装:**
```powershell
# Windows
powershell -ExecutionPolicy Bypass -File install.ps1

# macOS / Linux
bash install.sh
```

**远程一键安装:**
```powershell
# Windows
iwr -useb https://raw.githubusercontent.com/wuwenjie0307/claude-config-sync/main/install.ps1 | iex

# macOS / Linux
bash <(curl -fsSL https://raw.githubusercontent.com/wuwenjie0307/claude-config-sync/main/install.sh)
```

**可选参数:**
```powershell
install.ps1 -VaultPath "D:\MyVault"    # 指定 Obsidian Vault 路径
install.ps1 -SkipMCP                    # 跳过 MCP 包预安装
install.sh --vault-path ~/Documents/MyVault --skip-mcp --github-user myname
```

## 安装脚本做了什么

| 步骤 | 说明 |
|---|---|
| 1. 备份 | 覆盖前将已有配置备份到 `~/.claude/backups/<timestamp>/` |
| 2. Skills | 复制自定义 skills 并**自动替换占位符**（路径、GitHub 用户名） |
| 3. Hooks | 安装 hooks 配置 |
| 4. MCP | 从 `mcp-manifest.txt` 读取包列表预安装（跳过 `understand-*` 和内置 skills） |
| 5. 模板 | 仅在 `mcp.json` 不存在时才复制模板，**已有配置不会被覆盖** |

## 占位符系统

Skill 文件中使用占位符而非硬编码路径，安装时自动替换：

| 占位符 | 替换为 | 示例 |
|---|---|---|
| `{{VAULT_PATH}}` | 用户的 Obsidian Vault 路径 | `C:\Users\me\Desktop\Obsidian` |
| `{{REPO_PATH}}` | 仓库本地路径 | `/home/me/claude-config-sync` |
| `{{GITHUB_USER}}` | GitHub 用户名 | `wuwenjie0307` |

## 完整清单

### Custom Skills（自定义，安装脚本自动部署）

| Skill | 功能 |
|---|---|
| `obsidian` | Obsidian Vault 管理 — 项目添加、Bug 记录、更新日志、上下文加载 |
| `mysql-query` | MySQL 直连查询（MCP 不可用时的备选方案） |
| `image-vision` | 调用硅基流动 Qwen 视觉模型识别图片内容（API Key 需自行配置） |
| `claude-config-sync` | 一键同步 Claude Code 配置到 GitHub |

### Plugin Skills（在 Claude Code 中运行安装命令）

| Skill | 功能 |
|---|---|
| `understand` | 扫描代码库，生成交互式知识图谱 |
| `understand-dashboard` | 打开 Web 交互仪表板（React Flow） |
| `understand-chat` | 向代码库知识图谱提问 |
| `understand-diff` | 分析 git diff 影响范围 |
| `understand-explain` | 深入解释特定文件/函数 |
| `understand-domain` | 提取业务领域知识图谱 |
| `understand-knowledge` | 管理外部知识库 |
| `understand-onboard` | 生成新人入职指南 |

```
/plugin marketplace add Lum1104/Understand-Anything
/plugin install understand-anything
```

### Agents（Understand-Anything 自带，9 个）

`project-scanner` `file-analyzer` `architecture-analyzer` `domain-analyzer` `tour-builder` `graph-reviewer` `knowledge-graph-guide` `article-analyzer` `assemble-reviewer`

### MCP Servers

| Server | 包名 | 用途 |
|---|---|---|
| `api-lab` | `api-lab-mcp` | API 测试和调试 |
| `brave-search` | `@modelcontextprotocol/server-brave-search` | Web 搜索（需要 Brave API Key） |
| `codegraph` | `@lum1104/codegraph-mcp` | 代码知识图谱索引 |

### Hooks

| Hook | 触发时机 | 检测方式 |
|---|---|---|
| PostToolUse | Bash 命令执行后 | 对比 `git rev-parse HEAD` 与存储的 commit hash |
| SessionStart | 新会话启动 | 同上，检测图谱是否过期 |

hooks 不再用 grep 匹配 git 命令字符串，改用 `git rev-parse HEAD` 比对，别名、脚本调用都能正确触发。

## 目录结构

```
claude-config-sync/
├── README.md
├── install.sh                          # macOS/Linux 安装脚本
├── install.ps1                         # Windows 安装脚本
├── config/
│   ├── mcp.json                        # MCP Server 配置模板
│   ├── mcp-manifest.txt                # MCP 包列表（安装脚本读取）
│   ├── hooks.json                      # Hooks 配置
│   └── settings.template.json          # 模型配置（Anthropic 原生 + DeepSeek 双模板）
└── skills/
    ├── obsidian/SKILL.md
    ├── mysql-query/SKILL.md
    ├── image-vision/SKILL.md
    ├── image-vision/vision.py
    └── claude-config-sync/SKILL.md
```

## 添加到新设备

```bash
git clone git@github.com:wuwenjie0307/claude-config-sync.git
cd claude-config-sync

# Windows
powershell -ExecutionPolicy Bypass -File install.ps1 -VaultPath "C:\Users\you\Desktop\Obsidian"

# macOS / Linux
bash install.sh --vault-path ~/Documents/Obsidian --github-user yourname
```

然后：
1. 编辑 `~/.claude/mcp.json` → 填入 Brave API Key
2. 编辑 `~/.claude/settings.json` → 填入模型 API Key
3. 打开 Claude Code → 运行 `/plugin install understand-anything`
4. 重启 Claude Code

## 已知限制

| 风险 | 说明 |
|---|---|
| 第三方依赖 | `@lum1104/codegraph-mcp` 和 `Understand-Anything` 插件由个人维护，无 fallback 方案。若停更需自行寻找替代。 |
| SSH / Git 依赖 | 安装脚本假设已配置好 GitHub SSH 密钥和 `git`，未处理 HTTPS 回退。 |

## 回滚

如果安装出了问题：
```bash
# 恢复被覆盖的配置
cp -r ~/.claude/backups/<timestamp>/* ~/.claude/
```
