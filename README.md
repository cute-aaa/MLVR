# MLVR

**M**adVR + **L**AVFilters + **V**apourSynth + vs-**R**IFE — PotPlayer 一键增强安装脚本

---

## 中文说明

### 这是什么

一键脚本，自动安装和配置 PotPlayer 的增强组件：

| 组件 | 作用 |
|------|------|
| **madVR** | 高质量视频渲染器，支持 HDR、色彩管理 |
| **LAV Filters** | 全能解码器（Video/Audio/Splitter），支持几乎所有格式 |
| **VapourSynth** | 视频处理框架，配合 vsrife 插件实现 AI 补帧 |
| **vs-rife** | RIFE 补帧插件，将帧率提升 2 倍（如 30fps→60fps） |

### 脚本功能

- 自动检测 PotPlayer 安装路径（注册表 / 手动输入）
- 静默安装 LAV Filters（64位组件）
- 解压并注册 madVR
- 下载并安装 VapourSynth Portable（含 Python 3.14 embeddable）
- 安装 vs-rife 补帧插件
- **自动配置 PotPlayer INI 文件**：
  - 添加 LAV Video/Audio/Splitter 滤镜（Prefer 优先级）
  - 设置 madVR 为默认渲染器
  - 启用 VapourSynth RIFE 2x 补帧脚本

### 使用方法

1. 下载本仓库
2. 将以下文件放到脚本同目录：
   - `LAVFilters-0.82-Installer.exe`（[GitHub Releases](https://github.com/Nevcairiel/LAVFilters/releases)）
   - `madvr*.zip`（[madVR 官网](https://www.madshi.net/)）
3. 右键 `MLVR.bat` → **以管理员身份运行**
4. 按提示选择 Python 环境和是否安装 vs-rife

### 前置要求

- Windows 10/11 (x64)
- PotPlayer 已安装
- 网络连接（下载 VapourSynth 需要访问 github.com 和 python.org）

### 文件结构

```
MLVR.bat            # 中文版脚本
MLVR-en.bat         # English version
README.md           # 本文档
.gitignore
vapoursynth/
  rife_2x.vpy       # RIFE 2x 补帧脚本（自动部署）
```

---

## English

### What is this

One-click script to install and configure PotPlayer enhancement components:

| Component | Purpose |
|-----------|---------|
| **madVR** | High-quality video renderer with HDR and color management |
| **LAV Filters** | Universal decoder suite (Video/Audio/Splitter) for nearly all formats |
| **VapourSynth** | Video processing framework, used with vsrife for AI frame interpolation |
| **vs-rife** | RIFE frame interpolation plugin, doubles frame rate (e.g. 30fps→60fps) |

### What the script does

- Auto-detects PotPlayer installation path (registry / manual input)
- Silent-installs LAV Filters (64-bit components)
- Extracts and registers madVR
- Downloads and installs VapourSynth Portable (with Python 3.14 embeddable)
- Installs vs-rife frame interpolation plugin
- **Auto-configures PotPlayer INI file**:
  - Adds LAV Video/Audio/Splitter filters (Prefer merit)
  - Sets madVR as default renderer
  - Enables VapourSynth RIFE 2x interpolation script

### Usage

1. Download this repository
2. Place these files in the same directory as the script:
   - `LAVFilters-0.82-Installer.exe` ([GitHub Releases](https://github.com/Nevcairiel/LAVFilters/releases))
   - `madvr*.zip` ([madVR website](https://www.madshi.net/))
3. Right-click `MLVR-en.bat` → **Run as administrator**
4. Follow prompts to choose Python environment and install vs-rife

### Prerequisites

- Windows 10/11 (x64)
- PotPlayer installed
- Internet connection (VapourSynth download requires github.com and python.org)

### File structure

```
MLVR.bat            # Chinese version
MLVR-en.bat         # English version
README.md           # This file
.gitignore
vapoursynth/
  rife_2x.vpy       # RIFE 2x interpolation script (auto-deployed)
```
