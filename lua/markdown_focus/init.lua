local drafts = require("markdown_focus.drafts")
local edit = require("markdown_focus.edit")
local focus = require("markdown_focus.focus")
local fold = require("markdown_focus.fold")
local parser = require("markdown_focus.parser")

local M = {}

local default_keymaps = {
  { "n", "<CR>", focus.focus_current_block, "Markdown focus: focus block" },
  { "n", "zf", focus.focus_current_block, "Markdown focus: focus block" },
  { "n", "<BS>", focus.unfocus, "Markdown focus: unfocus" },
  { "n", "zu", focus.unfocus, "Markdown focus: unfocus" },
  { "n", "<Tab>", fold.toggle_current_block, "Markdown focus: toggle block" },
  { "i", "<Tab>", edit.indent_current_line, "Markdown focus: indent bullet" },
  { "i", "<S-Tab>", edit.outdent_current_line, "Markdown focus: outdent bullet" },
  { "x", "<Tab>", edit.indent_visual, "Markdown focus: indent selection" },
  { "x", "<S-Tab>", edit.outdent_visual, "Markdown focus: outdent selection" },
  { "n", "<leader>mD", drafts.open_dir, "Markdown focus: open drafts" },
}

local function map(bufnr, mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, noremap = true, desc = desc })
end

local function notify_parser_error(reason, detail)
  local suffix = detail and (": " .. tostring(detail)) or ""
  vim.notify(
    "Markdown focus: Tree-sitter Markdown parser unavailable (" .. tostring(reason) .. ")" .. suffix,
    vim.log.levels.ERROR
  )
end

--- Enables buffer-local Markdown Focus Mode mappings for the current Markdown buffer.
function M.enable(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local filetype = vim.bo[bufnr].filetype
  if filetype ~= "markdown" and filetype ~= "markdown.outline" then
    vim.notify("Markdown focus: current buffer is not Markdown", vim.log.levels.WARN)
    return false
  end

  local ok, reason, detail = parser.ensure_available(bufnr)
  if not ok then
    notify_parser_error(reason, detail)
    return false
  end

  vim.b[bufnr].markdown_focus_enabled = true
  vim.b[bufnr].markdown_focus_original_filetype = vim.b[bufnr].markdown_focus_original_filetype or filetype
  vim.bo[bufnr].filetype = "markdown.outline"
  vim.wo.foldmethod = "manual"

  for _, keymap in ipairs(default_keymaps) do
    map(bufnr, keymap[1], keymap[2], keymap[3], keymap[4])
  end

  drafts.cleanup()
  vim.notify("Markdown Focus Mode enabled", vim.log.levels.INFO)
  return true
end

--- Registers Markdown Focus Mode commands.
function M.setup()
  vim.api.nvim_create_user_command("MarkdownFocusEnable", function()
    M.enable()
  end, { force = true })
  vim.api.nvim_create_user_command("MarkdownFocus", function()
    focus.focus_current_block(0)
  end, { force = true })
  vim.api.nvim_create_user_command("MarkdownUnfocus", function()
    focus.unfocus(0)
  end, { force = true })
  vim.api.nvim_create_user_command("MarkdownFocusToggleBlock", function()
    fold.toggle_current_block(0)
  end, { force = true })
  vim.api.nvim_create_user_command("MarkdownFocusOpenDrafts", function()
    drafts.open_dir()
  end, { force = true })
  vim.api.nvim_create_user_command("MarkdownFocusCleanupDrafts", function()
    drafts.cleanup()
  end, { force = true })
end

M.focus_current_block = focus.focus_current_block
M.unfocus = focus.unfocus
M.toggle_current_block = fold.toggle_current_block

return M
