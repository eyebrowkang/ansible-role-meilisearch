# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.0] - Unreleased

### Added

- `meilisearch_config_custom_options` for appending raw TOML lines to the default config template

### Changed

- `meilisearch_config_template` takes precedence over `meilisearch_config_custom_options` when both are set
- Environment file deployment and `EnvironmentFile` in the systemd unit are skipped when `meilisearch_env_variables` is empty

## [2.0.0] - 2026-01-26

### Breaking Changes

- `meilisearch_no_analytics` changed from string `"true"` to boolean `true` (strict input validation will reject strings)
- Environment file generation now uses `meilisearch_env_variables`; `templates/meilisearch.env.j2` was removed
- Installation now only downloads the binary when it does not already exist (no version-based overwrite)
- `meilisearch.toml.j2` no longer renders hardcoded defaults; `master_key` is now conditional
- Added strict validation for `meilisearch_http_addr` and `meilisearch_schedule_snapshot` that can fail previously accepted inputs
- Version comparison now prevents downgrades and skips upgrades when versions match

### Added

- Dumpless upgrade support via `meilisearch_upgrade: "dumpless"`
- Dump-based upgrade support via `meilisearch_upgrade: "dump"`
- SHA256 checksum verification for binary downloads (with built-in checksums for v1.19.1 and v1.33.1)
- `meilisearch_checksum` variable to override built-in checksums
- `meilisearch_schedule_snapshot` configuration option for periodic snapshots
- Automatic version comparison to skip unnecessary upgrades
- `meilisearch_config_template` variable for custom TOML config templates
- `meilisearch_env_variables` dict for variable-driven environment file generation
- `meilisearch_import_health_retries` and `meilisearch_import_health_delay` to tune health checks after dump import
- `tasks/validate.yml` with comprehensive input validation (env, upgrade mode, version format, http_addr format, schedule_snapshot)
- `tasks/resolve_http_addr.yml` to normalize `meilisearch_http_addr` for health checks
- `tasks/version_check.yml` for upgrade version comparison
- `tasks/upgrade_dump.yml` for dump-based upgrade flow
- Split task files: setup.yml, install.yml, upgrade_dumpless.yml, upgrade_dump.yml, configure.yml, service.yml
- Molecule scenarios for `http_addr` and production master key validation
- Molecule default test scenario (vagrant/libvirt with Debian 12)
- `.ansible-lint` configuration

### Changed

- Restructured `tasks/main.yml` to include validation, version checking, and both upgrade paths
- Moved `meilisearch_upgrade_snapshot_timeout_retries` and `meilisearch_upgrade_snapshot_poll_interval` from `vars/main.yml` to `defaults/main.yml` (now user-overridable)
- Health checks now normalize wildcard/IPv6 addresses and use loopback for `0.0.0.0`/`::`
- `meilisearch_http_addr` validation now allows `[IPv6]:port`
- `meilisearch.toml.j2` renders `schedule_snapshot` as an integer
- Systemd unit `ReadWritePaths` now includes data, dumps, and snapshots directories
- Dump-based upgrades only back up the data directory when it exists and is non-empty
- Rewrote README with variable reference table and example playbooks
- Role now targets Meilisearch v1.19+ compatibility

### Removed

- Version comparison logic for binary downloads

## [1.0.0] - 2025-09-04

### Added

- Initial release of ansible-role-meilisearch
- Install and configure Meilisearch as a systemd service
- Configurable installation with default Meilisearch v1.19.1

[2.0.0]: https://github.com/eyebrowkang/ansible-role-meilisearch/compare/1.0.0...2.0.0
[1.0.0]: https://github.com/eyebrowkang/ansible-role-meilisearch/releases/tag/1.0.0
