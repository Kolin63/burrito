function burrito_check()
  -- get all lines in buffer
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  -- needs to be a variable so we can change it
  local lines_amt = #lines

  for i = 1, lines_amt do
    local line = lines[i]

    -- check line length
    if #line > 80 then

      -- split line into multiple 80-character lines
      local new_lines = {}
      repeat
        local break_col = 80

        -- smart wrapping with words
        for col=80, 1, -1 do
          if line:sub(col, col) == ' ' then
            break_col = col
            goto split_line
          end
        end

        -- split the line
        ::split_line::
        table.insert(new_lines, line:sub(1, break_col))
        line = line:sub(break_col + 1)
        lines_amt = lines_amt + 1

      until #line == 0

      -- replace long line with 80 character one, and insert other lines
      vim.api.nvim_buf_set_lines(0, i-1, i, false, new_lines)

      -- change cursor position to the next line
      local old_cursor_pos = vim.api.nvim_win_get_cursor(0)
      vim.api.nvim_win_set_cursor(0, { 
        old_cursor_pos[1] + #new_lines - 1, -- row
        #new_lines[#new_lines]              -- column
      })

    end
  end
end

-- set the auto command to check the file for lines that need to be wrapped
-- whenever the file is changed
vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
  pattern = "*.md",
  callback = burrito_check
})
