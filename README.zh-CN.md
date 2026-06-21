# ansible-role-meilisearch（中文）

在 Linux 上以 systemd 服务的形式安装、配置并升级 [Meilisearch](https://www.meilisearch.com/) 搜索引擎的 Ansible role。

> 本文以**常用配置与示例**为主。完整变量参考、全部说明与更多示例请见英文文档：[README.md](README.md) 与 [EXAMPLES.md](EXAMPLES.md)。
>
> 本 role 面向 Meilisearch v1.19+，更老的版本可能不适用。

## 功能简介

- 创建用户与用户组
- 下载并全新安装二进制（仅在缺失时安装；仅在开启升级且目标版本更高时升级）
- 可选 SHA256 校验，内置部分版本的校验值
- 渲染 TOML 配置与可选的环境变量文件（含 `master_key` 的任务默认 `no_log`）
- 配置并管理 systemd 服务（含一组安全加固指令）
- 服务启动后做端口监听与 `/health` 健康检查
- 两种升级流程：**dumpless**（原地迁移）与 **dump**（导出→换二进制→导入）；升级前先快照/备份，失败时尽力回滚（dump 完整回滚，dumpless 仅回滚下载失败）
- 版本比对：同版本空操作、阻止降级、阻止 dumpless 跨大版本升级
- 计划快照配置

## 环境要求

- Ansible >= 2.18
- 目标主机支持 systemd 与 python3
- 安装/升级官方 Linux 二进制需 glibc >= 2.35（仅对已存在二进制做纯配置时不受此限制）
- 可访问网络以下载 Meilisearch 二进制
- 开启 fact 采集（role 使用 `ansible_facts.architecture` 与 `ansible_facts.date_time`）

支持架构：x86_64 (amd64)、ARM64 (aarch64)。CI 默认在 Debian 12 与 Ubuntu 24.04 上测试。

> Rocky Linux 9 / EL9 自带 glibc 2.34，无法运行当前官方二进制；请改用受支持的发行版、Docker，或预置自行编译的二进制。

## 快速开始

最小化全新安装。`meilisearch_env` 默认为 `production`，此时 `meilisearch_master_key` **必填且至少 16 字节**，建议用 `openssl rand -hex 16` 生成并存入 ansible-vault：

```yaml
- name: Install Meilisearch
  hosts: search
  become: true
  vars:
    meilisearch_master_key: "{{ vault_meilisearch_master_key }}"
  roles:
    - eyebrowkang.meilisearch
```

## 常用变量

仅列最常用项；完整变量表见 [README.md](README.md#role-variables)。

| 变量                            | 默认值                               | 说明                                                       |
| ------------------------------- | ------------------------------------ | ---------------------------------------------------------- |
| `meilisearch_master_key`        | （生产必填）                         | API 主密钥；`production` 下必填且 ≥16 字节，`openssl rand -hex 16` 生成 |
| `meilisearch_version`           | `"v1.33.1"`                          | 安装/升级的目标版本（必须以 `v` 开头）                     |
| `meilisearch_env`               | `"production"`                       | 运行环境（`production` 或 `development`）                  |
| `meilisearch_http_addr`         | `"localhost:7700"`                   | 监听地址（`host:port` 或 `[IPv6]:port`，不带协议头）       |
| `meilisearch_db_path`           | `"{{ meilisearch_home }}/data"`      | 数据库存储路径                                             |
| `meilisearch_schedule_snapshot` | `false`                              | 计划快照（`false` 或正整数秒）                            |
| `meilisearch_upgrade`           | `""`                                 | 升级模式：`""`（不升级）、`"dump"`、`"dumpless"`           |
| `meilisearch_config_custom_options` | `""`                             | 由自带模板追加的原样 TOML 行                               |
| `meilisearch_env_variables`     | `{}`                                 | 渲染为可选 systemd 环境变量文件的字典                      |
| `meilisearch_no_log`            | `true`                               | 隐藏可能含密钥的任务输出（仅调试时设为 `false`）          |

## 基本配置示例

### 自定义配置与环境变量

```yaml
- name: Install Meilisearch with custom config
  hosts: search
  become: true
  vars:
    meilisearch_master_key: "{{ vault_meilisearch_master_key }}"
    meilisearch_http_addr: "0.0.0.0:7700" # 监听全部 IPv4；健康检查走 127.0.0.1
    meilisearch_schedule_snapshot: 3600
    meilisearch_env_variables:
      MEILI_LOG_LEVEL: "WARN"
  roles:
    - eyebrowkang.meilisearch
```

### IPv6 监听

```yaml
- name: Install Meilisearch with IPv6 bind
  hosts: search
  become: true
  vars:
    meilisearch_master_key: "{{ vault_meilisearch_master_key }}"
    meilisearch_http_addr: "[::]:7700"
  roles:
    - eyebrowkang.meilisearch
```

### 升级（dumpless / dump）

```yaml
- name: Upgrade Meilisearch (dumpless)
  hosts: search
  become: true
  vars:
    meilisearch_version: "v1.33.1"
    meilisearch_upgrade: "dumpless"
    meilisearch_master_key: "{{ vault_meilisearch_master_key }}"
  roles:
    - eyebrowkang.meilisearch
```

把 `meilisearch_upgrade` 改为 `"dump"` 即走 dump 流程（导出→备份数据目录→换二进制→导入）。dump 与 dumpless 的完整示例见 [EXAMPLES.md](EXAMPLES.md#dumpless-upgrade)。

## 升级说明

- 不设 `meilisearch_upgrade` 时，仅在 `/usr/local/bin/meilisearch` 缺失时才下载，**不会**因为 `meilisearch_version` 变了就替换已有二进制。
- 版本比对、同版本空操作、降级阻止仅在设置了 `meilisearch_upgrade` 时生效；升级完成后请把它改回 `""` 再做日常配置运行。
- **dumpless 跨大版本升级会被拒绝**——dump 才是 Meilisearch 官方的跨大版本机制，跨大版本请用 `meilisearch_upgrade: dump`。
- **升级期间不要同时改动** `meilisearch_db_path`、`meilisearch_dump_dir`、`meilisearch_snapshot_dir`、`meilisearch_http_addr`：role 会在升级前比对已部署 TOML，若不一致会提前失败；请在升级健康后另起一次运行再改这些路径/地址。
- 失败处理：两种流程升级前都会先创建快照/备份。**dump** 流程若导入未健康，会还原数据目录与旧二进制并重启旧服务；**dumpless** 流程仅在**下载失败**时还原旧二进制并重启，而**迁移本身失败时不会自动回滚**（半迁移的 DB 无法靠换回旧二进制恢复）——此时请用升级前的快照恢复。

## 配置模板与校验

自带模板 `meilisearch.toml.j2` 覆盖常见场景。需要更细的配置时，有两种方式：

- **加性扩展**：用 `meilisearch_config_custom_options` 追加原样 TOML 行（不要重复自带模板已渲染的键）。
- **整体替换**：用 `meilisearch_config_template` 指定你自己的模板。

一旦整体替换模板，升级期的「敏感路径未变」校验会**被跳过**（该校验依赖读取自带模板渲染的 TOML 文本），此时由你自行保证升级期间不改动数据路径。`master_key` 长度、架构、版本格式、`http_addr` 格式等**内禀校验**仍始终执行。

## 密钥管理（ansible-vault）

```bash
ansible-vault create group_vars/search/vault.yml
```

```yaml
# group_vars/search/vault.yml
vault_meilisearch_master_key: "8d98d6a3143bc0d83be006e7bacbb46c"
```

生成主密钥：

```bash
openssl rand -hex 16
```

## 测试

本 role 使用 [Molecule](https://ansible.readthedocs.io/projects/molecule/) 测试，全部场景基于 systemd 的 Docker 容器：

```bash
uv sync            # 安装本地开发工具链
make test          # docker 冒烟测试（default 场景）

# 单独运行某个功能场景
uv run molecule test -s upgrade_dump
uv run molecule test -s negative
```

场景：`default`、`http_addr`、`production_master_key`、`config_options`、`upgrade_dump`、`upgrade_dumpless`、`negative`。

## 更多

- 完整变量参考与说明：[README.md](README.md)
- 全部示例（自定义配置、IPv6、升级、vault 等）：[EXAMPLES.md](EXAMPLES.md)

## 许可证

MIT
