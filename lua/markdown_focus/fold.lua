local parser = require("markdown_focus.parser")

local M = {}
local closed_by_bufnr = {}

local function block_key(block)
  return tostring(block.start_row) .. ":" .. tostring(block.end_row)
end

local function state(bufnr)
  closed_by_bufnr[bufnr] = closed_by_bufnr[bufnr] or {}
  return closed_by_bufnr[bufnr]
end

--- Toggles a manual fold for the current heading or list subtree body.
function M.toggle_current_block(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local block, reason, detail = parser.current_cursor_block(bufnr)
  if reason then
    local suffix = detail and (": " .. tostring(detail)) or ""
    vim.notify(
      "Markdown focus: Tree-sitter Markdown parser unavailable (" .. tostring(reason) .. ")" .. suffix,
      vim.log.levels.ERROR
    )
    return
  end
  if not block then
    vim.notify("Markdown focus: cursor is not on a heading or bullet", vim.log.levels.WARN)
    return
  end
  if block.end_row <= block.start_row then
    return
  end

  vim.wo.foldmethod = "manual"
  local closed = state(bufnr)
  local key = block_key(block)
  local start_line = block.start_row + 2
  local end_line = block.end_row + 1

  if closed[key] then
    vim.cmd(string.format("silent! %d,%dfoldopen!", start_line, end_line))
    closed[key] = nil
  else
    vim.cmd(string.format("silent! %d,%dfold", start_line, end_line))
    vim.cmd(string.format("silent! %d,%dfoldclose!", start_line, end_line))
    closed[key] = true
  end
end

return M
