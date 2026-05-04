local M = {}

local day_seconds = 24 * 60 * 60
local uv = vim.uv or vim.loop

local function sanitize(value)
  return tostring(value):gsub("[^%w%._-]+", "_")
end

function M.root()
  return vim.fn.stdpath("state") .. "/markdown-focus/drafts"
end

--- Removes recovery drafts older than roughly one day.
function M.cleanup(root, now)
  root = root or M.root()
  now = now or os.time()
  if vim.fn.isdirectory(root) == 0 then
    return
  end

  for _, path in ipairs(vim.fn.glob(root .. "/*.md", false, true)) do
    local mtime = vim.fn.getftime(path)
    if mtime > 0 and now - mtime > day_seconds then
      vim.fn.delete(path)
    end
  end
end

--- Writes focused Markdown text to a timestamped recovery draft.
function M.write(opts)
  opts = opts or {}
  local root = opts.root or M.root()
  vim.fn.mkdir(root, "p")
  M.cleanup(root)

  local source_name = sanitize(vim.fn.fnamemodify(opts.source_path or "buffer", ":t"))
  local range = string.format("L%d-L%d", (opts.start_row or 0) + 1, (opts.end_row or 0) + 1)
  local unique = string.format("%.0f", uv.hrtime())
  local path = string.format("%s/%s-%s-%s-%s.md", root, os.date("%Y%m%d-%H%M%S"), unique, source_name, range)
  vim.fn.writefile(opts.lines or {}, path)
  return path
end

function M.open_dir(root)
  vim.cmd.edit(vim.fn.fnameescape(root or M.root()))
end

return M
