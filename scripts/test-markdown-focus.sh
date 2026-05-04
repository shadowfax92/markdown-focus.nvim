#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")/.."

nvim --headless -u NONE -n \
  --cmd "set rtp^=$(pwd)" \
  -c "lua local ok, err = xpcall(function() dofile('tests/markdown_focus_smoke.lua') end, debug.traceback); if not ok then print(err); vim.cmd('cquit 1') end" \
  -c "qa!"
