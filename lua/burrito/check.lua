-- SPDX-License-Identifier: MIT
-- Copyright (c) Colin Melican 2025

local M = {}

local config = require("burrito/config")

local get_line_type = require("burrito/util").get_line_type
local get_indent_amount = require("burrito/util").get_indent_amount

-- checks buffer for lines that need to be wrapped
-- start_line: what line to start checking at, inclusive
-- end_line: what line to stop at, exclusive. -1 whole file. -2 paragraph.
M.burrito_check_wrap = function(start_line, end_line)
  if end_line == nil then end_line = -1 end
  print("wrap: " .. start_line .. " -> " .. end_line)
  -- get all lines in buffer
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, -1, false)

  for i = start_line, #lines + start_line - 1 do
    if i == end_line and end_line >= 0 then goto early_return end
    local linei = i - start_line + 1
    local line = lines[linei]

    -- dont join with next line if:
    -- line is long
    if #line <= config.get_col() then goto check_next_line end
    -- line is no wrap
    if get_line_type(i) == "nowrap" then
      if end_line == -2 then goto early_return
      else goto check_next_line end
    end

    -- the line can be wrapped, so wrap the line
    print("wrap: " .. i)

    -- split line into two 80-character lines
    local new_lines = {}

    -- the column at which the line is going to be broken
    local break_col = config.get_col()

    -- smart wrapping with words
    for col=config.get_col(), 1, -1 do
      if line:sub(col, col) == ' ' then
        break_col = col
        goto split_line
      end
    end

    ::split_line::
    new_lines[1] = line:sub(1, break_col)
    new_lines[2] = string.rep(" ", get_indent_amount(i).indent)
    .. line:sub(break_col + 1)

    -- calculate new cursor position
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    if cursor_pos[1] == i and cursor_pos[2] >= break_col then
      cursor_pos[1] = cursor_pos[1] + 1
      cursor_pos[2] = get_indent_amount(i).indent + cursor_pos[2] - break_col
    end

    -- replace long line with 80 character one and the new line
    vim.api.nvim_buf_set_lines(0, i-1, i, true, new_lines)

    -- change cursor position to the next line
    vim.api.nvim_win_set_cursor(0, cursor_pos)

    -- recurse
    M.burrito_check_wrap(i + 1, end_line)
    goto early_return

    ::check_next_line::
  end
  ::early_return::
end

-- start_line: what line to start checking at, inclusive
-- end_line: what line to stop at, exclusive. -1 whole file. -2 paragraph.
M.burrito_check_join = function(start_line, end_line)
  if end_line == nil then end_line = -1 end
  print("join: " .. start_line .. " -> " .. end_line)
  -- get all lines in buffer
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, -1, false)

  for i = start_line, #lines + start_line - 1 do
    if i == end_line and end_line >= 0 then goto early_return end
    local linei = i - start_line + 1
    local line = lines[linei]

    local next_linei = linei + 1

    -- out of bounds check
    if next_linei > #lines then
      goto early_return
    end

    local next_line = lines[next_linei]

    -- dont join with next line if:
    -- line is long
    if #line > config.get_col() then goto check_next_line end
    -- line is independent
    local line_type = get_line_type(i)
    if line_type == "independent" then
      if end_line == -2 then goto early_return
      else goto check_next_line end
    end
    -- line is no wrap
    if line_type == "nowrap" then
      if end_line == -2 then goto early_return
      else goto check_next_line end
    end
    -- next line is independent
    local next_line_type = get_line_type(i + 1)
    if next_line_type == "independent" then
      if end_line == -2 then goto early_return
      else goto check_next_line end
    end
    -- next line is no wrap
    if next_line_type == "nowrap" then
      if end_line == -2 then goto early_return
      else goto check_next_line end
    end
    -- next line is bottom only
    if next_line_type == "bottom" then
      if end_line == -2 then goto early_return
      else goto check_next_line end
    end
    -- cursor is on next line and insert mode
    if vim.api.nvim_get_mode().mode == "i"
      and vim.api.nvim_win_get_cursor(0)[1] == i + 1 then
      goto check_next_line end

    -- the lines can be joined, so join the lines
    print("join: " .. i)

    -- if a space needs to be appended to the end of the first line
    if line:sub(#line) ~= " " then
      line = line .. " "
    end

    -- remove leading whitespace from next line
    while next_line:sub(1, 1) == " " do
      next_line = next_line:sub(2)
    end

    -- calculate how much of next line can be added
    local break_col = config.get_col() - #line
    while next_line:sub(break_col, break_col) ~= " "
      and break_col ~= #next_line do

      break_col = break_col - 1
      if break_col < 1 then goto check_next_line end

    end

    -- join the lines
    local new_lines = {}
    new_lines[1] = line .. next_line:sub(1, break_col)
    new_lines[2] = next_line:sub(break_col + 1)
    if new_lines[2] == "" then table.remove(new_lines, 2) end

    -- calculate new cursor position
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    if cursor_pos[1] == i + 1 then
      if cursor_pos[2] + 1 <= break_col then
        cursor_pos[1] = cursor_pos[1] - 1
        cursor_pos[2] = #line + #next_line + cursor_pos[2] - break_col + 1
      else
        cursor_pos[2] = cursor_pos[2] - break_col
      end
    end

    -- replace the line
    vim.api.nvim_buf_set_lines(0, i-1, i+1, false, new_lines)

    -- update cursor position
    local new_length = #vim.api.nvim_buf_get_lines(0, start_line - 1, -1, false)
    if cursor_pos[1] > new_length then
      cursor_pos[1] = new_length
    end
    vim.api.nvim_win_set_cursor(0, cursor_pos)

    -- recurse
    M.burrito_check_join(i, end_line)
    goto early_return

    ::check_next_line::
  end
  ::early_return::
end

return M
