# ansible-role-meilisearch

An Ansible role to install and configure Meilisearch as a systemd service on Linux systems.

## Description

This role automates the installation of Meilisearch, a lightweight, fast and powerful search engine. It handles:

- User and group creation
- Binary download and installation
- Configuration file deployment
- Systemd service setup and management

## Requirements

- Ansible >= 2.11
- Target system with systemd support
- Internet access for downloading Meilisearch binary

## Supported Operating Systems

### Linux

Theoretically, any Linux distribution with systemd support and python3 installed is OK.
But I only tested it on Debian 12.

### Architectures

- x86_64 (amd64)
- ARM64 (aarch64)

## Role Variables

### Required Variables

- `meilisearch_master_key`: Master key for securing Meilisearch API. Generate with `openssl rand -hex 16` and store using ansible-vault for security.

### Default Variables

Available variables are listed below, along with default values (see `defaults/main.yml`):

```yaml
# Meilisearch version to install
meilisearch_version: "v1.19.1"

# User and group configuration
meilisearch_user: "meilisearch"
meilisearch_group: "meilisearch"
meilisearch_home: "/var/lib/meilisearch"

# Configuration directory
meilisearch_config_dir: "/etc/meilisearch"

# Database and storage paths
meilisearch_db_path: "{{ meilisearch_home }}/data"
meilisearch_dump_dir: "{{ meilisearch_home }}/dumps"
meilisearch_snapshot_dir: "{{ meilisearch_home }}/snapshots"

# Service configuration
meilisearch_env: "production"
meilisearch_http_addr: "localhost:7700"
meilisearch_no_analytics: "true"
```

## Dependencies

None.

## Example

meilisearch-playbook.yml:

```yaml
- name: Install and config meilisearch
  hosts: all
  become: true

  roles:
    - eyebrowkang.meilisearch
```

vault.yml:

```yaml
meilisearch_master_key: "8d98d6a3143bc0d83be006e7bacbb46c"
```

## License

MIT
