#!/bin/bash
set -e

SCRIPT_DIR="$(dirname "${BASE_SOURCE[0]}")"
REGISTRY_DIR="$SCRIPT_DIR/registry"
PROJECT_DIR="$SCRIPT_DIR/test-1"
PREBUILT_DIR="$SCRIPT_DIR/prebuilt"

check_dir () {
  if [[ ! -d "$1" ]]; then
    echo >&2 "ERROR: Missing directory: $1"
    exit 1
  fi
}

check_dir "$REGISTRY_DIR"
check_dir "$PROJECT_DIR"
check_dir "$PREBUILT_DIR"

REGISTRY_DIR="$(realpath "$REGISTRY_DIR")"
PREBUILT_DIR="$(realpath "$PREBUILT_DIR")"

cat > "$PROJECT_DIR"/.bazelrc <<EOF
# AUTO-GENERATED DO NOT EDIT!

# Enable BzlMode usage (https://bazel.build/docs/bzlmod)
common --experimental_enable_bzlmod

# Path to the BzlMod registry to use.
common --registry=file://$(realpath "$REGISTRY_DIR")
EOF

PLATFORMS_VERSION=0.0.4
cat > "$REGISTRY_DIR/modules/platforms/${PLATFORMS_VERSION}/source.json" <<EOF
{
  "url": "file://${PREBUILT_DIR}/platforms-${PLATFORMS_VERSION}"
}
EOF

SKYLIB_VERSION=1.0.3
cat > "$REGISTRY_DIR/modules/bazel_skylib/${SKYLIB_VERSION}/source.json" <<EOF
{
  "url": "file://${PREBUILT_DIR}/bazel-skylib-${SKYLIB_VERSION}"
}
EOF
