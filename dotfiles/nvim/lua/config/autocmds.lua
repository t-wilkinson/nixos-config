-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

local function augroup(name)
  return vim.api.nvim_create_augroup("my_" .. name, { clear = true })
end

vim.api.nvim_create_autocmd("FileType", {
  group = augroup("no_spell"),
  pattern = {
    "markdown",
    "md",
  },
  callback = function()
    vim.opt_local.spell = false
    vim.opt_local.syntax = "markdown"
  end,
})
