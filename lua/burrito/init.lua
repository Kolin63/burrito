-- set the auto command to check the file for lines that need to be wrapped
-- whenever the file is changed
vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
  pattern = "*.md",
  callback = function() require("burrito/check"):check() end
})

-- make a user command if the wrapping somehow got outdated
vim.api.nvim_create_user_command("Burrito", function() 
  require("burrito/check"):check() end, {})
