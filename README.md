# ansible-role-meilisearch

An Ansible role to install, configure, and upgrade Meilisearch as a systemd service on Linux systems.

## Description

This role automates the deployment of [Meilisearch](https://www.meilisearch.com/), a fast and relevant search engine. It handles:

- User and group creation
- Binary download and installation (fresh install only, no version-based overwrite)
- TOML configuration and environment file deployment
- Systemd service setup and management
- Health check verification
- Dumpless upgrade flow for version upgrades

## Requirements

- Ansible >= 2.16
- Target system with systemd support
- Internet access for downloading Meilisearch binary

## Supported Platforms

### Linux

Any Linux distribution with systemd support and python3 installed. Tested on Debian 12.

### Architectures

- x86_64 (amd64)
- ARM64 (aarch64)

## Role Variables

### Required Variables

| Variable                 | Description                                                                                 |
| ------------------------ | ------------------------------------------------------------------------------------------- |
| `meilisearch_master_key` | Master key for securing Meilisearch API. Required for production and for dumpless upgrades. |

### Default Variables

| Variable                      | Default                              | Description                                          |
| ----------------------------- | ------------------------------------ | ---------------------------------------------------- |
| `meilisearch_version`         | `"v1.19.1"`                          | Meilisearch version to install/upgrade to            |
| `meilisearch_user`            | `"meilisearch"`                      | System user to run Meilisearch                       |
| `meilisearch_group`           | `"meilisearch"`                      | System group for Meilisearch                         |
| `meilisearch_home`            | `"/var/lib/meilisearch"`             | Home directory for the Meilisearch user              |
| `meilisearch_config_dir`      | `"/etc/meilisearch"`                 | Directory for configuration files                    |
| `meilisearch_db_path`         | `"{{ meilisearch_home }}/data"`      | Database storage path                                |
| `meilisearch_env`             | `"production"`                       | Instance environment (`production` or `development`) |
| `meilisearch_http_addr`       | `"localhost:7700"`                   | HTTP listen address                                  |
| `meilisearch_no_analytics`    | `true`                               | Disable built-in telemetry                           |
| `meilisearch_dump_dir`        | `"{{ meilisearch_home }}/dumps"`     | Directory for dump files                             |
| `meilisearch_snapshot_dir`    | `"{{ meilisearch_home }}/snapshots"` | Directory for snapshot files                         |
| `meilisearch_upgrade`         | `""`                                 | Set to `"dumpless"` to perform a dumpless upgrade    |
| `meilisearch_config_template` | `"meilisearch.toml.j2"`              | Path to a custom TOML config template                |
| `meilisearch_env_variables`   | `{}`                                 | Dict of environment variables for the env file       |

## Dependencies

None.

## Examples

### Minimal - Fresh Install

```yaml
- name: Install Meilisearch
  hosts: search
  become: true
  vars:
    meilisearch_master_key: "{{ vault_meilisearch_master_key }}"
  roles:
    - eyebrowkang.meilisearch
```

### Custom Configuration and Environment Variables

```yaml
- name: Install Meilisearch with custom config
  hosts: search
  become: true
  vars:
    meilisearch_master_key: "{{ vault_meilisearch_master_key }}"
    meilisearch_http_addr: "0.0.0.0:7700"
    meilisearch_env_variables:
      MEILI_LOG_LEVEL: "WARN"
  roles:
    - eyebrowkang.meilisearch
```

### Dumpless Upgrade

Upgrade an existing Meilisearch instance to a new version using the dumpless upgrade feature. The role will create a snapshot, stop the service, download the new binary, run the upgrade, and restart.

```yaml
- name: Upgrade Meilisearch
  hosts: search
  become: true
  vars:
    meilisearch_version: "v1.20.0"
    meilisearch_upgrade: "dumpless"
    meilisearch_master_key: "{{ vault_meilisearch_master_key }}"
  roles:
    - eyebrowkang.meilisearch
```

### Vault Usage

Store your master key securely with ansible-vault:

```bash
# Create an encrypted vault file
ansible-vault create group_vars/search/vault.yml
```

```yaml
# group_vars/search/vault.yml
vault_meilisearch_master_key: "8d98d6a3143bc0d83be006e7bacbb46c"
```

Generate a master key:

```bash
openssl rand -hex 16
```

## License

MIT
