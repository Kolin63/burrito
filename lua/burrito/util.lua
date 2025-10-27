-- SPDX-License-Identifier: MIT
-- Copyright (c) Colin Melican 2025

local M = {}

local config = require("burrito/config")

local regex = require("burrito/regex").regex
local regex_string = require("burrito/regex").regex_string

-- returns the amount of spaces that line line_number is indented because of
-- any above list patterns.
-- for example:
-- 1. hello
--    world
-- get_indent_amount(2) would return 3, because "1. " is 3 characters long.
-- in the same example, get_indent_amount(1) would also return 3 for the same
-- reason.
-- another example:
-- 1. hello
--    world
--    > oh, the places you'll go
--      -dr. seuss
-- get_indent_amount(4) would return 5
M.get_indent_amount = function(line_number)
  local lines = vim.api.nvim_buf_get_lines(0, 0, line_number, false)
  local indent = 0
  local output_line = ""
  for _, line in ipairs(lines) do
    -- remove whitespace from indentation
    for w = 1, indent do
      if line:sub(1, 1) == " " then
        line = line:sub(2)
      else
        indent = w - 1
        goto stop_whitespace_check
      end
    end
    ::stop_whitespace_check::

    local leftover = line
    output_line = leftover
    repeat
      local match_made = false
      for _, pattern in ipairs(config.get_bottom_only_patterns()) do
        local r = regex_string(leftover, pattern)
        if r.matched == true then
          leftover = r.leftover
          match_made = true
          goto check_again
        end
      end
      ::check_again::
    until match_made == false
    indent = indent + #line - #leftover
  end
  return { indent = indent, line = output_line }
end

-- returns true if given line is a no wrap line
M.is_no_wrap = function(line)
  for _, pattern in ipairs(config.get_no_wrap_patterns()) do
    if regex(line, pattern) == true then
      return true
    end
  end
  return false
end

-- returns true if line line_number is in a fenced code block
M.is_code_block = function(line_number)
  local lines = vim.api.nvim_buf_get_lines(0, 0, line_number, false)
  for _, pattern in ipairs(config.get_code_block_patterns()) do
    local status = false
    for _, line in ipairs(lines) do
      if regex(line, pattern) == true then
        status = not status
      end
    end
    if status == true then return status end
    return status
  end
end

-- returns "normal", "independent", "bottom", or "nowrap"
M.get_line_type = function(line_number)
  local line = M.get_indent_amount(line_number).line
  for _, pattern in ipairs(config.get_independent_patterns()) do
    if regex(line, pattern) == true then
      return "independent"
    end
  end

  for _, pattern in ipairs(config.get_bottom_only_patterns()) do
    if regex(line, pattern) == true then
      return "bottom"
    end
  end

  if M.is_no_wrap(line) or M.is_code_block(line_number) then
    return "nowrap"
  end

  return "normal"
end

return M
