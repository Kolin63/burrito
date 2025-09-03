independent_patterns = { 
  " {0,3}\\* *\\* *\\*",          -- Thematic Breaks
  " {0,3}- *- *-",                -- Thematic Breaks
  " {0,3}_ *_ *_",                -- Thematic Breaks
  " {0,3}#{1,6} ",                -- ATX Headings
  " {0,3}-+ *$",                  -- Setext Heading Underline
  " {0,3}=+ *$",                  -- Setext Heading Underline
  " *$",                          -- All Whitespace
  " {4}",                         -- Indented Code Block
  " {0,3}`{3}",                   -- Fenced Code Block
  " {0,3}~{3}",                   -- Fenced Code Block
  "[|:]",                         -- Tables
}

bottom_only_patterns = {
  " {0,3}>",                      -- Block Quote
  " {0,3}[-+*] ",                 -- Bullet Lists
  " {0,3}[0123456789]{1,9}[.)] ", -- Ordered Lists
}

-- returns true if pattern was found
function regex(input, pattern)
  return regex_string(input, pattern).matched
end

-- returns the part of the string that did not match the pattern
function regex_string(input, pattern)

  local backslash = false

  local surround = "" -- what is currently surrounding

  local matching_chars = {} -- the char(s) that we are currently looking for
  local match_min = 0 -- minimum times to match the char (inclusive)
  local match_max = 0 -- maximum times to match the char (inclusive) -1 for infinite

  local quantifier_found = false

  for i = 1, #pattern, 1 do

    local char = pattern:sub(i, i)

    local is_literal = false
    if backslash == true then is_literal = true end
    if surround == "[" and char ~= "]" then is_literal = true end

    if char == "\\" and is_literal == false then
      backslash = true

    elseif char == "^" and is_literal == false then
      if i ~= 1 then
        print("BURRITO: ERROR: ^ anchor must be in first character")
      end
    elseif char == "$" and is_literal == false then
      if i ~= #pattern then
        print("BURRITO: ERROR: $ anchor must be in last character")
      end
      return { matched = #input == 0, leftover = input }

    elseif char == "*" and is_literal == false then
      match_min = 0
      match_max = -1
      quantifier_found = true

    elseif char == "+" and is_literal == false then
      match_min = 1
      match_max = -1
      quantifier_found = true

    elseif char == "{" and surround == "" and is_literal == false then
      surround = "{"
      match_min = 0
      match_max = -1
    elseif char == "," and surround == "{" then
      surround = "{,"
      match_max = 0
    elseif char == "}" and (surround == "{" or surround == "{,") then
      surround = ""
      quantifier_found = true

    elseif surround == "{" then
      match_min = (match_min .. char) + 0
      match_max = match_min
    elseif surround == "{," then
      match_max = (match_max .. char) + 0

    elseif char == "[" and surround == "" and is_literal == false then
      surround = "["
      match_min = 1
      match_max = 1
    elseif surround == "[" and not (char == "]" and is_literal == false) then
      table.insert(matching_chars, char)

    else
      backslash = false
      surround = ""
      is_literal = false
      if char ~= "]" then
        table.insert(matching_chars, char)
      end

      -- if there is no quantifier following this char
      local next_char = pattern:sub(i + 1, i + 1)
      if next_char ~= "^" and next_char ~= "$" and next_char ~= "*" 
        and next_char ~= "+" and next_char ~= "{" then

        match_min = 1
        match_max = 1
        quantifier_found = true
      end
    end

    if quantifier_found then
      local inputi = 1
      local chars_found = 0

      while true do
        local inputchar = input:sub(inputi, inputi)

        for _, checkchar in ipairs(matching_chars) do
          if inputchar == checkchar then
            chars_found = chars_found + 1
            goto char_found
          end
        end

        goto non_match -- char wasn't found

        ::char_found::

        if inputi == match_max or inputi == #input then
          goto non_match
        end

        inputi = inputi + 1
      end

      ::non_match::
      if chars_found >= match_min then
        input = input:sub(chars_found + 1)
      else
        return { matched = false, leftover = input }
      end

      matching_chars = {}
      match_min = 0
      match_max = 0
      quantifier_found = false

    end

  end

  return { matched = true, leftover = input }
end

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
function get_indent_amount(line_number)
  local lines = vim.api.nvim_buf_get_lines(0, 0, line_number, false)
  local indent = 0
  local output_line = ""
  for i, line in ipairs(lines) do
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
      for _, pattern in ipairs(bottom_only_patterns) do
        r = regex_string(leftover, pattern)
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

-- returns "normal", "independent", or "bottom"
function get_line_type(line_number)
  local line = get_indent_amount(line_number).line
  for _, pattern in ipairs(independent_patterns) do
    if regex(line, pattern) == true then
      return "independent"
    end
  end

  for _, pattern in ipairs(bottom_only_patterns) do
    if regex(line, pattern) == true then
      return "bottom"
    end
  end

  return "normal"
end

-- checks buffer for lines that need to be wrapped
-- start_line: what line to start checking at
function burrito_check_wrap(start_line)
  -- get all lines in buffer
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, -1, false)

  for i = start_line, #lines + start_line - 1 do
    local linei = i - start_line + 1
    local line = lines[linei]

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
      burrito_check_wrap(i + 1)
      return

    end
  end
end

-- checks buffer for lines that need to be joined
-- start_line: what line to start checking at
function burrito_check_join(start_line)
  -- get all lines in buffer
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, -1, false)

  for i = start_line, #lines + start_line - 1 do
    local linei = i - start_line + 1
    local line = lines[linei]

    local next_linei = linei + 1

    -- out of bounds check
    if next_linei > #lines then
      goto check_next_line
    end

    local next_line = lines[next_linei]

    -- dont join with next line if:
    -- line is long
    if #line > 80 then goto check_next_line end
    -- line is independent
    line_type = get_line_type(linei)
    if line_type == "independent" then goto check_next_line end
    -- next line is independent
    next_line_type = get_line_type(next_linei)
    if next_line_type == "independent" then goto check_next_line end
    -- next line is bottom only
    if next_line_type == "bottom" then goto check_next_line end

    -- the lines can be joined, so join the lines
    new_line = { line }

    -- if a space needs to be appended to the end of the first line
    if line:sub(#line) ~= " " then
      new_line[1] = new_line[1] .. " "
    end

    -- add the next line to new line
    new_line[1] = new_line[1] .. next_line

    -- replace the line
    vim.api.nvim_buf_set_lines(0, i-1, i+1, true, new_line)

    -- recurse
    if #new_line[1] > 80 then
      burrito_check_wrap(i)
    end

    ::check_next_line::
  end
  ::early_return::
end

-- set the auto command to check the file for lines that need to be wrapped
-- whenever the file is changed in insert mode
vim.api.nvim_create_autocmd("TextChangedI", {
  pattern = "*.test",
  callback = function() burrito_check_wrap(1) end
})

-- set the auto command to check the file for lines that need to be wrapped
-- whenever the file is changed out of insert mode
vim.api.nvim_create_autocmd("TextChanged", {
  pattern = "*.test",
  callback = function() 
    burrito_check_wrap(1) 
    burrito_check_join(1)
  end
})

-- set the auto command to check the file for lines that need to be wrapped
-- whenever insert mode is left
vim.api.nvim_create_autocmd("InsertLeave", {
  pattern = "*.test",
  callback = function() burrito_check_join(1) end
})

-- make a user command if the wrapping somehow got outdated
vim.api.nvim_create_user_command("Burrito", function() 
  burrito_check_wrap(1) 
  burrito_check_join(1)
end, {})

vim.api.nvim_create_user_command("BurritoLineTypes", function()
  start_line = 1
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, -1, false)

  for i = start_line, #lines + start_line - 1 do
    local linei = i - start_line + 1
    local line = lines[linei]
    print(linei .. ".\t" .. get_line_type(linei):sub(1,1) .. get_indent_amount(linei).indent .. "\t" .. line)
  end
end, {})
