# RTX 3050 Ti Laptop (8GB 魔改) 功耗管理工具箱

Windows 批处理工具集：检测环境、查看状态、**自选功耗**、刷写官方签名 vBIOS、配置**开机自动应用功耗**。

针对"4 GB 颗粒魔改为 8 GB"的 RTX 3050 Ti Laptop 显卡设计。所有脚本在执行前会自动校验本机环境（系统版本、驱动、硬件 ID、显存、文件完整性、功耗范围、平台是否变更），不匹配时主动中止并说明原因。

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

### 0. 三条命令上手

```bat
bootstrap.bat                      :: 检查/修复运行环境（缺目录、缺文件、启动项失效）
scripts\preflight.bat              :: 环境预检（系统/驱动/硬件/文件/平台变更）
menu.bat                           :: 进入菜单，日常操作都在这里
```

`menu.bat` 首屏会直接显示：系统版本、权限、显卡型号、设备状态、DEV ID、显存、当前功耗范围。

### 1. 设置功耗（最常用）

```bat
scripts\set_powerlimit.bat         :: 交互式
scripts\set_powerlimit.bat 45      :: 直接指定
scripts\set_powerlimit.bat 0       :: 恢复固件默认值
```

- 可设范围由固件声明（通常 1 W ~ Max），超出范围会被拒绝。
- 应用后**回读校验**，生效才写入 `config\power_profile.txt`。

### 2. 开机自动应用功耗（可选）

```bat
setup\install_startup.bat          :: 安装（自动提权）
setup\remove_startup.bat           :: 卸载
```

安装后创建计划任务 `RTX3050Ti8G-PowerProfile`：登录后延迟 30 秒、最高权限、隐藏窗口运行 `scripts\startup_apply.bat`。

**安全设计**：配置不存在、数值非法、驱动未就绪（最多等 60 秒）、数值超出固件上限时，脚本**静默退出，不做任何修改**。

### 3. 刷写 / 回滚

```bat
scripts\flash_80w.bat              :: 刷 80W（强制先备份，二次确认）
scripts\flash_60w.bat              :: 回原厂（优先用本机备份）
scripts\backup_vbios.bat           :: 只备份当前 vBIOS
scripts\restore_backup.bat         :: 从历史备份中选一个刷回
```

---

## 兼容性与自适应行为

### 系统兼容矩阵

| 项目 | 支持范围 | 说明 |
|---|---|---|
| Windows 10 | 1809 (build 17763) 及以上 | 低于此版本直接拒绝 |
| Windows 11 | 21H2 起全部版本，含未来小版本 | 不按版本号硬编码，只按 build 判定 |
| 架构 | x64 / ARM64（x64 模拟） | 非 AMD64 只告警不中止 |
| PowerShell | 5.1（系统自带） | 缺失或版本过低 → 预检降级为纯批处理路径 |
| 语言/区域 | 任意 | 所有中文 UI 文本外置到 `lang\zh-CN.txt`，脚本本身纯 ASCII |
| 权限 | 普通用户可查；刷写/设功耗自动 UAC 提权 | 非管理员会明确报错而不是静默挂起 |

> **版本号不写死**：所有判断基于 `build` 数字与运行时探测结果，Windows 11 每次功能更新（22H2 / 23H2 / 24H2 / 26H2 …）都不需要改代码。

### 三类"环境变了"的场景

| 场景 | 检测方式 | 工具行为 |
|---|---|---|
| **缺软件环境**（驱动未装 / nvidia-smi 丢失 / PowerShell 被裁剪 / ROM 缺失） | `scripts\lib\probe.ps1` 三级探测：`Get-PnpDevice` → `Win32_VideoController` → 注册表 `Enum\PCI`；驱动缺失时仍能读到硬件 ID 与显存 | 预检返回 2（可运行但告警）或 1（阻断），并给出具体修复命令；`bootstrap.bat` 能自动建目录、校验工具哈希、按 `RTX3050TI_NVFLASH_URL` 重新下载 nvflash |
| **换主板 / 换 CPU / 整机更换** | `config\machine_profile.txt` 记录 `gpu_dev / gpu_subsys / gpu_vram_mb`，每次预检比对 | 首次运行写"新记录"；`DEV/SUBSYS/显存` 任一变化 → 标红"平台已变更"，**强制走备份流程**再允许刷写 |
| **换系统 / 换盘 / 目录搬家** | 计划任务里存的是绝对路径，预检用 `findstr` 比对当前根目录 | 路径失效 → 告警"已安装但路径指向旧目录"，并提示重跑 `setup\install_startup.bat` 自动重建 |

### 刷写安全链（缺一不可）

```
require_admin → preflight(0/2 才继续) → DEV==25A0 → 设备状态==OK
  → 驱动已加载 → 强制备份 → 备份文件 ≥ 900000 字节
  → 用户输入 YES → nvflash --protectoff → 刷写 → 分类结果
```

任一步失败即中止，**绝不在无备份的情况下写入固件**。

---

## 全部脚本

| 脚本 | 作用 | 需要管理员 |
|---|---|---|
| `menu.bat` | 统一入口菜单（12 项） | 否（具体操作时自动提权） |
| `bootstrap.bat` | 运行环境加载 / 修复：目录、工具哈希、ROM、启动项路径、磁盘 | 否 |
| `pack_release.bat` | 生成发布包（校验 → 打包 → 输出 SHA256） | 否 |
| `scripts\preflight.bat` | 环境预检，返回码 0=就绪 / 2=告警 / 1=阻断；`--quiet` 静默、`--nopause` 免暂停 | 否 |
| `scripts\env_check.bat` | 预检 + 启动配置 + 目录信息（给人看的完整版） | 否 |
| `scripts\status.bat` | 显存/功耗/频率/温度/驱动/vBIOS 版本 | 否 |
| `scripts\set_powerlimit.bat` | 自选功耗并保存配置 | 是 |
| `scripts\flash_80w.bat` | 刷入 80 W vBIOS（强制备份 + 风险确认） | 是 |
| `scripts\flash_60w.bat` | 恢复原厂 vBIOS | 是 |
| `scripts\backup_vbios.bat` | 备份当前 vBIOS 到 `backups\`，写 `backups\index.txt` | 是 |
| `scripts\restore_backup.bat` | 列出历史备份并选择刷回（支持 `--latest`） | 是 |
| `scripts\verify.bat` | 文件完整性校验：编码、SHA256、目录结构、语言表 | 否 |
| `scripts\startup_apply.bat` | 开机启动调用（由计划任务触发） | 计划任务以最高权限运行 |
| `setup\install_startup.bat` / `remove_startup.bat` | 安装 / 卸载开机启动项 | 是 |

所有需要权限的脚本都会**自动弹出 UAC 提权**，无需手动右键。

---

## 目录结构

```
RTX3050Ti-8G-Toolkit/
├─ menu.bat                    统一入口
├─ bootstrap.bat               环境加载 / 修复
├─ pack_release.bat            生成发布包
├─ VERSION
├─ lang/
│  └─ zh-CN.txt                全部中文 UI 文本（ID|文本，脚本本身纯 ASCII）
├─ scripts/
│  ├─ lib/
│  │  ├─ common.bat            调度器式公共库（探测/提权/校验/备份/刷写/消息）
│  │  ├─ probe.ps1             硬件探测（驱动缺失也能识别）
│  │  ├─ check_text.ps1        编码与换行校验
│  │  └─ pack.ps1              打包
│  ├─ preflight.bat / env_check.bat / status.bat / verify.bat
│  ├─ set_powerlimit.bat
│  ├─ flash_80w.bat / flash_60w.bat
│  ├─ backup_vbios.bat / restore_backup.bat
│  └─ startup_apply.bat
├─ setup/
│  ├─ install_startup.bat / remove_startup.bat
│  ├─ task_install.ps1         计划任务注册（Register-ScheduledTask）
│  └─ startup_launch.ps1       隐藏窗口 launcher
├─ roms/
│  ├─ RTX3050Ti_Laptop_94.07.3a.00.0e.rom   原厂 60W / 8GB
│  ├─ HP.RTX3050TiMobile.4096.210618.rom     官方签名 80W / 4GB SKU
│  ├─ SHA256SUMS.txt
│  └─ SOURCES.md               来源、授权与风险说明
├─ tools/
│  ├─ nvflashb.exe             NVIDIA 固件刷写工具（见致谢）
│  └─ SHA256SUMS.txt
├─ config/
│  ├─ power_profile.example.txt   功耗配置样例
│  └─ power_profile.txt           实际配置（运行后生成）
├─ backups/                     vBIOS 备份（.gitignore）
├─ dist/                        发布包产物（.gitignore）
├─ docs/
│  └─ 技术报告-签名机制与刷写结论.md
├─ logs/                        运行日志（.gitignore）
└─ .github/workflows/release.yml  CI：打 tag 自动构建 Release
```

---

## 打包与发布

```bat
pack_release.bat            :: 交互式
pack_release.bat --ci       :: CI 用，不暂停
```

流程：`verify.bat --pack-mode` 全量校验 → 复制白名单文件 → 剥离运行期产物（日志、备份、个人配置）→ 归一化 CRLF/去 BOM → 生成 `SHA256SUMS.txt` → 打 zip（正斜杠路径，跨平台解压安全）。

产物：`dist\RTX3050Ti-8G-Toolkit_v<版本>_win-x64.zip`，并打印大小与 SHA256。

发布到 GitHub：

1. 新建仓库并 push；
2. 打 tag（如 `v1.1.0`）后 push，`.github/workflows/release.yml` 会在 `windows-latest` 上自动构建并上传 Release 资产；
3. 或手动把 `dist\*.zip` 拖到 Release。

> 发布包已在全新目录做过端到端验证：解压 → `verify.bat` 全绿 → `bootstrap.bat` 就绪 → `menu.bat` 正常显示。

---

## 故障排查

### 刷 80 W 后独显不工作（设备管理器代码 10）

```bat
scripts\flash_60w.bat
```

若提示找不到设备：设备管理器 → 显示适配器 → 右键 "Microsoft 基本显示适配器" → **卸载设备**（不要勾选"删除驱动程序软件"）→ 重新执行上一步。

### `nvidia-smi` 不可用 / 找不到命令

显卡驱动未加载。先跑 `scripts\env_check.bat` 确认状态，再按上一条处理。

### 提示"输入无效"或"超过固件允许上限"

固件把功耗墙锁在某个值（常见 60 W / 85 W / 95 W，视固件而定）。脚本会显示当前实际范围，请在该范围内选择。

### 设置功耗后回读值没有变化

部分笔记本在运行时调整功耗墙会被 EC 拒绝，而 `nvidia-smi` 仍返回退出码 0。本工具在应用后会**回读校验**，未变化时给出警告且不写入配置。

这种情况下功耗只能通过更换 vBIOS 固件调整。

### 开机启动没有生效

查看 `logs\startup.log`，并重跑 `scripts\preflight.bat` 看"开机启动项"一节：

- `已安装, 但路径指向旧目录` → 目录搬过家/换过盘，重跑 `setup\install_startup.bat`；
- `未安装` → 没装；
- 已安装且路径有效但不生效 → 检查 `config\power_profile.txt` 是否存在、开机时驱动加载是否慢于 30 秒。

### 提示"平台已变更"

换过主板 / CPU / 整机，或显存容量与记录不符。这是**预期行为**：先跑 `scripts\backup_vbios.bat` 重新备份，确认无误后再继续。

### 界面出现 `[M0123]` 之类的方括号编号

说明 `lang\zh-CN.txt` 缺失或损坏（消息表未加载）。运行 `scripts\verify.bat` 查看，或重新解压发布包。

---

## 脚本编写约定（贡献者必读）

以下约束全部来自实测踩坑，改脚本前请先读完。

### 编码与文本

| 约束 | 原因 |
|---|---|
| `.bat` 文件必须是 **UTF-8 无 BOM + CRLF** 且**内容纯 ASCII** | `chcp 65001` 后 `cmd.exe` 读取含多字节字符的批处理会**文件指针漂移**，随机吞掉行首字符，表现为 `'注意:' 不是内部或外部命令`、`: was unexpected at this time`。插一个空行就能改变故障位置，极难排查 |
| 所有中文 UI 文本放 `lang\zh-CN.txt`，格式 `M0001\|文本` | 脚本只用 `call "%LIB%" msg M0001` 引用。新增文案只需加一行，不动批处理 |
| `lang\*.txt` 必须是 CRLF、无 BOM | `for /f` 逐行载入，BOM 会污染第一个 ID |

### 消息表机制（重要）

```
载入：init 时一次性把 M0001..M03xx 读进 MSG_M0001 环境变量（O(1) 查表）
查表：msgs 取 !MSG_<ID>!，做 {1}..{6} 位置替换，再用一次 for 变量回注完成 !VAR! 展开
输出：call echo %%MSGTXT%%
```

| 约束 | 原因 |
|---|---|
| 占位符在 `lang\zh-CN.txt` 里写成 `^!VAR^!` | 载入时 `for` 变量替换会先注入文本，caret 让 `!` 逃过那一轮延迟展开；随后查表时的一次 for 回注才会真正展开 |
| 文本里的变量必须用 `!VAR!`，**不能用 `%VAR%`** | `call echo %%MSGTXT%%` 只有两轮展开，`%VAR%` 出现在第二轮之后，永远不会被展开（实测会原样打印 `%GPU_VRAM_MB%`） |
| 不要在消息文本里写 `%%a` 这类 for 变量 | 消息是运行时字符串，for 变量在写入时已失效；应改成 `{1}` 占位符，由调用方传参 |

### 批处理语法

| 约束 | 原因 |
|---|---|
| `for /f ... in ("文件路径")` 必须加 `usebackq` | 否则引号内容被当字面量解析，读不到文件 |
| `for /f` 内的逗号必须写成 `^,` | `--format=csv^,noheader`、`--query-gpu=a^,b`；否则逗号被吞，nvidia-smi 报 `Option noheader is not recognized` |
| 括号块内一律用 `!VAR!`，不要用 `%VAR%` | 块内 `%VAR%` 在解析期展开，拿到的是调用前的旧值 |
| 块内 `echo` 文本不能含半角 `(` `)` | 会提前闭合括号块，报 `: was unexpected at this time` |
| 块内 `echo` 文本不能含 `!` | 延迟展开会把 `[!]` 吃掉，改用 `[WARN]` |
| `chcp 65001` 只在入口脚本执行一次 | `common.bat` 每条消息被调用一次，里面再跑 `chcp` 等于每条消息多一次进程创建（实测 +10 ms/条） |
| 跨文件调用统一用 `call "lib\common.bat" <命令> "参数"` | `cmd` 不支持跨文件 `call :label`；调度器模式且库内不能用 `setlocal`，否则变量传不回 |
| 传参一律加引号 | 未加引号时含空格的参数会被截断 |
| 需要管理员时先检查 `net session` | `nvflash` 在非管理员下打开显示驱动失败会**无限期挂起**，必须前置拦截 |
| 应用功耗后必须回读校验 | `nvidia-smi -pl` 被 EC 拒绝时仍返回退出码 0 |

### 自检

提交前跑：

```bat
scripts\verify.bat
```

会检查：所有 `.bat` 编码/换行/ASCII 注释、`nvflashb.exe` 与两个 ROM 的 SHA256、目录结构完整性、`lang\zh-CN.txt` 是否存在。

---

## 环境要求

- Windows 10 (1809+) / Windows 11（x64）
- PowerShell 5.1（系统自带）
- NVIDIA 驱动已安装，且能识别到 RTX 3050 Ti **Laptop**
- 刷写功能需要管理员权限（脚本自动提权）
- 磁盘约 25 MB（工具本体）+ 2 MB（ROM）

---

## 技术结论摘要

为什么本项目不提供"修改 ROM 功耗值再刷入"的功能？（完整版见 `docs/技术报告-签名机制与刷写结论.md`）

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
