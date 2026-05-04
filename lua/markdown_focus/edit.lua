local M = {}

local function bullet_parts(line)
  return line:match("^(%s*)([-*+]%s+.*)$")
end

local function current_row()
  return vim.api.nvim_win_get_cursor(0)[1] - 1
end

--- Indents Markdown bullet lines in the inclusive row range.
function M.indent_lines(bufnr, start_row, end_row)
  bufnr = bufnr or 0
  local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false)
  for i, line in ipairs(lines) do
    if bullet_parts(line) then
      lines[i] = "  " .. line
    end
  end
  vim.api.nvim_buf_set_lines(bufnr, start_row, end_row + 1, false, lines)
end

--- Outdents Markdown bullet lines in the inclusive row range.
function M.outdent_lines(bufnr, start_row, end_row)
  bufnr = bufnr or 0
  local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false)
  for i, line in ipairs(lines) do
    local indent, rest = bullet_parts(line)
    if indent and #indent > 0 then
      local remove = math.min(2, #indent)
      lines[i] = indent:sub(remove + 1) .. rest
    end
  end
  vim.api.nvim_buf_set_lines(bufnr, start_row, end_row + 1, false, lines)
end

function M.indent_current_line()
  local row = current_row()
  M.indent_lines(0, row, row)
end

function M.outdent_current_line()
  local row = current_row()
  M.outdent_lines(0, row, row)
end

function M.indent_visual()
  local start_row = vim.fn.line("v") - 1
  local end_row = vim.fn.line(".") - 1
  if start_row > end_row then
    start_row, end_row = end_row, start_row
  end
  M.indent_lines(0, start_row, end_row)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
end

function M.outdent_visual()
  local start_row = vim.fn.line("v") - 1
  local end_row = vim.fn.line(".") - 1
  if start_row > end_row then
    start_row, end_row = end_row, start_row
  end
  M.outdent_lines(0, start_row, end_row)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
end

return M
