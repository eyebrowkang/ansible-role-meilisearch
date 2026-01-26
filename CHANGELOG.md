# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - Unreleased

### Added

- Dumpless upgrade support via `meilisearch_upgrade: "dumpless"`
- `meilisearch_config_template` variable for custom TOML config templates
- `meilisearch_env_variables` dict for variable-driven environment file generation
- Split task files: setup.yml, install.yml, upgrade.yml, configure.yml, service.yml

### Changed

- Simplified installation: binary is only downloaded if it does not already exist (no version-based overwrite)
- `meilisearch_no_analytics` changed from string `"true"` to boolean `true`
- Simplified `meilisearch.toml.j2` template (removed hardcoded defaults, master_key is now conditional)
- Environment file is now generated from `meilisearch_env_variables` dict instead of a static template
- Restructured `tasks/main.yml` as an orchestrator that includes split task files
- Rewrote README with variable reference table and example playbooks

### Removed

- `templates/meilisearch.env.j2` (replaced by variable-driven generation in configure.yml)
- Version comparison logic for binary downloads

## [1.0.0] - 2025-09-04

### Added

- Initial release of ansible-role-meilisearch
- Install and configure Meilisearch as a systemd service
- Configurable installation with default Meilisearch v1.19.1

[1.1.0]: https://github.com/eyebrowkang/ansible-role-meilisearch/compare/1.0.0...1.1.0
[1.0.0]: https://github.com/eyebrowkang/ansible-role-meilisearch/releases/tag/1.0.0
