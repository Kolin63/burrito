print("burrito")

vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
  pattern = "*.md",
  callback = function()
    print("changed")
  end
})

[[
for each line in file:
  if length of line > 80:
    bool changed
    for col = 80; col > 0; --col:
      if line[col] == space or hyphon:
        changed = true
        insert newline
        break
    if !changed:
      insert newline at col 80
    if line[i+2] doesn't start with space or asterisk or hyphon:
      join next line and line i+2
]]
