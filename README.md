# ansible-role-meilisearch

An Ansible role to install, configure, and upgrade Meilisearch as a systemd service on Linux systems.

> **Note:** This role targets Meilisearch v1.19+ and may not work with older versions.

## Description

This role automates the deployment of [Meilisearch](https://www.meilisearch.com/), a fast and relevant search engine. It handles:

- User and group creation
- Binary download and installation (fresh install only, no version-based overwrite)
- SHA256 checksum verification (with built-in checksums for known versions)
- TOML configuration and environment file deployment
- Systemd service setup and management
- Health check verification
- Dumpless upgrade flow for version upgrades
- Dump-based upgrade flow for version upgrades
- Automatic version comparison to skip unnecessary upgrades and prevent downgrades
- Scheduled snapshot configuration

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

| Variable                                       | Default                              | Description                                                            |
| ---------------------------------------------- | ------------------------------------ | ---------------------------------------------------------------------- |
| `meilisearch_version`                          | `"v1.33.1"`                          | Meilisearch version to install/upgrade to (must start with `v`)        |
| `meilisearch_user`                             | `"meilisearch"`                      | System user to run Meilisearch                                         |
| `meilisearch_group`                            | `"meilisearch"`                      | System group for Meilisearch                                           |
| `meilisearch_home`                             | `"/var/lib/meilisearch"`             | Home directory for the Meilisearch user                                |
| `meilisearch_config_dir`                       | `"/etc/meilisearch"`                 | Directory for configuration files                                      |
| `meilisearch_db_path`                          | `"{{ meilisearch_home }}/data"`      | Database storage path                                                  |
| `meilisearch_env`                              | `"production"`                       | Instance environment (`production` or `development`)                   |
| `meilisearch_http_addr`                        | `"localhost:7700"`                   | HTTP listen address (`host:port` or `[IPv6]:port`)                     |
| `meilisearch_no_analytics`                     | `true`                               | Disable built-in telemetry                                             |
| `meilisearch_dump_dir`                         | `"{{ meilisearch_home }}/dumps"`     | Directory for dump files                                               |
| `meilisearch_snapshot_dir`                     | `"{{ meilisearch_home }}/snapshots"` | Directory for snapshot files                                           |
| `meilisearch_schedule_snapshot`                | `false`                              | Schedule periodic snapshots (`false` or a positive integer in seconds) |
| `meilisearch_upgrade`                          | `""`                                 | Upgrade mode: `""` (none), `"dump"`, or `"dumpless"`                   |
| `meilisearch_checksum`                         | `""`                                 | SHA256 checksum for binary verification (overrides built-in checksums) |
| `meilisearch_upgrade_snapshot_timeout_retries` | `60`                                 | Number of retries when polling upgrade snapshot/dump task status       |
| `meilisearch_upgrade_snapshot_poll_interval`   | `10`                                 | Seconds between polls when checking upgrade snapshot/dump task status  |
| `meilisearch_import_health_retries`            | `30`                                 | Retries when waiting for health after dump import                      |
| `meilisearch_import_health_delay`              | `10`                                 | Seconds between health checks after dump import                        |
| `meilisearch_config_template`                  | `"meilisearch.toml.j2"`              | Path to a custom TOML config template                                  |
| `meilisearch_config_custom_options`            | `""`                                 | Raw TOML lines appended to the generated config file (default template only) |
| `meilisearch_env_variables`                    | `{}`                                 | Dict of environment variables for the env file (created when non-empty, removed when empty) |

### Notes

- `meilisearch_http_addr` must be `host:port` or `[IPv6]:port` (no scheme).
- If `meilisearch_http_addr` is `0.0.0.0` or `::`, the role uses `127.0.0.1` or `::1` for internal health checks.
- `meilisearch_config_custom_options` and `meilisearch_config_template` are mutually exclusive; if both are set, the template takes precedence and custom options are ignored.
- The environment file is rendered only when `meilisearch_env_variables` is non-empty and removed otherwise.

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
    meilisearch_http_addr: "0.0.0.0:7700" # bind all IPv4; health checks use 127.0.0.1
    meilisearch_schedule_snapshot: 3600
    meilisearch_env_variables:
      MEILI_LOG_LEVEL: "WARN"
  roles:
    - eyebrowkang.meilisearch
```

### IPv6 Listen Address

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

### Dumpless Upgrade

Upgrade an existing Meilisearch instance to a new version using the dumpless upgrade feature. The role will create a snapshot, stop the service, download the new binary, run the upgrade, and restart.

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

### Dump-Based Upgrade

Upgrade by creating a dump, backing up the data directory, installing the new binary, and importing the dump. This is useful when the dumpless upgrade is not available or not desired.

```yaml
- name: Upgrade Meilisearch (dump)
  hosts: search
  become: true
  vars:
    meilisearch_version: "v1.33.1"
    meilisearch_upgrade: "dump"
    meilisearch_master_key: "{{ vault_meilisearch_master_key }}"
    meilisearch_import_health_retries: 60
    meilisearch_import_health_delay: 5
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
