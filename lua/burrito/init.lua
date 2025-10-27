-- SPDX-License-Identifier: MIT
-- Copyright (c) Colin Melican 2025

local M = {}

local config = require("burrito/config")

local burrito_check_wrap = require("burrito/check").burrito_check_wrap
local burrito_check_join = require("burrito/check").burrito_check_join

-- config
M.setup = function(setup)
  if setup.col ~= nil then
    config.set_col(setup.col)
  end
  if setup.file_types ~= nil then
    config.set_file_types(setup.file_types)
  end
  if setup.independent_patterns ~= nil then
    config.set_independent_patterns(setup.independent_patterns)
  end
  if setup.bottom_only_patterns ~= nil then
    config.set_bottom_only_patterns(setup.bottom_only_patterns)
  end
  if setup.no_wrap_patterns ~= nil then
    config.set_no_wrap_patterns(setup.no_wrap_patterns)
  end
  if setup.code_block_patterns ~= nil then
    config.set_code_block_patterns(setup.code_block_patterns)
  end

  local update_burrito = function()
    burrito_check_wrap(1)
    burrito_check_join(1)
  end

  -- set the auto command to check the file for lines that need to be wrapped
  -- whenever the file is changed in insert mode
  vim.api.nvim_create_autocmd("TextChangedI", {
    pattern = config.get_file_types(),
    callback = update_burrito
  })

  -- set the auto command to check the file for lines that need to be wrapped
  -- whenever the file is changed out of insert mode
  vim.api.nvim_create_autocmd("TextChanged", {
    pattern = config.get_file_types(),
    callback = update_burrito
  })

  -- set the auto command to check the file for lines that need to be wrapped
  -- whenever insert mode is left
  vim.api.nvim_create_autocmd("InsertLeave", {
    pattern = config.get_file_types(),
    callback = update_burrito
  })

  -- make a user command if the wrapping somehow got outdated
  vim.api.nvim_create_user_command("Burrito", function()
    print("Running Burrito...")
    burrito_check_wrap(1)
    burrito_check_join(1)
  end, {})

end

return M
