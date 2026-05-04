# markdown-focus.nvim

Opt-in Markdown focus mode for Neovim.

The plugin opens the current Markdown heading or bullet subtree in a temporary editable buffer, then writes it back to the original source range only if that range has not changed. Focused edits are also written to timestamped recovery drafts under Neovim state. If writeback is refused, the focus buffer stays open and the draft path is reported.

## Usage

```lua
{
  "shadowfax/markdown-focus.nvim",
  dir = vim.fn.expand("~/code/hacks/markdown-focus.nvim"),
  config = function()
    require("markdown_focus").setup()
  end,
}
```

Commands:

- `:MarkdownFocusEnable`
- `:MarkdownFocus`
- `:MarkdownUnfocus`
- `:MarkdownFocusToggleBlock`
- `:MarkdownFocusOpenDrafts`
- `:MarkdownFocusCleanupDrafts`

Default focus-mode mappings:

- `<CR>` or `zf`: focus current heading or bullet subtree
- `<BS>` or `zu`: write back and return to the source buffer
- `<Tab>` in normal mode: toggle the current subtree fold
- `<Tab>` / `<S-Tab>` in insert or visual mode: indent or outdent Markdown bullet lines
- `<leader>mD`: open recovery drafts
