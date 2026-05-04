local drafts = require("markdown_focus.drafts")
local parser = require("markdown_focus.parser")
local writeback = require("markdown_focus.writeback")

local M = {}

local function resolve_current_buf(bufnr)
  if not bufnr or bufnr == 0 then
    return vim.api.nvim_get_current_buf()
  end
  return bufnr
end

local function source_path(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  return name ~= "" and name or "buffer-" .. bufnr .. ".md"
end

local function notify_parse_error(reason, detail)
  local suffix = detail and (": " .. tostring(detail)) or ""
  vim.notify(
    "Markdown focus: Tree-sitter Markdown parser unavailable (" .. tostring(reason) .. ")" .. suffix,
    vim.log.levels.ERROR
  )
end

local function set_focus_keymaps(bufnr)
  local opts = { buffer = bufnr, silent = true, noremap = true }
  vim.keymap.set("n", "<BS>", function()
    M.unfocus(bufnr)
  end, vim.tbl_extend("force", opts, { desc = "Markdown focus: unfocus" }))
  vim.keymap.set("n", "zu", function()
    M.unfocus(bufnr)
  end, vim.tbl_extend("force", opts, { desc = "Markdown focus: unfocus" }))
end

--- Opens the current heading or list subtree in an editable focus buffer.
function M.focus_current_block(source_bufnr)
  source_bufnr = resolve_current_buf(source_bufnr)
  local block, reason, detail = parser.current_cursor_block(source_bufnr)
  if reason then
    notify_parse_error(reason, detail)
    return nil
  end
  if not block then
    vim.notify("Markdown focus: cursor is not on a heading or bullet", vim.log.levels.WARN)
    return nil
  end

  local cursor = vim.api.nvim_win_get_cursor(0)
  local selected = vim.api.nvim_buf_get_lines(source_bufnr, block.start_row, block.end_row + 1, false)
  local focus_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[focus_buf].buftype = "nofile"
  vim.bo[focus_buf].bufhidden = "hide"
  vim.bo[focus_buf].swapfile = false
  vim.bo[focus_buf].filetype = "markdown.outline"
  vim.api.nvim_buf_set_name(
    focus_buf,
    string.format(
      "markdown-focus://%s:L%d-L%d",
      vim.fn.fnamemodify(source_path(source_bufnr), ":t"),
      block.start_row + 1,
      block.end_row + 1
    )
  )
  vim.api.nvim_buf_set_lines(focus_buf, 0, -1, false, selected)
  vim.b[focus_buf].markdown_focus = {
    source_bufnr = source_bufnr,
    source_path = source_path(source_bufnr),
    source_start_row = block.start_row,
    source_end_row = block.end_row,
    original_hash = writeback.hash_lines(selected),
    source_cursor = cursor,
  }
  vim.api.nvim_set_current_buf(focus_buf)
  set_focus_keymaps(focus_buf)
  return focus_buf
end

--- Writes focused edits back to the source buffer or preserves them in a draft.
function M.unfocus(focus_bufnr, opts)
  focus_bufnr = resolve_current_buf(focus_bufnr)
  opts = opts or {}

  if not vim.api.nvim_buf_is_valid(focus_bufnr) then
    return { ok = false, reason = "focus_missing" }
  end

  local meta = vim.b[focus_bufnr].markdown_focus
  if not meta then
    vim.notify("Markdown focus: current buffer is not a focus buffer", vim.log.levels.WARN)
    return { ok = false, reason = "not_focus_buffer" }
  end

  local focused_lines = vim.api.nvim_buf_get_lines(focus_bufnr, 0, -1, false)
  drafts.write({
    root = opts.draft_root,
    source_path = meta.source_path,
    start_row = meta.source_start_row,
    end_row = meta.source_end_row,
    lines = focused_lines,
  })

  local result = writeback.apply({
    source_bufnr = meta.source_bufnr,
    source_path = meta.source_path,
    start_row = meta.source_start_row,
    end_row = meta.source_end_row,
    original_hash = meta.original_hash,
    lines = focused_lines,
    draft_root = opts.draft_root,
  })

  if result.ok then
    vim.api.nvim_set_current_buf(meta.source_bufnr)
    pcall(vim.api.nvim_win_set_cursor, 0, meta.source_cursor)
    vim.api.nvim_buf_delete(focus_bufnr, { force = true })
  elseif vim.api.nvim_buf_is_valid(focus_bufnr) then
    vim.api.nvim_set_current_buf(focus_bufnr)
  end

  return result
end

return M
