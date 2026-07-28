set shell := ["bash", "-cu"]

ruff := "uvx --from ruff==0.15.22 ruff"

default: check

# Check shell and Python sources without changing them.
lint:
  shellcheck bootstrap.sh scripts/*.sh steps/*.sh tests/*.sh
  shfmt -d -i 2 -ci bootstrap.sh scripts/*.sh steps/*.sh tests/*.sh
  {{ruff}} check scripts/*.py
  {{ruff}} format --check scripts/*.py

# Format shell and Python sources in place.
fmt:
  shfmt -w -i 2 -ci bootstrap.sh scripts/*.sh steps/*.sh tests/*.sh
  {{ruff}} check --fix scripts/*.py
  {{ruff}} format scripts/*.py

test:
  tests/test-claude-settings.sh
  tests/test-bootstrap-sandbox.sh
  scripts/doctor.sh --repo-only

check: lint test

# Inspect repository and installed machine health.
doctor:
  scripts/doctor.sh

# Run the full machine bootstrap.
bootstrap:
  ./bootstrap.sh
