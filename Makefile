# Local dev targets (mirror CI). Requires uv: https://docs.astral.sh/uv/
.PHONY: help install deps lint test converge destroy
help:
	@echo "install   - uv sync (dev toolchain)"
	@echo "lint      - yamllint + ansible-lint"
	@echo "deps      - install Galaxy collections that ansible-lint needs"
	@echo "test      - molecule test (default docker scenario)"
	@echo "converge  - molecule converge (docker)"
	@echo "destroy   - molecule destroy (docker)"

install:
	uv sync

# ansible-lint resolves the active molecule scenario's collections (e.g. community.docker,
# used by the docker scenario's create.yml) from the Galaxy install path, so install them
# first — the same step CI runs before linting. molecule's own test sequence installs these
# via dependency:galaxy.
deps:
	uv run ansible-galaxy collection install -r molecule/default/collections.yml

lint: deps
	uv run yamllint .
	uv run ansible-lint
test:
	uv run molecule test

converge:
	uv run molecule converge

destroy:
	uv run molecule destroy
