local drafts = require("markdown_focus.drafts")

local M = {}

function M.hash_lines(lines)
  return vim.fn.sha256(table.concat(lines or {}, "\n"))
end

local function write_draft(opts)
  return drafts.write({
    root = opts.draft_root,
    source_path = opts.source_path,
    start_row = opts.start_row,
    end_row = opts.end_row,
    lines = opts.lines,
  })
end

local function refuse(opts, reason, message)
  local path = write_draft(opts)
  vim.notify(message .. " Draft: " .. path, vim.log.levels.ERROR)
  return { ok = false, reason = reason, draft_path = path }
end

--- Replaces a source range only when it still matches the stored range hash.
function M.apply(opts)
  if not opts.source_bufnr or not vim.api.nvim_buf_is_valid(opts.source_bufnr) then
    return refuse(opts, "source_missing", "Markdown focus source buffer is gone.")
  end

  local current = vim.api.nvim_buf_get_lines(opts.source_bufnr, opts.start_row, opts.end_row + 1, false)
  if M.hash_lines(current) ~= opts.original_hash then
    return refuse(opts, "source_changed", "Markdown focus source changed.")
  end

  vim.api.nvim_buf_set_lines(opts.source_bufnr, opts.start_row, opts.end_row + 1, false, opts.lines or {})
  return { ok = true }
end

return M
