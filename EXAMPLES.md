# Examples

Playbook examples for the `eyebrowkang.meilisearch` role. For the full variable
reference and notes, see [README.md](README.md). For a minimal fresh-install
example, see the [Examples](README.md#examples) section there.

## Custom Configuration and Environment Variables

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

Extra TOML keys the built-in template does not expose can be appended verbatim
with `meilisearch_config_custom_options` (do not duplicate keys the template
already renders):

```yaml
- name: Install Meilisearch with extra TOML options
  hosts: search
  become: true
  vars:
    meilisearch_master_key: "{{ vault_meilisearch_master_key }}"
    meilisearch_config_custom_options: |
      log_level = "WARN"
      max_indexing_memory = "2 GiB"
  roles:
    - eyebrowkang.meilisearch
```

## IPv6 Listen Address

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

## Dumpless Upgrade

Upgrade an existing Meilisearch instance to a new version using the dumpless
upgrade feature. The role creates a snapshot, stops the service, downloads the
new binary, runs the in-place migration, and restarts. A failed **download** is
rolled back (previous binary restored and service restarted); if the in-place
**migration** itself fails, recover from the pre-upgrade snapshot — a
half-migrated database cannot be reverted by swapping the binary back.

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

> Dumpless upgrades across **major** versions are refused — dumps are
> Meilisearch's supported cross-major mechanism, so use a dump-based upgrade to
> cross a major version.

## Dump-Based Upgrade

Upgrade by creating a dump, backing up the data directory, installing the new
binary, and importing the dump. Useful when the dumpless upgrade is not
available or not desired, and the only supported path across major versions.
If the import does not become healthy, the role restores the previous data
directory and binary and restarts the old service before failing.

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

> During an upgrade run, do not also change `meilisearch_db_path`,
> `meilisearch_dump_dir`, `meilisearch_snapshot_dir`, or `meilisearch_http_addr`;
> apply storage or listen-address changes in a separate run after the upgrade is
> healthy.

## Vault Usage

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
