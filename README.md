# RTX 3050 Ti Laptop (8GB 魔改) 功耗管理工具箱

Windows 批处理工具集：检测环境、查看状态、**自选功耗**、刷写官方签名 vBIOS、配置**开机自动应用功耗**。

针对"4 GB 颗粒魔改为 8 GB"的 RTX 3050 Ti Laptop 显卡设计，所有脚本在执行前会自动校验本机环境（型号、驱动、文件完整性、功耗范围），不匹配时主动中止。

---

## ⚠️ 先读这一段（风险与适用性）

| 结论 | 说明 |
|---|---|
| ✅ **可用** | 自选功耗（1 W ~ 固件声明上限）、状态查看、环境自检、开机启动自动应用 |
| ⚠️ **有风险** | 刷入 80 W vBIOS：80 W 固件来自 4 GB SKU 机型，在 8 GB 魔改卡上**可能导致冷启动后独显失效（设备代码 10）**，可用本工具一键回滚 |
| ❌ **不可行** | "自己修改原厂 ROM 的功耗数值再刷入"：被 NVIDIA 固件签名机制封死，软件无解（5 组对照实验已证伪，详见 `docs/`） |

> 本工具只使用**官方签名的原厂固件**，不修改任何固件内容，风险边界清晰、可回滚。

---

## 快速开始

### 1. 获取与自检

```bat
:: 双击 menu.bat 选择 [1] 环境自检, 或直接运行
scripts\env_check.bat
```

自检会输出：显卡型号、驱动状态、当前功耗范围、工具/ROM 完整性、开机启动项状态。

### 2. 设置功耗（最常用）

```bat
:: 交互式: 直接回车脚本, 输入瓦数
scripts\set_powerlimit.bat

:: 或直接指定
scripts\set_powerlimit.bat 45
```

- 可设范围由固件声明（通常 1 W ~ Max）。超出范围会被拒绝并给出提示。
- 设置结果自动保存到 `config\power_profile.txt`。

### 3. 开机自动应用功耗（可选）

```bat
setup\install_startup.bat     :: 安装（需管理员，自动提权）
setup\remove_startup.bat      :: 卸载
```

安装后创建计划任务 `RTX3050Ti8G-PowerProfile`：用户登录后延迟 30 秒、以最高权限运行 `scripts\startup_apply.bat`，读取 `config\power_profile.txt` 并应用。

**安全设计**：配置不存在、数值非法、显卡驱动未就绪（最多等待 60 秒）、或数值超出固件上限时，脚本**静默退出，不做任何修改**，绝不触碰固件。

---

## 全部脚本

| 脚本 | 作用 | 需要管理员 |
|---|---|---|
| `menu.bat` | 统一入口菜单 | 否（执行具体操作时自动提权） |
| `scripts\env_check.bat` | 环境自检 | 否 |
| `scripts\status.bat` | 查看显存/功耗/频率/温度/BIOS 版本 | 否（读 BIOS 版本需要） |
| `scripts\set_powerlimit.bat` | 自选功耗并保存配置 | 是 |
| `scripts\flash_80w.bat` | 刷入 80 W vBIOS（含风险确认与回滚提示） | 是 |
| `scripts\flash_60w.bat` | 恢复原厂 60 W vBIOS（安全，随时可执行） | 是 |
| `scripts\startup_apply.bat` | 开机启动调用（由计划任务触发，无需手动运行） | 计划任务以最高权限运行 |
| `setup\install_startup.bat` | 安装开机启动项 | 是 |
| `setup\remove_startup.bat` | 卸载开机启动项 | 是 |

所有需要权限的脚本都会**自动弹出 UAC 提权**，无需手动右键。

---

## 目录结构

```
RTX3050Ti-8G-Toolkit/
├─ menu.bat                    统一入口
├─ scripts/
│  ├─ lib\common.bat           公共函数库（提权/检测/校验/日志）
│  ├─ env_check.bat            环境自检
│  ├─ status.bat               状态查询
│  ├─ set_powerlimit.bat       自选功耗
│  ├─ flash_80w.bat            刷 80W（含风险确认）
│  ├─ flash_60w.bat            回滚原厂
│  └─ startup_apply.bat        开机启动脚本
├─ setup/
│  ├─ install_startup.bat      安装开机启动
│  └─ remove_startup.bat       卸载开机启动
├─ roms/
│  ├─ RTX3050Ti_Laptop_94.07.3a.00.0e.rom   原厂 60W / 8GB
│  ├─ HP.RTX3050TiMobile.4096.210618.rom     官方签名 80W / 4GB SKU
│  └─ SOURCES.md               来源、授权与风险说明
├─ tools/
│  └─ nvflashb.exe             NVIDIA 固件刷写工具（见致谢）
├─ config/
│  └─ power_profile.txt        功耗配置（由 set_powerlimit.bat 生成）
├─ docs/
│  └─ 技术报告-签名机制与刷写结论.md   完整技术分析（为什么不能改 ROM）
├─ logs/                       运行日志（自动生成，不纳入版本控制）
└─ README.md
```

---

## 故障排查

### 刷 80 W 后独显不工作（设备管理器代码 10）

这是本工具已知的风险场景（80 W 固件来自 4 GB SKU，冷启动显存训练可能失败）。

```bat
scripts\flash_60w.bat
```

若提示找不到设备：设备管理器 → 显示适配器 → 右键 "Microsoft 基本显示适配器" → **卸载设备**（不要勾选"删除驱动程序软件"）→ 重新执行上一步。

### `nvidia-smi` 不可用 / 找不到命令

说明显卡驱动未加载。先用 `scripts\env_check.bat` 确认状态，再按上面第 3 条处理。

### 提示"输入无效"或"超过固件允许上限"

固件把功耗墙锁定在某个值（常见 60 W / 85 W / 95 W，视固件而定）。脚本会显示当前实际范围，请在该范围内选择。

### 设置功耗后回读值没有变化

部分笔记本（含本项目作者使用的机型）在运行时调整功耗墙会被笔记本 EC 拒绝，而 `nvidia-smi` 仍返回成功退出码。因此本工具在应用后会**回读校验**：若数值未变化会给出警告。

这种情况下功耗只能通过更换 vBIOS 固件调整（`flash_80w.bat` / `flash_60w.bat`）。

### 开机启动没有生效

查看 `logs\startup.log`。常见原因：`config\power_profile.txt` 不存在、开机时驱动加载慢于 30 秒（可重新运行 `setup\install_startup.bat` 生成带延迟任务）、或当时显卡驱动加载失败、或该机型不支持运行时调功耗（见上一条）。

---

## 脚本编写约定（贡献者必读）

本项目批处理在 Windows `cmd.exe` 下运行，以下约束来自实测踩坑，修改脚本时请遵守：

| 约束 | 原因 |
|---|---|
| 文件必须保存为 **UTF-8 无 BOM + CRLF** 换行 | BOM 会被 `cmd` 当作命令执行；LF 换行在部分场景异常 |
| **`rem` 注释只能用 ASCII** | `chcp 65001` 之后，`cmd` 会在多字节注释处丢失文件指针，把注释内容当命令执行（表现为 `'xxx' 不是内部或外部命令`）。中文只能出现在 `echo` 输出中 |
| **`for /f` 内的逗号必须写成 `^,`** | `--format=csv^,noheader`、`--query-gpu=a^,b`；否则逗号被吞导致 nvidia-smi 报 `Option noheader is not recognized` |
| 括号块内一律用 `!VAR!`，不要用 `%VAR%` | 块内 `%VAR%` 在解析期展开，拿到的是调用前的旧值 |
| 跨文件调用统一用 `call "lib\common.bat" <命令> "参数"` | `cmd` 不支持 `call :label` 跨文件；调度器模式且库内不能用 `setlocal`，否则变量无法传回 |
| **传给调度器的多词文本必须加引号** | 未加引号时只有第一个词会作为 `%~2` 被接收 |
| 数值校验在调用方内联实现 | 跨文件 `call` 中的 `for /f` 解析行为与单文件内不一致，实测会导致合法值被误判 |
| 应用功耗后必须回读校验 | `nvidia-smi -pl` 在被 EC 拒绝时仍返回退出码 0 |

---

## 环境要求

- Windows 10 / 11（x64）
- NVIDIA 驱动已安装，且能识别到 RTX 3050 Ti **Laptop**
- 刷写功能需要管理员权限（脚本自动提权）
- 磁盘约 25 MB（工具本体）+ 2 MB（ROM）

---

## 技术结论摘要

为什么本项目不提供"修改 ROM 功耗值再刷入"的功能？以下是实测结论（完整版见 `docs/技术报告-签名机制与刷写结论.md`）：

1. RTX 30 系起 NVIDIA 启用 **BIOS Certificate 2.0（RSA 签名 + HMAC 校验）**，覆盖整个 vBIOS 镜像；
2. 改一个字节即签名失效，**无法伪造**（需要 NVIDIA 私钥）；
3. GPU 的 Falcon uCode 在真正的写入命令（`NV_UCODE_CMD_COMMAND_EWR`）阶段会再次校验镜像（"OK to flash" 检查）；
4. 官方 nvflash、OMGVflash、nvflashk 均无法写入未签名镜像；本项目作者亦通过自制二进制补丁（跳过主机侧校验）验证过，**依然被 GPU 侧拒绝**。

因此：**唯一可靠的提功耗路径是刷入官方签名的 80 W 固件**，代价是必须接受 4 GB SKU 固件在魔改卡上的冷启动风险。

---

## 致谢与许可

- 刷写工具 [nvflashb.exe](https://github.com/WillyBilly06/NVFLASH)（MIT License，作者 WillyBilly06，基于 NVIDIA 官方 nvflash 5.867）
- vBIOS 数据参考 [TechPowerUp GPU vBIOS Collection](https://www.techpowerup.com/vgabios/)
- 本项目代码以 MIT 许可证发布，详见 `LICENSE`

## 免责声明

刷写 vBIOS 存在导致显卡无法使用的风险，且可能影响保修。请务必：

- 已确认自身设备与固件适配后再操作；
- 保持电源稳定，刷写期间不要断电或强制关机；
- 保留本仓库中的原厂 ROM 作为回滚手段。

作者不对使用本工具造成的任何硬件损坏承担责任。
