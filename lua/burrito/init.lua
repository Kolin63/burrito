-- checks buffer for lines that need to be wrapped
-- start_line: what line to start checking at
function burrito_check(start_line)
  -- get all lines in buffer
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, -1, false)

  for i = start_line, #lines + start_line - 1 do
    local line = lines[i - start_line + 1]

    -- check line length for if it needs to be wrapped
    if #line > 80 then

      -- split line into two 80-character lines
      local new_lines = {}
      
      -- the column at which the line is going to be broken
      local break_col = 80

      -- smart wrapping with words
      for col=80, 1, -1 do
        if line:sub(col, col) == ' ' then
          break_col = col
          goto split_line
        end
      end

      ::split_line::
      new_lines[1] = line:sub(1, break_col)
      new_lines[2] = line:sub(break_col + 1)

      -- calculate new cursor position
      local cursor_pos = vim.api.nvim_win_get_cursor(0)
      if cursor_pos[2] >= 80 then
        cursor_pos[1] = cursor_pos[1] + 1
        cursor_pos[2] = cursor_pos[2] - break_col + 1
      end

      -- replace long line with 80 character one and the new line
      vim.api.nvim_buf_set_lines(0, i-1, i, true, new_lines)

      -- change cursor position to the next line
      vim.api.nvim_win_set_cursor(0, cursor_pos)

      -- recurse
      burrito_check(i + 1)

    end
  end

end

-- set the auto command to check the file for lines that need to be wrapped
-- whenever the file is changed
vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
  pattern = "*.md",
  callback = function() burrito_check(1) end
})

-- make a user command if the wrapping somehow got outdated
vim.api.nvim_create_user_command("Burrito", function() burrito_check(1) end, {})
