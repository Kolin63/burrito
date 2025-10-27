-- SPDX-License-Identifier: MIT
-- Copyright (c) Colin Melican 2025

local M = {}

local config = {
  col = 80,                         -- The column to wrap text at

  range = 1,                        -- Amount of lines that will be checked
                                    -- above and below the cursor. The :Burrito
                                    -- command will check whole file. Set this
                                    -- value to -1 to always check whole file.

  check_whole_paragraph = true,     -- If the entire paragraph should be checked
                                    -- rather than stopping at the end of the
                                    -- range.

  file_types = { "*.md" },          -- What file types Burrito will check for

  -- lines that wrap with no other lines
  independent_patterns = {
    " {0,3}\\* *\\* *\\*",          -- Thematic Breaks
    " {0,3}- *- *-",                -- Thematic Breaks
    " {0,3}_ *_ *_",                -- Thematic Breaks
    " {0,3}-+ *$",                  -- Setext Heading Underline
    " {0,3}=+ *$",                  -- Setext Heading Underline
    " *$",                          -- All Whitespace
    " {0,3}`{3}",                   -- Fenced Code Block
    " {0,3}~{3}",                   -- Fenced Code Block
  },

  -- lines that wrap only with lines below
  bottom_only_patterns = {
    " {0,3}>",                      -- Block Quote
    " {0,3}[-+*] ",                 -- Bullet Lists
    " {0,3}[0123456789]{1,9}[.)] ", -- Ordered Lists
  },

  -- lines that don't wrap at all, not even if it reaches col 80
  no_wrap_patterns = {
    " {0,3}#{1,6} ",                -- ATX Headings
    " {4}",                         -- Indented Code Block
    "[|:]",                         -- Tables
  },

  -- lines that surround lines that don't wrap at all
  code_block_patterns = {
    " {0,3}`{3}",                   -- Fenced Code Block
    " {0,3}~{3}",                   -- Fenced Code Block
  },
}

M.get = function() return config end
M.set = function(x) config = x end

M.get_col = function() return config.col end
M.set_col = function(x) config.col = x end

M.get_range = function() return config.range end
M.set_range = function(x) config.range = x end

M.get_check_whole_paragraph = function() return config.check_whole_paragraph end
M.set_check_whole_paragraph = function(x) config.check_whole_paragraph = x end

M.get_file_types = function() return config.file_types end
M.set_file_types = function(x) config.file_types = x end

M.get_independent_patterns = function() return config.independent_patterns end
M.set_independent_patterns = function(x) config.independent_patterns = x end

M.get_bottom_only_patterns = function() return config.bottom_only_patterns end
M.set_bottom_only_patterns = function(x) config.bottom_only_patterns = x end

M.get_no_wrap_patterns = function() return config.no_wrap_patterns end
M.set_no_wrap_patterns = function(x) config.no_wrap_patterns = x end

M.get_code_block_patterns = function() return config.code_block_patterns end
M.set_code_block_patterns = function(x) config.code_block_patterns = x end

return M
