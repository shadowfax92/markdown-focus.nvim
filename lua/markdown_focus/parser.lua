local M = {}

local heading_nodes = {
  atx_heading = true,
}

local function node_end_row(node)
  local _, _, end_row, end_col = node:range()
  if end_col == 0 then
    return math.max(0, end_row - 1)
  end
  return end_row
end

local function heading_level(line)
  local marks = line:match("^(#+)%s+")
  return marks and #marks or nil
end

local function bullet_indent(line)
  local indent = line:match("^(%s*)[-*+]%s+")
  return indent and #indent or nil
end

local function line_at(bufnr, row)
  return vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
end

local function parse_root(bufnr)
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "markdown")
  if not ok or not parser then
    return nil, "parser_unavailable", parser
  end

  local parsed_ok, trees = pcall(function()
    return parser:parse()
  end)
  if not parsed_ok or not trees or not trees[1] then
    return nil, "parse_failed", trees
  end

  return trees[1]:root()
end

local function contains(block, cursor_row)
  return block.start_row <= cursor_row and cursor_row <= block.end_row
end

local function better_candidate(candidate, current)
  if not current then
    return true
  end
  if candidate.start_row ~= current.start_row then
    return candidate.start_row > current.start_row
  end
  return candidate.end_row < current.end_row
end

local function heading_child(section)
  for child in section:iter_children() do
    if heading_nodes[child:type()] then
      return child
    end
  end
end

local function section_block(bufnr, node)
  local heading = heading_child(node)
  if not heading then
    return nil
  end

  local start_row = ({ heading:range() })[1]
  local line = line_at(bufnr, start_row)
  local level = heading_level(line)
  if not level then
    return nil
  end

  return {
    kind = "heading",
    start_row = start_row,
    end_row = node_end_row(node),
    level = level,
    text = line,
  }
end

local function list_item_block(bufnr, node)
  local start_row = ({ node:range() })[1]
  local line = line_at(bufnr, start_row)
  local indent = bullet_indent(line)
  if not indent then
    return nil
  end

  return {
    kind = "list_item",
    start_row = start_row,
    end_row = node_end_row(node),
    indent = indent,
    text = line,
  }
end

local function find_candidate(bufnr, node, cursor_row, best)
  local block
  if node:type() == "section" then
    block = section_block(bufnr, node)
  elseif node:type() == "list_item" then
    block = list_item_block(bufnr, node)
  end

  if block and contains(block, cursor_row) and better_candidate(block, best) then
    best = block
  end

  for child in node:iter_children() do
    best = find_candidate(bufnr, child, cursor_row, best)
  end

  return best
end

--- Returns the nearest Tree-sitter heading or list-item block for a zero-indexed row.
function M.current_block(bufnr, cursor_row)
  bufnr = bufnr or 0
  local root, reason, detail = parse_root(bufnr)
  if not root then
    return nil, reason, detail
  end
  return find_candidate(bufnr, root, cursor_row, nil)
end

--- Returns the current window cursor's block in the target Markdown buffer.
function M.current_cursor_block(bufnr)
  return M.current_block(bufnr or 0, vim.api.nvim_win_get_cursor(0)[1] - 1)
end

--- Verifies that the Markdown Tree-sitter parser can parse this buffer.
function M.ensure_available(bufnr)
  local root, reason, detail = parse_root(bufnr or 0)
  if not root then
    return false, reason, detail
  end
  return true
end

return M
