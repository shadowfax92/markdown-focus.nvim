vim.opt.runtimepath:prepend(vim.fn.getcwd())

local function assert_same(actual, expected, label)
  if not vim.deep_equal(actual, expected) then
    error(string.format("%s:\nexpected %s\ngot %s", label, vim.inspect(expected), vim.inspect(actual)))
  end
end

local function assert_truthy(value, label)
  if not value then
    error(label)
  end
end

local function scratch_markdown(lines)
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].filetype = "markdown"
  vim.api.nvim_buf_set_name(bufnr, vim.fn.tempname() .. ".md")
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_set_current_buf(bufnr)
  return bufnr
end

vim.notify = function() end

local parser = require("markdown_focus.parser")
local focus = require("markdown_focus.focus")
local drafts = require("markdown_focus.drafts")
local edit = require("markdown_focus.edit")
local fold = require("markdown_focus.fold")

local source = scratch_markdown({
  "# Week",
  "",
  "## Today",
  "- old",
  "  - child",
  "## Tomorrow",
  "- next",
})

assert_same(parser.current_block(source, 2), {
  kind = "heading",
  start_row = 2,
  end_row = 4,
  level = 2,
  text = "## Today",
}, "heading block")

assert_same(parser.current_block(source, 4), {
  kind = "list_item",
  start_row = 4,
  end_row = 4,
  indent = 2,
  text = "  - child",
}, "nested list item block")

vim.api.nvim_win_set_cursor(0, { 3, 0 })
local focus_buf = focus.focus_current_block(source)
assert_truthy(focus_buf, "expected focus buffer")
assert_same(vim.api.nvim_buf_get_lines(focus_buf, 0, -1, false), {
  "## Today",
  "- old",
  "  - child",
}, "focused lines")

vim.api.nvim_buf_set_lines(focus_buf, 1, 2, false, { "- new" })
local draft_root = vim.fn.tempname()
local result = focus.unfocus(0, { draft_root = draft_root })
assert_truthy(result.ok, "expected unfocus writeback")
assert_same(vim.api.nvim_get_current_buf(), source, "unfocus should switch back to source")
assert_truthy(not vim.api.nvim_buf_is_valid(focus_buf), "focus buffer should close after writeback")
assert_same(vim.api.nvim_buf_get_lines(source, 0, -1, false), {
  "# Week",
  "",
  "## Today",
  "- new",
  "  - child",
  "## Tomorrow",
  "- next",
}, "source after writeback")
assert_truthy(#vim.fn.glob(draft_root .. "/*.md", false, true) > 0, "expected recovery draft")

vim.api.nvim_win_set_cursor(0, { 4, 0 })
local drift_buf = focus.focus_current_block(0)
assert_truthy(drift_buf, "expected drift focus buffer")
vim.api.nvim_buf_set_lines(source, 3, 4, false, { "- changed elsewhere" })
vim.api.nvim_buf_set_lines(drift_buf, 0, -1, false, { "- focused edit" })
local drift_root = vim.fn.tempname()
local win_count = #vim.api.nvim_list_wins()
local drift_result = focus.unfocus(drift_buf, { draft_root = drift_root })
assert_same(drift_result.reason, "source_changed", "drift reason")
assert_truthy(vim.api.nvim_buf_is_valid(drift_buf), "focus buffer should stay open after drift")
assert_same(#vim.api.nvim_list_wins(), win_count, "drift should not open a split")
assert_same(vim.api.nvim_get_current_buf(), drift_buf, "drift should keep focus buffer current")
assert_truthy(#vim.fn.glob(drift_root .. "/*.md", false, true) > 0, "expected drift draft")

local edit_buf = scratch_markdown({
  "## Heading",
  "- task",
  "  - child",
})
edit.indent_lines(edit_buf, 0, 2)
assert_same(vim.api.nvim_buf_get_lines(edit_buf, 0, -1, false), {
  "## Heading",
  "  - task",
  "    - child",
}, "indent only bullets")
edit.outdent_lines(edit_buf, 0, 2)
assert_same(vim.api.nvim_buf_get_lines(edit_buf, 0, -1, false), {
  "## Heading",
  "- task",
  "  - child",
}, "outdent only bullets")

vim.api.nvim_win_set_cursor(0, { 1, 0 })
fold.toggle_current_block(edit_buf)
assert_truthy(vim.fn.foldclosed(2) ~= -1, "expected folded block")
fold.toggle_current_block(edit_buf)
assert_same(vim.fn.foldclosed(2), -1, "expected open block")

local para_source = scratch_markdown({
  "## Notes",
  "lead line of para",
  "  indented child",
  "  another child",
  "",
  "- bullet",
  "  - nested",
})

assert_same(parser.current_block(para_source, 1), {
  kind = "paragraph",
  start_row = 1,
  end_row = 3,
  text = "lead line of para",
}, "paragraph block from lead line")

assert_same(parser.current_block(para_source, 2), {
  kind = "paragraph",
  start_row = 1,
  end_row = 3,
  text = "lead line of para",
}, "paragraph block from continuation line")

assert_same(parser.current_block(para_source, 5), {
  kind = "list_item",
  start_row = 5,
  end_row = 6,
  indent = 0,
  text = "- bullet",
}, "bullet still focuses its subtree, not its inner paragraph")

vim.api.nvim_win_set_cursor(0, { 3, 0 })
local para_focus = focus.focus_current_block(para_source)
assert_truthy(para_focus, "expected paragraph focus buffer")
assert_same(vim.api.nvim_buf_get_lines(para_focus, 0, -1, false), {
  "lead line of para",
  "  indented child",
  "  another child",
}, "focused paragraph lines")

-- :w saves the block back in place and keeps you in focus mode; repeated saves keep working.
local save_source = scratch_markdown({
  "## Plans",
  "- one",
  "- two",
})
vim.api.nvim_win_set_cursor(0, { 1, 0 })
local save_focus = focus.focus_current_block(save_source)
assert_truthy(save_focus, "expected save focus buffer")
assert_same(vim.bo[save_focus].buftype, "acwrite", "focus buffer must be acwrite so :w works")
assert_truthy(not vim.bo[save_focus].modified, "fresh focus buffer should be unmodified")

vim.api.nvim_buf_set_lines(save_focus, 1, 2, false, { "- ONE" })
local save_root = vim.fn.tempname()
local save_result = focus.save(0, { draft_root = save_root })
assert_truthy(save_result.ok, "expected save writeback")
assert_truthy(vim.api.nvim_buf_is_valid(save_focus), "save should keep the focus buffer open")
assert_same(vim.api.nvim_get_current_buf(), save_focus, "save should stay in the focus buffer")
assert_truthy(not vim.bo[save_focus].modified, "save should clear 'modified'")
assert_same(vim.api.nvim_buf_get_lines(save_source, 0, -1, false), {
  "## Plans",
  "- ONE",
  "- two",
}, "source after first save")
assert_truthy(#vim.fn.glob(save_root .. "/*.md", false, true) > 0, "expected save draft")

-- A second save after more edits must still apply: range + hash advanced on the first save.
vim.api.nvim_buf_set_lines(save_focus, 2, 3, false, { "- two", "- three" })
local save_result2 = focus.save(0, { draft_root = save_root })
assert_truthy(save_result2.ok, "expected second save writeback")
assert_same(vim.api.nvim_buf_get_lines(save_source, 0, -1, false), {
  "## Plans",
  "- ONE",
  "- two",
  "- three",
}, "source after second save grows the range")

-- :w through BufWriteCmd exercises the same path end-to-end.
vim.api.nvim_buf_set_lines(save_focus, 1, 2, false, { "- uno" })
vim.cmd("silent write")
assert_truthy(not vim.bo[save_focus].modified, ":w via BufWriteCmd should clear 'modified'")
assert_same(vim.api.nvim_buf_get_lines(save_source, 0, -1, false), {
  "## Plans",
  "- uno",
  "- two",
  "- three",
}, "source after :w")

drafts.cleanup(draft_root, os.time() + 25 * 60 * 60)

print("markdown_focus_smoke: ok")
