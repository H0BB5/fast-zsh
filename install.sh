#!/usr/bin/env bash
# Convenience wrapper so the repo root has a single entry point. Flags pass through.
exec "$(cd "$(dirname "$0")" && pwd)/skills/fast-zsh/scripts/install.sh" "$@"
