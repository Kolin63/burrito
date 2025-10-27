local M = {}

-- returns the part of the string that did not match the pattern
M.regex_string = function(input, pattern)

  local backslash = false

  local surround = "" -- what is currently surrounding

  local matching_chars = {} -- the char(s) that we are currently looking for
  local match_min = 0 -- minimum times to match the char (inclusive)
  local match_max = 0 -- maximum times to match the char (inclusive) -1 infinite

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

-- returns true if pattern was found
M.regex = function(input, pattern)
  return M.regex_string(input, pattern).matched
end


return M
