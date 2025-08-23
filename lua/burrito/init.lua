function burrito_check()
  -- get all lines in buffer
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  -- needs to be a variable so we can change it
  local lines_amt = #lines

  for i = 1, lines_amt do
    local line = lines[i]

    -- check line length
    if #line > 80 then

      local new_lines = {}
      repeat
        table.insert(new_lines, line:sub(1, 80))
        line = line:sub(81)
        lines_amt = lines_amt + 1
      until #line == 0

      vim.api.nvim_buf_set_lines(0, i-1, i, false, new_lines)
      local old_cursor_pos = vim.api.nvim_win_get_cursor(0)
      vim.api.nvim_win_set_cursor(0, { old_cursor_pos[1] + #new_lines - 1, 1 })
    end
  end
end

-- set the auto command to check the file for lines that need to be wrapped
-- whenever the file is changed
vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
  pattern = "*.md",
  callback = burrito_check
})
