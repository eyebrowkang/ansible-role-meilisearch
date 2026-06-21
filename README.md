# ansible-role-meilisearch

[![CI](https://github.com/eyebrowkang/ansible-role-meilisearch/actions/workflows/ci.yml/badge.svg)](https://github.com/eyebrowkang/ansible-role-meilisearch/actions/workflows/ci.yml)

An Ansible role to install, configure, and upgrade Meilisearch as a systemd service on Linux systems.

📖 [中文文档 / Chinese README](README.zh-CN.md) · [Examples](EXAMPLES.md)

> **Note:** This role targets Meilisearch v1.19+ and may not work with older versions.

## Description

This role automates the deployment of [Meilisearch](https://www.meilisearch.com/), a fast and relevant search engine. It handles:

- User and group creation
- Binary download and fresh installation
- Optional SHA256 checksum verification, with built-in checksums for selected versions
- TOML configuration and environment file deployment
- Systemd service setup and management
- Health check verification
- Dumpless upgrade flow for version upgrades
- Dump-based upgrade flow for version upgrades
- Version comparison for explicit upgrade runs, including same-version no-op and downgrade prevention
- Scheduled snapshot configuration

## Requirements

- ansible-core >= 2.18.0
- Target system with systemd and python3 support
- Official Meilisearch Linux binary install/upgrade requires glibc >= 2.35
- Internet access for downloading Meilisearch binary
- Fact gathering enabled (the role uses `ansible_facts.architecture` and `ansible_facts.date_time`)

## Supported Platforms

### Linux

Any Linux distribution with systemd support and python3 installed. Installing or upgrading the official Meilisearch Linux binary additionally requires glibc >= 2.35. The default CI scenario runs on Debian 12 and Ubuntu 24.04. Functional Molecule scenarios use systemd-enabled Debian 12 Docker containers by default.

Rocky Linux 9 / EL9 ships glibc 2.34 and cannot run current official Meilisearch Linux binaries. Use a supported distribution, Docker, or preinstall a custom-built Meilisearch binary on those systems. Configuration-only runs against an existing binary are not blocked by the glibc check.

### Architectures

- x86_64 (amd64)
- ARM64 (aarch64)

## Role Variables

### Required Variables

| Variable                 | Description                                                                                 |
| ------------------------ | ------------------------------------------------------------------------------------------- |
| `meilisearch_master_key` | Master key for securing Meilisearch API. Required (at least 16 bytes) when `meilisearch_env` is `production`; optional otherwise. |

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
| `meilisearch_config_custom_options`            | `""`                                 | Raw TOML lines appended by the built-in config template                 |
| `meilisearch_env_variables`                    | `{}`                                 | Dict rendered as the optional systemd environment file                  |
| `meilisearch_no_log`                           | `true`                               | Hide task output that may contain secrets (set `false` only to debug)   |

### Notes

- Without `meilisearch_upgrade`, the role only downloads the binary when `/usr/local/bin/meilisearch` does not exist. It does not replace an existing binary just because `meilisearch_version` changed.
- If `meilisearch_upgrade` is set but Meilisearch is not installed yet, the role performs a fresh install of `meilisearch_version` instead of an upgrade.
- Version comparison, same-version no-op handling, and downgrade prevention run only when `meilisearch_upgrade` is set.
- Use `meilisearch_upgrade` for the upgrade run, then return it to `""` for normal configuration runs.
- `meilisearch_http_addr` must be `host:port` or `[IPv6]:port` (no scheme).
- If `meilisearch_http_addr` is `0.0.0.0` or `::`, the role uses `127.0.0.1` or `::1` for internal health checks.
- Built-in checksums currently cover `v1.19.1` and `v1.33.1`. Set `meilisearch_checksum` for other versions when checksum verification is required. The value is passed directly to `ansible.builtin.get_url`, for example `sha256:<digest>`.
- `meilisearch_config_custom_options` is appended only by the built-in `meilisearch.toml.j2` template. If you set `meilisearch_config_template` to a custom template, that template controls whether this variable is used.
- Do not duplicate TOML keys already rendered by the built-in template in `meilisearch_config_custom_options`.
- The environment file is rendered only when `meilisearch_env_variables` is non-empty and removed otherwise. Values are JSON-encoded (`KEY="value"`) so spaces and special characters survive systemd's `EnvironmentFile` parsing.
- During an upgrade run, do not change `meilisearch_db_path`, `meilisearch_dump_dir`, `meilisearch_snapshot_dir`, or `meilisearch_http_addr`. The role fails early if these values differ from the currently deployed TOML; apply storage or listen-address changes in a separate run after the upgrade is healthy. This check reads the deployed TOML and therefore only runs with the built-in `meilisearch.toml.j2` template; with a custom `meilisearch_config_template` it is skipped (you are responsible for keeping those paths stable during the upgrade).
- A dumpless upgrade across major versions is refused, because dumps are Meilisearch's supported cross-major mechanism — use `meilisearch_upgrade: dump` to cross a major version.

## Dependencies

None.

## Examples

### Minimal — Fresh Install

```yaml
- name: Install Meilisearch
  hosts: search
  become: true
  vars:
    meilisearch_master_key: "{{ vault_meilisearch_master_key }}"
  roles:
    - eyebrowkang.meilisearch
```

More examples — custom configuration and environment variables, IPv6 listen
address, dumpless and dump-based upgrades, and ansible-vault usage — are in
**[EXAMPLES.md](EXAMPLES.md)**.

## Testing

This role is tested with [Molecule](https://ansible.readthedocs.io/projects/molecule/). All scenarios use systemd-enabled Docker containers; no vagrant/libvirt scenario is required.

```bash
# Install the local dev toolchain
uv sync

# Container smoke test (docker)
make test

# Run an individual functional scenario
uv run molecule test -s config_options
uv run molecule test -s http_addr
uv run molecule test -s production_master_key
uv run molecule test -s upgrade_dump
uv run molecule test -s upgrade_dumpless
uv run molecule test -s negative
```

The `default` scenario supports the `MOLECULE_DISTRO` matrix used by CI: `debian12` and `ubuntu2404`. Functional scenarios default to `debian12`.

Scenarios: `default`, `http_addr`, `production_master_key`, `config_options`, `upgrade_dump`, `upgrade_dumpless`, `negative`.

## License

MIT
