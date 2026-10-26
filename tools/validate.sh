#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT_BIN=${GODOT_BIN:-godot}
logs=${FACTORY_LOG_DIR:-/tmp/alaska-validation}
mkdir -p "$logs"
for target in import runtime; do
  case "$target" in
    import) args=(--editor --import --quit);;
    runtime) args=(--quit-after 30);;
  esac
  "$GODOT_BIN" --headless --path . "${args[@]}" > "$logs/$target.log" 2>&1 || { cat "$logs/$target.log"; exit 1; }
  cat "$logs/$target.log"
  if grep -Eq 'SCRIPT ERROR|Parse Error|Failed to load script|^ERROR:' "$logs/$target.log"; then exit 1; fi
done
python3 tools/check_site.py
