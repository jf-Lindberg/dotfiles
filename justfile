set shell := ["bash", "-cu"]

default: check

# Check shell scripts without changing them.
lint:
  shellcheck bootstrap.sh steps/*.sh
  shfmt -d -i 2 -ci bootstrap.sh steps/*.sh

# Format shell scripts in place.
fmt:
  shfmt -w -i 2 -ci bootstrap.sh steps/*.sh

test:
  tests/test-claude-settings.sh

check: lint test
