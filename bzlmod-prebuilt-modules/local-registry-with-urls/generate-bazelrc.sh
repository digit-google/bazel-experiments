#!/bin/bash
set -e

SCRIPT_DIR="$(dirname "${BASE_SOURCE[0]}")"
REGISTRY_DIR="$SCRIPT_DIR/registry"
PROJECT_DIR="$SCRIPT_DIR/test-1"

if [[ ! -d "$REGISTRY_DIR" ]]; then
  echo >&2 "ERROR: Missing registry directory: $REGISTRY_DIR"
  exit 1
fi

if [[ ! -d "$PROJECT_DIR" ]]; then
  echo >&2 "ERROR: Missing project directory: $PROJECT_DIR"
  exit 1
fi

cat > "$PROJECT_DIR"/.bazelrc <<EOF
# Enable BzlMode usage (https://bazel.build/docs/bzlmod)
common --experimental_enable_bzlmod

# Path to the BzlMod registry to use.
common --registry=file://$(realpath "$REGISTRY_DIR")
EOF
