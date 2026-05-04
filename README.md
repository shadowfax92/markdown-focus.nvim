<div align="center">

# ✍️ markdown-focus.nvim

**An opt-in focus buffer for Markdown headings and bullets.**

*Zoom into one outline block, edit without the surrounding noise, then write it back safely.*

</div>

Markdown notes get big fast. `markdown-focus.nvim` lets you put your cursor on a heading or bullet, open just that subtree in a temporary editable buffer, and then unfocus back into the original document. It refuses stale writebacks when the source changed underneath you, and it always leaves a recovery draft behind.

- 🔎 **Block focus** — isolate the current heading or list item subtree into a `markdown.outline` buffer
- ✍️ **Editable scratch** — work in a normal Markdown buffer with your Markdown ftplugin settings
- 🛡️ **Drift-safe writeback** — source ranges are hash-checked before replacement
- 💾 **Recovery drafts** — focused content is written to timestamped drafts before writeback
- 🧭 **Outline folding** — toggle the current subtree body with a manual fold
- ↕️ **Bullet shaping** — indent and outdent bullet lines from insert or visual mode
- 🧹 **Self-cleaning** — recovery drafts older than roughly a day are pruned on enable

---

## Install

Requires Neovim with the Markdown Tree-sitter parser available.

```vim
:TSInstall markdown
```

With lazy.nvim:

```lua
{
  "shadowfax/markdown-focus.nvim",
  dir = vim.fn.expand("~/code/hacks/markdown-focus.nvim"),
  ft = { "markdown", "markdown.outline" },
  cmd = {
    "MarkdownFocusEnable",
    "MarkdownFocus",
    "MarkdownUnfocus",
    "MarkdownFocusToggleBlock",
    "MarkdownFocusOpenDrafts",
    "MarkdownFocusCleanupDrafts",
  },
  config = function()
    require("markdown_focus").setup()
  end,
}
```

## Quick Start

```vim
:MarkdownFocusEnable
```

Put the cursor on a Markdown heading or bullet:

```text
zf          focus the current block
zu          write back and return
<Tab>       fold or unfold the current block body
```

The focused buffer uses the `markdown.outline` filetype, so you can share settings with Markdown while keeping focus-specific plugin disables or mappings separate.

## Commands

```vim
:MarkdownFocusEnable          " enable buffer-local focus mappings
:MarkdownFocus                " focus the current heading or bullet subtree
:MarkdownUnfocus              " write focused edits back to the source
:MarkdownFocusToggleBlock     " toggle a manual fold for the current subtree
:MarkdownFocusOpenDrafts      " open the recovery draft directory
:MarkdownFocusCleanupDrafts   " delete old recovery drafts
```

## Mappings

After `:MarkdownFocusEnable`, these buffer-local mappings are installed:

| Mapping | Mode | Purpose |
|---------|------|---------|
| `<CR>` | Normal | Focus current block |
| `zf` | Normal | Focus current block |
| `<BS>` | Normal | Unfocus and write back |
| `zu` | Normal | Unfocus and write back |
| `<Tab>` | Normal | Toggle current block fold |
| `<Tab>` | Insert | Indent current bullet line |
| `<S-Tab>` | Insert | Outdent current bullet line |
| `<Tab>` | Visual | Indent selected bullet lines |
| `<S-Tab>` | Visual | Outdent selected bullet lines |
| `<leader>mD` | Normal | Open recovery drafts |

## How it works

Three moving pieces:

1. **Parser** — Tree-sitter finds the nearest Markdown `section` or `list_item` around the cursor.
2. **Focus buffer** — the selected source range is copied into an unlisted `nofile` buffer named like `markdown-focus://note.md:L12-L30`.
3. **Writeback** — unfocus compares the current source range with its original hash before replacing it.

If the source buffer disappeared or changed, writeback is refused. The focus buffer stays open, and the attempted content is preserved under:

```text
stdpath("state")/markdown-focus/drafts/
```

## Testing

```sh
scripts/test-markdown-focus.sh
```

The smoke test covers heading and list selection, focus/unfocus writeback, stale-source refusal, recovery drafts, bullet indenting, and subtree folding.

---

> Personal plugin built for my own Markdown workflow. Fork and adapt.
