# Antigravity Auto-Retry (macOS Native Menu Bar & CLI Tool)

专为 **Antigravity** 与 **Antigravity IDE** 设计的 macOS 原生极速自动 Retry 监控工具。

在遭遇 Claude 模型报错（`Agent terminated due to error`）或网络/风控拦截（`Our servers are experiencing high traffic right now`）时，本工具使用 macOS 原生 Vision 硬件加速 OCR 识别，**以极短间隔自动、连续点击 Retry 按钮**，直到模型恢复工作。

---

## 🌟 核心功能特性

- ⚡ **即时连续重试 (Continuous Aggressive Retry)**：打破手动频点击的繁琐，自动监控 `Antigravity` / `Antigravity IDE` 窗口画面，检测到 `Retry` 按钮即刻触发点击。
- 🔍 **零依赖原生 Vision OCR**：采用 macOS 系统的 `Vision.framework` 硬件加速文字识别，无需安装任何 Python 包、Tesseract 或第三方库。
- 🖱️ **鼠标坐标还原**：自动记录点击前用户的光标位置，点击 `Retry` 后瞬间复位，完全不干扰日常键盘打字与鼠标操作。
- 🔄 **macOS 顶部状态栏 Menu Bar App**：
  - 动态显示运行状态 `🔄 Retry (Active)` / `⏸️ Retry (Paused)`
  - 支持快捷切换重试频率：`⚡ 0.5s (Instant)` | `⏱️ 1.0s (Default)` | `2.0s` | `5.0s`
  - 实时统计累计成功自动重试次数
- 🖥️ **CLI 模式**：支持终端静默运行及后台开机自启。

---

## 🛠️ 构建与安装

### 1. 本地一键构建
```bash
make build
```
编译成功后会在项目根目录下生成 `antigravity-retry` 可执行文件。

### 2. 运行状态栏菜单应用
```bash
make run
# 或直接运行
./antigravity-retry
```
运行后，macOS 顶部状态栏（Menu Bar）会出现 `🔄 Retry (Active)` 图标。

### 3. 一键安装到系统可执行路径
```bash
make install
```
将程序安装至 `~/.local/bin/antigravity-retry`。

---

## 🔐 macOS 权限配置说明

由于本工具需要捕获 Antigravity 窗口画面并发送鼠标点击指令，首次运行时 macOS 会弹出权限申请：

1. **屏幕录制权限 (Screen Recording)**：
   - 打开 `系统设置 (System Settings)` -> `隐私与安全性 (Privacy & Security)` -> `屏幕与系统音频录制 (Screen & System Audio Recording)`。
   - 勾选 `antigravity-retry` 或你运行该程序的终端应用程序（如 Terminal / iTerm / VS Code / Antigravity）。

2. **辅助功能权限 (Accessibility)**：
   - 打开 `系统设置 (System Settings)` -> `隐私与安全性 (Privacy & Security)` -> `辅助功能 (Accessibility)`。
   - 允许 `antigravity-retry` 或终端应用控制你的电脑（用于发送点击事件）。

---

## ⚙️ 命令行选项

```bash
./antigravity-retry --help
```

- `./antigravity-retry` : 以 macOS 顶部状态栏 App 模式运行（推荐）。
- `./antigravity-retry --cli` : 以 CLI 后台静默模式运行。
- `./antigravity-retry --cli --interval 0.5` : 设置以 0.5 秒频率连续扫描重试。
- `./antigravity-retry --test-ocr` : 执行单次 OCR 测试，输出窗口检测情况。
